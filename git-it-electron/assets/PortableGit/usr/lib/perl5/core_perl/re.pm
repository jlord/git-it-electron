package re;

# pragma for controlling the regexp engine
use strict;
use warnings;

our $VERSION     = "0.32";
our @ISA         = qw(Exporter);
our @EXPORT_OK   = ('regmust',
                    qw(is_regexp regexp_pattern
                       regname regnames regnames_count));
our %EXPORT_OK = map { $_ => 1 } @EXPORT_OK;

my %bitmask = (
    taint   => 0x00100000, # HINT_RE_TAINT
    eval    => 0x00200000, # HINT_RE_EVAL
);

my $flags_hint = 0x02000000; # HINT_RE_FLAGS
my $PMMOD_SHIFT = 0;
my %reflags = (
    m => 1 << ($PMMOD_SHIFT + 0),
    s => 1 << ($PMMOD_SHIFT + 1),
    i => 1 << ($PMMOD_SHIFT + 2),
    x => 1 << ($PMMOD_SHIFT + 3),
    n => 1 << ($PMMOD_SHIFT + 5),
    p => 1 << ($PMMOD_SHIFT + 6),
    strict => 1 << ($PMMOD_SHIFT + 10),
# special cases:
    d => 0,
    l => 1,
    u => 2,
    a => 3,
    aa => 4,
);

sub setcolor {
 eval {				# Ignore errors
  require Term::Cap;

  my $terminal = Tgetent Term::Cap ({OSPEED => 9600}); # Avoid warning.
  my $props = $ENV{PERL_RE_TC} || 'md,me,so,se,us,ue';
  my @props = split /,/, $props;
  my $colors = join "\t", map {$terminal->Tputs($_,1)} @props;

  $colors =~ s/\0//g;
  $ENV{PERL_RE_COLORS} = $colors;
 };
 if ($@) {
    $ENV{PERL_RE_COLORS} ||= qq'\t\t> <\t> <\t\t';
 }

}

my %flags = (
    COMPILE         => 0x0000FF,
    PARSE           => 0x000001,
    OPTIMISE        => 0x000002,
    TRIEC           => 0x000004,
    DUMP            => 0x000008,
    FLAGS           => 0x000010,
    TEST            => 0x000020,

    EXECUTE         => 0x00FF00,
    INTUIT          => 0x000100,
    MATCH           => 0x000200,
    TRIEE           => 0x000400,

    EXTRA           => 0xFF0000,
    TRIEM           => 0x010000,
    OFFSETS         => 0x020000,
    OFFSETSDBG      => 0x040000,
    STATE           => 0x080000,
    OPTIMISEM       => 0x100000,
    STACK           => 0x280000,
    BUFFERS         => 0x400000,
    GPOS            => 0x800000,
);
$flags{ALL} = -1 & ~($flags{OFFSETS}|$flags{OFFSETSDBG}|$flags{BUFFERS});
$flags{All} = $flags{all} = $flags{DUMP} | $flags{EXECUTE};
$flags{Extra} = $flags{EXECUTE} | $flags{COMPILE} | $flags{GPOS};
$flags{More} = $flags{MORE} = $flags{All} | $flags{TRIEC} | $flags{TRIEM} | $flags{STATE};
$flags{State} = $flags{DUMP} | $flags{EXECUTE} | $flags{STATE};
$flags{TRIE} = $flags{DUMP} | $flags{EXECUTE} | $flags{TRIEC};

if (defined &DynaLoader::boot_DynaLoader) {
    require XSLoader;
    XSLoader::load();
}
# else we're miniperl
# We need to work for miniperl, because the XS toolchain uses Text::Wrap, which
# uses re 'taint'.

sub _load_unload {
    my ($on)= @_;
    if ($on) {
	# We call install() every time, as if we didn't, we wouldn't
	# "see" any changes to the color environment var since
	# the last time it was called.

	# install() returns an integer, which if casted properly
	# in C resolves to a structure containing the regexp
	# hooks. Setting it to a random integer will guarantee
	# segfaults.
	$^H{regcomp} = install();
    } else {
        delete $^H{regcomp};
    }
}

