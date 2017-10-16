package PerlIO::via::QuotedPrint;

$VERSION= '0.08';

# be as strict as possible
use strict;

# modules that we need
use MIME::QuotedPrint (); # no need to pollute this namespace

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Standard Perl features
#
#-------------------------------------------------------------------------------
#  IN: 1 class to bless with
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { bless \*PUSHED,$_[0] } #PUSHED

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)
#      2 handle to read from
# OUT: 1 decoded string

sub FILL {

    # decode and return
    my $line= readline( $_[1] );
    return ( defined $line )
      ? MIME::QuotedPrint::decode_qp($line)
      : undef;
} #FILL

#-------------------------------------------------------------------------------
#  IN: 1 instantiated object (ignored)
#      2 buffer to be written
#      3 handle to write to
# OUT: 1 number of bytes written

sub WRITE {

    # encode and write to handle: indicate result
    return ( print { $_[2] } MIME::QuotedPrint::encode_qp( $_[1] ) )
      ? length( $_[1] )
      : -1;
} #WRITE

#-------------------------------------------------------------------------------

__END__

=head1 NAME

PerlIO::via::QuotedPrint - PerlIO layer for quoted-printable strings

=head1 SYNOPSIS

 use PerlIO::via::QuotedPrint;

 open( my $in, '<:via(QuotedPrint)', 'file.qp' )
   or die "Can't open file.qp for reading: $!\n";
 
 open( my $out, '>:via(QuotedPrint)', 'file.qp' )
   or die "Can't open file.qp for writing: $!\n";

=head1 VERSION

This documentation describes version 0.08.

=head1 DESCRIPTION

This module implements a PerlIO layer that works on files encoded in the
quoted-printable format.  It will decode from quoted-printable while reading
from a handle, and it will encode as quoted-printable while writing to a handle.

=head1 REQUIRED MODULES

 MIME::QuotedPrint (any)

=head1 SEE ALSO

L<PerlIO::via>, L<MIME::QuotedPrint>, L<PerlIO::via::Base64>,
L<PerlIO::via::MD5>, L<PerlIO::via::StripHTML>, L<PerlIO::via::Rotate>.

=head1 ACKNOWLEDGEMENTS

Based on example that was initially added to MIME::QuotedPrint.pm for the
5.8.0 distribution of Perl.

=head1 COPYRIGHT

Copyright (c) 2002, 2003, 2004, 2012 Elizabeth Mattijsen.  All rights reserved.
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
