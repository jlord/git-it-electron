# vim: ts=4 sts=4 sw=4 et:
package HTTP::Tiny;
use strict;
use warnings;
# ABSTRACT: A small, simple, correct HTTP/1.1 client

our $VERSION = '0.054';

use Carp ();

#pod =method new
#pod
#pod     $http = HTTP::Tiny->new( %attributes );
#pod
#pod This constructor returns a new HTTP::Tiny object.  Valid attributes include:
#pod
#pod =for :list
#pod * C<agent> —
#pod     A user-agent string (defaults to 'HTTP-Tiny/$VERSION'). If C<agent> — ends in a space character, the default user-agent string is appended.
#pod * C<cookie_jar> —
#pod     An instance of L<HTTP::CookieJar> — or equivalent class that supports the C<add> and C<cookie_header> methods
#pod * C<default_headers> —
#pod     A hashref of default headers to apply to requests
#pod * C<local_address> —
#pod     The local IP address to bind to
#pod * C<keep_alive> —
#pod     Whether to reuse the last connection (if for the same scheme, host and port) (defaults to 1)
#pod * C<max_redirect> —
#pod     Maximum number of redirects allowed (defaults to 5)
#pod * C<max_size> —
#pod     Maximum response size (only when not using a data callback).  If defined, responses larger than this will return an exception.
#pod * C<http_proxy> —
#pod     URL of a proxy server to use for HTTP connections (default is C<$ENV{http_proxy}> — if set)
#pod * C<https_proxy> —
#pod     URL of a proxy server to use for HTTPS connections (default is C<$ENV{https_proxy}> — if set)
#pod * C<proxy> —
#pod     URL of a generic proxy server for both HTTP and HTTPS connections (default is C<$ENV{all_proxy}> — if set)
#pod * C<no_proxy> —
#pod     List of domain suffixes that should not be proxied.  Must be a comma-separated string or an array reference. (default is C<$ENV{no_proxy}> —)
#pod * C<timeout> —
#pod     Request timeout in seconds (default is 60)
#pod * C<verify_SSL> —
#pod     A boolean that indicates whether to validate the SSL certificate of an C<https> —
#pod     connection (default is false)
#pod * C<SSL_options> —
#pod     A hashref of C<SSL_*> — options to pass through to L<IO::Socket::SSL>
#pod
#pod Passing an explicit C<undef> for C<proxy>, C<http_proxy> or C<https_proxy> will
#pod prevent getting the corresponding proxies from the environment.
#pod
#pod Exceptions from C<max_size>, C<timeout> or other errors will result in a
#pod pseudo-HTTP status code of 599 and a reason of "Internal Exception". The
#pod content field in the response will contain the text of the exception.
#pod
#pod The C<keep_alive> parameter enables a persistent connection, but only to a
#pod single destination scheme, host and port.  Also, if any connection-relevant
#pod attributes are modified, or if the process ID or thread ID change, the
#pod persistent connection will be dropped.  If you want persistent connections
#pod across multiple destinations, use multiple HTTP::Tiny objects.
#pod
#pod See L</SSL SUPPORT> for more on the C<verify_SSL> and C<SSL_options> attributes.
#pod
#pod =cut

my @attributes;
BEGIN {
    @attributes = qw(
        cookie_jar default_headers http_proxy https_proxy keep_alive
        local_address max_redirect max_size proxy no_proxy timeout
        SSL_options verify_SSL
    );
    my %persist_ok = map {; $_ => 1 } qw(
        cookie_jar default_headers max_redirect max_size
    );
    no strict 'refs';
    no warnings 'uninitialized';
    for my $accessor ( @attributes ) {
        *{$accessor} = sub {
            @_ > 1
                ? do {
                    delete $_[0]->{handle} if !$persist_ok{$accessor} && $_[1] ne $_[0]->{$accessor};
                    $_[0]->{$accessor} = $_[1]
                }
                : $_[0]->{$accessor};
        };
    }
}

sub agent {
    my($self, $agent) = @_;
    if( @_ > 1 ){
        $self->{agent} =
            (defined $agent && $agent =~ / $/) ? $agent . $self->_agent : $agent;
    }
    return $self->{agent};
}

sub new {
    my($class, %args) = @_;

    my $self = {
        max_redirect => 5,
        timeout      => 60,
        keep_alive   => 1,
        verify_SSL   => $args{verify_SSL} || $args{verify_ssl} || 0, # no verification by default
        no_proxy     => $ENV{no_proxy},
    };

    bless $self, $class;

    $class->_validate_cookie_jar( $args{cookie_jar} ) if $args{cookie_jar};

    for my $key ( @attributes ) {
        $self->{$key} = $args{$key} if exists $args{$key}
    }

    $self->agent( exists $args{agent} ? $args{agent} : $class->_agent );

    $self->_set_proxies;

    return $self;
}

sub _set_proxies {
    my ($self) = @_;

    # get proxies from %ENV only if not provided; explicit undef will disable
    # getting proxies from the environment

    # generic proxy
    if (! exists $self->{proxy} ) {
        $self->{proxy} = $ENV{all_proxy} || $ENV{ALL_PROXY};
    }

    if ( defined $self->{proxy} ) {
        $self->_split_proxy( 'generic proxy' => $self->{proxy} ); # validate
    }
    else {
        delete $self->{proxy};
    }

    # http proxy
    if (! exists $self->{http_proxy} ) {
        # under CGI, bypass HTTP_PROXY as request sets it from Proxy header
        local $ENV{HTTP_PROXY} if $ENV{REQUEST_METHOD};
        $self->{http_proxy} = $ENV{http_proxy} || $ENV{HTTP_PROXY} || $self->{proxy};
    }

    if ( defined $self->{http_proxy} ) {
        $self->_split_proxy( http_proxy => $self->{http_proxy} ); # validate
        $self->{_has_proxy}{http} = 1;
    }
    else {
        delete $self->{http_proxy};
    }

    # https proxy
    if (! exists $self->{https_proxy} ) {
        $self->{https_proxy} = $ENV{https_proxy} || $ENV{HTTPS_PROXY} || $self->{proxy};
    }

    if ( $self->{https_proxy} ) {
        $self->_split_proxy( https_proxy => $self->{https_proxy} ); # validate
        $self->{_has_proxy}{https} = 1;
    }
    else {
        delete $self->{https_proxy};
    }

    # Split no_proxy to array reference if not provided as such
    unless ( ref $self->{no_proxy} eq 'ARRAY' ) {
        $self->{no_proxy} =
            (defined $self->{no_proxy}) ? [ split /\s*,\s*/, $self->{no_proxy} ] : [];
    }

    return;
}

#pod =method get|head|put|post|delete
#pod
#pod     $response = $http->get($url);
#pod     $response = $http->get($url, \%options);
#pod     $response = $http->head($url);
#pod
#pod These methods are shorthand for calling C<request()> for the given method.  The
#pod URL must have unsafe characters escaped and international domain names encoded.
#pod See C<request()> for valid options and a description of the response.
#pod
#pod The C<success> field of the response will be true if the status code is 2XX.
#pod
#pod =cut

for my $sub_name ( qw/get head put post delete/ ) {
    my $req_method = uc $sub_name;
    no strict 'refs';
    eval <<"HERE"; ## no critic
    sub $sub_name {
        my (\$self, \$url, \$args) = \@_;
        \@_ == 2 || (\@_ == 3 && ref \$args eq 'HASH')
        or Carp::croak(q/Usage: \$http->$sub_name(URL, [HASHREF])/ . "\n");
        return \$self->request('$req_method', \$url, \$args || {});
    }
HERE
}

#pod =method post_form
#pod
#pod     $response = $http->post_form($url, $form_data);
#pod     $response = $http->post_form($url, $form_data, \%options);
#pod
#pod This method executes a C<POST> request and sends the key/value pairs from a
#pod form data hash or array reference to the given URL with a C<content-type> of
#pod C<application/x-www-form-urlencoded>.  If data is provided as an array
#pod reference, the order is preserved; if provided as a hash reference, the terms
#pod are sorted on key and value for consistency.  See documentation for the
#pod C<www_form_urlencode> method for details on the encoding.
#pod
#pod The URL must have unsafe characters escaped and international domain names
#pod encoded.  See C<request()> for valid options and a description of the response.
#pod Any C<content-type> header or content in the options hashref will be ignored.
#pod
#pod The C<success> field of the response will be true if the status code is 2XX.
#pod
#pod =cut

