# Copyright (c) 1997-2009 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Maintained since 2013 by Paul Evans <leonerd@leonerd.org.uk>

package List::Util;

use strict;
require Exporter;

our @ISA        = qw(Exporter);
our @EXPORT_OK  = qw(
  all any first min max minstr maxstr none notall product reduce sum sum0 shuffle
  pairmap pairgrep pairfirst pairs pairkeys pairvalues
);
our $VERSION    = "1.41";
our $XS_VERSION = $VERSION;
$VERSION    = eval $VERSION;

require XSLoader;
XSLoader::load('List::Util', $XS_VERSION);

sub import
{
  my $pkg = caller;

  # (RT88848) Touch the caller's $a and $b, to avoid the warning of
  #   Name "main::a" used only once: possible typo" warning
  no strict 'refs';
  ${"${pkg}::a"} = ${"${pkg}::a"};
  ${"${pkg}::b"} = ${"${pkg}::b"};

  goto &Exporter::import;
}

# For objects returned by pairs()
sub List::Util::_Pair::key   { shift->[0] }
sub List::Util::_Pair::value { shift->[1] }

1;

__END__

=head1 NAME

List::Util - A selection of general-utility list subroutines

=head1 SYNOPSIS

    use List::Util qw(first max maxstr min minstr reduce shuffle sum);

=head1 DESCRIPTION

C<List::Util> contains a selection of subroutines that people have expressed
would be nice to have in the perl core, but the usage would not really be high
enough to warrant the use of a keyword, and the size so small such that being
individual extensions would be wasteful.

By default C<List::Util> does not export any subroutines.

=cut

=head1 LIST-REDUCTION FUNCTIONS

The following set of functions all reduce a list down to a single value.

=cut

=head2 $result = reduce { BLOCK } @list

Reduces C<@list> by calling C<BLOCK> in a scalar context multiple times,
setting C<$a> and C<$b> each time. The first call will be with C<$a> and C<$b>
set to the first two elements of the list, subsequent calls will be done by
setting C<$a> to the result of the previous call and C<$b> to the next element
in the list.

Returns the result of the last call to the C<BLOCK>. If C<@list> is empty then
C<undef> is returned. If C<@list> only contains one element then that element
is returned and C<BLOCK> is not executed.

The following examples all demonstrate how C<reduce> could be used to implement
the other list-reduction functions in this module. (They are not in fact
implemented like this, but instead in a more efficient manner in individual C
functions).

    $foo = reduce { defined($a)            ? $a :
                    $code->(local $_ = $b) ? $b :
                                             undef } undef, @list # first

    $foo = reduce { $a > $b ? $a : $b } 1..10       # max
    $foo = reduce { $a gt $b ? $a : $b } 'A'..'Z'   # maxstr
    $foo = reduce { $a < $b ? $a : $b } 1..10       # min
    $foo = reduce { $a lt $b ? $a : $b } 'aa'..'zz' # minstr
    $foo = reduce { $a + $b } 1 .. 10               # sum
    $foo = reduce { $a . $b } @bar                  # concat

    $foo = reduce { $a || $code->(local $_ = $b) } 0, @bar   # any
    $foo = reduce { $a && $code->(local $_ = $b) } 1, @bar   # all
    $foo = reduce { $a && !$code->(local $_ = $b) } 1, @bar  # none
    $foo = reduce { $a || !$code->(local $_ = $b) } 0, @bar  # notall
       # Note that these implementations do not fully short-circuit

If your algorithm requires that C<reduce> produce an identity value, then make
sure that you always pass that identity value as the first argument to prevent
C<undef> being returned

  $foo = reduce { $a + $b } 0, @values;             # sum with 0 identity value

The remaining list-reduction functions are all specialisations of this generic
idea.

=head2 any

    my $bool = any { BLOCK } @list;

I<Since version 1.33.>

Similar to C<grep> in that it evaluates C<BLOCK> setting C<$_> to each element
of C<@list> in turn. C<any> returns true if any element makes the C<BLOCK>
return a true value. If C<BLOCK> never returns true or C<@list> was empty then
it returns false.

Many cases of using C<grep> in a conditional can be written using C<any>
instead, as it can short-circuit after the first true result.

    if( any { length > 10 } @strings ) {
        # at least one string has more than 10 characters
    }

=head2 all

    my $bool = all { BLOCK } @list;

I<Since version 1.33.>

Similar to L</any>, except that it requires all elements of the C<@list> to
make the C<BLOCK> return true. If any element returns false, then it returns
false. If the C<BLOCK> never returns false or the C<@list> was empty then it
returns true.

=head2 none

