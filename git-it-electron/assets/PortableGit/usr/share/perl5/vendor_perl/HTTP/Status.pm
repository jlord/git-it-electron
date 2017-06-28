package HTTP::Status;

use strict;
require 5.002;   # because we use prototypes

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(is_info is_success is_redirect is_error status_message);
@EXPORT_OK = qw(is_client_error is_server_error);
$VERSION = "6.03";

# Note also addition of mnemonics to @EXPORT below

# Unmarked codes are from RFC 2616
# See also: http://en.wikipedia.org/wiki/List_of_HTTP_status_codes

my %StatusCode = (
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',                      # RFC 2518 (WebDAV)
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',                    # RFC 2518 (WebDAV)
    208 => 'Already Reported',		      # RFC 5842
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Large',
    415 => 'Unsupported Media Type',
    416 => 'Request Range Not Satisfiable',
    417 => 'Expectation Failed',
    418 => 'I\'m a teapot',		      # RFC 2324
    422 => 'Unprocessable Entity',            # RFC 2518 (WebDAV)
    423 => 'Locked',                          # RFC 2518 (WebDAV)
    424 => 'Failed Dependency',               # RFC 2518 (WebDAV)
    425 => 'No code',                         # WebDAV Advanced Collections
    426 => 'Upgrade Required',                # RFC 2817
    428 => 'Precondition Required',
    429 => 'Too Many Requests',
    431 => 'Request Header Fields Too Large',
    449 => 'Retry with',                      # unofficial Microsoft
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',         # RFC 2295
    507 => 'Insufficient Storage',            # RFC 2518 (WebDAV)
    509 => 'Bandwidth Limit Exceeded',        # unofficial
    510 => 'Not Extended',                    # RFC 2774
    511 => 'Network Authentication Required',
);

my $mnemonicCode = '';
my ($code, $message);
while (($code, $message) = each %StatusCode) {
    # create mnemonic subroutines
    $message =~ s/I'm/I am/;
    $message =~ tr/a-z \-/A-Z__/;
    $mnemonicCode .= "sub HTTP_$message () { $code }\n";
    $mnemonicCode .= "*RC_$message = \\&HTTP_$message;\n";  # legacy
    $mnemonicCode .= "push(\@EXPORT_OK, 'HTTP_$message');\n";
    $mnemonicCode .= "push(\@EXPORT, 'RC_$message');\n";
}
eval $mnemonicCode; # only one eval for speed
die if $@;

# backwards compatibility
*RC_MOVED_TEMPORARILY = \&RC_FOUND;  # 302 was renamed in the standard
push(@EXPORT, "RC_MOVED_TEMPORARILY");

%EXPORT_TAGS = (
   constants => [grep /^HTTP_/, @EXPORT_OK],
   is => [grep /^is_/, @EXPORT, @EXPORT_OK],
);


sub status_message  ($) { $StatusCode{$_[0]}; }

sub is_info         ($) { $_[0] >= 100 && $_[0] < 200; }
sub is_success      ($) { $_[0] >= 200 && $_[0] < 300; }
sub is_redirect     ($) { $_[0] >= 300 && $_[0] < 400; }
sub is_error        ($) { $_[0] >= 400 && $_[0] < 600; }
sub is_client_error ($) { $_[0] >= 400 && $_[0] < 500; }
sub is_server_error ($) { $_[0] >= 500 && $_[0] < 600; }

1;


__END__

=head1 NAME

HTTP::Status - HTTP Status code processing

=head1 SYNOPSIS

 use HTTP::Status qw(:constants :is status_message);

 if ($rc != HTTP_OK) {
     print status_message($rc), "\n";
 }

 if (is_success($rc)) { ... }
 if (is_error($rc)) { ... }
 if (is_redirect($rc)) { ... }

=head1 DESCRIPTION

I<HTTP::Status> is a library of routines for defining and
classifying HTTP status codes for libwww-perl.  Status codes are
used to encode the overall outcome of an HTTP response message.  Codes
correspond to those defined in RFC 2616 and RFC 2518.

=head1 CONSTANTS

