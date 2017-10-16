package Text::Wrap;

use warnings::register;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(wrap fill);
@EXPORT_OK = qw($columns $break $huge);

$VERSION = 2013.0523;
$SUBVERSION = 'modern';

use 5.010_000;

use vars qw($VERSION $SUBVERSION $columns $debug $break $huge $unexpand $tabstop $separator $separator2);
use strict;

BEGIN	{
	$columns = 76;  # <= screen width
	$debug = 0;
	$break = '(?=\s)\X';
	$huge = 'wrap'; # alternatively: 'die' or 'overflow'
	$unexpand = 1;
	$tabstop = 8;
	$separator = "\n";
	$separator2 = undef;
}

my $CHUNK = qr/\X/;

sub _xlen(_) { scalar(() = $_[0] =~ /$CHUNK/g) }

sub _xpos(_) { _xlen( substr( $_[0], 0, pos($_[0]) ) ) }

use Text::Tabs qw(expand unexpand);

sub wrap
{
	my ($ip, $xp, @t) = @_;

	local($Text::Tabs::tabstop) = $tabstop;
	my $r = "";
	my $tail = pop(@t);
	my $t = expand(join("", (map { /\s+\z/ ? ( $_ ) : ($_, ' ') } @t), $tail));
	my $lead = $ip;
	my $nll = $columns - _xlen(expand($xp)) - 1;
	if ($nll <= 0 && $xp ne '') {
		my $nc = _xlen(expand($xp)) + 2;
		warnings::warnif "Increasing \$Text::Wrap::columns from $columns to $nc to accommodate length of subsequent tab";
		$columns = $nc;
		$nll = 1;
	}
	my $ll = $columns - _xlen(expand($ip)) - 1;
	$ll = 0 if $ll < 0;
	my $nl = "";
	my $remainder = "";

	use re 'taint';

	pos($t) = 0;
	while ($t !~ /\G(?:$break)*\Z/gc) {
		if ($t =~ /\G((?:(?=[^\n])\X){0,$ll})($break|\n+|\z)/xmgc) {
			$r .= $unexpand 
				? unexpand($nl . $lead . $1)
				: $nl . $lead . $1;
			$remainder = $2;
		} elsif ($huge eq 'wrap' && $t =~ /\G((?:(?=[^\n])\X){$ll})/gc) {
			$r .= $unexpand 
				? unexpand($nl . $lead . $1)
				: $nl . $lead . $1;
			$remainder = defined($separator2) ? $separator2 : $separator;
		} elsif ($huge eq 'overflow' && $t =~ /\G((?:(?=[^\n])\X)*?)($break|\n+|\z)/xmgc) {
			$r .= $unexpand 
				? unexpand($nl . $lead . $1)
				: $nl . $lead . $1;
			$remainder = $2;
		} elsif ($huge eq 'die') {
			die "couldn't wrap '$t'";
		} elsif ($columns < 2) {
			warnings::warnif "Increasing \$Text::Wrap::columns from $columns to 2";
			$columns = 2;
			return ($ip, $xp, @t);
		} else {
			die "This shouldn't happen";
		}
			
		$lead = $xp;
		$ll = $nll;
		$nl = defined($separator2)
			? ($remainder eq "\n"
				? "\n"
				: $separator2)
			: $separator;
	}
	$r .= $remainder;

	print "-----------$r---------\n" if $debug;

	print "Finish up with '$lead'\n" if $debug;

	my($opos) = pos($t);

	$r .= $lead . substr($t, pos($t), length($t) - pos($t))
		if pos($t) ne length($t);

	print "-----------$r---------\n" if $debug;;

	return $r;
}

sub fill 
{
	my ($ip, $xp, @raw) = @_;
	my @para;
	my $pp;

	for $pp (split(/\n\s+/, join("\n",@raw))) {
		$pp =~ s/\s+/ /g;
		my $x = wrap($ip, $xp, $pp);
		push(@para, $x);
	}

	# if paragraph_indent is the same as line_indent, 
	# separate paragraphs with blank lines

	my $ps = ($ip eq $xp) ? "\n\n" : "\n";
	return join ($ps, @para);
}

1;
__END__

=head1 NAME

Text::Wrap - line wrapping to form simple paragraphs

=head1 SYNOPSIS 

B<Example 1>

	use Text::Wrap;

	$initial_tab = "\t";	# Tab before first line
	$subsequent_tab = "";	# All other lines flush left

	print wrap($initial_tab, $subsequent_tab, @text);
	print fill($initial_tab, $subsequent_tab, @text);

	$lines = wrap($initial_tab, $subsequent_tab, @text);

	@paragraphs = fill($initial_tab, $subsequent_tab, @text);

B<Example 2>

	use Text::Wrap qw(wrap $columns $huge);

	$columns = 132;		# Wrap at 132 characters
	$huge = 'die';
	$huge = 'wrap';
	$huge = 'overflow';

B<Example 3>

	use Text::Wrap;

	$Text::Wrap::columns = 72;
	print wrap('', '', @text);

=head1 DESCRIPTION