sub bits {
    my $on = shift;
    my $bits = 0;
    my $turning_all_off = ! @_ && ! $on;
    my %seen;   # Has flag already been seen?
    if ($turning_all_off) {

        # Pretend were called with certain parameters, which are best dealt
        # with that way.
        push @_, keys %bitmask; # taint and eval
        push @_, 'strict';
    }

    # Process each subpragma parameter
   ARG:
    foreach my $idx (0..$#_){
        my $s=$_[$idx];
        if ($s eq 'Debug' or $s eq 'Debugcolor') {
            setcolor() if $s =~/color/i;
            ${^RE_DEBUG_FLAGS} = 0 unless defined ${^RE_DEBUG_FLAGS};
            for my $idx ($idx+1..$#_) {
                if ($flags{$_[$idx]}) {
                    if ($on) {
                        ${^RE_DEBUG_FLAGS} |= $flags{$_[$idx]};
                    } else {
                        ${^RE_DEBUG_FLAGS} &= ~ $flags{$_[$idx]};
                    }
                } else {
                    require Carp;
                    Carp::carp("Unknown \"re\" Debug flag '$_[$idx]', possible flags: ",
                               join(", ",sort keys %flags ) );
                }
            }
            _load_unload($on ? 1 : ${^RE_DEBUG_FLAGS});
            last;
        } elsif ($s eq 'debug' or $s eq 'debugcolor') {
	    setcolor() if $s =~/color/i;
	    _load_unload($on);
	    last;
        } elsif (exists $bitmask{$s}) {
	    $bits |= $bitmask{$s};
	} elsif ($EXPORT_OK{$s}) {
	    require Exporter;
	    re->export_to_level(2, 're', $s);
        } elsif ($s eq 'strict') {
            if ($on) {
                $^H{reflags} |= $reflags{$s};
                warnings::warnif('experimental::re_strict',
                                 "\"use re 'strict'\" is experimental");

                # Turn on warnings if not already done.
                if (! warnings::enabled('regexp')) {
                    require warnings;
                    warnings->import('regexp');
                    $^H{re_strict} = 1;
                }
            }
            else {
                $^H{reflags} &= ~$reflags{$s} if $^H{reflags};

                # Turn off warnings if we turned them on.
                warnings->unimport('regexp') if $^H{re_strict};
            }
	    if ($^H{reflags}) {
                $^H |= $flags_hint;
            }
            else {
                $^H &= ~$flags_hint;
            }
	} elsif ($s =~ s/^\///) {
	    my $reflags = $^H{reflags} || 0;
	    my $seen_charset;
	    while ($s =~ m/( . )/gx) {
                local $_ = $1;
		if (/[adul]/) {
                    # The 'a' may be repeated; hide this from the rest of the
                    # code by counting and getting rid of all of them, then
                    # changing to 'aa' if there is a repeat.
                    if ($_ eq 'a') {
                        my $sav_pos = pos $s;
                        my $a_count = $s =~ s/a//g;
                        pos $s = $sav_pos - 1;  # -1 because got rid of the 'a'
                        if ($a_count > 2) {
			    require Carp;
                            Carp::carp(
                            qq 'The "a" flag may only appear a maximum of twice'
                            );
                        }
                        elsif ($a_count == 2) {
                            $_ = 'aa';
                        }
                    }
		    if ($on) {
			if ($seen_charset) {
			    require Carp;
                            if ($seen_charset ne $_) {
                                Carp::carp(
                                qq 'The "$seen_charset" and "$_" flags '
                                .qq 'are exclusive'
                                );
                            }
                            else {
                                Carp::carp(
                                qq 'The "$seen_charset" flag may not appear '
                                .qq 'twice'
                                );
                            }
			}
			$^H{reflags_charset} = $reflags{$_};
			$seen_charset = $_;
		    }
		    else {
			delete $^H{reflags_charset}
                                     if defined $^H{reflags_charset}
                                        && $^H{reflags_charset} == $reflags{$_};
		    }
		} elsif (exists $reflags{$_}) {
                    $seen{$_}++;
                    $on
		      ? $reflags |= $reflags{$_}
		      : ($reflags &= ~$reflags{$_});
		} else {
		    require Carp;
		    Carp::carp(
		     qq'Unknown regular expression flag "$_"'
		    );
		    next ARG;
		}
	    }
	    ($^H{reflags} = $reflags or defined $^H{reflags_charset})
	                    ? $^H |= $flags_hint
	                    : ($^H &= ~$flags_hint);
	} else {
	    require Carp;
	    Carp::carp("Unknown \"re\" subpragma '$s' (known ones are: ",
                       join(', ', map {qq('$_')} 'debug', 'debugcolor', sort keys %bitmask),
                       ")");
	}
    }
    if (exists $seen{'x'} && $seen{'x'} > 1
        && (warnings::enabled("deprecated")
            || warnings::enabled("regexp")))
    {
        my $message = "Having more than one /x regexp modifier is deprecated";
        if (warnings::enabled("deprecated")) {
            warnings::warn("deprecated", $message);
        }
        else {
            warnings::warn("regexp", $message);
        }
    }

    if ($turning_all_off) {
        _load_unload(0);
        $^H{reflags} = 0;
        $^H{reflags_charset} = 0;
        $^H &= ~$flags_hint;
    }

    $bits;
}

