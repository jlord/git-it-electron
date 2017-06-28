# Copyrights 1995-2014 by [Mark Overmeer <perl@overmeer.net>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

use strict;

package Mail::Mailer::qmail;
use vars '$VERSION';
$VERSION = '2.14';

use base 'Mail::Mailer::rfc822';

sub exec($$$$)
{   my($self, $exe, $args, $to, $sender) = @_;
    my $address = defined $sender && $sender =~ m/\<(.*?)\>/ ? $1 : $sender;

    exec($exe, (defined $address ? "-f$address" : ()));
    die "ERROR: cannot run $exe: $!";
}

1;
