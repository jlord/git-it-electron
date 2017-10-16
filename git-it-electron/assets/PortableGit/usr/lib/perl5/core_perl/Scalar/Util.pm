# Copyright (c) 1997-2007 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Maintained since 2013 by Paul Evans <leonerd@leonerd.org.uk>

package Scalar::Util;

use strict;
require Exporter;
require List::Util; # List::Util loads the XS

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
  blessed refaddr reftype weaken unweaken isweak

  dualvar isdual isvstring looks_like_number openhandle readonly set_prototype
  tainted
);
our $VERSION    = "1.41";
$VERSION   = eval $VERSION;

our @EXPORT_FAIL;

unless (defined &weaken) {
  push @EXPORT_FAIL, qw(weaken);
}
unless (defined &isweak) {
  push @EXPORT_FAIL, qw(isweak isvstring);
}
unless (defined &isvstring) {
  push @EXPORT_FAIL, qw(isvstring);
}

sub export_fail {
  if (grep { /^(?:weaken|isweak)$/ } @_ ) {
    require Carp;
    Carp::croak("Weak references are not implemented in the version of perl");
  }

  if (grep { /^isvstring$/ } @_ ) {
    require Carp;
    Carp::croak("Vstrings are not implemented in the version of perl");
  }

  @_;
}

# set_prototype has been moved to Sub::Util with a different interface
sub set_prototype(&$)
{
  my ( $code, $proto ) = @_;
  return Sub::Util::set_prototype( $proto, $code );
}

1;

__END__

=head1 NAME

Scalar::Util - A selection of general-utility scalar subroutines

=head1 SYNOPSIS

    use Scalar::Util qw(blessed dualvar isdual readonly refaddr reftype
                        tainted weaken isweak isvstring looks_like_number
                        set_prototype);
                        # and other useful utils appearing below

=head1 DESCRIPTION

C<Scalar::Util> contains a selection of subroutines that people have expressed
would be nice to have in the perl core, but the usage would not really be high
enough to warrant the use of a keyword, and the size so small such that being
individual extensions would be wasteful.

By default C<Scalar::Util> does not export any subroutines.

=cut

=head1 FUNCTIONS FOR REFERENCES

The following functions all perform some useful activity on reference values.

=head2 blessed

    my $pkg = blessed( $ref );

If C<$ref> is a blessed reference the name of the package that it is blessed
into is returned. Otherwise C<undef> is returned.

    $scalar = "foo";
    $class  = blessed $scalar;           # undef

    $ref    = [];
    $class  = blessed $ref;              # undef

    $obj    = bless [], "Foo";
    $class  = blessed $obj;              # "Foo"

Take care when using this function simply as a truth test (such as in
C<if(blessed $ref)...>) because the package name C<"0"> is defined yet false.

=head2 refaddr

    my $addr = refaddr( $ref );

If C<$ref> is reference the internal memory address of the referenced value is
returned as a plain integer. Otherwise C<undef> is returned.

    $addr = refaddr "string";           # undef
    $addr = refaddr \$var;              # eg 12345678
    $addr = refaddr [];                 # eg 23456784

    $obj  = bless {}, "Foo";
    $addr = refaddr $obj;               # eg 88123488

=head2 reftype

    my $type = reftype( $ref );

If C<$ref> is a reference the basic Perl type of the variable referenced is
returned as a plain string (such as C<ARRAY> or C<HASH>). Otherwise C<undef>
is returned.

    $type = reftype "string";           # undef
    $type = reftype \$var;              # SCALAR
    $type = reftype [];                 # ARRAY

    $obj  = bless {}, "Foo";
    $type = reftype $obj;               # HASH

=head2 weaken

    weaken( $ref );

The lvalue C<$ref> will be turned into a weak reference. This means that it
will not hold a reference count on the object it references. Also when the
reference count on that object reaches zero, the reference will be set to
undef. This function mutates the lvalue passed as its argument and returns no
value.

This is useful for keeping copies of references, but you don't want to prevent
the object being DESTROY-ed at its usual time.

    {
      my $var;
      $ref = \$var;
      weaken($ref);                     # Make $ref a weak reference
    }
    # $ref is now undef

Note that if you take a copy of a scalar with a weakened reference, the copy
will be a strong reference.

    my $var;
    my $foo = \$var;
    weaken($foo);                       # Make $foo a weak reference
    my $bar = $foo;                     # $bar is now a strong reference

This may be less obvious in other situations, such as C<grep()>, for instance
when grepping through a list of weakened references to objects that may have
been destroyed already:

    @object = grep { defined } @object;

This will indeed remove all references to destroyed objects, but the remaining
references to objects will be strong, causing the remaining objects to never be
destroyed because there is now always a strong reference to them in the @object
array.

=head2 unweaken

    unweaken( $ref );

I<Since version 1.36.>