C<Text::Wrap::wrap()> is a very simple paragraph formatter.  It formats a
single paragraph at a time by breaking lines at word boundaries.
Indentation is controlled for the first line (C<$initial_tab>) and
all subsequent lines (C<$subsequent_tab>) independently.  Please note: 
C<$initial_tab> and C<$subsequent_tab> are the literal strings that will
be used: it is unlikely you would want to pass in a number.

C<Text::Wrap::fill()> is a simple multi-paragraph formatter.  It formats
each paragraph separately and then joins them together when it's done.  It
will destroy any whitespace in the original text.  It breaks text into
paragraphs by looking for whitespace after a newline.  In other respects,
it acts like wrap().

C<wrap()> compresses trailing whitespace into one newline, and C<fill()>
deletes all trailing whitespace.

Both C<wrap()> and C<fill()> return a single string.

Unlike the old Unix fmt(1) utility, this module correctly accounts for
any Unicode combining characters (such as diacriticals) that may occur
in each line for both expansion and unexpansion.  These are overstrike
characters that do not increment the logical position.  Make sure
you have the appropriate Unicode settings enabled.

=head1 OVERRIDES

C<Text::Wrap::wrap()> has a number of variables that control its behavior.
Because other modules might be using C<Text::Wrap::wrap()> it is suggested
that you leave these variables alone!  If you can't do that, then 
use C<local($Text::Wrap::VARIABLE) = YOURVALUE> when you change the
values so that the original value is restored.  This C<local()> trick
will not work if you import the variable into your own namespace.

Lines are wrapped at C<$Text::Wrap::columns> columns (default value: 76).
C<$Text::Wrap::columns> should be set to the full width of your output
device.  In fact, every resulting line will have length of no more than
C<$columns - 1>.

It is possible to control which characters terminate words by
modifying C<$Text::Wrap::break>. Set this to a string such as
C<'[\s:]'> (to break before spaces or colons) or a pre-compiled regexp
such as C<qr/[\s']/> (to break before spaces or apostrophes). The
default is simply C<'\s'>; that is, words are terminated by spaces.
(This means, among other things, that trailing punctuation  such as
full stops or commas stay with the word they are "attached" to.)
Setting C<$Text::Wrap::break> to a regular expression that doesn't
eat any characters (perhaps just a forward look-ahead assertion) will
cause warnings.

Beginner note: In example 2, above C<$columns> is imported into
the local namespace, and set locally.  In example 3,
C<$Text::Wrap::columns> is set in its own namespace without importing it.

C<Text::Wrap::wrap()> starts its work by expanding all the tabs in its
input into spaces.  The last thing it does it to turn spaces back
into tabs.  If you do not want tabs in your results, set 
C<$Text::Wrap::unexpand> to a false value.  Likewise if you do not
want to use 8-character tabstops, set C<$Text::Wrap::tabstop> to
the number of characters you do want for your tabstops.

If you want to separate your lines with something other than C<\n>
then set C<$Text::Wrap::separator> to your preference.  This replaces
all newlines with C<$Text::Wrap::separator>.  If you just want to 
preserve existing newlines but add new breaks with something else, set
C<$Text::Wrap::separator2> instead.

When words that are longer than C<$columns> are encountered, they
are broken up.  C<wrap()> adds a C<"\n"> at column C<$columns>.
This behavior can be overridden by setting C<$huge> to
'die' or to 'overflow'.  When set to 'die', large words will cause
C<die()> to be called.  When set to 'overflow', large words will be
left intact.  

Historical notes: 'die' used to be the default value of
C<$huge>.  Now, 'wrap' is the default value.

=head1 EXAMPLES

Code:

  print wrap("\t","",<<END);
  This is a bit of text that forms 
  a normal book-style indented paragraph
  END

Result:

  "	This is a bit of text that forms
  a normal book-style indented paragraph   
  "

Code:

  $Text::Wrap::columns=20;
  $Text::Wrap::separator="|";
  print wrap("","","This is a bit of text that forms a normal book-style paragraph");

Result:

  "This is a bit of|text that forms a|normal book-style|paragraph"

=head1 SUBVERSION

This module comes in two flavors: one for modern perls (5.10 and above)
and one for ancient obsolete perls.  The version for modern perls has
support for Unicode.  The version for old perls does not.  You can tell
which version you have installed by looking at C<$Text::Wrap::SUBVERSION>:
it is C<old> for obsolete perls and C<modern> for current perls.

This man page is for the version for modern perls and so that's probably
what you've got.

=head1 SEE ALSO

For correct handling of East Asian half- and full-width characters, 
see L<Text::WrapI18N>.  For more detailed controls: L<Text::Format>.

=head1 AUTHOR

David Muir Sharnoff <cpan@dave.sharnoff.org> with help from Tim Pierce and
many many others.  

=head1 LICENSE

Copyright (C) 1996-2009 David Muir Sharnoff.  
Copyright (C) 2012-2013 Google, Inc.
This module may be modified, used, copied, and redistributed at your own risk.
Although allowed by the preceding license, please do not publicly
redistribute modified versions of this code with the name "Text::Wrap"
unless it passes the unmodified Text::Wrap test suite.