sub post_form {
    my ($self, $url, $data, $args) = @_;
    (@_ == 3 || @_ == 4 && ref $args eq 'HASH')
        or Carp::croak(q/Usage: $http->post_form(URL, DATAREF, [HASHREF])/ . "\n");

    my $headers = {};
    while ( my ($key, $value) = each %{$args->{headers} || {}} ) {
        $headers->{lc $key} = $value;
    }
    delete $args->{headers};

    return $self->request('POST', $url, {
            %$args,
            content => $self->www_form_urlencode($data),
            headers => {
                %$headers,
                'content-type' => 'application/x-www-form-urlencoded'
            },
        }
    );
}

#pod =method mirror
#pod
#pod     $response = $http->mirror($url, $file, \%options)
#pod     if ( $response->{success} ) {
#pod         print "$file is up to date\n";
#pod     }
#pod
#pod Executes a C<GET> request for the URL and saves the response body to the file
#pod name provided.  The URL must have unsafe characters escaped and international
#pod domain names encoded.  If the file already exists, the request will include an
#pod C<If-Modified-Since> header with the modification timestamp of the file.  You
#pod may specify a different C<If-Modified-Since> header yourself in the C<<
#pod $options->{headers} >> hash.
#pod
#pod The C<success> field of the response will be true if the status code is 2XX
#pod or if the status code is 304 (unmodified).
#pod
#pod If the file was modified and the server response includes a properly
#pod formatted C<Last-Modified> header, the file modification time will
#pod be updated accordingly.
#pod
#pod =cut

sub mirror {
    my ($self, $url, $file, $args) = @_;
    @_ == 3 || (@_ == 4 && ref $args eq 'HASH')
      or Carp::croak(q/Usage: $http->mirror(URL, FILE, [HASHREF])/ . "\n");
    if ( -e $file and my $mtime = (stat($file))[9] ) {
        $args->{headers}{'if-modified-since'} ||= $self->_http_date($mtime);
    }
    my $tempfile = $file . int(rand(2**31));

    require Fcntl;
    sysopen my $fh, $tempfile, Fcntl::O_CREAT()|Fcntl::O_EXCL()|Fcntl::O_WRONLY()
       or Carp::croak(qq/Error: Could not create temporary file $tempfile for downloading: $!\n/);
    binmode $fh;
    $args->{data_callback} = sub { print {$fh} $_[0] };
    my $response = $self->request('GET', $url, $args);
    close $fh
        or Carp::croak(qq/Error: Caught error closing temporary file $tempfile: $!\n/);

    if ( $response->{success} ) {
        rename $tempfile, $file
            or Carp::croak(qq/Error replacing $file with $tempfile: $!\n/);
        my $lm = $response->{headers}{'last-modified'};
        if ( $lm and my $mtime = $self->_parse_http_date($lm) ) {
            utime $mtime, $mtime, $file;
        }
    }
    $response->{success} ||= $response->{status} eq '304';
    unlink $tempfile;
    return $response;
}

#pod =method request
#pod
#pod     $response = $http->request($method, $url);
#pod     $response = $http->request($method, $url, \%options);
#pod
#pod Executes an HTTP request of the given method type ('GET', 'HEAD', 'POST',
#pod 'PUT', etc.) on the given URL.  The URL must have unsafe characters escaped and
#pod international domain names encoded.
#pod
#pod If the URL includes a "user:password" stanza, they will be used for Basic-style
#pod authorization headers.  (Authorization headers will not be included in a
#pod redirected request.) For example:
#pod
#pod     $http->request('GET', 'http://Aladdin:open sesame@example.com/');
#pod
#pod If the "user:password" stanza contains reserved characters, they must
#pod be percent-escaped:
#pod
#pod     $http->request('GET', 'http://john%40example.com:password@example.com/');
#pod
#pod A hashref of options may be appended to modify the request.
#pod
#pod Valid options are:
#pod
#pod =for :list
#pod * C<headers> —
#pod     A hashref containing headers to include with the request.  If the value for
#pod     a header is an array reference, the header will be output multiple times with
#pod     each value in the array.  These headers over-write any default headers.
#pod * C<content> —
#pod     A scalar to include as the body of the request OR a code reference
#pod     that will be called iteratively to produce the body of the request
#pod * C<trailer_callback> —
#pod     A code reference that will be called if it exists to provide a hashref
#pod     of trailing headers (only used with chunked transfer-encoding)
#pod * C<data_callback> —
#pod     A code reference that will be called for each chunks of the response
#pod     body received.
#pod
#pod The C<Host> header is generated from the URL in accordance with RFC 2616.  It
#pod is a fatal error to specify C<Host> in the C<headers> option.  Other headers
#pod may be ignored or overwritten if necessary for transport compliance.
#pod
#pod If the C<content> option is a code reference, it will be called iteratively
#pod to provide the content body of the request.  It should return the empty
#pod string or undef when the iterator is exhausted.
#pod
#pod If the C<content> option is the empty string, no C<content-type> or
#pod C<content-length> headers will be generated.
#pod
#pod If the C<data_callback> option is provided, it will be called iteratively until
#pod the entire response body is received.  The first argument will be a string
#pod containing a chunk of the response body, the second argument will be the
#pod in-progress response hash reference, as described below.  (This allows
#pod customizing the action of the callback based on the C<status> or C<headers>
#pod received prior to the content body.)
#pod
#pod The C<request> method returns a hashref containing the response.  The hashref
#pod will have the following keys:
#pod
#pod =for :list
#pod * C<success> —
#pod     Boolean indicating whether the operation returned a 2XX status code
#pod * C<url> —
#pod     URL that provided the response. This is the URL of the request unless
#pod     there were redirections, in which case it is the last URL queried
#pod     in a redirection chain
#pod * C<status> —
#pod     The HTTP status code of the response
#pod * C<reason> —
#pod     The response phrase returned by the server
#pod * C<content> —
#pod     The body of the response.  If the response does not have any content
#pod     or if a data callback is provided to consume the response body,
#pod     this will be the empty string
#pod * C<headers> —
#pod     A hashref of header fields.  All header field names will be normalized
#pod     to be lower case. If a header is repeated, the value will be an arrayref;
#pod     it will otherwise be a scalar string containing the value
#pod
#pod On an exception during the execution of the request, the C<status> field will
#pod contain 599, and the C<content> field will contain the text of the exception.
#pod
#pod =cut

my %idempotent = map { $_ => 1 } qw/GET HEAD PUT DELETE OPTIONS TRACE/;

sub request {
    my ($self, $method, $url, $args) = @_;
    @_ == 3 || (@_ == 4 && ref $args eq 'HASH')
      or Carp::croak(q/Usage: $http->request(METHOD, URL, [HASHREF])/ . "\n");
    $args ||= {}; # we keep some state in this during _request

    # RFC 2616 Section 8.1.4 mandates a single retry on broken socket
    my $response;
    for ( 0 .. 1 ) {
        $response = eval { $self->_request($method, $url, $args) };
        last unless $@ && $idempotent{$method}
            && $@ =~ m{^(?:Socket closed|Unexpected end)};
    }

    if (my $e = $@) {
        # maybe we got a response hash thrown from somewhere deep
        if ( ref $e eq 'HASH' && exists $e->{status} ) {
            return $e;
        }

        # otherwise, stringify it
        $e = "$e";
        $response = {
            url     => $url,
            success => q{},
            status  => 599,
            reason  => 'Internal Exception',
            content => $e,
            headers => {
                'content-type'   => 'text/plain',
                'content-length' => length $e,
            }
        };
    }
    return $response;
}

#pod =method www_form_urlencode
#pod
#pod     $params = $http->www_form_urlencode( $data );
#pod     $response = $http->get("http://example.com/query?$params");
#pod
#pod This method converts the key/value pairs from a data hash or array reference
#pod into a C<x-www-form-urlencoded> string.  The keys and values from the data
#pod reference will be UTF-8 encoded and escaped per RFC 3986.  If a value is an
#pod array reference, the key will be repeated with each of the values of the array
#pod reference.  If data is provided as a hash reference, the key/value pairs in the
#pod resulting string will be sorted by key and value for consistent ordering.
#pod
#pod =cut

sub www_form_urlencode {
    my ($self, $data) = @_;
    (@_ == 2 && ref $data)
        or Carp::croak(q/Usage: $http->www_form_urlencode(DATAREF)/ . "\n");
    (ref $data eq 'HASH' || ref $data eq 'ARRAY')
        or Carp::croak("form data must be a hash or array reference\n");

    my @params = ref $data eq 'HASH' ? %$data : @$data;
    @params % 2 == 0
        or Carp::croak("form data reference must have an even number of terms\n");

    my @terms;
    while( @params ) {
        my ($key, $value) = splice(@params, 0, 2);
        if ( ref $value eq 'ARRAY' ) {
            unshift @params, map { $key => $_ } @$value;
        }
        else {
            push @terms, join("=", map { $self->_uri_escape($_) } $key, $value);
        }
    }

    return join("&", (ref $data eq 'ARRAY') ? (@terms) : (sort @terms) );
}