=head2 notall

    my $bool = none { BLOCK } @list;

    my $bool = notall { BLOCK } @list;

I<Since version 1.33.>

Similar to L</any> and L</all>, but with the return sense inverted. C<none>
returns true only if no value in the C<@list> causes the C<BLOCK> to return
true, and C<notall> returns true only if not all of the values do.

=head2 first

    my $val = first { BLOCK } @list;

Similar to C<grep> in that it evaluates C<BLOCK> setting C<$_> to each element
of C<@list> in turn. C<first> returns the first element where the result from
C<BLOCK> is a true value. If C<BLOCK> never returns true or C<@list> was empty
then C<undef> is returned.

    $foo = first { defined($_) } @list    # first defined value in @list
    $foo = first { $_ > $value } @list    # first value in @list which
                                          # is greater than $value

=head2 max

    my $num = max @list;

Returns the entry in the list with the highest numerical value. If the list is
empty then C<undef> is returned.

    $foo = max 1..10                # 10
    $foo = max 3,9,12               # 12
    $foo = max @bar, @baz           # whatever

=head2 maxstr

    my $str = maxstr @list;

Similar to L</max>, but treats all the entries in the list as strings and
returns the highest string as defined by the C<gt> operator. If the list is
empty then C<undef> is returned.

    $foo = maxstr 'A'..'Z'          # 'Z'
    $foo = maxstr "hello","world"   # "world"
    $foo = maxstr @bar, @baz        # whatever

=head2 min

    my $num = min @list;

Similar to L</max> but returns the entry in the list with the lowest numerical
value. If the list is empty then C<undef> is returned.

    $foo = min 1..10                # 1
    $foo = min 3,9,12               # 3
    $foo = min @bar, @baz           # whatever

=head2 minstr

    my $str = minstr @list;

Similar to L</min>, but treats all the entries in the list as strings and
returns the lowest string as defined by the C<lt> operator. If the list is
empty then C<undef> is returned.

    $foo = minstr 'A'..'Z'          # 'A'
    $foo = minstr "hello","world"   # "hello"
    $foo = minstr @bar, @baz        # whatever

=head2 product

    my $num = product @list;

I<Since version 1.35.>

Returns the numerical product of all the elements in C<@list>. If C<@list> is
empty then C<1> is returned.

    $foo = product 1..10            # 3628800
    $foo = product 3,9,12           # 324

=head2 sum

    my $num_or_undef = sum @list;

Returns the numerical sum of all the elements in C<@list>. For backwards
compatibility, if C<@list> is empty then C<undef> is returned.

    $foo = sum 1..10                # 55
    $foo = sum 3,9,12               # 24
    $foo = sum @bar, @baz           # whatever

=head2 sum0

    my $num = sum0 @list;

I<Since version 1.26.>

Similar to L</sum>, except this returns 0 when given an empty list, rather
than C<undef>.

=cut

=head1 KEY/VALUE PAIR LIST FUNCTIONS

The following set of functions, all inspired by L<List::Pairwise>, consume an
even-sized list of pairs. The pairs may be key/value associations from a hash,
or just a list of values. The functions will all preserve the original ordering
of the pairs, and will not be confused by multiple pairs having the same "key"
value - nor even do they require that the first of each pair be a plain string.

=cut

=head2 pairgrep

    my @kvlist = pairgrep { BLOCK } @kvlist;

    my $count = pairgrep { BLOCK } @kvlist;

I<Since version 1.29.>

Similar to perl's C<grep> keyword, but interprets the given list as an
even-sized list of pairs. It invokes the C<BLOCK> multiple times, in scalar
context, with C<$a> and C<$b> set to successive pairs of values from the
C<@kvlist>.

Returns an even-sized list of those pairs for which the C<BLOCK> returned true
in list context, or the count of the B<number of pairs> in scalar context.
(Note, therefore, in scalar context that it returns a number half the size of
the count of items it would have returned in list context).

    @subset = pairgrep { $a =~ m/^[[:upper:]]+$/ } @kvlist

As with C<grep> aliasing C<$_> to list elements, C<pairgrep> aliases C<$a> and
C<$b> to elements of the given list. Any modifications of it by the code block
will be visible to the caller.

=head2 pairfirst

    my ( $key, $val ) = pairfirst { BLOCK } @kvlist;

    my $found = pairfirst { BLOCK } @kvlist;

I<Since version 1.30.>

Similar to the L</first> function, but interprets the given list as an
even-sized list of pairs. It invokes the C<BLOCK> multiple times, in scalar
context, with C<$a> and C<$b> set to successive pairs of values from the
C<@kvlist>.

