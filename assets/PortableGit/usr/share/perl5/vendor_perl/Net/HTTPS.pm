package Net::HTTPS;

use strict;
use vars qw($VERSION $SSL_SOCKET_CLASS @ISA);

$VERSION = "6.09";
$VERSION = eval $VERSION;

# Figure out which SSL implementation to use
if ($SSL_SOCKET_CLASS) {
    # somebody already set it
}
elsif ($SSL_SOCKET_CLASS = $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS}) {
    unless ($SSL_SOCKET_CLASS =~ /^(IO::Socket::SSL|Net::SSL)\z/) {
	die "Bad socket class [$SSL_SOCKET_CLASS]";
    }
    eval "require $SSL_SOCKET_CLASS";
    die $@ if $@;
}
elsif ($IO::Socket::SSL::VERSION) {
    $SSL_SOCKET_CLASS = "IO::Socket::SSL"; # it was already loaded
}
elsif ($Net::SSL::VERSION) {
    $SSL_SOCKET_CLASS = "Net::SSL";
}
else {
    eval { require IO::Socket::SSL; };
    if ($@) {
	my $old_errsv = $@;
	eval {
	    require Net::SSL;  # from Crypt-SSLeay
	};
	if ($@) {
	    $old_errsv =~ s/\s\(\@INC contains:.*\)/)/g;
	    die $old_errsv . $@;
	}
	$SSL_SOCKET_CLASS = "Net::SSL";
    }
    else {
	$SSL_SOCKET_CLASS = "IO::Socket::SSL";
    }
}

require Net::HTTP::Methods;

@ISA=($SSL_SOCKET_CLASS, 'Net::HTTP::Methods');

sub configure {
    my($self, $cnf) = @_;
    $self->http_configure($cnf);
}

sub http_connect {
    my($self, $cnf) = @_;
    if ($self->isa("Net::SSL")) {
	if ($cnf->{SSL_verify_mode}) {
	    if (my $f = $cnf->{SSL_ca_file}) {
		$ENV{HTTPS_CA_FILE} = $f;
	    }
	    if (my $f = $cnf->{SSL_ca_path}) {
		$ENV{HTTPS_CA_DIR} = $f;
	    }
	}
	if ($cnf->{SSL_verifycn_scheme}) {
	    $@ = "Net::SSL from Crypt-SSLeay can't verify hostnames; either install IO::Socket::SSL or turn off verification by setting the PERL_LWP_SSL_VERIFY_HOSTNAME environment variable to 0";
	    return undef;
	}
    }
    $self->SUPER::configure($cnf);
}

sub http_default_port {
    443;
}

if ($SSL_SOCKET_CLASS eq "Net::SSL") {
    # The underlying SSLeay classes fails to work if the socket is
    # placed in non-blocking mode.  This override of the blocking
    # method makes sure it stays the way it was created.
    *blocking = sub { };
}

1;

=head1 NAME

Net::HTTPS - Low-level HTTP over SSL/TLS connection (client)

=head1 DESCRIPTION

The C<Net::HTTPS> is a low-level HTTP over SSL/TLS client.  The interface is the same
as the interface for C<Net::HTTP>, but the constructor method take additional parameters
as accepted by L<IO::Socket::SSL>.  The C<Net::HTTPS> object isa C<IO::Socket::SSL>
too, which make it inherit additional methods from that base class.

For historical reasons this module also supports using C<Net::SSL> (from the
Crypt-SSLeay distribution) as its SSL driver and base class.  This base is
automatically selected if available and C<IO::Socket::SSL> isn't.  You might
also force which implementation to use by setting $Net::HTTPS::SSL_SOCKET_CLASS
before loading this module.  If not set this variable is initialized from the
C<PERL_NET_HTTPS_SSL_SOCKET_CLASS> environment variable.

=head1 ENVIRONMENT

You might set the C<PERL_NET_HTTPS_SSL_SOCKET_CLASS> environment variable to the name
of the base SSL implementation (and Net::HTTPS base class) to use.  The default
is C<IO::Socket::SSL>.  Currently the only other supported value is C<Net::SSL>.

=head1 SEE ALSO

L<Net::HTTP>, L<IO::Socket::SSL>
