##
## Generic data connection package
##

package Net::FTP::dataconn;

use 5.008001;

use strict;
use warnings;

use Carp;
use Errno;
use Net::Cmd;

our $VERSION = '3.05';

$Net::FTP::IOCLASS or die "please load Net::FTP before Net::FTP::dataconn";
our @ISA = $Net::FTP::IOCLASS;

sub reading {
  my $data = shift;
  ${*$data}{'net_ftp_bytesread'} = 0;
}


sub abort {
  my $data = shift;
  my $ftp  = ${*$data}{'net_ftp_cmd'};

  # no need to abort if we have finished the xfer
  return $data->close
    if ${*$data}{'net_ftp_eof'};

  # for some reason if we continuously open RETR connections and not
  # read a single byte, then abort them after a while the server will
  # close our connection, this prevents the unexpected EOF on the
  # command channel -- GMB
  if (exists ${*$data}{'net_ftp_bytesread'}
    && (${*$data}{'net_ftp_bytesread'} == 0))
  {
    my $buf     = "";
    my $timeout = $data->timeout;
    $data->can_read($timeout) && sysread($data, $buf, 1);
  }

  ${*$data}{'net_ftp_eof'} = 1;    # fake

  $ftp->abort;                     # this will close me
}


sub _close {
  my $data = shift;
  my $ftp  = ${*$data}{'net_ftp_cmd'};

  $data->SUPER::close();

  delete ${*$ftp}{'net_ftp_dataconn'}
    if defined $ftp
    && exists ${*$ftp}{'net_ftp_dataconn'}
    && $data == ${*$ftp}{'net_ftp_dataconn'};
}


sub close {
  my $data = shift;
  my $ftp  = ${*$data}{'net_ftp_cmd'};

  if (exists ${*$data}{'net_ftp_bytesread'} && !${*$data}{'net_ftp_eof'}) {
    my $junk;
    eval { local($SIG{__DIE__}); $data->read($junk, 1, 0) };
    return $data->abort unless ${*$data}{'net_ftp_eof'};
  }

  $data->_close;

  return unless defined $ftp;

  $ftp->response() == CMD_OK
    && $ftp->message =~ /unique file name:\s*(\S*)\s*\)/
    && (${*$ftp}{'net_ftp_unique'} = $1);

  $ftp->status == CMD_OK;
}


sub _select {
  my ($data, $timeout, $do_read) = @_;
  my ($rin, $rout, $win, $wout, $tout, $nfound);

  vec($rin = '', fileno($data), 1) = 1;

  ($win, $rin) = ($rin, $win) unless $do_read;

  while (1) {
    $nfound = select($rout = $rin, $wout = $win, undef, $tout = $timeout);

    last if $nfound >= 0;

    croak "select: $!"
      unless $!{EINTR};
  }

  $nfound;
}


sub can_read {
  _select(@_[0, 1], 1);
}


sub can_write {
  _select(@_[0, 1], 0);
}


sub cmd {
  my $ftp = shift;

  ${*$ftp}{'net_ftp_cmd'};
}


sub bytes_read {
  my $ftp = shift;

  ${*$ftp}{'net_ftp_bytesread'} || 0;
}

1;

__END__

=head1 NAME

Net::FTP::dataconn - FTP Client data connection class

=head1 DESCRIPTION

Some of the methods defined in C<Net::FTP> return an object which will
be derived from this class. The dataconn class itself is derived from
the C<IO::Socket::INET> class, so any normal IO operations can be performed.
However the following methods are defined in the dataconn class and IO should
be performed using these.

=over 4

=item read ( BUFFER, SIZE [, TIMEOUT ] )

Read C<SIZE> bytes of data from the server and place it into C<BUFFER>, also
performing any <CRLF> translation necessary. C<TIMEOUT> is optional, if not
given, the timeout value from the command connection will be used.

Returns the number of bytes read before any <CRLF> translation.

=item write ( BUFFER, SIZE [, TIMEOUT ] )

Write C<SIZE> bytes of data from C<BUFFER> to the server, also
performing any <CRLF> translation necessary. C<TIMEOUT> is optional, if not
given, the timeout value from the command connection will be used.

Returns the number of bytes written before any <CRLF> translation.

=item bytes_read ()

Returns the number of bytes read so far.

=item abort ()

Abort the current data transfer.

=item close ()

Close the data connection and get a response from the FTP server. Returns
I<true> if the connection was closed successfully and the first digit of
the response from the server was a '2'.

=back

=cut