#--------------------------------------------------------------------------#
# private methods
#--------------------------------------------------------------------------#

my %DefaultPort = (
    http => 80,
    https => 443,
);

sub _agent {
    my $class = ref($_[0]) || $_[0];
    (my $default_agent = $class) =~ s{::}{-}g;
    return $default_agent . "/" . $class->VERSION;
}

sub _request {
    my ($self, $method, $url, $args) = @_;

    my ($scheme, $host, $port, $path_query, $auth) = $self->_split_url($url);

    my $request = {
        method    => $method,
        scheme    => $scheme,
        host      => $host,
        port      => $port,
        host_port => ($port == $DefaultPort{$scheme} ? $host : "$host:$port"),
        uri       => $path_query,
        headers   => {},
    };

    # We remove the cached handle so it is not reused in the case of redirect.
    # If all is well, it will be recached at the end of _request.  We only
    # reuse for the same scheme, host and port
    my $handle = delete $self->{handle};
    if ( $handle ) {
        unless ( $handle->can_reuse( $scheme, $host, $port ) ) {
            $handle->close;
            undef $handle;
        }
    }
    $handle ||= $self->_open_handle( $request, $scheme, $host, $port );

    $self->_prepare_headers_and_cb($request, $args, $url, $auth);
    $handle->write_request($request);

    my $response;
    do { $response = $handle->read_response_header }
        until (substr($response->{status},0,1) ne '1');

    $self->_update_cookie_jar( $url, $response ) if $self->{cookie_jar};

    if ( my @redir_args = $self->_maybe_redirect($request, $response, $args) ) {
        $handle->close;
        return $self->_request(@redir_args, $args);
    }

    my $known_message_length;
    if ($method eq 'HEAD' || $response->{status} =~ /^[23]04/) {
        # response has no message body
        $known_message_length = 1;
    }
    else {
        my $data_cb = $self->_prepare_data_cb($response, $args);
        $known_message_length = $handle->read_body($data_cb, $response);
    }

    if ( $self->{keep_alive}
        && $known_message_length
        && $response->{protocol} eq 'HTTP/1.1'
        && ($response->{headers}{connection} || '') ne 'close'
    ) {
        $self->{handle} = $handle;
    }
    else {
        $handle->close;
    }

    $response->{success} = substr( $response->{status}, 0, 1 ) eq '2';
    $response->{url} = $url;
    return $response;
}

sub _open_handle {
    my ($self, $request, $scheme, $host, $port) = @_;

    my $handle  = HTTP::Tiny::Handle->new(
        timeout         => $self->{timeout},
        SSL_options     => $self->{SSL_options},
        verify_SSL      => $self->{verify_SSL},
        local_address   => $self->{local_address},
        keep_alive      => $self->{keep_alive}
    );

    if ($self->{_has_proxy}{$scheme} && ! grep { $host =~ /\Q$_\E$/ } @{$self->{no_proxy}}) {
        return $self->_proxy_connect( $request, $handle );
    }
    else {
        return $handle->connect($scheme, $host, $port);
    }
}

