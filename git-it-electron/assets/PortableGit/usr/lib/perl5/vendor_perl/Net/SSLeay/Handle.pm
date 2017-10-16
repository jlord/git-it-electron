package Net::SSLeay::Handle;

require 5.005_03;
use strict;

use Socket;
use Net::SSLeay;

require Exporter;

=head1 NAME

Net::SSLeay::Handle - Perl module that lets SSL (HTTPS) sockets be
handled as standard file handles.

=head1 SYNOPSIS

  use Net::SSLeay::Handle qw/shutdown/;
  my ($host, $port) = ("localhost", 443);

  tie(*SSL, "Net::SSLeay::Handle", $host, $port);

  print SSL "GET / HTTP/1.0\r\n";
  shutdown(\*SSL, 1);
  print while (<SSL>);
  close SSL;                                                       

=head1 DESCRIPTION

Net::SSLeay::Handle allows you to request and receive HTTPS web pages
using "old-fashion" file handles as in:

    print SSL "GET / HTTP/1.0\r\n";

and

    print while (<SSL>);

If you export the shutdown routine, then the only extra code that
you need to add to your program is the tie function as in:

    my $socket;
    if ($scheme eq "https") {
        tie(*S2, "Net::SSLeay::Handle", $host, $port);
        $socket = \*S2;
    else {
        $socket = Net::SSLeay::Handle->make_socket($host, $port);
    }
    print $socket $request_headers;
    ... 

=cut

use vars qw(@ISA @EXPORT_OK $VERSION);
@ISA = qw(Exporter);
@EXPORT_OK = qw(shutdown);
$VERSION = '0.61';

my $Initialized;       #-- only _initialize() once
my $Debug = 0;         #-- pretty hokey
my %Glob_Ref;          #-- used to make unique \*S names for versions < 5.6

#== Tie Handle Methods ========================================================
#
# see perldoc perltie for details.
#
#==============================================================================

sub TIEHANDLE {
    my ($class, $socket, $port) = @_;
    $Debug > 10 and print "TIEHANDLE(@{[join ', ', @_]})\n";

    ref $socket eq "GLOB" or $socket = $class->make_socket($socket, $port);

    $class->_initialize();

    my $ctx = Net::SSLeay::CTX_new() or die_now("Failed to create SSL_CTX $!");
    my $ssl = Net::SSLeay::new($ctx) or die_now("Failed to create SSL $!");

    my $fileno = fileno($socket);

  Net::SSLeay::set_fd($ssl, $fileno);   # Must use fileno

    my $resp = Net::SSLeay::connect($ssl);

    $Debug and print "Cipher '" . Net::SSLeay::get_cipher($ssl) . "'\n";

	my $self = bless {
        ssl    => $ssl, 
        ctx    => $ctx,
        socket => $socket,
        fileno => $fileno,
    }, $class;

    return $self;
}

sub PRINT {
    my $self = shift;

    my $ssl  = _get_ssl($self);
    my $resp = 0;
    for my $msg (@_) {
        defined $msg or last;
        $resp = Net::SSLeay::write($ssl, $msg) or last;
    }
    return $resp;
}

sub READLINE {
    my $self = shift;
    my $ssl  = _get_ssl($self);
	if (wantarray) {
		my @lines;
		while (my $line = Net::SSLeay::ssl_read_until($ssl)) {
			push @lines, $line;
		}
		return @lines;
	} else {
		my $line = Net::SSLeay::ssl_read_until($ssl); 
		return $line ? $line : undef;
	}
}

sub READ {
    my ($self, $buf, $len, $offset) = \ (@_);
    my $ssl = _get_ssl($$self);
    defined($$offset) or 
      return length($$buf = Net::SSLeay::ssl_read_all($ssl, $$len));

    defined(my $read = Net::SSLeay::ssl_read_all($ssl, $$len))
      or return undef;

    my $buf_len = length($$buf);
    $$offset > $buf_len and $$buf .= chr(0) x ($$offset - $buf_len);
    substr($$buf, $$offset) = $read;
    return length($read);
}

sub WRITE {
    my $self = shift;
    my ($buf, $len, $offset) = @_;
    $offset = 0 unless defined $offset;

    # Return number of characters written.
    my $ssl  = $self->_get_ssl();
    return $len if Net::SSLeay::write($ssl, substr($buf, $offset, $len));
    return undef;
}

sub CLOSE {
    my $self = shift;
    my $fileno = $self->{fileno};
    $Debug > 10 and print "close($fileno)\n";
    Net::SSLeay::free ($self->{ssl});
    Net::SSLeay::CTX_free ($self->{ctx});
    close $self->{socket};
}

sub FILENO  { $_[0]->{fileno} }


=head1 FUNCTIONS

=over

=item shutdown

  shutdown(\*SOCKET, $mode)

Calls to the main shutdown() don't work with tied sockets created with this
module.  This shutdown should be able to distinquish between tied and untied
sockets and do the right thing.

=cut

sub shutdown {
    my ($obj, @params) = @_;

	my $socket = UNIVERSAL::isa($obj, 'Net::SSLeay::Handle') ?
		$obj->{socket} : $obj;
    return shutdown($socket, @params);
}

=item debug

  my $debug = Net::SSLeay::Handle->debug()
  Net::SSLeay::Handle->debug(1)

Get/set debuging mode. Always returns the debug value before the function call.
if an additional argument is given the debug option will be set to this value.

=cut

sub debug {
    my ($class, $debug) = @_;
    my $old_debug = $Debug;
    @_ >1 and $Debug = $debug || 0;
    return $old_debug;
}

#=== Internal Methods =========================================================

=item make_socket

  my $sock = Net::SSLeay::Handle->make_socket($host, $port);

Creates a socket that is connected to $post using $port. It uses
$Net::SSLeay::proxyhost and proxyport if set and authentificates itself against
this proxy depending on $Net::SSLeay::proxyauth. It also turns autoflush on for
the created socket.

=cut

sub make_socket {
    my ($class, $host, $port) = @_;
    $Debug > 10 and print "_make_socket(@{[join ', ', @_]})\n";
    $host ||= 'localhost';
    $port ||= 443;

    my $phost = $Net::SSLeay::proxyhost;
    my $pport = $Net::SSLeay::proxyhost ? $Net::SSLeay::proxyport : $port;

    my $dest_ip     = gethostbyname($phost || $host);
    my $host_params = sockaddr_in($pport, $dest_ip);
    my $socket = $^V ? undef : $class->_glob_ref("$host:$port");
    
    socket($socket, &PF_INET(), &SOCK_STREAM(), 0) or die "socket: $!";
    connect($socket, $host_params)                 or die "connect: $!";

    my $old_select = select($socket); $| = 1; select($old_select);
    $phost and do {
        my $auth = $Net::SSLeay::proxyauth;
        my $CRLF = $Net::SSLeay::CRLF;
        print $socket "CONNECT $host:$port HTTP/1.0$auth$CRLF$CRLF";
        my $line = <$socket>;
    };
    return $socket;
}

=back

=cut

#--- _glob_ref($strings) ------------------------------------------------------
#
# Create a unique namespace name and return a glob ref to it.  Would be great
# to use the fileno but need this before we get back the fileno.
# NEED TO LOCK THIS ROUTINE IF USING THREADS. (but it is only used for
# versions < 5.6 :)
#------------------------------------------------------------------------------

sub _glob_ref {
    my $class = shift;
    my $preamb = join("", @_) || "_glob_ref";
    my $num = ++$Glob_Ref{$preamb};
    my $name = "$preamb:$num";
    no strict 'refs';
    my $glob_ref = \*$name;
    use strict 'refs';

    $Debug and do {
        print "GLOB_REF $preamb\n";
        while (my ($k, $v) = each %Glob_Ref) {print "$k = $v\n"} 
        print "\n";
    };

    return $glob_ref;
}

sub _initialize {
    $Initialized++ and return;
  Net::SSLeay::load_error_strings();
  Net::SSLeay::SSLeay_add_ssl_algorithms();
  Net::SSLeay::randomize();
}

sub __dummy {
    my $host = $Net::SSLeay::proxyhost;
    my $port = $Net::SSLeay::proxyport;
    my $auth = $Net::SSLeay::proxyauth;
}

#--- _get_self($socket) -------------------------------------------------------
# Returns a hash containing attributes for $socket (= \*SOMETHING) based
# on fileno($socket).  Will return undef if $socket was not created here.
#------------------------------------------------------------------------------

sub _get_self { return $_[0]; }

#--- _get_ssl($socket) --------------------------------------------------------
# Returns a the "ssl" attribute for $socket (= \*SOMETHING) based
# on fileno($socket).  Will cause a warning and return undef if $socket was not
# created here.
#------------------------------------------------------------------------------

sub _get_ssl {
    return $_[0]->{ssl};
}

1;

__END__

=head2 USING EXISTING SOCKETS

One of the motivations for writing this module was to avoid
duplicating socket creation code (which is mostly error handling).
The calls to tie() above where it is passed a $host and $port is
provided for convenience testing.  If you already have a socket
connected to the right host and port, S1, then you can do something
like:

    my $socket \*S1;
    if ($scheme eq "https") {
        tie(*S2, "Net::SSLeay::Handle", $socket);
        $socket = \*S2;
    }
    my $last_sel = select($socket); $| = 1; select($last_sel);
    print $socket $request_headers;
    ... 

Note: As far as I know you must be careful with the globs in the tie()
function.  The first parameter must be a glob (*SOMETHING) and the
last parameter must be a reference to a glob (\*SOMETHING_ELSE) or a
scaler that was assigned to a reference to a glob (as in the example
above)

Also, the two globs must be different.  When I tried to use the same
glob, I got a core dump.

=head2 EXPORT

None by default.

You can export the shutdown() function.

It is suggested that you do export shutdown() or use the fully
qualified Net::SSLeay::Handle::shutdown() function to shutdown SSL
sockets.  It should be smart enough to distinguish between SSL and
non-SSL sockets and do the right thing.

=head1 EXAMPLES

  use Net::SSLeay::Handle qw/shutdown/;
  my ($host, $port) = ("localhost", 443);

  tie(*SSL, "Net::SSLeay::Handle", $host, $port);

  print SSL "GET / HTTP/1.0\r\n";
  shutdown(\*SSL, 1);
  print while (<SSL>);
  close SSL; 

=head1 TODO

Better error handling.  Callback routine?

=head1 CAVEATS

Tying to a file handle is a little tricky (for me at least).

The first parameter to tie() must be a glob (*SOMETHING) and the last
parameter must be a reference to a glob (\*SOMETHING_ELSE) or a scaler
that was assigned to a reference to a glob ($s = \*SOMETHING_ELSE).
Also, the two globs must be different.  When I tried to use the same
glob, I got a core dump.

I was able to associate attributes to globs created by this module
(like *SSL above) by making a hash of hashes keyed by the file head1.

Support for old perls may not be 100%. If in trouble try 5.6.0 or
newer.

=head1 CHANGES

Please see Net-SSLeay-Handle-0.50/Changes file.

=head1 KNOWN BUGS

If you let this module construct sockets for you with Perl versions
below v.5.6 then there is a slight memory leak.  Other upgrade your
Perl, or create the sockets yourself.  The leak was created to let
these older versions of Perl access more than one Handle at a time.

=head1 AUTHOR

Jim Bowlin jbowlin@linklint.org

=head1 SEE ALSO

Net::SSLeay, perl(1), http://openssl.org/

=cut
