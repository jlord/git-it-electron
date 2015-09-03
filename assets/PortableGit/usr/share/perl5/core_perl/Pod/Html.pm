package Pod::Html;
use strict;
require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
$VERSION = 1.22;
@ISA = qw(Exporter);
@EXPORT = qw(pod2html htmlify);
@EXPORT_OK = qw(anchorify);

use Carp;
use Config;
use Cwd;
use File::Basename;
use File::Spec;
use File::Spec::Unix;
use Getopt::Long;
use Pod::Simple::Search;
use locale; # make \w work right in non-ASCII lands

=head1 NAME

Pod::Html - module to convert pod files to HTML

=head1 SYNOPSIS

    use Pod::Html;
    pod2html([options]);

=head1 DESCRIPTION

Converts files from pod format (see L<perlpod>) to HTML format.  It
can automatically generate indexes and cross-references, and it keeps
a cache of things it knows how to cross-reference.

=head1 FUNCTIONS

=head2 pod2html

    pod2html("pod2html",
             "--podpath=lib:ext:pod:vms",
             "--podroot=/usr/src/perl",
             "--htmlroot=/perl/nmanual",
             "--recurse",
             "--infile=foo.pod",
             "--outfile=/perl/nmanual/foo.html");

pod2html takes the following arguments:

=over 4

=item backlink

    --backlink

Turns every C<head1> heading into a link back to the top of the page.
By default, no backlinks are generated.

=item cachedir

    --cachedir=name

Creates the directory cache in the given directory.

=item css

    --css=stylesheet

Specify the URL of a cascading style sheet.  Also disables all HTML/CSS
C<style> attributes that are output by default (to avoid conflicts).

=item flush

    --flush

Flushes the directory cache.

=item header

    --header
    --noheader

Creates header and footer blocks containing the text of the C<NAME>
section.  By default, no headers are generated.

=item help

    --help

Displays the usage message.

=item htmldir

    --htmldir=name

Sets the directory to which all cross references in the resulting
html file will be relative. Not passing this causes all links to be
absolute since this is the value that tells Pod::Html the root of the 
documentation tree.

Do not use this and --htmlroot in the same call to pod2html; they are
mutually exclusive.

=item htmlroot

    --htmlroot=name

Sets the base URL for the HTML files.  When cross-references are made,
the HTML root is prepended to the URL.

Do not use this if relative links are desired: use --htmldir instead.

Do not pass both this and --htmldir to pod2html; they are mutually
exclusive.

=item index

    --index
    --noindex

Generate an index at the top of the HTML file.  This is the default
behaviour.

=item infile

    --infile=name

Specify the pod file to convert.  Input is taken from STDIN if no
infile is specified.

=item outfile

    --outfile=name

Specify the HTML file to create.  Output goes to STDOUT if no outfile
is specified.

=item poderrors

    --poderrors
    --nopoderrors

Include a "POD ERRORS" section in the outfile if there were any POD 
errors in the infile. This section is included by default.

=item podpath

    --podpath=name:...:name

Specify which subdirectories of the podroot contain pod files whose
HTML converted forms can be linked to in cross references.

=item podroot

    --podroot=name

Specify the base directory for finding library pods. Default is the
current working directory.

=item quiet

    --quiet
    --noquiet

Don't display I<mostly harmless> warning messages.  These messages
will be displayed by default.  But this is not the same as C<verbose>
mode.

=item recurse

    --recurse
    --norecurse

Recurse into subdirectories specified in podpath (default behaviour).

=item title

    --title=title

Specify the title of the resulting HTML file.

=item verbose

    --verbose
    --noverbose

Display progress messages.  By default, they won't be displayed.

=back

=head2 htmlify

    htmlify($heading);

Converts a pod section specification to a suitable section specification
for HTML. Note that we keep spaces and special characters except
C<", ?> (Netscape problem) and the hyphen (writer's problem...).

=head2 anchorify

    anchorify(@heading);

Similar to C<htmlify()>, but turns non-alphanumerics into underscores.  Note
that C<anchorify()> is not exported by default.

=head1 ENVIRONMENT

Uses C<$Config{pod2html}> to setup default options.

=head1 AUTHOR