sub _proxy_connect {
    my ($self, $request, $handle) = @_;

    my @proxy_vars;
    if ( $request->{scheme} eq 'https' ) {
        Carp::croak(qq{No https_proxy defined}) unless $self->{https_proxy};
        @proxy_vars = $self->_split_proxy( https_proxy => $self->{https_proxy} );
        if ( $proxy_vars[0] eq 'https' ) {
            Carp::croak(qq{Can't proxy https over https: $request->{uri} via $self->{https_proxy}});
        }
    }
    else {
        Carp::croak(qq{No http_proxy defined}) unless $self->{http_proxy};
        @proxy_vars = $self->_split_proxy( http_proxy => $self->{http_proxy} );
    }

    my ($p_scheme, $p_host, $p_port, $p_auth) = @proxy_vars;

    if ( length $p_auth && ! defined $request->{headers}{'proxy-authorization'} ) {
        $self->_add_basic_auth_header( $request, 'proxy-authorization' => $p_auth );
    }

    $handle->connect($p_scheme, $p_host, $p_port);

    if ($request->{scheme} eq 'https') {
        $self->_create_proxy_tunnel( $request, $handle );
    }
    else {
        # non-tunneled proxy requires absolute URI
        $request->{uri} = "$request->{scheme}://$request->{host_port}$request->{uri}";
    }

    return $handle;
}

sub _split_proxy {
    my ($self, $type, $proxy) = @_;

    my ($scheme, $host, $port, $path_query, $auth) = eval { $self->_split_url($proxy) };

    unless(
        defined($scheme) && length($scheme) && length($host) && length($port)
        && $path_query eq '/'
    ) {
        Carp::croak(qq{$type URL must be in format http[s]://[auth@]<host>:<port>/\n});
    }

    return ($scheme, $host, $port, $auth);
}

sub _create_proxy_tunnel {
    my ($self, $request, $handle) = @_;

    $handle->_assert_ssl;

    my $agent = exists($request->{headers}{'user-agent'})
        ? $request->{headers}{'user-agent'} : $self->{agent};

    my $connect_request = {
        method    => 'CONNECT',
        uri       => "$request->{host}:$request->{port}",
        headers   => {
            host => "$request->{host}:$request->{port}",
            'user-agent' => $agent,
        }
    };

    if ( $request->{headers}{'proxy-authorization'} ) {
        $connect_request->{headers}{'proxy-authorization'} =
            delete $request->{headers}{'proxy-authorization'};
    }

    $handle->write_request($connect_request);
    my $response;
    do { $response = $handle->read_response_header }
        until (substr($response->{status},0,1) ne '1');

    # if CONNECT failed, throw the response so it will be
    # returned from the original request() method;
    unless (substr($response->{status},0,1) eq '2') {
        die $response;
    }

    # tunnel established, so start SSL handshake
    $handle->start_ssl( $request->{host} );

    return;
}

sub _prepare_headers_and_cb {
    my ($self, $request, $args, $url, $auth) = @_;

    for ($self->{default_headers}, $args->{headers}) {
        next unless defined;
        while (my ($k, $v) = each %$_) {
            $request->{headers}{lc $k} = $v;
        }
    }

    if (exists $request->{headers}{'host'}) {
        die(qq/The 'Host' header must not be provided as header option\n/);
    }

    $request->{headers}{'host'}         = $request->{host_port};
    $request->{headers}{'user-agent'} ||= $self->{agent};
    $request->{headers}{'connection'}   = "close"
        unless $self->{keep_alive};

    if ( defined $args->{content} ) {
        if (ref $args->{content} eq 'CODE') {
            $request->{headers}{'content-type'} ||= "application/octet-stream";
            $request->{headers}{'transfer-encoding'} = 'chunked'
              unless $request->{headers}{'content-length'}
                  || $request->{headers}{'transfer-encoding'};
            $request->{cb} = $args->{content};
        }
        elsif ( length $args->{content} ) {
            my $content = $args->{content};
            if ( $] ge '5.008' ) {
                utf8::downgrade($content, 1)
                    or die(qq/Wide character in request message body\n/);
            }
            $request->{headers}{'content-type'} ||= "application/octet-stream";
            $request->{headers}{'content-length'} = length $content
              unless $request->{headers}{'content-length'}
                  || $request->{headers}{'transfer-encoding'};
            $request->{cb} = sub { substr $content, 0, length $content, '' };
        }
        $request->{trailer_cb} = $args->{trailer_callback}
            if ref $args->{trailer_callback} eq 'CODE';
    }

    ### If we have a cookie jar, then maybe add relevant cookies
    if ( $self->{cookie_jar} ) {
        my $cookies = $self->cookie_jar->cookie_header( $url );
        $request->{headers}{cookie} = $cookies if length $cookies;
    }

    # if we have Basic auth parameters, add them
    if ( length $auth && ! defined $request->{headers}{authorization} ) {
        $self->_add_basic_auth_header( $request, 'authorization' => $auth );
    }

    return;
}

sub _add_basic_auth_header {
    my ($self, $request, $header, $auth) = @_;
    require MIME::Base64;
    $request->{headers}{$header} =
        "Basic " . MIME::Base64::encode_base64($auth, "");
    return;
}

sub _prepare_data_cb {
    my ($self, $response, $args) = @_;
    my $data_cb = $args->{data_callback};
    $response->{content} = '';

    if (!$data_cb || $response->{status} !~ /^2/) {
        if (defined $self->{max_size}) {
            $data_cb = sub {
                $_[1]->{content} .= $_[0];
                die(qq/Size of response body exceeds the maximum allowed of $self->{max_size}\n/)
                  if length $_[1]->{content} > $self->{max_size};
            };
        }
        else {
            $data_cb = sub { $_[1]->{content} .= $_[0] };
        }
    }
    return $data_cb;
}

sub _update_cookie_jar {
    my ($self, $url, $response) = @_;

    my $cookies = $response->{headers}->{'set-cookie'};
    return unless defined $cookies;

    my @cookies = ref $cookies ? @$cookies : $cookies;

    $self->cookie_jar->add( $url, $_ ) for @cookies;

    return;
}

sub _validate_cookie_jar {
    my ($class, $jar) = @_;

    # duck typing
    for my $method ( qw/add cookie_header/ ) {
        Carp::croak(qq/Cookie jar must provide the '$method' method\n/)
            unless ref($jar) && ref($jar)->can($method);
    }

    return;
}

sub _maybe_redirect {
    my ($self, $request, $response, $args) = @_;
    my $headers = $response->{headers};
    my ($status, $method) = ($response->{status}, $request->{method});
    if (($status eq '303' or ($status =~ /^30[127]/ && $method =~ /^GET|HEAD$/))
        and $headers->{location}
        and ++$args->{redirects} <= $self->{max_redirect}
    ) {
        my $location = ($headers->{location} =~ /^\//)
            ? "$request->{scheme}://$request->{host_port}$headers->{location}"
            : $headers->{location} ;
        return (($status eq '303' ? 'GET' : $method), $location);
    }
    return;
}

sub _split_url {
    my $url = pop;

    # URI regex adapted from the URI module
    my ($scheme, $host, $path_query) = $url =~ m<\A([^:/?#]+)://([^/?#]*)([^#]*)>
      or die(qq/Cannot parse URL: '$url'\n/);

    $scheme     = lc $scheme;
    $path_query = "/$path_query" unless $path_query =~ m<\A/>;

    my $auth = '';
    if ( (my $i = index $host, '@') != -1 ) {
        # user:pass@host
        $auth = substr $host, 0, $i, ''; # take up to the @ for auth
        substr $host, 0, 1, '';          # knock the @ off the host

        # userinfo might be percent escaped, so recover real auth info
        $auth =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    }
    my $port = $host =~ s/:(\d*)\z// && length $1 ? $1
             : $scheme eq 'http'                  ? 80
             : $scheme eq 'https'                 ? 443
             : undef;

    return ($scheme, (length $host ? lc $host : "localhost") , $port, $path_query, $auth);
}

# Date conversions adapted from HTTP::Date
my $DoW = "Sun|Mon|Tue|Wed|Thu|Fri|Sat";
my $MoY = "Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec";
sub _http_date {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($_[1]);
    return sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
        substr($DoW,$wday*4,3),
        $mday, substr($MoY,$mon*4,3), $year+1900,
        $hour, $min, $sec
    );
}

sub _parse_http_date {
    my ($self, $str) = @_;
    require Time::Local;
    my @tl_parts;
    if ($str =~ /^[SMTWF][a-z]+, +(\d{1,2}) ($MoY) +(\d\d\d\d) +(\d\d):(\d\d):(\d\d) +GMT$/) {
        @tl_parts = ($6, $5, $4, $1, (index($MoY,$2)/4), $3);
    }
    elsif ($str =~ /^[SMTWF][a-z]+, +(\d\d)-($MoY)-(\d{2,4}) +(\d\d):(\d\d):(\d\d) +GMT$/ ) {
        @tl_parts = ($6, $5, $4, $1, (index($MoY,$2)/4), $3);
    }
    elsif ($str =~ /^[SMTWF][a-z]+ +($MoY) +(\d{1,2}) +(\d\d):(\d\d):(\d\d) +(?:[^0-9]+ +)?(\d\d\d\d)$/ ) {
        @tl_parts = ($5, $4, $3, $2, (index($MoY,$1)/4), $6);
    }
    return eval {
        my $t = @tl_parts ? Time::Local::timegm(@tl_parts) : -1;
        $t < 0 ? undef : $t;
    };
}

# URI escaping adapted from URI::Escape
# c.f. http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4.1
# perl 5.6 ready UTF-8 encoding adapted from JSON::PP
my %escapes = map { chr($_) => sprintf("%%%02X", $_) } 0..255;
$escapes{' '}="+";
my $unsafe_char = qr/[^A-Za-z0-9\-\._~]/;

sub _uri_escape {
    my ($self, $str) = @_;
    if ( $] ge '5.008' ) {
        utf8::encode($str);
    }
    else {
        $str = pack("U*", unpack("C*", $str)) # UTF-8 encode a byte string
            if ( length $str == do { use bytes; length $str } );
        $str = pack("C*", unpack("C*", $str)); # clear UTF-8 flag
    }
    $str =~ s/($unsafe_char)/$escapes{$1}/ge;
    return $str;
}

package
    HTTP::Tiny::Handle; # hide from PAUSE/indexers
use strict;
use warnings;

use Errno      qw[EINTR EPIPE];
use IO::Socket qw[SOCK_STREAM];

# PERL_HTTP_TINY_IPV4_ONLY is a private environment variable to force old
# behavior if someone is unable to boostrap CPAN from a new perl install; it is
# not intended for general, per-client use and may be removed in the future
my $SOCKET_CLASS =
    $ENV{PERL_HTTP_TINY_IPV4_ONLY} ? 'IO::Socket::INET' :
    eval { require IO::Socket::IP; IO::Socket::IP->VERSION(0.25) } ? 'IO::Socket::IP' :
    'IO::Socket::INET';

sub BUFSIZE () { 32768 } ## no critic

my $Printable = sub {
    local $_ = shift;
    s/\r/\\r/g;
    s/\n/\\n/g;
    s/\t/\\t/g;
    s/([^\x20-\x7E])/sprintf('\\x%.2X', ord($1))/ge;
    $_;
};

my $Token = qr/[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7A\x7C\x7E]/;

sub new {
    my ($class, %args) = @_;
    return bless {
        rbuf             => '',
        timeout          => 60,
        max_line_size    => 16384,
        max_header_lines => 64,
        verify_SSL       => 0,
        SSL_options      => {},
        %args
    }, $class;
}

sub connect {
    @_ == 4 || die(q/Usage: $handle->connect(scheme, host, port)/ . "\n");
    my ($self, $scheme, $host, $port) = @_;

    if ( $scheme eq 'https' ) {
        $self->_assert_ssl;
    }
    elsif ( $scheme ne 'http' ) {
      die(qq/Unsupported URL scheme '$scheme'\n/);
    }
    $self->{fh} = $SOCKET_CLASS->new(
        PeerHost  => $host,
        PeerPort  => $port,
        $self->{local_address} ?
            ( LocalAddr => $self->{local_address} ) : (),
        Proto     => 'tcp',
        Type      => SOCK_STREAM,
        Timeout   => $self->{timeout},
        KeepAlive => !!$self->{keep_alive}
    ) or die(qq/Could not connect to '$host:$port': $@\n/);

    binmode($self->{fh})
      or die(qq/Could not binmode() socket: '$!'\n/);

    $self->start_ssl($host) if $scheme eq 'https';

    $self->{scheme} = $scheme;
    $self->{host} = $host;
    $self->{port} = $port;
    $self->{pid} = $$;
    $self->{tid} = _get_tid();

    return $self;
}

sub start_ssl {
    my ($self, $host) = @_;

    # As this might be used via CONNECT after an SSL session
    # to a proxy, we shut down any existing SSL before attempting
    # the handshake
    if ( ref($self->{fh}) eq 'IO::Socket::SSL' ) {
        unless ( $self->{fh}->stop_SSL ) {
            my $ssl_err = IO::Socket::SSL->errstr;
            die(qq/Error halting prior SSL connection: $ssl_err/);
        }
    }

    my $ssl_args = $self->_ssl_args($host);
    IO::Socket::SSL->start_SSL(
        $self->{fh},
        %$ssl_args,
        SSL_create_ctx_callback => sub {
            my $ctx = shift;
            Net::SSLeay::CTX_set_mode($ctx, Net::SSLeay::MODE_AUTO_RETRY());
        },
    );

    unless ( ref($self->{fh}) eq 'IO::Socket::SSL' ) {
        my $ssl_err = IO::Socket::SSL->errstr;
        die(qq/SSL connection failed for $host: $ssl_err\n/);
    }
}

sub close {
    @_ == 1 || die(q/Usage: $handle->close()/ . "\n");
    my ($self) = @_;
    CORE::close($self->{fh})
      or die(qq/Could not close socket: '$!'\n/);
}

sub write {
    @_ == 2 || die(q/Usage: $handle->write(buf)/ . "\n");
    my ($self, $buf) = @_;

    if ( $] ge '5.008' ) {
        utf8::downgrade($buf, 1)
            or die(qq/Wide character in write()\n/);
    }

    my $len = length $buf;
    my $off = 0;

    local $SIG{PIPE} = 'IGNORE';

    while () {
        $self->can_write
          or die(qq/Timed out while waiting for socket to become ready for writing\n/);
        my $r = syswrite($self->{fh}, $buf, $len, $off);
        if (defined $r) {
            $len -= $r;
            $off += $r;
            last unless $len > 0;
        }
        elsif ($! == EPIPE) {
            die(qq/Socket closed by remote server: $!\n/);
        }
        elsif ($! != EINTR) {
            if ($self->{fh}->can('errstr')){
                my $err = $self->{fh}->errstr();
                die (qq/Could not write to SSL socket: '$err'\n /);
            }
            else {
                die(qq/Could not write to socket: '$!'\n/);
            }

        }
    }
    return $off;
}

sub read {
    @_ == 2 || @_ == 3 || die(q/Usage: $handle->read(len [, allow_partial])/ . "\n");
    my ($self, $len, $allow_partial) = @_;

    my $buf  = '';
    my $got = length $self->{rbuf};

    if ($got) {
        my $take = ($got < $len) ? $got : $len;
        $buf  = substr($self->{rbuf}, 0, $take, '');
        $len -= $take;
    }

    while ($len > 0) {
        $self->can_read
          or die(q/Timed out while waiting for socket to become ready for reading/ . "\n");
        my $r = sysread($self->{fh}, $buf, $len, length $buf);
        if (defined $r) {
            last unless $r;
            $len -= $r;
        }
        elsif ($! != EINTR) {
            if ($self->{fh}->can('errstr')){
                my $err = $self->{fh}->errstr();
                die (qq/Could not read from SSL socket: '$err'\n /);
            }
            else {
                die(qq/Could not read from socket: '$!'\n/);
            }
        }
    }
    if ($len && !$allow_partial) {
        die(qq/Unexpected end of stream\n/);
    }
    return $buf;
}

sub readline {
    @_ == 1 || die(q/Usage: $handle->readline()/ . "\n");
    my ($self) = @_;

    while () {
        if ($self->{rbuf} =~ s/\A ([^\x0D\x0A]* \x0D?\x0A)//x) {
            return $1;
        }
        if (length $self->{rbuf} >= $self->{max_line_size}) {
            die(qq/Line size exceeds the maximum allowed size of $self->{max_line_size}\n/);
        }
        $self->can_read
          or die(qq/Timed out while waiting for socket to become ready for reading\n/);
        my $r = sysread($self->{fh}, $self->{rbuf}, BUFSIZE, length $self->{rbuf});
        if (defined $r) {
            last unless $r;
        }
        elsif ($! != EINTR) {
            if ($self->{fh}->can('errstr')){
                my $err = $self->{fh}->errstr();
                die (qq/Could not read from SSL socket: '$err'\n /);
            }
            else {
                die(qq/Could not read from socket: '$!'\n/);
            }
        }
    }
    die(qq/Unexpected end of stream while looking for line\n/);
}

sub read_header_lines {
    @_ == 1 || @_ == 2 || die(q/Usage: $handle->read_header_lines([headers])/ . "\n");
    my ($self, $headers) = @_;
    $headers ||= {};
    my $lines   = 0;
    my $val;

    while () {
         my $line = $self->readline;

         if (++$lines >= $self->{max_header_lines}) {
             die(qq/Header lines exceeds maximum number allowed of $self->{max_header_lines}\n/);
         }
         elsif ($line =~ /\A ([^\x00-\x1F\x7F:]+) : [\x09\x20]* ([^\x0D\x0A]*)/x) {
             my ($field_name) = lc $1;
             if (exists $headers->{$field_name}) {
                 for ($headers->{$field_name}) {
                     $_ = [$_] unless ref $_ eq "ARRAY";
                     push @$_, $2;
                     $val = \$_->[-1];
                 }
             }
             else {
                 $val = \($headers->{$field_name} = $2);
             }
         }
         elsif ($line =~ /\A [\x09\x20]+ ([^\x0D\x0A]*)/x) {
             $val
               or die(qq/Unexpected header continuation line\n/);
             next unless length $1;
             $$val .= ' ' if length $$val;
             $$val .= $1;
         }
         elsif ($line =~ /\A \x0D?\x0A \z/x) {
            last;
         }
         else {
            die(q/Malformed header line: / . $Printable->($line) . "\n");
         }
    }
    return $headers;
}

sub write_request {
    @_ == 2 || die(q/Usage: $handle->write_request(request)/ . "\n");
    my($self, $request) = @_;
    $self->write_request_header(@{$request}{qw/method uri headers/});
    $self->write_body($request) if $request->{cb};
    return;
}

my %HeaderCase = (
    'content-md5'      => 'Content-MD5',
    'etag'             => 'ETag',
    'te'               => 'TE',
    'www-authenticate' => 'WWW-Authenticate',
    'x-xss-protection' => 'X-XSS-Protection',
);

# to avoid multiple small writes and hence nagle, you can pass the method line or anything else to
# combine writes.
sub write_header_lines {
    (@_ == 2 || @_ == 3 && ref $_[1] eq 'HASH') || die(q/Usage: $handle->write_header_lines(headers[,prefix])/ . "\n");
    my($self, $headers, $prefix_data) = @_;

    my $buf = (defined $prefix_data ? $prefix_data : '');
    while (my ($k, $v) = each %$headers) {
        my $field_name = lc $k;
        if (exists $HeaderCase{$field_name}) {
            $field_name = $HeaderCase{$field_name};
        }
        else {
            $field_name =~ /\A $Token+ \z/xo
              or die(q/Invalid HTTP header field name: / . $Printable->($field_name) . "\n");
            $field_name =~ s/\b(\w)/\u$1/g;
            $HeaderCase{lc $field_name} = $field_name;
        }
        for (ref $v eq 'ARRAY' ? @$v : $v) {
            $_ = '' unless defined $_;
            $buf .= "$field_name: $_\x0D\x0A";
        }
    }
    $buf .= "\x0D\x0A";
    return $self->write($buf);
}

# return value indicates whether message length was defined; this is generally
# true unless there was no content-length header and we just read until EOF.
# Other message length errors are thrown as exceptions
sub read_body {
    @_ == 3 || die(q/Usage: $handle->read_body(callback, response)/ . "\n");
    my ($self, $cb, $response) = @_;
    my $te = $response->{headers}{'transfer-encoding'} || '';
    my $chunked = grep { /chunked/i } ( ref $te eq 'ARRAY' ? @$te : $te ) ;
    return $chunked
        ? $self->read_chunked_body($cb, $response)
        : $self->read_content_body($cb, $response);
}

sub write_body {
    @_ == 2 || die(q/Usage: $handle->write_body(request)/ . "\n");
    my ($self, $request) = @_;
    if ($request->{headers}{'content-length'}) {
        return $self->write_content_body($request);
    }
    else {
        return $self->write_chunked_body($request);
    }
}

sub read_content_body {
    @_ == 3 || @_ == 4 || die(q/Usage: $handle->read_content_body(callback, response, [read_length])/ . "\n");
    my ($self, $cb, $response, $content_length) = @_;
    $content_length ||= $response->{headers}{'content-length'};

    if ( defined $content_length ) {
        my $len = $content_length;
        while ($len > 0) {
            my $read = ($len > BUFSIZE) ? BUFSIZE : $len;
            $cb->($self->read($read, 0), $response);
            $len -= $read;
        }
        return length($self->{rbuf}) == 0;
    }

    my $chunk;
    $cb->($chunk, $response) while length( $chunk = $self->read(BUFSIZE, 1) );

    return;
}

sub write_content_body {
    @_ == 2 || die(q/Usage: $handle->write_content_body(request)/ . "\n");
    my ($self, $request) = @_;

    my ($len, $content_length) = (0, $request->{headers}{'content-length'});
    while () {
        my $data = $request->{cb}->();

        defined $data && length $data
          or last;

        if ( $] ge '5.008' ) {
            utf8::downgrade($data, 1)
                or die(qq/Wide character in write_content()\n/);
        }

        $len += $self->write($data);
    }

    $len == $content_length
      or die(qq/Content-Length mismatch (got: $len expected: $content_length)\n/);

    return $len;
}

sub read_chunked_body {
    @_ == 3 || die(q/Usage: $handle->read_chunked_body(callback, $response)/ . "\n");
    my ($self, $cb, $response) = @_;

    while () {
        my $head = $self->readline;

        $head =~ /\A ([A-Fa-f0-9]+)/x
          or die(q/Malformed chunk head: / . $Printable->($head) . "\n");

        my $len = hex($1)
          or last;

        $self->read_content_body($cb, $response, $len);

        $self->read(2) eq "\x0D\x0A"
          or die(qq/Malformed chunk: missing CRLF after chunk data\n/);
    }
    $self->read_header_lines($response->{headers});
    return 1;
}

sub write_chunked_body {
    @_ == 2 || die(q/Usage: $handle->write_chunked_body(request)/ . "\n");
    my ($self, $request) = @_;

    my $len = 0;
    while () {
        my $data = $request->{cb}->();

        defined $data && length $data
          or last;

        if ( $] ge '5.008' ) {
            utf8::downgrade($data, 1)
                or die(qq/Wide character in write_chunked_body()\n/);
        }

        $len += length $data;

        my $chunk  = sprintf '%X', length $data;
           $chunk .= "\x0D\x0A";
           $chunk .= $data;
           $chunk .= "\x0D\x0A";

        $self->write($chunk);
    }
    $self->write("0\x0D\x0A");
    $self->write_header_lines($request->{trailer_cb}->())
        if ref $request->{trailer_cb} eq 'CODE';
    return $len;
}

sub read_response_header {
    @_ == 1 || die(q/Usage: $handle->read_response_header()/ . "\n");
    my ($self) = @_;

    my $line = $self->readline;

    $line =~ /\A (HTTP\/(0*\d+\.0*\d+)) [\x09\x20]+ ([0-9]{3}) [\x09\x20]+ ([^\x0D\x0A]*) \x0D?\x0A/x
      or die(q/Malformed Status-Line: / . $Printable->($line). "\n");

    my ($protocol, $version, $status, $reason) = ($1, $2, $3, $4);

    die (qq/Unsupported HTTP protocol: $protocol\n/)
        unless $version =~ /0*1\.0*[01]/;

    return {
        status       => $status,
        reason       => $reason,
        headers      => $self->read_header_lines,
        protocol     => $protocol,
    };
}

sub write_request_header {
    @_ == 4 || die(q/Usage: $handle->write_request_header(method, request_uri, headers)/ . "\n");
    my ($self, $method, $request_uri, $headers) = @_;

    return $self->write_header_lines($headers, "$method $request_uri HTTP/1.1\x0D\x0A");
}

sub _do_timeout {
    my ($self, $type, $timeout) = @_;
    $timeout = $self->{timeout}
        unless defined $timeout && $timeout >= 0;

    my $fd = fileno $self->{fh};
    defined $fd && $fd >= 0
      or die(qq/select(2): 'Bad file descriptor'\n/);

    my $initial = time;
    my $pending = $timeout;
    my $nfound;

    vec(my $fdset = '', $fd, 1) = 1;

    while () {
        $nfound = ($type eq 'read')
            ? select($fdset, undef, undef, $pending)
            : select(undef, $fdset, undef, $pending) ;
        if ($nfound == -1) {
            $! == EINTR
              or die(qq/select(2): '$!'\n/);
            redo if !$timeout || ($pending = $timeout - (time - $initial)) > 0;
            $nfound = 0;
        }
        last;
    }
    $! = 0;
    return $nfound;
}

sub can_read {
    @_ == 1 || @_ == 2 || die(q/Usage: $handle->can_read([timeout])/ . "\n");
    my $self = shift;
    if ( ref($self->{fh}) eq 'IO::Socket::SSL' ) {
        return 1 if $self->{fh}->pending;
    }
    return $self->_do_timeout('read', @_)
}

sub can_write {
    @_ == 1 || @_ == 2 || die(q/Usage: $handle->can_write([timeout])/ . "\n");
    my $self = shift;
    return $self->_do_timeout('write', @_)
}

sub _assert_ssl {
    # Need IO::Socket::SSL 1.42 for SSL_create_ctx_callback
    die(qq/IO::Socket::SSL 1.42 must be installed for https support\n/)
        unless eval {require IO::Socket::SSL; IO::Socket::SSL->VERSION(1.42)};
    # Need Net::SSLeay 1.49 for MODE_AUTO_RETRY
    die(qq/Net::SSLeay 1.49 must be installed for https support\n/)
        unless eval {require Net::SSLeay; Net::SSLeay->VERSION(1.49)};
}

sub can_reuse {
    my ($self,$scheme,$host,$port) = @_;
    return 0 if
        $self->{pid} != $$
        || $self->{tid} != _get_tid()
        || length($self->{rbuf})
        || $scheme ne $self->{scheme}
        || $host ne $self->{host}
        || $port ne $self->{port}
        || eval { $self->can_read(0) }
        || $@ ;
        return 1;
}

# Try to find a CA bundle to validate the SSL cert,
# prefer Mozilla::CA or fallback to a system file
sub _find_CA_file {
    my $self = shift();

    return $self->{SSL_options}->{SSL_ca_file}
        if $self->{SSL_options}->{SSL_ca_file} and -e $self->{SSL_options}->{SSL_ca_file};

    return Mozilla::CA::SSL_ca_file()
        if eval { require Mozilla::CA };

    # cert list copied from golang src/crypto/x509/root_unix.go
    foreach my $ca_bundle (
        "/etc/ssl/certs/ca-certificates.crt",     # Debian/Ubuntu/Gentoo etc.
        "/etc/pki/tls/certs/ca-bundle.crt",       # Fedora/RHEL
        "/etc/ssl/ca-bundle.pem",                 # OpenSUSE
        "/etc/openssl/certs/ca-certificates.crt", # NetBSD
        "/etc/ssl/cert.pem",                      # OpenBSD
        "/usr/local/share/certs/ca-root-nss.crt", # FreeBSD/DragonFly
        "/etc/pki/tls/cacert.pem",                # OpenELEC
        "/etc/certs/ca-certificates.crt",         # Solaris 11.2+
    ) {
        return $ca_bundle if -e $ca_bundle;
    }

    die qq/Couldn't find a CA bundle with which to verify the SSL certificate.\n/
      . qq/Try installing Mozilla::CA from CPAN\n/;
}

# for thread safety, we need to know thread id if threads are loaded
sub _get_tid {
    no warnings 'reserved'; # for 'threads'
    return threads->can("tid") ? threads->tid : 0;
}

sub _ssl_args {
    my ($self, $host) = @_;

    my %ssl_args;

    # This test reimplements IO::Socket::SSL::can_client_sni(), which wasn't
    # added until IO::Socket::SSL 1.84
    if ( Net::SSLeay::OPENSSL_VERSION_NUMBER() >= 0x01000000 ) {
        $ssl_args{SSL_hostname} = $host,          # Sane SNI support
    }

    if ($self->{verify_SSL}) {
        $ssl_args{SSL_verifycn_scheme}  = 'http'; # enable CN validation
        $ssl_args{SSL_verifycn_name}    = $host;  # set validation hostname
        $ssl_args{SSL_verify_mode}      = 0x01;   # enable cert validation
        $ssl_args{SSL_ca_file}          = $self->_find_CA_file;
    }
    else {
        $ssl_args{SSL_verifycn_scheme}  = 'none'; # disable CN validation
        $ssl_args{SSL_verify_mode}      = 0x00;   # disable cert validation
    }

    # user options override settings from verify_SSL
    for my $k ( keys %{$self->{SSL_options}} ) {
        $ssl_args{$k} = $self->{SSL_options}{$k} if $k =~ m/^SSL_/;
    }

    return \%ssl_args;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny - A small, simple, correct HTTP/1.1 client

=head1 VERSION

version 0.054

=head1 SYNOPSIS

    use HTTP::Tiny;

    my $response = HTTP::Tiny->new->get('http://example.com/');

    die "Failed!\n" unless $response->{success};

    print "$response->{status} $response->{reason}\n";

    while (my ($k, $v) = each %{$response->{headers}}) {
        for (ref $v eq 'ARRAY' ? @$v : $v) {
            print "$k: $_\n";
        }
    }

    print $response->{content} if length $response->{content};

=head1 DESCRIPTION

This is a very simple HTTP/1.1 client, designed for doing simple
requests without the overhead of a large framework like L<LWP::UserAgent>.

It is more correct and more complete than L<HTTP::Lite>.  It supports
proxies and redirection.  It also correctly resumes after EINTR.

If L<IO::Socket::IP> 0.25 or later is installed, HTTP::Tiny will use it instead
of L<IO::Socket::INET> for transparent support for both IPv4 and IPv6.

Cookie support requires L<HTTP::CookieJar> or an equivalent class.

=head1 METHODS

=head2 new

    $http = HTTP::Tiny->new( %attributes );

This constructor returns a new HTTP::Tiny object.  Valid attributes include:

=over 4

=item *

C<agent> — A user-agent string (defaults to 'HTTP-Tiny/$VERSION'). If C<agent> — ends in a space character, the default user-agent string is appended.

=item *

C<cookie_jar> — An instance of L<HTTP::CookieJar> — or equivalent class that supports the C<add> and C<cookie_header> methods

=item *

C<default_headers> — A hashref of default headers to apply to requests

=item *

C<local_address> — The local IP address to bind to

=item *

C<keep_alive> — Whether to reuse the last connection (if for the same scheme, host and port) (defaults to 1)

=item *

C<max_redirect> — Maximum number of redirects allowed (defaults to 5)

=item *

C<max_size> — Maximum response size (only when not using a data callback).  If defined, responses larger than this will return an exception.

=item *

C<http_proxy> — URL of a proxy server to use for HTTP connections (default is C<$ENV{http_proxy}> — if set)

=item *

C<https_proxy> — URL of a proxy server to use for HTTPS connections (default is C<$ENV{https_proxy}> — if set)

=item *

C<proxy> — URL of a generic proxy server for both HTTP and HTTPS connections (default is C<$ENV{all_proxy}> — if set)

=item *

C<no_proxy> — List of domain suffixes that should not be proxied.  Must be a comma-separated string or an array reference. (default is C<$ENV{no_proxy}> —)

=item *

C<timeout> — Request timeout in seconds (default is 60)

=item *

C<verify_SSL> — A boolean that indicates whether to validate the SSL certificate of an C<https> — connection (default is false)

=item *

C<SSL_options> — A hashref of C<SSL_*> — options to pass through to L<IO::Socket::SSL>

=back

Passing an explicit C<undef> for C<proxy>, C<http_proxy> or C<https_proxy> will
prevent getting the corresponding proxies from the environment.

Exceptions from C<max_size>, C<timeout> or other errors will result in a
pseudo-HTTP status code of 599 and a reason of "Internal Exception". The
content field in the response will contain the text of the exception.

The C<keep_alive> parameter enables a persistent connection, but only to a
single destination scheme, host and port.  Also, if any connection-relevant
attributes are modified, or if the process ID or thread ID change, the
persistent connection will be dropped.  If you want persistent connections
across multiple destinations, use multiple HTTP::Tiny objects.

See L</SSL SUPPORT> for more on the C<verify_SSL> and C<SSL_options> attributes.

=head2 get|head|put|post|delete

    $response = $http->get($url);
    $response = $http->get($url, \%options);
    $response = $http->head($url);

These methods are shorthand for calling C<request()> for the given method.  The
URL must have unsafe characters escaped and international domain names encoded.
See C<request()> for valid options and a description of the response.

The C<success> field of the response will be true if the status code is 2XX.

=head2 post_form

    $response = $http->post_form($url, $form_data);
    $response = $http->post_form($url, $form_data, \%options);

This method executes a C<POST> request and sends the key/value pairs from a
form data hash or array reference to the given URL with a C<content-type> of
C<application/x-www-form-urlencoded>.  If data is provided as an array
reference, the order is preserved; if provided as a hash reference, the terms
are sorted on key and value for consistency.  See documentation for the
C<www_form_urlencode> method for details on the encoding.

The URL must have unsafe characters escaped and international domain names
encoded.  See C<request()> for valid options and a description of the response.
Any C<content-type> header or content in the options hashref will be ignored.

The C<success> field of the response will be true if the status code is 2XX.

=head2 mirror

    $response = $http->mirror($url, $file, \%options)
    if ( $response->{success} ) {
        print "$file is up to date\n";
    }

Executes a C<GET> request for the URL and saves the response body to the file
name provided.  The URL must have unsafe characters escaped and international
domain names encoded.  If the file already exists, the request will include an
C<If-Modified-Since> header with the modification timestamp of the file.  You
may specify a different C<If-Modified-Since> header yourself in the C<<
$options->{headers} >> hash.

The C<success> field of the response will be true if the status code is 2XX
or if the status code is 304 (unmodified).

If the file was modified and the server response includes a properly
formatted C<Last-Modified> header, the file modification time will
be updated accordingly.

=head2 request

    $response = $http->request($method, $url);
    $response = $http->request($method, $url, \%options);

Executes an HTTP request of the given method type ('GET', 'HEAD', 'POST',
'PUT', etc.) on the given URL.  The URL must have unsafe characters escaped and
international domain names encoded.

If the URL includes a "user:password" stanza, they will be used for Basic-style
authorization headers.  (Authorization headers will not be included in a
redirected request.) For example:

    $http->request('GET', 'http://Aladdin:open sesame@example.com/');

If the "user:password" stanza contains reserved characters, they must
be percent-escaped:

    $http->request('GET', 'http://john%40example.com:password@example.com/');

A hashref of options may be appended to modify the request.

Valid options are:

=over 4

=item *

C<headers> — A hashref containing headers to include with the request.  If the value for a header is an array reference, the header will be output multiple times with each value in the array.  These headers over-write any default headers.

=item *

C<content> — A scalar to include as the body of the request OR a code reference that will be called iteratively to produce the body of the request

=item *

C<trailer_callback> — A code reference that will be called if it exists to provide a hashref of trailing headers (only used with chunked transfer-encoding)

=item *

C<data_callback> — A code reference that will be called for each chunks of the response body received.

=back

The C<Host> header is generated from the URL in accordance with RFC 2616.  It
is a fatal error to specify C<Host> in the C<headers> option.  Other headers
may be ignored or overwritten if necessary for transport compliance.

If the C<content> option is a code reference, it will be called iteratively
to provide the content body of the request.  It should return the empty
string or undef when the iterator is exhausted.

If the C<content> option is the empty string, no C<content-type> or
C<content-length> headers will be generated.

If the C<data_callback> option is provided, it will be called iteratively until
the entire response body is received.  The first argument will be a string
containing a chunk of the response body, the second argument will be the
in-progress response hash reference, as described below.  (This allows
customizing the action of the callback based on the C<status> or C<headers>
received prior to the content body.)

The C<request> method returns a hashref containing the response.  The hashref
will have the following keys:

=over 4

=item *

C<success> — Boolean indicating whether the operation returned a 2XX status code

=item *

C<url> — URL that provided the response. This is the URL of the request unless there were redirections, in which case it is the last URL queried in a redirection chain

=item *

C<status> — The HTTP status code of the response

=item *

C<reason> — The response phrase returned by the server

=item *

C<content> — The body of the response.  If the response does not have any content or if a data callback is provided to consume the response body, this will be the empty string

=item *

C<headers> — A hashref of header fields.  All header field names will be normalized to be lower case. If a header is repeated, the value will be an arrayref; it will otherwise be a scalar string containing the value

=back

On an exception during the execution of the request, the C<status> field will
contain 599, and the C<content> field will contain the text of the exception.

=head2 www_form_urlencode

    $params = $http->www_form_urlencode( $data );
    $response = $http->get("http://example.com/query?$params");

This method converts the key/value pairs from a data hash or array reference
into a C<x-www-form-urlencoded> string.  The keys and values from the data
reference will be UTF-8 encoded and escaped per RFC 3986.  If a value is an
array reference, the key will be repeated with each of the values of the array
reference.  If data is provided as a hash reference, the key/value pairs in the
resulting string will be sorted by key and value for consistent ordering.

=for Pod::Coverage SSL_options
agent
cookie_jar
default_headers
http_proxy
https_proxy
keep_alive
local_address
max_redirect
max_size
no_proxy
proxy
timeout
verify_SSL

=head1 SSL SUPPORT

Direct C<https> connections are supported only if L<IO::Socket::SSL> 1.56 or
greater and L<Net::SSLeay> 1.49 or greater are installed. An exception will be
thrown if new enough versions of these modules are not installed or if the SSL
encryption fails. An C<https> connection may be made via an C<http> proxy that
supports the CONNECT command (i.e. RFC 2817).  You may not proxy C<https> via
a proxy that itself requires C<https> to communicate.

SSL provides two distinct capabilities:

=over 4

=item *

Encrypted communication channel

=item *

Verification of server identity

=back

B<By default, HTTP::Tiny does not verify server identity>.

Server identity verification is controversial and potentially tricky because it
depends on a (usually paid) third-party Certificate Authority (CA) trust model
to validate a certificate as legitimate.  This discriminates against servers
with self-signed certificates or certificates signed by free, community-driven
CA's such as L<CAcert.org|http://cacert.org>.

By default, HTTP::Tiny does not make any assumptions about your trust model,
threat level or risk tolerance.  It just aims to give you an encrypted channel
when you need one.

Setting the C<verify_SSL> attribute to a true value will make HTTP::Tiny verify
that an SSL connection has a valid SSL certificate corresponding to the host
name of the connection and that the SSL certificate has been verified by a CA.
Assuming you trust the CA, this will protect against a L<man-in-the-middle
attack|http://en.wikipedia.org/wiki/Man-in-the-middle_attack>.  If you are
concerned about security, you should enable this option.

Certificate verification requires a file containing trusted CA certificates.
If the L<Mozilla::CA> module is installed, HTTP::Tiny will use the CA file
included with it as a source of trusted CA's.  (This means you trust Mozilla,
the author of Mozilla::CA, the CPAN mirror where you got Mozilla::CA, the
toolchain used to install it, and your operating system security, right?)

If that module is not available, then HTTP::Tiny will search several
system-specific default locations for a CA certificate file:

=over 4

=item *

/etc/ssl/certs/ca-certificates.crt

=item *

/etc/pki/tls/certs/ca-bundle.crt

=item *

/etc/ssl/ca-bundle.pem

=back

An exception will be raised if C<verify_SSL> is true and no CA certificate file
is available.

If you desire complete control over SSL connections, the C<SSL_options> attribute
lets you provide a hash reference that will be passed through to
C<IO::Socket::SSL::start_SSL()>, overriding any options set by HTTP::Tiny. For
example, to provide your own trusted CA file:

    SSL_options => {
        SSL_ca_file => $file_path,
    }

The C<SSL_options> attribute could also be used for such things as providing a
client certificate for authentication to a server or controlling the choice of
cipher used for the SSL connection. See L<IO::Socket::SSL> documentation for
details.

=head1 PROXY SUPPORT

HTTP::Tiny can proxy both C<http> and C<https> requests.  Only Basic proxy
authorization is supported and it must be provided as part of the proxy URL:
C<http://user:pass@proxy.example.com/>.

HTTP::Tiny supports the following proxy environment variables:

=over 4

=item *

http_proxy or HTTP_PROXY

=item *

https_proxy or HTTPS_PROXY

=item *

all_proxy or ALL_PROXY

=back

If the C<REQUEST_METHOD> environment variable is set, then this might be a CGI
process and C<HTTP_PROXY> would be set from the C<Proxy:> header, which is a
security risk.  If C<REQUEST_METHOD> is set, C<HTTP_PROXY> (the upper case
variant only) is ignored.

Tunnelling C<https> over an C<http> proxy using the CONNECT method is
supported.  If your proxy uses C<https> itself, you can not tunnel C<https>
over it.

Be warned that proxying an C<https> connection opens you to the risk of a
man-in-the-middle attack by the proxy server.

The C<no_proxy> environment variable is supported in the format of a
comma-separated list of domain extensions proxy should not be used for.

Proxy arguments passed to C<new> will override their corresponding
environment variables.

=head1 LIMITATIONS

HTTP::Tiny is I<conditionally compliant> with the
L<HTTP/1.1 specifications|http://www.w3.org/Protocols/>:

=over 4

=item *

"Message Syntax and Routing" [RFC7230]

=item *

"Semantics and Content" [RFC7231]

=item *

"Conditional Requests" [RFC7232]

=item *

"Range Requests" [RFC7233]

=item *

"Caching" [RFC7234]

=item *

"Authentication" [RFC7235]

=back

It attempts to meet all "MUST" requirements of the specification, but does not
implement all "SHOULD" requirements.  (Note: it was developed against the
earlier RFC 2616 specification and may not yet meet the revised RFC 7230-7235
spec.)

Some particular limitations of note include:

=over

=item *

HTTP::Tiny focuses on correct transport.  Users are responsible for ensuring
that user-defined headers and content are compliant with the HTTP/1.1
specification.

=item *

Users must ensure that URLs are properly escaped for unsafe characters and that
international domain names are properly encoded to ASCII. See L<URI::Escape>,
L<URI::_punycode> and L<Net::IDN::Encode>.

=item *

Redirection is very strict against the specification.  Redirection is only
automatic for response codes 301, 302 and 307 if the request method is 'GET' or
'HEAD'.  Response code 303 is always converted into a 'GET' redirection, as
mandated by the specification.  There is no automatic support for status 305
("Use proxy") redirections.

=item *

There is no provision for delaying a request body using an C<Expect> header.
Unexpected C<1XX> responses are silently ignored as per the specification.

=item *

Only 'chunked' C<Transfer-Encoding> is supported.

=item *

There is no support for a Request-URI of '*' for the 'OPTIONS' request.

=back

Despite the limitations listed above, HTTP::Tiny is considered
feature-complete.  New feature requests should be directed to
L<HTTP::Tiny::UA>.

=head1 SEE ALSO

=over 4

=item *

L<HTTP::Tiny::UA> - Higher level UA features for HTTP::Tiny

=item *

L<HTTP::Thin> - HTTP::Tiny wrapper with L<HTTP::Request>/L<HTTP::Response> compatibility

=item *

L<HTTP::Tiny::Mech> - Wrap L<WWW::Mechanize> instance in HTTP::Tiny compatible interface

=item *

L<IO::Socket::IP> - Required for IPv6 support

=item *

L<IO::Socket::SSL> - Required for SSL support

=item *

L<LWP::UserAgent> - If HTTP::Tiny isn't enough for you, this is the "standard" way to do things

=item *

L<Mozilla::CA> - Required if you want to validate SSL certificates

=item *

L<Net::SSLeay> - Required for SSL support

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/chansen/p5-http-tiny/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/chansen/p5-http-tiny>

  git clone https://github.com/chansen/p5-http-tiny.git

=head1 AUTHORS

=over 4

=item *

Christian Hansen <chansen@cpan.org>

=item *

David Golden <dagolden@cpan.org>

=back

=head1 CONTRIBUTORS

=for stopwords Alan Gardner Alessandro Ghedini Brad Gilbert Chris Nehren Weyl Claes Jakobsson Clinton Gormley Craig Berry David Mitchell Dean Pearce Edward Zborowski James Raspass Jess Robinson Lukas Eklund Martin J. Evans Martin-Louis Bright Mike Doherty Olaf Alders Petr Písař Serguei Trouchelle Sören Kornetzki Syohei YOSHIDA Tom Hukins Tony Cook

=over 4

=item *

Alan Gardner <gardner@pythian.com>

=item *

Alessandro Ghedini <al3xbio@gmail.com>

=item *

Brad Gilbert <bgills@cpan.org>

=item *

Chris Nehren <apeiron@cpan.org>

=item *

Chris Weyl <cweyl@alumni.drew.edu>

=item *

Claes Jakobsson <claes@surfar.nu>

=item *

Clinton Gormley <clint@traveljury.com>

=item *

Craig Berry <cberry@cpan.org>

=item *

David Mitchell <davem@iabyn.com>

=item *

Dean Pearce <pearce@pythian.com>

=item *

Edward Zborowski <ed@rubensteintech.com>

=item *

James Raspass <jraspass@gmail.com>

=item *

Jess Robinson <castaway@desert-island.me.uk>

=item *

Lukas Eklund <leklund@gmail.com>

=item *

Martin J. Evans <mjegh@ntlworld.com>

=item *

Martin-Louis Bright <mlbright@gmail.com>

=item *

Mike Doherty <doherty@cpan.org>

=item *

Olaf Alders <olaf@wundersolutions.com>

=item *

Petr Písař <ppisar@redhat.com>

=item *

Serguei Trouchelle <stro@cpan.org>

=item *

Sören Kornetzki <soeren.kornetzki@delti.com>

=item *

Syohei YOSHIDA <syohex@gmail.com>

=item *

Tom Hukins <tom@eborcom.com>

=item *

Tony Cook <tony@develop-help.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christian Hansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
