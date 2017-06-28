
package IO::Socket::SSL::Intercept;
use strict;
use warnings;
use Carp 'croak';
use IO::Socket::SSL::Utils;
use Net::SSLeay;

our $VERSION = '2.014';

sub new {
    my ($class,%args) = @_;

    my $cacert = delete $args{proxy_cert};
    if ( ! $cacert ) {
	if ( my $f = delete $args{proxy_cert_file} ) {
	    $cacert = PEM_file2cert($f);
	} else {
	    croak "no proxy_cert or proxy_cert_file given";
	}
    }

    my $cakey  = delete $args{proxy_key};
    if ( ! $cakey ) {
	if ( my $f = delete $args{proxy_key_file} ) {
	    $cakey = PEM_file2key($f);
	} else {
	    croak "no proxy_cert or proxy_cert_file given";
	}
    }

    my $certkey = delete $args{cert_key};
    if ( ! $certkey ) {
	if ( my $f = delete $args{cert_key_file} ) {
	    $certkey = PEM_file2key($f);
	}
    }

    my $cache = delete $args{cache} || {};

    my $self = bless {
	cacert => $cacert,
	cakey => $cakey,
	certkey => $certkey,
	serial => delete $args{serial} || 1,
	cache => $cache,
    };
    return $self;
}

sub DESTROY {
    # call various ssl _free routines
    my $self = shift or return;
    for ( \$self->{cacert}, 
	map { \$_->{cert} } ref($self->{cache}) ne 'CODE' ? values %{$self->{cache}} :()) {
	$$_ or next;
	CERT_free($$_);
	$$_ = undef;
    }
    for ( \$self->{cakey}, \$self->{pubkey} ) {
	$$_ or next;
	KEY_free($$_);
	$$_ = undef;
    }
}

sub clone_cert {
    my ($self,$old_cert,$clone_key) = @_;

    $clone_key ||= substr(unpack("H*",Net::SSLeay::X509_get_fingerprint($old_cert,'sha1')),0,16);
    if ( my ($clone,$key) = _get_cached($self,$clone_key)) {
	return ($clone,$key);
    }

    # create new certificate based on original
    # copy most but not all extensions
    my $hash = CERT_asHash($old_cert);
    if (my $ext = $hash->{ext}) {
	@$ext = grep {
	    $_->{sn} !~m{^(?:
		authorityInfoAccess    |
		subjectKeyIdentifier   |
		authorityKeyIdentifier |
		certificatePolicies    |
		crlDistributionPoints
	    )$}x
	} @$ext;
    }
    my ($clone,$key) = CERT_create(
	%$hash,
	serial => $self->{serial}++,
	issuer_cert => $self->{cacert},
	issuer_key => $self->{cakey},
	key => $self->{certkey},
    );

    # put into cache
    _set_cached($self,$clone_key,$clone,$key);

    return ($clone,$key);
}

sub _get_cached {
    my ($self,$clone_key) = @_;
    my $c = $self->{cache};
    return $c->($clone_key) if ref($c) eq 'CODE';
    my $e = $c->{$clone_key} or return;
    $e->{atime} = time();
    return ($e->{cert},$e->{key} || $self->{certkey});
}

sub _set_cached {
    my ($self,$clone_key,$cert,$key) = @_;
    my $c = $self->{cache};
    return $c->($clone_key,$cert,$key) if ref($c) eq 'CODE';
    $c->{$clone_key} = { 
	cert => $cert, 
	$self->{certkey} && $self->{certkey} == $key ? () : ( key => $key ),
	atime => time() 
    };
}


sub STORABLE_freeze { my $self = shift; $self->serialize() }
sub STORABLE_thaw   { my ($class,undef,$data) = @_; $class->unserialize($data) }

sub serialize {
    my $self = shift;
    my $data = pack("N",2); # version
    $data .= pack("N/a", PEM_cert2string($self->{cacert}));
    $data .= pack("N/a", PEM_key2string($self->{cakey}));
    if ( $self->{certkey} ) {
	$data .= pack("N/a", PEM_key2string($self->{certkey}));
    } else {
	$data .= pack("N/a", '');
    }
    $data .= pack("N",$self->{serial});
    if ( ref($self->{cache}) eq 'HASH' ) {
	while ( my($k,$v) = each %{ $self->{cache}} ) {
	    $data .= pack("N/aN/aN/aN", $k,
		PEM_cert2string($k->{cert}),
		$k->{key} ? PEM_key2string($k->{key}) : '',
		$k->{atime});
	}
    }
    return $data;
}

sub unserialize {
    my ($class,$data) = @_;
    unpack("N",substr($data,0,4,'')) == 2 or 
	croak("serialized with wrong version");
    ( my $cacert,my $cakey,my $certkey,my $serial,$data) 
	= unpack("N/aN/aN/aNa*",$data);
    my $self = bless {
	serial => $serial,
	cacert => PEM_string2cert($cacert),
	cakey => PEM_string2key($cakey),
	$certkey ? ( certkey => PEM_string2key($certkey)):(),
    }, ref($class)||$class;

    $self->{cache} = {} if $data ne '';
    while ( $data ne '' ) {
	(my $key,my $cert,my $certkey, my $atime,$data) = unpack("N/aN/aNa*",$data);
	$self->{cache}{$key} = { 
	    cert => PEM_string2cert($cert), 
	    $key ? ( key => PEM_string2key($certkey)):(),
	    atime => $atime 
	};
    }
    return $self;
}

1;

__END__

=head1 NAME

IO::Socket::SSL::Intercept -- SSL interception (man in the middle)

