package LWP::Simple;

use strict;
use vars qw($ua %loop_check $FULL_LWP @EXPORT @EXPORT_OK $VERSION);

require Exporter;

@EXPORT = qw(get head getprint getstore mirror);
@EXPORT_OK = qw($ua);

# I really hate this.  I was a bad idea to do it in the first place.
# Wonder how to get rid of it???  (It even makes LWP::Simple 7% slower
# for trivial tests)
use HTTP::Status;
push(@EXPORT, @HTTP::Status::EXPORT);

$VERSION = "6.13";

sub import
{
    my $pkg = shift;
    my $callpkg = caller;
    Exporter::export($pkg, $callpkg, @_);
}

use LWP::UserAgent ();
use HTTP::Status ();
use HTTP::Date ();
$ua = LWP::UserAgent->new;  # we create a global UserAgent object
$ua->agent("LWP::Simple/$VERSION ");
$ua->env_proxy;


sub get ($)
{
    my $response = $ua->get(shift);
    return $response->decoded_content if $response->is_success;
    return undef;
}


sub head ($)
{
    my($url) = @_;
    my $request = HTTP::Request->new(HEAD => $url);
    my $response = $ua->request($request);

    if ($response->is_success) {
	return $response unless wantarray;
	return (scalar $response->header('Content-Type'),
		scalar $response->header('Content-Length'),
		HTTP::Date::str2time($response->header('Last-Modified')),
		HTTP::Date::str2time($response->header('Expires')),
		scalar $response->header('Server'),
	       );
    }
    return;
}


sub getprint ($)
{
    my($url) = @_;
    my $request = HTTP::Request->new(GET => $url);
    local($\) = ""; # ensure standard $OUTPUT_RECORD_SEPARATOR
    my $callback = sub { print $_[0] };
    if ($^O eq "MacOS") {
	$callback = sub { $_[0] =~ s/\015?\012/\n/g; print $_[0] }
    }
    my $response = $ua->request($request, $callback);
    unless ($response->is_success) {
	print STDERR $response->status_line, " <URL:$url>\n";
    }
    $response->code;
}


sub getstore ($$)
{
    my($url, $file) = @_;
    my $request = HTTP::Request->new(GET => $url);
    my $response = $ua->request($request, $file);

    $response->code;
}


sub mirror ($$)
{
    my($url, $file) = @_;
    my $response = $ua->mirror($url, $file);
    $response->code;
}


1;

__END__

=head1 NAME

LWP::Simple - simple procedural interface to LWP

=head1 SYNOPSIS

 perl -MLWP::Simple -e 'getprint "http://www.sn.no"'

 use LWP::Simple;
 $content = get("http://www.sn.no/");
 die "Couldn't get it!" unless defined $content;

 if (mirror("http://www.sn.no/", "foo") == RC_NOT_MODIFIED) {
     ...
 }

 if (is_success(getprint("http://www.sn.no/"))) {
     ...
 }

=head1 DESCRIPTION

This module is meant for people who want a simplified view of the
libwww-perl library.  It should also be suitable for one-liners.  If
you need more control or access to the header fields in the requests
sent and responses received, then you should use the full object-oriented
interface provided by the C<LWP::UserAgent> module.

The following functions are provided (and exported) by this module:

=over 3

=item get($url)

The get() function will fetch the document identified by the given URL
and return it.  It returns C<undef> if it fails.  The $url argument can
be either a string or a reference to a URI object.

You will not be able to examine the response code or response headers
(like 'Content-Type') when you are accessing the web using this
function.  If you need that information you should use the full OO
interface (see L<LWP::UserAgent>).

=item head($url)

Get document headers. Returns the following 5 values if successful:
($content_type, $document_length, $modified_time, $expires, $server)

Returns an empty list if it fails.  In scalar context returns TRUE if
successful.

=item getprint($url)

Get and print a document identified by a URL. The document is printed
to the selected default filehandle for output (normally STDOUT) as
data is received from the network.  If the request fails, then the
status code and message are printed on STDERR.  The return value is
the HTTP response code.

=item getstore($url, $file)

Gets a document identified by a URL and stores it in the file. The
return value is the HTTP response code.

=item mirror($url, $file)

Get and store a document identified by a URL, using
I<If-modified-since>, and checking the I<Content-Length>.  Returns
the HTTP response code.

=back

This module also exports the HTTP::Status constants and procedures.
You can use them when you check the response code from getprint(),
getstore() or mirror().  The constants are:

   RC_CONTINUE
   RC_SWITCHING_PROTOCOLS
   RC_OK
   RC_CREATED
   RC_ACCEPTED
   RC_NON_AUTHORITATIVE_INFORMATION
   RC_NO_CONTENT
   RC_RESET_CONTENT
   RC_PARTIAL_CONTENT
   RC_MULTIPLE_CHOICES
   RC_MOVED_PERMANENTLY
   RC_MOVED_TEMPORARILY
   RC_SEE_OTHER
   RC_NOT_MODIFIED
   RC_USE_PROXY
   RC_BAD_REQUEST
   RC_UNAUTHORIZED
   RC_PAYMENT_REQUIRED
   RC_FORBIDDEN
   RC_NOT_FOUND
   RC_METHOD_NOT_ALLOWED
   RC_NOT_ACCEPTABLE
   RC_PROXY_AUTHENTICATION_REQUIRED
   RC_REQUEST_TIMEOUT
   RC_CONFLICT
   RC_GONE
   RC_LENGTH_REQUIRED
   RC_PRECONDITION_FAILED
   RC_REQUEST_ENTITY_TOO_LARGE
   RC_REQUEST_URI_TOO_LARGE
   RC_UNSUPPORTED_MEDIA_TYPE
   RC_INTERNAL_SERVER_ERROR
   RC_NOT_IMPLEMENTED
   RC_BAD_GATEWAY
   RC_SERVICE_UNAVAILABLE
   RC_GATEWAY_TIMEOUT
   RC_HTTP_VERSION_NOT_SUPPORTED

The HTTP::Status classification functions are:

=over 3

=item is_success($rc)

True if response code indicated a successful request.

=item is_error($rc)

True if response code indicated that an error occurred.

=back

The module will also export the LWP::UserAgent object as C<$ua> if you
ask for it explicitly.

The user agent created by this module will identify itself as
"LWP::Simple/#.##"
and will initialize its proxy defaults from the environment (by
calling $ua->env_proxy).

=head1 CAVEAT

Note that if you are using both LWP::Simple and the very popular CGI.pm
module, you may be importing a C<head> function from each module,
producing a warning like "Prototype mismatch: sub main::head ($) vs
none". Get around this problem by just not importing LWP::Simple's
C<head> function, like so:

        use LWP::Simple qw(!head);
        use CGI qw(:standard);  # then only CGI.pm defines a head()

Then if you do need LWP::Simple's C<head> function, you can just call
it as C<LWP::Simple::head($url)>.

=head1 SEE ALSO

L<LWP>, L<lwpcook>, L<LWP::UserAgent>, L<HTTP::Status>, L<lwp-request>,
L<lwp-mirror>