The following constant functions can be used as mnemonic status code
names.  None of these are exported by default.  Use the C<:constants>
tag to import them all.

   HTTP_CONTINUE                        (100)
   HTTP_SWITCHING_PROTOCOLS             (101)
   HTTP_PROCESSING                      (102)

   HTTP_OK                              (200)
   HTTP_CREATED                         (201)
   HTTP_ACCEPTED                        (202)
   HTTP_NON_AUTHORITATIVE_INFORMATION   (203)
   HTTP_NO_CONTENT                      (204)
   HTTP_RESET_CONTENT                   (205)
   HTTP_PARTIAL_CONTENT                 (206)
   HTTP_MULTI_STATUS                    (207)
   HTTP_ALREADY_REPORTED		(208)

   HTTP_MULTIPLE_CHOICES                (300)
   HTTP_MOVED_PERMANENTLY               (301)
   HTTP_FOUND                           (302)
   HTTP_SEE_OTHER                       (303)
   HTTP_NOT_MODIFIED                    (304)
   HTTP_USE_PROXY                       (305)
   HTTP_TEMPORARY_REDIRECT              (307)

   HTTP_BAD_REQUEST                     (400)
   HTTP_UNAUTHORIZED                    (401)
   HTTP_PAYMENT_REQUIRED                (402)
   HTTP_FORBIDDEN                       (403)
   HTTP_NOT_FOUND                       (404)
   HTTP_METHOD_NOT_ALLOWED              (405)
   HTTP_NOT_ACCEPTABLE                  (406)
   HTTP_PROXY_AUTHENTICATION_REQUIRED   (407)
   HTTP_REQUEST_TIMEOUT                 (408)
   HTTP_CONFLICT                        (409)
   HTTP_GONE                            (410)
   HTTP_LENGTH_REQUIRED                 (411)
   HTTP_PRECONDITION_FAILED             (412)
   HTTP_REQUEST_ENTITY_TOO_LARGE        (413)
   HTTP_REQUEST_URI_TOO_LARGE           (414)
   HTTP_UNSUPPORTED_MEDIA_TYPE          (415)
   HTTP_REQUEST_RANGE_NOT_SATISFIABLE   (416)
   HTTP_EXPECTATION_FAILED              (417)
   HTTP_I_AM_A_TEAPOT			(418)
   HTTP_UNPROCESSABLE_ENTITY            (422)
   HTTP_LOCKED                          (423)
   HTTP_FAILED_DEPENDENCY               (424)
   HTTP_NO_CODE                         (425)
   HTTP_UPGRADE_REQUIRED                (426)
   HTTP_PRECONDITION_REQUIRED		(428)
   HTTP_TOO_MANY_REQUESTS		(429)
   HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE (431)
   HTTP_RETRY_WITH                      (449)

   HTTP_INTERNAL_SERVER_ERROR           (500)
   HTTP_NOT_IMPLEMENTED                 (501)
   HTTP_BAD_GATEWAY                     (502)
   HTTP_SERVICE_UNAVAILABLE             (503)
   HTTP_GATEWAY_TIMEOUT                 (504)
   HTTP_HTTP_VERSION_NOT_SUPPORTED      (505)
   HTTP_VARIANT_ALSO_NEGOTIATES         (506)
   HTTP_INSUFFICIENT_STORAGE            (507)
   HTTP_BANDWIDTH_LIMIT_EXCEEDED        (509)
   HTTP_NOT_EXTENDED                    (510)
   HTTP_NETWORK_AUTHENTICATION_REQUIRED (511)

=head1 FUNCTIONS

The following additional functions are provided.  Most of them are
exported by default.  The C<:is> import tag can be used to import all
the classification functions.

=over 4

=item status_message( $code )

The status_message() function will translate status codes to human
readable strings. The string is the same as found in the constant
names above.  If the $code is unknown, then C<undef> is returned.

=item is_info( $code )

Return TRUE if C<$code> is an I<Informational> status code (1xx).  This
class of status code indicates a provisional response which can't have
any content.

=item is_success( $code )

Return TRUE if C<$code> is a I<Successful> status code (2xx).

=item is_redirect( $code )

Return TRUE if C<$code> is a I<Redirection> status code (3xx). This class of
status code indicates that further action needs to be taken by the
user agent in order to fulfill the request.

=item is_error( $code )

Return TRUE if C<$code> is an I<Error> status code (4xx or 5xx).  The function
returns TRUE for both client and server error status codes.

=item is_client_error( $code )

Return TRUE if C<$code> is a I<Client Error> status code (4xx). This class
of status code is intended for cases in which the client seems to have
erred.

This function is B<not> exported by default.

=item is_server_error( $code )

Return TRUE if C<$code> is a I<Server Error> status code (5xx). This class
of status codes is intended for cases in which the server is aware
that it has erred or is incapable of performing the request.

This function is B<not> exported by default.

=back

=head1 BUGS

For legacy reasons all the C<HTTP_> constants are exported by default
with the prefix C<RC_>.  It's recommended to use explicit imports and
the C<:constants> tag instead of relying on this.