Returns the first pair of values from the list for which the C<BLOCK> returned
true in list context, or an empty list of no such pair was found. In scalar
context it returns a simple boolean value, rather than either the key or the
value found.

    ( $key, $value ) = pairfirst { $a =~ m/^[[:upper:]]+$/ } @kvlist

As with C<grep> aliasing C<$_> to list elements, C<pairfirst> aliases C<$a> and
C<$b> to elements of the given list. Any modifications of it by the code block
will be visible to the caller.

=head2 pairmap

    my @list = pairmap { BLOCK } @kvlist;

    my $count = pairmap { BLOCK } @kvlist;

I<Since version 1.29.>

Similar to perl's C<map> keyword, but interprets the given list as an
even-sized list of pairs. It invokes the C<BLOCK> multiple times, in list
context, with C<$a> and C<$b> set to successive pairs of values from the
C<@kvlist>.

Returns the concatenation of all the values returned by the C<BLOCK> in list
context, or the count of the number of items that would have been returned in
scalar context.

    @result = pairmap { "The key $a has value $b" } @kvlist

As with C<map> aliasing C<$_> to list elements, C<pairmap> aliases C<$a> and
C<$b> to elements of the given list. Any modifications of it by the code block
will be visible to the caller.

See L</KNOWN BUGS> for a known-bug with C<pairmap>, and a workaround.

=head2 pairs

    my @pairs = pairs @kvlist;

I<Since version 1.29.>

A convenient shortcut to operating on even-sized lists of pairs, this function
returns a list of ARRAY references, each containing two items from the given
list. It is a more efficient version of

    @pairs = pairmap { [ $a, $b ] } @kvlist

It is most convenient to use in a C<foreach> loop, for example:

    foreach my $pair ( pairs @KVLIST ) {
       my ( $key, $value ) = @$pair;
       ...
    }

Since version C<1.39> these ARRAY references are blessed objects, recognising
the two methods C<key> and C<value>. The following code is equivalent:

    foreach my $pair ( pairs @KVLIST ) {
       my $key   = $pair->key;
       my $value = $pair->value;
       ...
    }

=head2 pairkeys

    my @keys = pairkeys @kvlist;

I<Since version 1.29.>

A convenient shortcut to operating on even-sized lists of pairs, this function
returns a list of the the first values of each of the pairs in the given list.
It is a more efficient version of

    @keys = pairmap { $a } @kvlist

=head2 pairvalues

    my @values = pairvalues @kvlist;

I<Since version 1.29.>

A convenient shortcut to operating on even-sized lists of pairs, this function
returns a list of the the second values of each of the pairs in the given list.
It is a more efficient version of

    @values = pairmap { $b } @kvlist

=cut

=head1 OTHER FUNCTIONS

=cut

=head2 shuffle

    my @values = shuffle @values;

Returns the values of the input in a random order

    @cards = shuffle 0..51      # 0..51 in a random order

=cut

=head1 KNOWN BUGS

=head2 RT #95409

L<https://rt.cpan.org/Ticket/Display.html?id=95409>

If the block of code given to L</pairmap> contains lexical variables that are
captured by a returned closure, and the closure is executed after the block
has been re-used for the next iteration, these lexicals will not see the
correct values. For example:

 my @subs = pairmap {
    my $var = "$a is $b";
    sub { print "$var\n" };
 } one => 1, two => 2, three => 3;

 $_->() for @subs;

Will incorrectly print

 three is 3
 three is 3
 three is 3

This is due to the performance optimisation of using C<MULTICALL> for the code
block, which means that fresh SVs do not get allocated for each call to the
block. Instead, the same SV is re-assigned for each iteration, and all the
closures will share the value seen on the final iteration.

To work around this bug, surround the code with a second set of braces. This
creates an inner block that defeats the C<MULTICALL> logic, and does get fresh
SVs allocated each time:

 my @subs = pairmap {
    {
       my $var = "$a is $b";
       sub { print "$var\n"; }
    }
 } one => 1, two => 2, three => 3;

This bug only affects closures that are generated by the block but used
afterwards. Lexical variables that are only used during the lifetime of the
block's execution will take their individual values for each invocation, as
normal.

=head1 SUGGESTED ADDITIONS

The following are additions that have been requested, but I have been reluctant
to add due to them being very simple to implement in perl

  # How many elements are true

  sub true { scalar grep { $_ } @_ }

  # How many elements are false

  sub false { scalar grep { !$_ } @_ }

=head1 SEE ALSO

L<Scalar::Util>, L<List::MoreUtils>

=head1 COPYRIGHT

Copyright (c) 1997-2007 Graham Barr <gbarr@pobox.com>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Recent additions and current maintenance by
Paul Evans, <leonerd@leonerd.org.uk>.

=cut