sub import {
    shift;
    $^H |= bits(1, @_);
}

sub unimport {
    shift;
    $^H &= ~ bits(0, @_);
}

1;

__END__

=head1 NAME

re - Perl pragma to alter regular expression behaviour

=head1 SYNOPSIS

    use re 'taint';
    ($x) = ($^X =~ /^(.*)$/s);     # $x is tainted here

    $pat = '(?{ $foo = 1 })';
    use re 'eval';
    /foo${pat}bar/;		   # won't fail (when not under -T
                                   # switch)

    {
	no re 'taint';		   # the default
	($x) = ($^X =~ /^(.*)$/s); # $x is not tainted here

	no re 'eval';		   # the default
	/foo${pat}bar/;		   # disallowed (with or without -T
                                   # switch)
    }

    use re 'strict';               # Raise warnings for more conditions

    use re '/ix';
    "FOO" =~ / foo /; # /ix implied
    no re '/x';
    "FOO" =~ /foo/; # just /i implied

    use re 'debug';		   # output debugging info during
    /^(.*)$/s;			   # compile and run time


    use re 'debugcolor';	   # same as 'debug', but with colored
                                   # output
    ...

    use re qw(Debug All);          # Same as "use re 'debug'", but you
                                   # can use "Debug" with things other
                                   # than 'All'
    use re qw(Debug More);         # 'All' plus output more details
    no re qw(Debug ALL);           # Turn on (almost) all re debugging
                                   # in this scope

    use re qw(is_regexp regexp_pattern); # import utility functions
    my ($pat,$mods)=regexp_pattern(qr/foo/i);
    if (is_regexp($obj)) { 
        print "Got regexp: ",
            scalar regexp_pattern($obj); # just as perl would stringify
    }                                    # it but no hassle with blessed
                                         # re's.