Marc Green, E<lt>marcgreen@cpan.orgE<gt>. 

Original version by Tom Christiansen, E<lt>tchrist@perl.comE<gt>.

=head1 SEE ALSO

L<perlpod>

=head1 COPYRIGHT

This program is distributed under the Artistic License.

=cut

my $Cachedir; 
my $Dircache;
my($Htmlroot, $Htmldir, $Htmlfile, $Htmlfileurl);
my($Podfile, @Podpath, $Podroot);
my $Poderrors;
my $Css;

my $Recurse;
my $Quiet;
my $Verbose;
my $Doindex;

my $Backlink;

my($Title, $Header);

my %Pages = ();                 # associative array used to find the location
                                #   of pages referenced by L<> links.

my $Curdir = File::Spec->curdir;

init_globals();

sub init_globals {
    $Cachedir = ".";            # The directory to which directory caches
                                #   will be written.

    $Dircache = "pod2htmd.tmp";

    $Htmlroot = "/";            # http-server base directory from which all
                                #   relative paths in $podpath stem.
    $Htmldir = "";              # The directory to which the html pages
                                #   will (eventually) be written.
    $Htmlfile = "";             # write to stdout by default
    $Htmlfileurl = "";          # The url that other files would use to
                                # refer to this file.  This is only used
                                # to make relative urls that point to
                                # other files.

    $Poderrors = 1;
    $Podfile = "";              # read from stdin by default
    @Podpath = ();              # list of directories containing library pods.
    $Podroot = $Curdir;         # filesystem base directory from which all
                                #   relative paths in $podpath stem.
    $Css = '';                  # Cascading style sheet
    $Recurse = 1;               # recurse on subdirectories in $podpath.
    $Quiet = 0;                 # not quiet by default
    $Verbose = 0;               # not verbose by default
    $Doindex = 1;               # non-zero if we should generate an index
    $Backlink = 0;              # no backlinks added by default
    $Header = 0;                # produce block header/footer
    $Title = '';                # title to give the pod(s)
}