=head1 SYNOPSIS

    use IO::Socket::SSL::Intercept;
    # create interceptor with proxy certificates
    my $mitm = IO::Socket::SSL::Intercept->new(
	proxy_cert_file => 'proxy_cert.pem',
	proxy_key_file  => 'proxy_key.pem',
	...
    );
    my $listen = IO::Socket::INET->new( LocalAddr => .., Listen => .. );
    while (1) {
	# TCP accept new client
	my $client = $listen->accept or next;
	# SSL connect to server
	my $server = IO::Socket::SSL->new(
	    PeerAddr => ..,
	    SSL_verify_mode => ...,
	    ...
	) or die "ssl connect failed: $!,$SSL_ERROR";
	# clone server certificate
	my ($cert,$key) = $mitm->clone_cert( $server->peer_certificate );
	# and upgrade client side to SSL with cloned certificate
	IO::Socket::SSL->start_SSL($client,
	    SSL_server => 1,
	    SSL_cert => $cert,
	    SSL_key => $key
	) or die "upgrade failed: $SSL_ERROR";
	# now transfer data between $client and $server and analyze
	# the unencrypted data
	...
    }


=head1 DESCRIPTION

This module provides functionality to clone certificates and sign them with a
proxy certificate, thus making it easy to intercept SSL connections (man in the
middle). It also manages a cache of the generated certificates.

=head1 How Intercepting SSL Works

Intercepting SSL connections is useful for analyzing encrypted traffic for
security reasons or for testing. It does not break the end-to-end security of
SSL, e.g. a properly written client will notice the interception unless you
explicitly configure the client to trust your interceptor.
Intercepting SSL works the following way:

=over 4

=item *

Create a new CA certificate, which will be used to sign the cloned certificates.
This proxy CA certificate should be trusted by the client, or (a properly
written client) will throw error messages or deny the connections because it
detected a man in the middle attack.
Due to the way the interception works there no support for client side
certificates is possible.

Using openssl such a proxy CA certificate and private key can be created with:

  openssl genrsa -out proxy_key.pem 1024
  openssl req -new -x509 -extensions v3_ca -key proxy_key.pem -out proxy_cert.pem
  # export as PKCS12 for import into browser
  openssl pkcs12 -export -in proxy_cert.pem -inkey proxy_key.pem -out proxy_cert.p12

=item * 

Configure client to connect to use intercepting proxy or somehow redirect
connections from client to the proxy (e.g. packet filter redirects, ARP or DNS
spoofing etc).

=item *

Accept the TCP connection from the client, e.g. don't do any SSL handshakes with
the client yet.

=item *

Establish the SSL connection to the server and verify the servers certificate as
usually. Then create a new certificate based on the original servers
certificate, but signed by your proxy CA.
This a the step where IO::Socket::SSL::Intercept helps.

=item *

Upgrade the TCP connection to the client to SSL using the cloned certificate
from the server. If the client trusts your proxy CA it will accept the upgrade
to SSL.

=item *

Transfer data between client and server. While the connections to client and
server are both encrypted with SSL you will read/write the unencrypted data in
your proxy application.

=back

=head1 METHODS 

IO::Socket::SSL::Intercept helps creating the cloned certificate with the
following methods:

=over 4

=item B<< $mitm = IO::Socket::SSL::Intercept->new(%args) >>

This creates a new interceptor object. C<%args> should be

=over 8

=item proxy_cert X509 | proxy_cert_file filename

This is the proxy certificate.
It can be either given by an X509 object from L<Net::SSLeay>s internal
representation, or using a file in PEM format.

=item proxy_key EVP_PKEY | proxy_key_file filename

This is the key for the proxy certificate.
It can be either given by an EVP_PKEY object from L<Net::SSLeay>s internal
representation, or using a file in PEM format.
The key should not have a passphrase.

=item pubkey EVP_PKEY | pubkey_file filename

This optional argument specifies the public key used for the cloned certificate.
It can be either given by an EVP_PKEY object from L<Net::SSLeay>s internal
representation, or using a file in PEM format.
If not given it will create a new public key on each call of C<new>.

=item serial INTEGER

This optional argument gives the starting point for the serial numbers of the
newly created certificates. Default to 1.

=item cache HASH | SUBROUTINE

This optional argument gives a way to cache created certificates, so that they
don't get recreated on future accesses to the same host.
If the argument ist not given an internal HASH ist used.

If the argument is a hash it will store for each generated certificate a hash
reference with C<cert> and C<atime> in the hash, where C<atime> is the time of
last access (to expire unused entries) and C<cert> is the certificate. Please
note, that the certificate is in L<Net::SSLeay>s internal X509 format and can
thus not be simply dumped and restored.
The key for the hash is an C<ident> either given to C<clone_cert> or generated
from the original certificate.

If the argument is a subroutine it will be called as C<< $cache->(ident) >>
to get an existing certificate and with C<< $cache->(ident,cert) >> to cache the
newly created certificate.

=back

=item B<< ($clone_cert,$key) = $mitm->clone_cert($original_cert,[ $ident ]) >>

This clones the given certificate.
An ident as the key into the cache can be given (like C<host:port>), if not it
will be created from the properties of the original certificate.
It returns the cloned certificate and its key (which is the same for alle
created certificates).

=item B<< $string = $mitm->serialize >>

This creates a serialized version of the object (e.g. a string) which can then
be used to persistantly store created certificates over restarts of the
application. The cache will only be serialized if it is a HASH.
To work together with L<Storable> the C<STORABLE_freeze> function is defined to
call C<serialize>.

=item B<< $mitm = IO::Socket::SSL::Intercept->unserialize($string) >>

This restores an Intercept object from a serialized string.
To work together with L<Storable> the C<STORABLE_thaw> function is defined to
call C<unserialize>.

=back

=head1 AUTHOR

Steffen Ullrich