(We use $^X in these examples because it's tainted by default.)

=head1 DESCRIPTION

=head2 'taint' mode

When C<use re 'taint'> is in effect, and a tainted string is the target
of a regexp, the regexp memories (or values returned by the m// operator
in list context) are tainted.  This feature is useful when regexp operations
on tainted data aren't meant to extract safe substrings, but to perform
other transformations.

=head2 'eval' mode

When C<use re 'eval'> is in effect, a regexp is allowed to contain
C<(?{ ... })> zero-width assertions and C<(??{ ... })> postponed
subexpressions that are derived from variable interpolation, rather than
appearing literally within the regexp.  That is normally disallowed, since
it is a
potential security risk.  Note that this pragma is ignored when the regular
expression is obtained from tainted data, i.e.  evaluation is always
disallowed with tainted regular expressions.  See L<perlre/(?{ code })> 
and L<perlre/(??{ code })>.

For the purpose of this pragma, interpolation of precompiled regular
expressions (i.e., the result of C<qr//>) is I<not> considered variable
interpolation.  Thus:

    /foo${pat}bar/

I<is> allowed if $pat is a precompiled regular expression, even
if $pat contains C<(?{ ... })> assertions or C<(??{ ... })> subexpressions.

=head2 'strict' mode

Note that this is an experimental feature which may be changed or removed in a
future Perl release.

When C<use re 'strict'> is in effect, stricter checks are applied than
otherwise when compiling regular expressions patterns.  These may cause more
warnings to be raised than otherwise, and more things to be fatal instead of
just warnings.  The purpose of this is to find and report at compile time some
things, which may be legal, but have a reasonable possibility of not being the
programmer's actual intent.  This automatically turns on the C<"regexp">
warnings category (if not already on) within its scope.

As an example of something that is caught under C<"strict'>, but not
otherwise, is the pattern

 qr/\xABC/

The C<"\x"> construct without curly braces should be followed by exactly two
hex digits; this one is followed by three.  This currently evaluates as
equivalent to

 qr/\x{AB}C/

that is, the character whose code point value is C<0xAB>, followed by the
letter C<C>.  But since C<C> is a a hex digit, there is a reasonable chance
that the intent was

 qr/\x{ABC}/

that is the single character at C<0xABC>.  Under C<'strict'> it is an error to
not follow C<\x> with exactly two hex digits.  When not under C<'strict'> a
warning is generated if there is only one hex digit, and no warning is raised
if there are more than two.

It is expected that what exactly C<'strict'> does will evolve over time as we
gain experience with it.  This means that programs that compile under it in
today's Perl may not compile, or may have more or fewer warnings, in future
Perls.  There is no backwards compatibility promises with regards to it.  Also
there are already proposals for an alternate syntax for enabling it.  For
these reasons, using it will raise a C<experimental::re_strict> class warning,
unless that category is turned off.

Note that if a pattern compiled within C<'strict'> is recompiled, say by
interpolating into another pattern, outside of C<'strict'>, it is not checked
again for strictness.  This is because if it works under strict it must work
under non-strict.

=head2 '/flags' mode

When C<use re '/flags'> is specified, the given flags are automatically
added to every regular expression till the end of the lexical scope.

C<no re '/flags'> will turn off the effect of C<use re '/flags'> for the
given flags.

For example, if you want all your regular expressions to have /msx on by
default, simply put

    use re '/msx';

at the top of your code.

The character set /adul flags cancel each other out. So, in this example,

    use re "/u";
    "ss" =~ /\xdf/;
    use re "/d";
    "ss" =~ /\xdf/;

the second C<use re> does an implicit C<no re '/u'>.

Turning on one of the character set flags with C<use re> takes precedence over the
C<locale> pragma and the 'unicode_strings' C<feature>, for regular
expressions. Turning off one of these flags when it is active reverts to
the behaviour specified by whatever other pragmata are in scope. For
example:

    use feature "unicode_strings";
    no re "/u"; # does nothing
    use re "/l";
    no re "/l"; # reverts to unicode_strings behaviour

=head2 'debug' mode

When C<use re 'debug'> is in effect, perl emits debugging messages when
compiling and using regular expressions.  The output is the same as that
obtained by running a C<-DDEBUGGING>-enabled perl interpreter with the
B<-Dr> switch. It may be quite voluminous depending on the complexity
of the match.  Using C<debugcolor> instead of C<debug> enables a
form of output that can be used to get a colorful display on terminals
that understand termcap color sequences.  Set C<$ENV{PERL_RE_TC}> to a
comma-separated list of C<termcap> properties to use for highlighting
strings on/off, pre-point part on/off.
See L<perldebug/"Debugging Regular Expressions"> for additional info.

As of 5.9.5 the directive C<use re 'debug'> and its equivalents are
lexically scoped, as the other directives are.  However they have both 
compile-time and run-time effects.

See L<perlmodlib/Pragmatic Modules>.

=head2 'Debug' mode

Similarly C<use re 'Debug'> produces debugging output, the difference
being that it allows the fine tuning of what debugging output will be
emitted. Options are divided into three groups, those related to
compilation, those related to execution and those related to special
purposes. The options are as follows:

=over 4

=item Compile related options

=over 4

=item COMPILE

Turns on all compile related debug options.

=item PARSE

Turns on debug output related to the process of parsing the pattern.

=item OPTIMISE

Enables output related to the optimisation phase of compilation.

=item TRIEC

Detailed info about trie compilation.

=item DUMP

Dump the final program out after it is compiled and optimised.

=item FLAGS

Dump the flags associated with the program

=item TEST

Print output intended for testing the internals of the compile process

=back

=item Execute related options

=over 4

=item EXECUTE

Turns on all execute related debug options.

=item MATCH

Turns on debugging of the main matching loop.

=item TRIEE

Extra debugging of how tries execute.

=item INTUIT

Enable debugging of start-point optimisations.

=back

=item Extra debugging options

=over 4

=item EXTRA

Turns on all "extra" debugging options.

=item BUFFERS

Enable debugging the capture group storage during match. Warning,
this can potentially produce extremely large output.

=item TRIEM

Enable enhanced TRIE debugging. Enhances both TRIEE
and TRIEC.

=item STATE

Enable debugging of states in the engine.

=item STACK

Enable debugging of the recursion stack in the engine. Enabling
or disabling this option automatically does the same for debugging
states as well. This output from this can be quite large.

=item GPOS

Enable debugging of the \G modifier.

=item OPTIMISEM

Enable enhanced optimisation debugging and start-point optimisations.
Probably not useful except when debugging the regexp engine itself.

=item OFFSETS

Dump offset information. This can be used to see how regops correlate
to the pattern. Output format is

   NODENUM:POSITION[LENGTH]

Where 1 is the position of the first char in the string. Note that position
can be 0, or larger than the actual length of the pattern, likewise length
can be zero.

=item OFFSETSDBG

Enable debugging of offsets information. This emits copious
amounts of trace information and doesn't mesh well with other
debug options.

Almost definitely only useful to people hacking
on the offsets part of the debug engine.


=back

=item Other useful flags

These are useful shortcuts to save on the typing.

=over 4

=item ALL

Enable all options at once except OFFSETS, OFFSETSDBG and BUFFERS.
(To get every single option without exception, use both ALL and EXTRA.)

=item All

Enable DUMP and all execute options. Equivalent to:

  use re 'debug';

=item MORE

=item More

Enable the options enabled by "All", plus STATE, TRIEC, and TRIEM.

=back

=back

As of 5.9.5 the directive C<use re 'debug'> and its equivalents are
lexically scoped, as are the other directives.  However they have both
compile-time and run-time effects.

=head2 Exportable Functions

As of perl 5.9.5 're' debug contains a number of utility functions that
may be optionally exported into the caller's namespace. They are listed
below.

=over 4

=item is_regexp($ref)

Returns true if the argument is a compiled regular expression as returned
by C<qr//>, false if it is not.

This function will not be confused by overloading or blessing. In
internals terms, this extracts the regexp pointer out of the
PERL_MAGIC_qr structure so it cannot be fooled.

=item regexp_pattern($ref)

If the argument is a compiled regular expression as returned by C<qr//>,
then this function returns the pattern.

In list context it returns a two element list, the first element
containing the pattern and the second containing the modifiers used when
the pattern was compiled.

  my ($pat, $mods) = regexp_pattern($ref);

In scalar context it returns the same as perl would when stringifying a raw
C<qr//> with the same pattern inside.  If the argument is not a compiled
reference then this routine returns false but defined in scalar context,
and the empty list in list context. Thus the following

    if (regexp_pattern($ref) eq '(?^i:foo)')

will be warning free regardless of what $ref actually is.

Like C<is_regexp> this function will not be confused by overloading
or blessing of the object.

=item regmust($ref)

If the argument is a compiled regular expression as returned by C<qr//>,
then this function returns what the optimiser considers to be the longest
anchored fixed string and longest floating fixed string in the pattern.

A I<fixed string> is defined as being a substring that must appear for the
pattern to match. An I<anchored fixed string> is a fixed string that must
appear at a particular offset from the beginning of the match. A I<floating
fixed string> is defined as a fixed string that can appear at any point in
a range of positions relative to the start of the match. For example,

    my $qr = qr/here .* there/x;
    my ($anchored, $floating) = regmust($qr);
    print "anchored:'$anchored'\nfloating:'$floating'\n";

results in

    anchored:'here'
    floating:'there'

Because the C<here> is before the C<.*> in the pattern, its position
can be determined exactly. That's not true, however, for the C<there>;
it could appear at any point after where the anchored string appeared.
Perl uses both for its optimisations, preferring the longer, or, if they are
equal, the floating.

B<NOTE:> This may not necessarily be the definitive longest anchored and
floating string. This will be what the optimiser of the Perl that you
are using thinks is the longest. If you believe that the result is wrong
please report it via the L<perlbug> utility.

=item regname($name,$all)

Returns the contents of a named buffer of the last successful match. If
$all is true, then returns an array ref containing one entry per buffer,
otherwise returns the first defined buffer.

=item regnames($all)

Returns a list of all of the named buffers defined in the last successful
match. If $all is true, then it returns all names defined, if not it returns
only names which were involved in the match.

=item regnames_count()

Returns the number of distinct names defined in the pattern used
for the last successful match.

B<Note:> this result is always the actual number of distinct
named buffers defined, it may not actually match that which is
returned by C<regnames()> and related routines when those routines
have not been called with the $all parameter set.

=back

=head1 SEE ALSO

L<perlmodlib/Pragmatic Modules>.

=cut