sub pod2html {
    local(@ARGV) = @_;
    local $_;

    init_globals();
    parse_command_line();

    # prevent '//' in urls
    $Htmlroot = "" if $Htmlroot eq "/";
    $Htmldir =~ s#/\z##;

    if (  $Htmlroot eq ''
       && defined( $Htmldir )
       && $Htmldir ne ''
       && substr( $Htmlfile, 0, length( $Htmldir ) ) eq $Htmldir
       ) {
        # Set the 'base' url for this file, so that we can use it
        # as the location from which to calculate relative links
        # to other files. If this is '', then absolute links will
        # be used throughout.
        #$Htmlfileurl = "$Htmldir/" . substr( $Htmlfile, length( $Htmldir ) + 1);
        # Is the above not just "$Htmlfileurl = $Htmlfile"?
        $Htmlfileurl = Pod::Html::_unixify($Htmlfile);

    }

    # load or generate/cache %Pages
    unless (get_cache($Dircache, \@Podpath, $Podroot, $Recurse)) {
        # generate %Pages
        my $pwd = getcwd();
        chdir($Podroot) || 
            die "$0: error changing to directory $Podroot: $!\n";

        # find all pod modules/pages in podpath, store in %Pages
        # - callback used to remove Podroot and extension from each file
        # - laborious to allow '.' in dirnames (e.g., /usr/share/perl/5.14.1)
        Pod::Simple::Search->new->inc(0)->verbose($Verbose)->laborious(1)
            ->callback(\&_save_page)->recurse($Recurse)->survey(@Podpath);

        chdir($pwd) || die "$0: error changing to directory $pwd: $!\n";

        # cache the directory list for later use
        warn "caching directories for later use\n" if $Verbose;
        open my $cache, '>', $Dircache
            or die "$0: error open $Dircache for writing: $!\n";

        print $cache join(":", @Podpath) . "\n$Podroot\n";
        my $_updirs_only = ($Podroot =~ /\.\./) && !($Podroot =~ /[^\.\\\/]/);
        foreach my $key (keys %Pages) {
            if($_updirs_only) {
              my $_dirlevel = $Podroot;
              while($_dirlevel =~ /\.\./) {
                $_dirlevel =~ s/\.\.//;
                # Assume $Pages{$key} has '/' separators (html dir separators).
                $Pages{$key} =~ s/^[\w\s\-\.]+\///;
              }
            }
            print $cache "$key $Pages{$key}\n";
        }

        close $cache or die "error closing $Dircache: $!";
    }

    # set options for the parser
    my $parser = Pod::Simple::XHTML::LocalPodLinks->new();
    $parser->codes_in_verbatim(0);
    $parser->anchor_items(1); # the old Pod::Html always did
    $parser->backlink($Backlink); # linkify =head1 directives
    $parser->htmldir($Htmldir);
    $parser->htmlfileurl($Htmlfileurl);
    $parser->htmlroot($Htmlroot);
    $parser->index($Doindex);
    $parser->no_errata_section(!$Poderrors); # note the inverse
    $parser->output_string(\my $output); # written to file later
    $parser->pages(\%Pages);
    $parser->quiet($Quiet);
    $parser->verbose($Verbose);

    # XXX: implement default title generator in pod::simple::xhtml
    # copy the way the old Pod::Html did it
    $Title = html_escape($Title);

    # We need to add this ourselves because we use our own header, not
    # ::XHTML's header. We need to set $parser->backlink to linkify
    # the =head1 directives
    my $bodyid = $Backlink ? ' id="_podtop_"' : '';

    my $csslink = '';
    my $tdstyle = ' style="background-color: #cccccc; color: #000"';

    if ($Css) {
        $csslink = qq(\n<link rel="stylesheet" href="$Css" type="text/css" />);
        $csslink =~ s,\\,/,g;
        $csslink =~ s,(/.):,$1|,;
        $tdstyle= '';
    }

    # header/footer block
    my $block = $Header ? <<END_OF_BLOCK : '';
<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_"$tdstyle valign="middle">
<big><strong><span class="_podblock_">&nbsp;$Title</span></strong></big>
</td></tr>
</table>
END_OF_BLOCK

    # create own header/footer because of --header
    $parser->html_header(<<"HTMLHEAD");
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$Title</title>$csslink
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:$Config{perladmin}" />
</head>

<body$bodyid>
$block
HTMLHEAD

    $parser->html_footer(<<"HTMLFOOT");
$block
</body>

</html>
HTMLFOOT

    my $input;
    unless (@ARGV && $ARGV[0]) {
        if ($Podfile and $Podfile ne '-') {
            $input = $Podfile;
        } else {
            $input = '-'; # XXX: make a test case for this
        }
    } else {
        $Podfile = $ARGV[0];
        $input = *ARGV;
    }

    warn "Converting input file $Podfile\n" if $Verbose;
    $parser->parse_file($input);

    # Write output to file
    $Htmlfile = "-" unless $Htmlfile; # stdout
    my $fhout;
    if($Htmlfile and $Htmlfile ne '-') {
        open $fhout, ">", $Htmlfile
            or die "$0: cannot open $Htmlfile file for output: $!\n";
    } else {
        open $fhout, ">-";
    }
    binmode $fhout, ":utf8";
    print $fhout $output;
    close $fhout or die "Failed to close $Htmlfile: $!";
    chmod 0644, $Htmlfile unless $Htmlfile eq '-';
}

##############################################################################

sub usage {
    my $podfile = shift;
    warn "$0: $podfile: @_\n" if @_;
    die <<END_OF_USAGE;
Usage:  $0 --help --htmldir=<name> --htmlroot=<URL>
           --infile=<name> --outfile=<name>
           --podpath=<name>:...:<name> --podroot=<name>
           --cachedir=<name> --flush --recurse --norecurse
           --quiet --noquiet --verbose --noverbose
           --index --noindex --backlink --nobacklink
           --header --noheader --poderrors --nopoderrors
           --css=<URL> --title=<name>

  --[no]backlink  - turn =head1 directives into links pointing to the top of
                      the page (off by default).
  --cachedir      - directory for the directory cache files.
  --css           - stylesheet URL
  --flush         - flushes the directory cache.
  --[no]header    - produce block header/footer (default is no headers).
  --help          - prints this message.
  --htmldir       - directory for resulting HTML files.
  --htmlroot      - http-server base directory from which all relative paths
                      in podpath stem (default is /).
  --[no]index     - generate an index at the top of the resulting html
                      (default behaviour).
  --infile        - filename for the pod to convert (input taken from stdin
                      by default).
  --outfile       - filename for the resulting html file (output sent to
                      stdout by default).
  --[no]poderrors - include a POD ERRORS section in the output if there were 
                      any POD errors in the input (default behavior).
  --podpath       - colon-separated list of directories containing library
                      pods (empty by default).
  --podroot       - filesystem base directory from which all relative paths
                      in podpath stem (default is .).
  --[no]quiet     - suppress some benign warning messages (default is off).
  --[no]recurse   - recurse on those subdirectories listed in podpath
                      (default behaviour).
  --title         - title that will appear in resulting html file.
  --[no]verbose   - self-explanatory (off by default).

END_OF_USAGE

}

