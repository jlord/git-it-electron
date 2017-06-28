# Copyrights 1995-2014 by [Mark Overmeer <perl@overmeer.net>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use strict;

package Mail::Mailer::testfile;
use vars '$VERSION';
$VERSION = '2.14';

use base 'Mail::Mailer::rfc822';

use Mail::Util qw/mailaddress/;

my $num = 0;
sub can_cc() { 0 }

sub exec($$$)
{   my ($self, $exe, $args, $to) = @_;

    my $outfn = $Mail::Mailer::testfile::config{outfile} || 'mailer.testfile';
    open F, '>>', $outfn
        or die "Cannot append message to testfile $outfn: $!";

    print F "\n===\ntest ", ++$num, " ", (scalar localtime),
            "\nfrom: " . mailaddress(),
            "\nto: " . join(' ',@{$to}), "\n\n";
    close F;

    untie *$self if tied *$self;
    tie *$self, 'Mail::Mailer::testfile::pipe', $self;
    $self;
}

sub close { 1 }

package Mail::Mailer::testfile::pipe;
use vars '$VERSION';
$VERSION = '2.14';


sub TIEHANDLE
{   my ($class, $self) = @_;
    bless \$self, $class;
}

sub PRINT
{   my $self = shift;
    open F, '>>', $Mail::Mailer::testfile::config{outfile} || 'mailer.testfile';
    print F @_;
    close F;
}

1;