The lvalue C<REF> will be turned from a weak reference back into a normal
(strong) reference again. This function mutates the lvalue passed as its
argument and returns no value. This undoes the action performed by
L</weaken>.

This function is slightly neater and more convenient than the
otherwise-equivalent code

    my $tmp = $REF;
    undef $REF;
    $REF = $tmp;

(because in particular, simply assigning a weak reference back to itself does
not work to unweaken it; C<$REF = $REF> does not work).

=head2 isweak

    my $weak = isweak( $ref );

Returns true if C<$ref> is a weak reference.

    $ref  = \$foo;
    $weak = isweak($ref);               # false
    weaken($ref);
    $weak = isweak($ref);               # true

B<NOTE>: Copying a weak reference creates a normal, strong, reference.

    $copy = $ref;
    $weak = isweak($copy);              # false

=head1 OTHER FUNCTIONS

=head2 dualvar

    my $var = dualvar( $num, $string );

Returns a scalar that has the value C<$num> in a numeric context and the value
C<$string> in a string context.

    $foo = dualvar 10, "Hello";
    $num = $foo + 2;                    # 12
    $str = $foo . " world";             # Hello world

=head2 isdual

    my $dual = isdual( $var );

I<Since version 1.26.>

If C<$var> is a scalar that has both numeric and string values, the result is
true.

    $foo = dualvar 86, "Nix";
    $dual = isdual($foo);               # true

Note that a scalar can be made to have both string and numeric content through
numeric operations:

    $foo = "10";
    $dual = isdual($foo);               # false
    $bar = $foo + 0;
    $dual = isdual($foo);               # true

Note that although C<$!> appears to be dual-valued variable, it is actually
implemented using a tied scalar:

    $! = 1;
    print("$!\n");                      # "Operation not permitted"
    $dual = isdual($!);                 # false

You can capture its numeric and string content using:

    $err = dualvar $!, $!;
    $dual = isdual($err);               # true

=head2 isvstring

    my $vstring = isvstring( $var );

If C<$var> is a scalar which was coded as a vstring the result is true.

    $vs   = v49.46.48;
    $fmt  = isvstring($vs) ? "%vd" : "%s"; #true
    printf($fmt,$vs);

=head2 looks_like_number

    my $isnum = looks_like_number( $var );

Returns true if perl thinks C<$var> is a number. See
L<perlapi/looks_like_number>.

=head2 openhandle

    my $fh = openhandle( $fh );

Returns C<$fh> itself if C<$fh> may be used as a filehandle and is open, or is
is a tied handle. Otherwise C<undef> is returned.

    $fh = openhandle(*STDIN);           # \*STDIN
    $fh = openhandle(\*STDIN);          # \*STDIN
    $fh = openhandle(*NOTOPEN);         # undef
    $fh = openhandle("scalar");         # undef

=head2 readonly

    my $ro = readonly( $var );

Returns true if C<$var> is readonly.

    sub foo { readonly($_[0]) }

    $readonly = foo($bar);              # false
    $readonly = foo(0);                 # true

=head2 set_prototype

    my $code = set_prototype( $code, $prototype );

Sets the prototype of the function given by the C<$code> reference, or deletes
it if C<$prototype> is C<undef>. Returns the C<$code> reference itself.

    set_prototype \&foo, '$$';

=head2 tainted

    my $t = tainted( $var );

Return true if C<$var> is tainted.

    $taint = tainted("constant");       # false
    $taint = tainted($ENV{PWD});        # true if running under -T

=head1 DIAGNOSTICS

Module use may give one of the following errors during import.

=over

=item Weak references are not implemented in the version of perl

The version of perl that you are using does not implement weak references, to
use L</isweak> or L</weaken> you will need to use a newer release of perl.

=item Vstrings are not implemented in the version of perl

The version of perl that you are using does not implement Vstrings, to use
L</isvstring> you will need to use a newer release of perl.

=item C<NAME> is only available with the XS version of Scalar::Util

C<Scalar::Util> contains both perl and C implementations of many of its
functions so that those without access to a C compiler may still use it.
However some of the functions are only available when a C compiler was
available to compile the XS version of the extension.

At present that list is: weaken, isweak, dualvar, isvstring, set_prototype

=back

=head1 KNOWN BUGS

There is a bug in perl5.6.0 with UV's that are >= 1<<31. This will
show up as tests 8 and 9 of dualvar.t failing

=head1 SEE ALSO

L<List::Util>

=head1 COPYRIGHT

Copyright (c) 1997-2007 Graham Barr <gbarr@pobox.com>. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Additionally L</weaken> and L</isweak> which are

Copyright (c) 1999 Tuomas J. Lukka <lukka@iki.fi>. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as perl itself.

Copyright (C) 2004, 2008  Matthijs van Duin.  All rights reserved.
Copyright (C) 2014 cPanel Inc.  All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