sub parse_command_line {
    my ($opt_backlink,$opt_cachedir,$opt_css,$opt_flush,$opt_header,
        $opt_help,$opt_htmldir,$opt_htmlroot,$opt_index,$opt_infile,
        $opt_outfile,$opt_poderrors,$opt_podpath,$opt_podroot,
        $opt_quiet,$opt_recurse,$opt_title,$opt_verbose,$opt_libpods);

    unshift @ARGV, split ' ', $Config{pod2html} if $Config{pod2html};
    my $result = GetOptions(
                       'backlink!'  => \$opt_backlink,
                       'cachedir=s' => \$opt_cachedir,
                       'css=s'      => \$opt_css,
                       'flush'      => \$opt_flush,
                       'help'       => \$opt_help,
                       'header!'    => \$opt_header,
                       'htmldir=s'  => \$opt_htmldir,
                       'htmlroot=s' => \$opt_htmlroot,
                       'index!'     => \$opt_index,
                       'infile=s'   => \$opt_infile,
                       'libpods=s'  => \$opt_libpods, # deprecated
                       'outfile=s'  => \$opt_outfile,
                       'poderrors!' => \$opt_poderrors,
                       'podpath=s'  => \$opt_podpath,
                       'podroot=s'  => \$opt_podroot,
                       'quiet!'     => \$opt_quiet,
                       'recurse!'   => \$opt_recurse,
                       'title=s'    => \$opt_title,
                       'verbose!'   => \$opt_verbose,
    );
    usage("-", "invalid parameters") if not $result;

    usage("-") if defined $opt_help;    # see if the user asked for help
    $opt_help = "";                     # just to make -w shut-up.

    @Podpath  = split(":", $opt_podpath) if defined $opt_podpath;
    warn "--libpods is no longer supported" if defined $opt_libpods;

    $Backlink  =          $opt_backlink   if defined $opt_backlink;
    $Cachedir  = _unixify($opt_cachedir)  if defined $opt_cachedir;
    $Css       =          $opt_css        if defined $opt_css;
    $Header    =          $opt_header     if defined $opt_header;
    $Htmldir   = _unixify($opt_htmldir)   if defined $opt_htmldir;
    $Htmlroot  = _unixify($opt_htmlroot)  if defined $opt_htmlroot;
    $Doindex   =          $opt_index      if defined $opt_index;
    $Podfile   = _unixify($opt_infile)    if defined $opt_infile;
    $Htmlfile  = _unixify($opt_outfile)   if defined $opt_outfile;
    $Poderrors =          $opt_poderrors  if defined $opt_poderrors;
    $Podroot   = _unixify($opt_podroot)   if defined $opt_podroot;
    $Quiet     =          $opt_quiet      if defined $opt_quiet;
    $Recurse   =          $opt_recurse    if defined $opt_recurse;
    $Title     =          $opt_title      if defined $opt_title;
    $Verbose   =          $opt_verbose    if defined $opt_verbose;

    warn "Flushing directory caches\n"
        if $opt_verbose && defined $opt_flush;
    $Dircache = "$Cachedir/pod2htmd.tmp";
    if (defined $opt_flush) {
        1 while unlink($Dircache);
    }
}

my $Saved_Cache_Key;

