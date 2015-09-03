package utf8;
use strict;
use warnings;
use re "/aa";  # So we won't even try to look at above Latin1, potentially
               # resulting in a recursive call

sub DEBUG () { 0 }
$|=1 if DEBUG;

sub DESTROY {}

my %Cache;

sub croak { require Carp; Carp::croak(@_) }

sub _loose_name ($) {
    # Given a lowercase property or property-value name, return its
    # standardized version that is expected for look-up in the 'loose' hashes
    # in Heavy.pl (hence, this depends on what mktables does).  This squeezes
    # out blanks, underscores and dashes.  The complication stems from the
    # grandfathered-in 'L_', which retains a single trailing underscore.

    my $loose = $_[0] =~ s/[-\s_]//rg;

    return $loose if $loose !~ / ^ (?: is | to )? l $/x;
    return 'l_' if $_[0] =~ / l .* _ /x;    # If original had a trailing '_'
    return $loose;
}

##
## "SWASH" == "SWATCH HASH". A "swatch" is a swatch of the Unicode landscape.
## It's a data structure that encodes a set of Unicode characters.
##

{
    # If a floating point number is within this distance from the value of a
    # fraction, it is considered to be that fraction, even if many more digits
    # are specified that don't exactly match.
    my $min_floating_slop;

    # To guard against this program calling something that in turn ends up
    # calling this program with the same inputs, and hence infinitely
    # recursing, we keep a stack of the properties that are currently in
    # progress, pushed upon entry, popped upon return.
    my @recursed;

    sub SWASHNEW {
        my ($class, $type, $list, $minbits, $none) = @_;
        my $user_defined = 0;
        local $^D = 0 if $^D;

        $class = "" unless defined $class;
        print STDERR __LINE__, ": class=$class, type=$type, list=",
                                (defined $list) ? $list : ':undef:',
                                ", minbits=$minbits, none=$none\n" if DEBUG;

        ##
        ## Get the list of codepoints for the type.
        ## Called from swash_init (see utf8.c) or SWASHNEW itself.
        ##
        ## Callers of swash_init:
        ##     op.c:pmtrans             -- for tr/// and y///
        ##     regexec.c:regclass_swash -- for /[]/, \p, and \P
        ##     utf8.c:is_utf8_common    -- for common Unicode properties
        ##     utf8.c:to_utf8_case      -- for lc, uc, ucfirst, etc. and //i
        ##     Unicode::UCD::prop_invlist
        ##     Unicode::UCD::prop_invmap
        ##
        ## Given a $type, our goal is to fill $list with the set of codepoint
        ## ranges. If $type is false, $list passed is used.
        ##
        ## $minbits:
        ##     For binary properties, $minbits must be 1.
        ##     For character mappings (case and transliteration), $minbits must
        ##     be a number except 1.
        ##
        ## $list (or that filled according to $type):
        ##     Refer to perlunicode.pod, "User-Defined Character Properties."
        ##     
        ##     For binary properties, only characters with the property value
        ##     of True should be listed. The 3rd column, if any, will be ignored
        ##
        ## $none is undocumented, so I'm (khw) trying to do some documentation
        ## of it now.  It appears to be if there is a mapping in an input file
        ## that maps to 'XXXX', then that is replaced by $none+1, expressed in
        ## hexadecimal.  It is used somehow in tr///.
        ##
        ## To make the parsing of $type clear, this code takes the a rather
        ## unorthodox approach of last'ing out of the block once we have the
        ## info we need. Were this to be a subroutine, the 'last' would just
        ## be a 'return'.
        ##
        #   If a problem is found $type is returned;
        #   Upon success, a new (or cached) blessed object is returned with
        #   keys TYPE, BITS, EXTRAS, LIST, and NONE with values having the
        #   same meanings as the input parameters.
        #   SPECIALS contains a reference to any special-treatment hash in the
        #       property.
        #   INVERT_IT is non-zero if the result should be inverted before use
        #   USER_DEFINED is non-zero if the result came from a user-defined
        my $file; ## file to load data from, and also part of the %Cache key.

        # Change this to get a different set of Unicode tables
        my $unicore_dir = 'unicore';
        my $invert_it = 0;
        my $list_is_from_mktables = 0;  # Is $list returned from a mktables
                                        # generated file?  If so, we know it's
                                        # well behaved.

        if ($type)
        {
            # Verify that this isn't a recursive call for this property.
            # Can't use croak, as it may try to recurse to here itself.
            my $class_type = $class . "::$type";
            if (grep { $_ eq $class_type } @recursed) {
                CORE::die "panic: Infinite recursion in SWASHNEW for '$type'\n";
            }
            push @recursed, $class_type;

            $type =~ s/^\s+//;
            $type =~ s/\s+$//;

            # regcomp.c surrounds the property name with '__" and '_i' if this
            # is to be caseless matching.
            my $caseless = $type =~ s/^(.*)__(.*)_i$/$1$2/;

            print STDERR __LINE__, ": type=$type, caseless=$caseless\n" if DEBUG;

        GETFILE:
            {
                ##
                ## It could be a user-defined property.  Look in current
                ## package if no package given
                ##


                my $caller0 = caller(0);
                my $caller1 = $type =~ s/(.+):://
                              ? $1
                              : $caller0 eq 'main'
                                ? 'main'
                                : caller(1);

                if (defined $caller1 && $type =~ /^I[ns]\w+$/) {
                    my $prop = "${caller1}::$type";
                    if (exists &{$prop}) {
                        # stolen from Scalar::Util::PP::tainted()
                        my $tainted;
                        {
                            local($@, $SIG{__DIE__}, $SIG{__WARN__});
                            local $^W = 0;
                            no warnings;
                            eval { kill 0 * $prop };
                            $tainted = 1 if $@ =~ /^Insecure/;
                        }
                        die "Insecure user-defined property \\p{$prop}\n"
                            if $tainted;
                        no strict 'refs';
                        $list = &{$prop}($caseless);
                        $user_defined = 1;
                        last GETFILE;
                    }
                }

                # During Perl's compilation, this routine may be called before
                # the tables are constructed.  If so, we have a chicken/egg
                # problem.  If we die, the tables never get constructed, so
                # keep going, but return an empty table so only what the code
                # has compiled in internally (currently ASCII/Latin1 range
                # matching) will work.
                BEGIN {
                    # Poor man's constant, to avoid a run-time check.
                    $utf8::{miniperl}
                        = \! defined &DynaLoader::boot_DynaLoader;
                }
                if (miniperl) {
                    eval "require '$unicore_dir/Heavy.pl'";
                    if ($@) {
                        print STDERR __LINE__, ": '$@'\n" if DEBUG;
                        pop @recursed if @recursed;
                        return $type;
                    }
                }
                else {
                    require "$unicore_dir/Heavy.pl";
                }
                BEGIN { delete $utf8::{miniperl} }

                # All property names are matched caselessly
                my $property_and_table = CORE::lc $type;
                print STDERR __LINE__, ": $property_and_table\n" if DEBUG;

                # See if is of the compound form 'property=value', where the
                # value indicates the table we should use.
                my ($property, $table, @remainder) =
                                    split /\s*[:=]\s*/, $property_and_table, -1;
                if (@remainder) {
                    pop @recursed if @recursed;
                    return $type;
                }

                my $prefix;
                if (! defined $table) {
                        
                    # Here, is the single form.  The property becomes empty, and
                    # the whole value is the table.
                    $table = $property;
                    $prefix = $property = "";
                } else {
                    print STDERR __LINE__, ": $property\n" if DEBUG;

                    # Here it is the compound property=table form.  The property
                    # name is always loosely matched, and always can have an
                    # optional 'is' prefix (which isn't true in the single
                    # form).
                    $property = _loose_name($property) =~ s/^is//r;

                    # And convert to canonical form.  Quit if not valid.
                    $property = $utf8::loose_property_name_of{$property};
                    if (! defined $property) {
                        pop @recursed if @recursed;
                        return $type;
                    }

                    $prefix = "$property=";

                    # If the rhs looks like it is a number...
                    print STDERR __LINE__, ": table=$table\n" if DEBUG;
                    if ($table =~ qr{ ^ [ \s 0-9 _  + / . -]+ $ }x) {
                        print STDERR __LINE__, ": table=$table\n" if DEBUG;

                        # Don't allow leading nor trailing slashes 
                        if ($table =~ / ^ \/ | \/ $ /x) {
                            pop @recursed if @recursed;
                            return $type;
                        }

                        # Split on slash, in case it is a rational, like \p{1/5}
                        my @parts = split qr{ \s* / \s* }x, $table, -1;
                        print __LINE__, ": $type\n" if @parts > 2 && DEBUG;

                        # Can have maximum of one slash
                        if (@parts > 2) {
                            pop @recursed if @recursed;
                            return $type;
                        }

                        foreach my $part (@parts) {
                            print __LINE__, ": part=$part\n" if DEBUG;

                            $part =~ s/^\+\s*//;    # Remove leading plus
                            $part =~ s/^-\s*/-/;    # Remove blanks after unary
                                                    # minus

                            # Remove underscores between digits.
                            $part =~ s/(?<= [0-9] ) _ (?= [0-9] ) //xg;

                            # No leading zeros (but don't make a single '0'
                            # into a null string)
                            $part =~ s/ ^ ( -? ) 0+ /$1/x;
                            $part .= '0' if $part eq '-' || $part eq "";

                            # No trailing zeros after a decimal point
                            $part =~ s/ ( \. .*? ) 0+ $ /$1/x;

                            # Begin with a 0 if a leading decimal point
                            $part =~ s/ ^ ( -? ) \. /${1}0./x;

                            # Ensure not a trailing decimal point: turn into an
                            # integer
                            $part =~ s/ \. $ //x;

                            print STDERR __LINE__, ": part=$part\n" if DEBUG;
                            #return $type if $part eq "";
                            
                            # Result better look like a number.  (This test is
                            # needed because, for example could have a plus in
                            # the middle.)
                            if ($part !~ / ^ -? [0-9]+ ( \. [0-9]+)? $ /x) {
                                pop @recursed if @recursed;
                                return $type;
                            }
                        }

                        #  If a rational...
                        if (@parts == 2) {

                            # If denominator is negative, get rid of it, and ...
                            if ($parts[1] =~ s/^-//) {

                                # If numerator is also negative, convert the
                                # whole thing to positive, or move the minus to
                                # the numerator
                                if ($parts[0] !~ s/^-//) {
                                    $parts[0] = '-' . $parts[0];
                                }
                            }
                            $table = join '/', @parts;
                        }
                        elsif ($property ne 'nv' || $parts[0] !~ /\./) {

                            # Here is not numeric value, or doesn't have a
                            # decimal point.  No further manipulation is
                            # necessary.  (Note the hard-coded property name.
                            # This could fail if other properties eventually
                            # had fractions as well; perhaps the cjk ones
                            # could evolve to do that.  This hard-coding could
                            # be fixed by mktables generating a list of
                            # properties that could have fractions.)
                            $table = $parts[0];
                        } else {

                            # Here is a floating point numeric_value.  Try to
                            # convert to rational.  First see if is in the list
                            # of known ones.
                            if (exists $utf8::nv_floating_to_rational{$parts[0]}) {
                                $table = $utf8::nv_floating_to_rational{$parts[0]};
                            } else {

                                # Here not in the list.  See if is close
                                # enough to something in the list.  First
                                # determine what 'close enough' means.  It has
                                # to be as tight as what mktables says is the
                                # maximum slop, and as tight as how many
                                # digits we were passed.  That is, if the user
                                # said .667, .6667, .66667, etc.  we match as
                                # many digits as they passed until get to
                                # where it doesn't matter any more due to the
                                # machine's precision.  If they said .6666668,
                                # we fail.
                                (my $fraction = $parts[0]) =~ s/^.*\.//;
                                my $epsilon = 10 ** - (length($fraction));
                                if ($epsilon > $utf8::max_floating_slop) {
                                    $epsilon = $utf8::max_floating_slop;
                                }

                                # But it can't be tighter than the minimum
                                # precision for this machine.  If haven't
                                # already calculated that minimum, do so now.
                                if (! defined $min_floating_slop) {

                                    # Keep going down an order of magnitude
                                    # until find that adding this quantity to
                                    # 1 remains 1; but put an upper limit on
                                    # this so in case this algorithm doesn't
                                    # work properly on some platform, that we
                                    # won't loop forever.
                                    my $count = 0;
                                    $min_floating_slop = 1;
                                    while (1+ $min_floating_slop != 1
                                           && $count++ < 50)
                                    {
                                        my $next = $min_floating_slop / 10;
                                        last if $next == 0; # If underflows,
                                                            # use previous one
                                        $min_floating_slop = $next;
                                        print STDERR __LINE__, ": min_float_slop=$min_floating_slop\n" if DEBUG;
                                    }

                                    # Back off a couple orders of magnitude,
                                    # just to be safe.
                                    $min_floating_slop *= 100;
                                }
                                    
                                if ($epsilon < $min_floating_slop) {
                                    $epsilon = $min_floating_slop;
                                }
                                print STDERR __LINE__, ": fraction=.$fraction; epsilon=$epsilon\n" if DEBUG;

                                undef $table;

                                # And for each possible rational in the table,
                                # see if it is within epsilon of the input.
                                foreach my $official
                                        (keys %utf8::nv_floating_to_rational)
                                {
                                    print STDERR __LINE__, ": epsilon=$epsilon, official=$official, diff=", abs($parts[0] - $official), "\n" if DEBUG;
                                    if (abs($parts[0] - $official) < $epsilon) {
                                      $table =
                                      $utf8::nv_floating_to_rational{$official};
                                        last;
                                    }
                                }

                                # Quit if didn't find one.
                                if (! defined $table) {
                                    pop @recursed if @recursed;
                                    return $type;
                                }
                            }
                        }
                        print STDERR __LINE__, ": $property=$table\n" if DEBUG;
                    }
                }

                # Combine lhs (if any) and rhs to get something that matches
                # the syntax of the lookups.
                $property_and_table = "$prefix$table";
                print STDERR __LINE__, ": $property_and_table\n" if DEBUG;

                # First try stricter matching.
                $file = $utf8::stricter_to_file_of{$property_and_table};

                # If didn't find it, try again with looser matching by editing
                # out the applicable characters on the rhs and looking up
                # again.
                if (! defined $file) {
                    $table = _loose_name($table);
                    $property_and_table = "$prefix$table";
                    print STDERR __LINE__, ": $property_and_table\n" if DEBUG;
                    $file = $utf8::loose_to_file_of{$property_and_table};
                }

                # Add the constant and go fetch it in.
                if (defined $file) {

                    # If the file name contains a !, it means to invert.  The
                    # 0+ makes sure result is numeric
                    $invert_it = 0 + $file =~ s/!//;

                    if ($utf8::why_deprecated{$file}) {
                        warnings::warnif('deprecated', "Use of '$type' in \\p{} or \\P{} is deprecated because: $utf8::why_deprecated{$file};");
                    }

                    if ($caseless
                        && exists $utf8::caseless_equivalent{$property_and_table})
                    {
                        $file = $utf8::caseless_equivalent{$property_and_table};
                    }

                    # The pseudo-directory '#' means that there really isn't a
                    # file to read, the data is in-line as part of the string;
                    # we extract it below.
                    $file = "$unicore_dir/lib/$file.pl" unless $file =~ m!^#/!;
                    last GETFILE;
                }
                print STDERR __LINE__, ": didn't find $property_and_table\n" if DEBUG;

                ##
                ## Last attempt -- see if it's a standard "To" name
                ## (e.g. "ToLower")  ToTitle is used by ucfirst().
                ## The user-level way to access ToDigit() and ToFold()
                ## is to use Unicode::UCD.
                ##
                # Only check if caller wants non-binary
                my $retried = 0;
                if ($minbits != 1 && $property_and_table =~ s/^to//) {{
                    # Look input up in list of properties for which we have
                    # mapping files.
                    if (defined ($file =
                          $utf8::loose_property_to_file_of{$property_and_table}))
                    {
                        $type = $utf8::file_to_swash_name{$file};
                        print STDERR __LINE__, ": type set to $type\n" if DEBUG;
                        $file = "$unicore_dir/$file.pl";
                        last GETFILE;
                    }   # If that fails see if there is a corresponding binary
                        # property file
                    elsif (defined ($file =
                                   $utf8::loose_to_file_of{$property_and_table}))
                    {

                        # Here, there is no map file for the property we are
                        # trying to get the map of, but this is a binary
                        # property, and there is a file for it that can easily
                        # be translated to a mapping.

                        # In the case of properties that are forced to binary,
                        # they are a combination.  We return the actual
                        # mapping instead of the binary.  If the input is
                        # something like 'Tocjkkiicore', it will be found in
                        # %loose_property_to_file_of above as => 'To/kIICore'.
                        # But the form like ToIskiicore won't be.  To fix
                        # this, it was easiest to do it here.  These
                        # properties are the complements of the default
                        # property, so there is an entry in %loose_to_file_of
                        # that is 'iskiicore' => '!kIICore/N', If we find such
                        # an entry, strip off things and try again, which
                        # should find the entry in %loose_property_to_file_of.
                        # Actual binary properties that are of this form, such
                        # as this entry: 'ishrkt' => '!Perl/Any' will also be
                        # retried, but won't be in %loose_property_to_file_of,
                        # and instead the next time through, it will find
                        # 'hrkt' => '!Perl/Any' and proceed.
                        redo if ! $retried
                                && $file =~ /^!/
                                && $property_and_table =~ s/^is//;

                        # This is a binary property.  Setting this here causes
                        # it to be stored as such in the cache, so if someone
                        # comes along later looking for just a binary, they
                        # get it.
                        $minbits = 1;

                        # The 0+ makes sure is numeric
                        $invert_it = 0 + $file =~ s/!//;
                        $file = "$unicore_dir/lib/$file.pl" unless $file =~ m!^#/!;
                        last GETFILE;
                    }
                } }

                ##
                ## If we reach this line, it's because we couldn't figure
                ## out what to do with $type. Ouch.
                ##

                pop @recursed if @recursed;
                return $type;
            } # end of GETFILE block

            if (defined $file) {
                print STDERR __LINE__, ": found it (file='$file')\n" if DEBUG;

                ##
                ## If we reach here, it was due to a 'last GETFILE' above
                ## (exception: user-defined properties and mappings), so we
                ## have a filename, so now we load it if we haven't already.

                # The pseudo-directory '#' means the result isn't really a
                # file, but is in-line, with semi-colons to be turned into
                # new-lines.  Since it is in-line there is no advantage to
                # caching the result
                if ($file =~ s!^#/!!) {
                    $list = $utf8::inline_definitions[$file];
                }
                else {
                    # Here, we have an actual file to read in and load, but it
                    # may already have been read-in and cached.  The cache key
                    # is the class and file to load, and whether the results
                    # need to be inverted.
                    my $found = $Cache{$class, $file, $invert_it};
                    if ($found and ref($found) eq $class) {
                        print STDERR __LINE__, ": Returning cached swash for '$class,$file,$invert_it' for \\p{$type}\n" if DEBUG;
                        pop @recursed if @recursed;
                        return $found;
                    }

                    local $@;
                    local $!;
                    $list = do $file; die $@ if $@;
                }

                $list_is_from_mktables = 1;
            }
        } # End of $type is non-null

        # Here, either $type was null, or we found the requested property and
        # read it into $list

        my $extras = "";

        my $bits = $minbits;

        # mktables lists don't have extras, like '&utf8::prop', so don't need
        # to separate them; also lists are already sorted, so don't need to do
        # that.
        if ($list && ! $list_is_from_mktables) {
            my $taint = substr($list,0,0); # maintain taint

            # Separate the extras from the code point list, and make sure
            # user-defined properties and tr/// are well-behaved for
            # downstream code.
            if ($user_defined || $none) {
                my @tmp = split(/^/m, $list);
                my %seen;
                no warnings;

                # The extras are anything that doesn't begin with a hex digit.
                $extras = join '', $taint, grep /^[^0-9a-fA-F]/, @tmp;

                # Remove the extras, and sort the remaining entries by the
                # numeric value of their beginning hex digits, removing any
                # duplicates.
                $list = join '', $taint,
                        map  { $_->[1] }
                        sort { $a->[0] <=> $b->[0] }
                        map  { /^([0-9a-fA-F]+)/ && !$seen{$1}++ ? [ CORE::hex($1), $_ ] : () }
                        @tmp; # XXX doesn't do ranges right
            }
            else {
                # mktables has gone to some trouble to make non-user defined
                # properties well-behaved, so we can skip the effort we do for
                # user-defined ones.  Any extras are at the very beginning of
                # the string.

                # This regex splits out the first lines of $list into $1 and
                # strips them off from $list, until we get one that begins
                # with a hex number, alone on the line, or followed by a tab.
                # Either portion may be empty.
                $list =~ s/ \A ( .*? )
                            (?: \z | (?= ^ [0-9a-fA-F]+ (?: \t | $) ) )
                          //msx;

                $extras = "$taint$1";
            }
        }

        if ($none) {
            my $hextra = sprintf "%04x", $none + 1;
            $list =~ s/\tXXXX$/\t$hextra/mg;
        }

        if ($minbits != 1 && $minbits < 32) { # not binary property
            my $top = 0;
            while ($list =~ /^([0-9a-fA-F]+)(?:[\t]([0-9a-fA-F]+)?)(?:[ \t]([0-9a-fA-F]+))?/mg) {
                my $min = CORE::hex $1;
                my $max = defined $2 ? CORE::hex $2 : $min;
                my $val = defined $3 ? CORE::hex $3 : 0;
                $val += $max - $min if defined $3;
                $top = $val if $val > $top;
            }
            my $topbits =
                $top > 0xffff ? 32 :
                $top > 0xff ? 16 : 8;
            $bits = $topbits if $bits < $topbits;
        }

        my @extras;
        if ($extras) {
            for my $x ($extras) {
                my $taint = substr($x,0,0); # maintain taint
                pos $x = 0;
                while ($x =~ /^([^0-9a-fA-F\n])(.*)/mg) {
                    my $char = "$1$taint";
                    my $name = "$2$taint";
                    print STDERR __LINE__, ": char [$char] => name [$name]\n"
                        if DEBUG;
                    if ($char =~ /[-+!&]/) {
                        my ($c,$t) = split(/::/, $name, 2);	# bogus use of ::, really
                        my $subobj;
                        if ($c eq 'utf8') {
                            $subobj = utf8->SWASHNEW($t, "", $minbits, 0);
                        }
                        elsif (exists &$name) {
                            $subobj = utf8->SWASHNEW($name, "", $minbits, 0);
                        }
                        elsif ($c =~ /^([0-9a-fA-F]+)/) {
                            $subobj = utf8->SWASHNEW("", $c, $minbits, 0);
                        }
                        print STDERR __LINE__, ": returned from getting sub object for $name\n" if DEBUG;
                        if (! ref $subobj) {
                            pop @recursed if @recursed && $type;
                            return $subobj;
                        }
                        push @extras, $name => $subobj;
                        $bits = $subobj->{BITS} if $bits < $subobj->{BITS};
                        $user_defined = $subobj->{USER_DEFINED}
                                              if $subobj->{USER_DEFINED};
                    }
                }
            }
        }

        if (DEBUG) {
            print STDERR __LINE__, ": CLASS = $class, TYPE => $type, BITS => $bits, NONE => $none, INVERT_IT => $invert_it, USER_DEFINED => $user_defined";
            print STDERR "\nLIST =>\n$list" if defined $list;
            print STDERR "\nEXTRAS =>\n$extras" if defined $extras;
            print STDERR "\n";
        }

        my $SWASH = bless {
            TYPE => $type,
            BITS => $bits,
            EXTRAS => $extras,
            LIST => $list,
            NONE => $none,
            USER_DEFINED => $user_defined,
            @extras,
        } => $class;

        if ($file) {
            $Cache{$class, $file, $invert_it} = $SWASH;
            if ($type
                && exists $utf8::SwashInfo{$type}
                && exists $utf8::SwashInfo{$type}{'specials_name'})
            {
                my $specials_name = $utf8::SwashInfo{$type}{'specials_name'};
                no strict "refs";
                print STDERR "\nspecials_name => $specials_name\n" if DEBUG;
                $SWASH->{'SPECIALS'} = \%$specials_name;
            }
            $SWASH->{'INVERT_IT'} = $invert_it;
        }

        pop @recursed if @recursed && $type;

        return $SWASH;
    }
}

# Now SWASHGET is recasted into a C function S_swatch_get (see utf8.c).

1;