sub get_cache {
    my($dircache, $podpath, $podroot, $recurse) = @_;
    my @cache_key_args = @_;

    # A first-level cache:
    # Don't bother reading the cache files if they still apply
    # and haven't changed since we last read them.

    my $this_cache_key = cache_key(@cache_key_args);
    return 1 if $Saved_Cache_Key and $this_cache_key eq $Saved_Cache_Key;
    $Saved_Cache_Key = $this_cache_key;

    # load the cache of %Pages if possible.  $tests will be
    # non-zero if successful.
    my $tests = 0;
    if (-f $dircache) {
        warn "scanning for directory cache\n" if $Verbose;
        $tests = load_cache($dircache, $podpath, $podroot);
    }

    return $tests;
}

sub cache_key {
    my($dircache, $podpath, $podroot, $recurse) = @_;
    return join('!',$dircache,$recurse,@$podpath,$podroot,stat($dircache));
}

#
# load_cache - tries to find if the cache stored in $dircache is a valid
#  cache of %Pages.  if so, it loads them and returns a non-zero value.
#
sub load_cache {
    my($dircache, $podpath, $podroot) = @_;
    my $tests = 0;
    local $_;

    warn "scanning for directory cache\n" if $Verbose;
    open(my $cachefh, '<', $dircache) ||
        die "$0: error opening $dircache for reading: $!\n";
    $/ = "\n";

    # is it the same podpath?
    $_ = <$cachefh>;
    chomp($_);
    $tests++ if (join(":", @$podpath) eq $_);

    # is it the same podroot?
    $_ = <$cachefh>;
    chomp($_);
    $tests++ if ($podroot eq $_);

    # load the cache if its good
    if ($tests != 2) {
        close($cachefh);
        return 0;
    }

    warn "loading directory cache\n" if $Verbose;
    while (<$cachefh>) {
        /(.*?) (.*)$/;
        $Pages{$1} = $2;
    }

    close($cachefh);
    return 1;
}


#
# html_escape: make text safe for HTML
#
sub html_escape {
    my $rest = $_[0];
    $rest   =~ s/&/&amp;/g;
    $rest   =~ s/</&lt;/g;
    $rest   =~ s/>/&gt;/g;
    $rest   =~ s/"/&quot;/g;
    # &apos; is only in XHTML, not HTML4.  Be conservative
    #$rest   =~ s/'/&apos;/g;
    return $rest;
}

#
# htmlify - converts a pod section specification to a suitable section
# specification for HTML. Note that we keep spaces and special characters
# except ", ? (Netscape problem) and the hyphen (writer's problem...).
#
sub htmlify {
    my( $heading) = @_;
    $heading =~ s/(\s+)/ /g;
    $heading =~ s/\s+\Z//;
    $heading =~ s/\A\s+//;
    # The hyphen is a disgrace to the English language.
    # $heading =~ s/[-"?]//g;
    $heading =~ s/["?]//g;
    $heading = lc( $heading );
    return $heading;
}

#
# similar to htmlify, but turns non-alphanumerics into underscores
#
sub anchorify {
    my ($anchor) = @_;
    $anchor = htmlify($anchor);
    $anchor =~ s/\W/_/g;
    return $anchor;
}

#
# store POD files in %Pages
#
sub _save_page {
    my ($modspec, $modname) = @_;

    # Remove Podroot from path
    $modspec = $Podroot eq File::Spec->curdir
               ? File::Spec->abs2rel($modspec)
               : File::Spec->abs2rel($modspec,
                                     File::Spec->canonpath($Podroot));

    # Convert path to unix style path
    $modspec = Pod::Html::_unixify($modspec);

    my ($file, $dir) = fileparse($modspec, qr/\.[^.]*/); # strip .ext
    $Pages{$modname} = $dir.$file;
}

sub _unixify {
    my $full_path = shift;
    return '' unless $full_path;
    return $full_path if $full_path eq '/';

    my ($vol, $dirs, $file) = File::Spec->splitpath($full_path);
    my @dirs = $dirs eq File::Spec->curdir()
               ? (File::Spec::Unix->curdir())
               : File::Spec->splitdir($dirs);
    if (defined($vol) && $vol) {
        $vol =~ s/:$// if $^O eq 'VMS';
        $vol = uc $vol if $^O eq 'MSWin32';

        if( $dirs[0] ) {
            unshift @dirs, $vol;
        }
        else {
            $dirs[0] = $vol;
        }
    }
    unshift @dirs, '' if File::Spec->file_name_is_absolute($full_path);
    return $file unless scalar(@dirs);
    $full_path = File::Spec::Unix->catfile(File::Spec::Unix->catdir(@dirs),
                                           $file);
    $full_path =~ s|^\/|| if $^O eq 'MSWin32'; # C:/foo works, /C:/foo doesn't
    $full_path =~ s/\^\././g if $^O eq 'VMS'; # unescape dots
    return $full_path;
}

package Pod::Simple::XHTML::LocalPodLinks;
use strict;
use warnings;
use parent 'Pod::Simple::XHTML';

use File::Spec;
use File::Spec::Unix;

__PACKAGE__->_accessorize(
 'htmldir',
 'htmlfileurl',
 'htmlroot',
 'pages', # Page name => relative/path/to/page from root POD dir
 'quiet',
 'verbose',
);

sub resolve_pod_page_link {
    my ($self, $to, $section) = @_;

    return undef unless defined $to || defined $section;
    if (defined $section) {
        $section = '#' . $self->idify($section, 1);
        return $section unless defined $to;
    } else {
        $section = '';
    }

    my $path; # path to $to according to %Pages
    unless (exists $self->pages->{$to}) {
        # Try to find a POD that ends with $to and use that.
        # e.g., given L<XHTML>, if there is no $Podpath/XHTML in %Pages,
        # look for $Podpath/*/XHTML in %Pages, with * being any path,
        # as a substitute (e.g., $Podpath/Pod/Simple/XHTML)
        my @matches;
        foreach my $modname (keys %{$self->pages}) {
            push @matches, $modname if $modname =~ /::\Q$to\E\z/;
        }

        if ($#matches == -1) {
            warn "Cannot find \"$to\" in podpath: " . 
                 "cannot find suitable replacement path, cannot resolve link\n"
                 unless $self->quiet;
            return '';
        } elsif ($#matches == 0) {
            warn "Cannot find \"$to\" in podpath: " .
                 "using $matches[0] as replacement path to $to\n" 
                 unless $self->quiet;
            $path = $self->pages->{$matches[0]};
        } else {
            warn "Cannot find \"$to\" in podpath: " .
                 "more than one possible replacement path to $to, " .
                 "using $matches[-1]\n" unless $self->quiet;
            # Use [-1] so newer (higher numbered) perl PODs are used
            $path = $self->pages->{$matches[-1]};
        }
    } else {
        $path = $self->pages->{$to};
    }

    my $url = File::Spec::Unix->catfile(Pod::Html::_unixify($self->htmlroot),
                                        $path);

    if ($self->htmlfileurl ne '') {
        # then $self->htmlroot eq '' (by definition of htmlfileurl) so
        # $self->htmldir needs to be prepended to link to get the absolute path
        # that will be relativized
        $url = relativize_url(
            File::Spec::Unix->catdir(Pod::Html::_unixify($self->htmldir), $url),
            $self->htmlfileurl # already unixified
        );
    }

    return $url . ".html$section";
}

#
# relativize_url - convert an absolute URL to one relative to a base URL.
# Assumes both end in a filename.
#
sub relativize_url {
    my ($dest, $source) = @_;

    # Remove each file from its path
    my ($dest_volume, $dest_directory, $dest_file) =
        File::Spec::Unix->splitpath( $dest );
    $dest = File::Spec::Unix->catpath( $dest_volume, $dest_directory, '' );

    my ($source_volume, $source_directory, $source_file) =
        File::Spec::Unix->splitpath( $source );
    $source = File::Spec::Unix->catpath( $source_volume, $source_directory, '' );

    my $rel_path = '';
    if ($dest ne '') {
       $rel_path = File::Spec::Unix->abs2rel( $dest, $source );
    }

    if ($rel_path ne '' && substr( $rel_path, -1 ) ne '/') {
        $rel_path .= "/$dest_file";
    } else {
        $rel_path .= "$dest_file";
    }

    return $rel_path;
}

1;
