#
# $Id: H2Z.pm,v 2.2 2006/06/03 20:28:48 dankogai Exp $
#

package Encode::JP::H2Z;

use strict;
use warnings;

our $RCSID = q$Id: H2Z.pm,v 2.2 2006/06/03 20:28:48 dankogai Exp $;
our $VERSION = do { my @r = ( q$Revision: 2.2 $ =~ /\d+/g ); sprintf "%d." . "%02d" x $#r, @r };

use Encode::CJKConstants qw(:all);

use vars qw(%_D2Z  $_PAT_D2Z
  %_Z2D  $_PAT_Z2D
  %_H2Z  $_PAT_H2Z
  %_Z2H  $_PAT_Z2H);

%_H2Z = (
    "\x8e\xa1" => "\xa1\xa3",    #��
    "\x8e\xa2" => "\xa1\xd6",    #��
    "\x8e\xa3" => "\xa1\xd7",    #��
    "\x8e\xa4" => "\xa1\xa2",    #��
    "\x8e\xa5" => "\xa1\xa6",    #��
    "\x8e\xa6" => "\xa5\xf2",    #��
    "\x8e\xa7" => "\xa5\xa1",    #��
    "\x8e\xa8" => "\xa5\xa3",    #��
    "\x8e\xa9" => "\xa5\xa5",    #��
    "\x8e\xaa" => "\xa5\xa7",    #��
    "\x8e\xab" => "\xa5\xa9",    #��
    "\x8e\xac" => "\xa5\xe3",    #��
    "\x8e\xad" => "\xa5\xe5",    #��
    "\x8e\xae" => "\xa5\xe7",    #��
    "\x8e\xaf" => "\xa5\xc3",    #��
    "\x8e\xb0" => "\xa1\xbc",    #��
    "\x8e\xb1" => "\xa5\xa2",    #��
    "\x8e\xb2" => "\xa5\xa4",    #��
    "\x8e\xb3" => "\xa5\xa6",    #��
    "\x8e\xb4" => "\xa5\xa8",    #��
    "\x8e\xb5" => "\xa5\xaa",    #��
    "\x8e\xb6" => "\xa5\xab",    #��
    "\x8e\xb7" => "\xa5\xad",    #��
    "\x8e\xb8" => "\xa5\xaf",    #��
    "\x8e\xb9" => "\xa5\xb1",    #��
    "\x8e\xba" => "\xa5\xb3",    #��
    "\x8e\xbb" => "\xa5\xb5",    #��
    "\x8e\xbc" => "\xa5\xb7",    #��
    "\x8e\xbd" => "\xa5\xb9",    #��
    "\x8e\xbe" => "\xa5\xbb",    #��
    "\x8e\xbf" => "\xa5\xbd",    #��
    "\x8e\xc0" => "\xa5\xbf",    #��
    "\x8e\xc1" => "\xa5\xc1",    #��
    "\x8e\xc2" => "\xa5\xc4",    #��
    "\x8e\xc3" => "\xa5\xc6",    #��
    "\x8e\xc4" => "\xa5\xc8",    #��
    "\x8e\xc5" => "\xa5\xca",    #��
    "\x8e\xc6" => "\xa5\xcb",    #��
    "\x8e\xc7" => "\xa5\xcc",    #��
    "\x8e\xc8" => "\xa5\xcd",    #��
    "\x8e\xc9" => "\xa5\xce",    #��
    "\x8e\xca" => "\xa5\xcf",    #��
    "\x8e\xcb" => "\xa5\xd2",    #��
    "\x8e\xcc" => "\xa5\xd5",    #��
    "\x8e\xcd" => "\xa5\xd8",    #��
    "\x8e\xce" => "\xa5\xdb",    #��
    "\x8e\xcf" => "\xa5\xde",    #��
    "\x8e\xd0" => "\xa5\xdf",    #��
    "\x8e\xd1" => "\xa5\xe0",    #��
    "\x8e\xd2" => "\xa5\xe1",    #��
    "\x8e\xd3" => "\xa5\xe2",    #��
    "\x8e\xd4" => "\xa5\xe4",    #��
    "\x8e\xd5" => "\xa5\xe6",    #��
    "\x8e\xd6" => "\xa5\xe8",    #��
    "\x8e\xd7" => "\xa5\xe9",    #��
    "\x8e\xd8" => "\xa5\xea",    #��
    "\x8e\xd9" => "\xa5\xeb",    #��
    "\x8e\xda" => "\xa5\xec",    #��
    "\x8e\xdb" => "\xa5\xed",    #��
    "\x8e\xdc" => "\xa5\xef",    #��
    "\x8e\xdd" => "\xa5\xf3",    #��
    "\x8e\xde" => "\xa1\xab",    #��
    "\x8e\xdf" => "\xa1\xac",    #��
);

%_D2Z = (
    "\x8e\xb6\x8e\xde" => "\xa5\xac",    #��
    "\x8e\xb7\x8e\xde" => "\xa5\xae",    #��
    "\x8e\xb8\x8e\xde" => "\xa5\xb0",    #��
    "\x8e\xb9\x8e\xde" => "\xa5\xb2",    #��
    "\x8e\xba\x8e\xde" => "\xa5\xb4",    #��
    "\x8e\xbb\x8e\xde" => "\xa5\xb6",    #��
    "\x8e\xbc\x8e\xde" => "\xa5\xb8",    #��
    "\x8e\xbd\x8e\xde" => "\xa5\xba",    #��
    "\x8e\xbe\x8e\xde" => "\xa5\xbc",    #��
    "\x8e\xbf\x8e\xde" => "\xa5\xbe",    #��
    "\x8e\xc0\x8e\xde" => "\xa5\xc0",    #��
    "\x8e\xc1\x8e\xde" => "\xa5\xc2",    #��
    "\x8e\xc2\x8e\xde" => "\xa5\xc5",    #��
    "\x8e\xc3\x8e\xde" => "\xa5\xc7",    #��
    "\x8e\xc4\x8e\xde" => "\xa5\xc9",    #��
    "\x8e\xca\x8e\xde" => "\xa5\xd0",    #��
    "\x8e\xcb\x8e\xde" => "\xa5\xd3",    #��
    "\x8e\xcc\x8e\xde" => "\xa5\xd6",    #��
    "\x8e\xcd\x8e\xde" => "\xa5\xd9",    #��
    "\x8e\xce\x8e\xde" => "\xa5\xdc",    #��
    "\x8e\xca\x8e\xdf" => "\xa5\xd1",    #��
    "\x8e\xcb\x8e\xdf" => "\xa5\xd4",    #��
    "\x8e\xcc\x8e\xdf" => "\xa5\xd7",    #��
    "\x8e\xcd\x8e\xdf" => "\xa5\xda",    #��
    "\x8e\xce\x8e\xdf" => "\xa5\xdd",    #��
    "\x8e\xb3\x8e\xde" => "\xa5\xf4",    #��
);

# init only once;

#$_PAT_D2Z = join("|", keys %_D2Z);
#$_PAT_H2Z = join("|", keys %_H2Z);

%_Z2H = reverse %_H2Z;
%_Z2D = reverse %_D2Z;

#$_PAT_Z2H    = join("|", keys %_Z2H);
#$_PAT_Z2D    = join("|", keys %_Z2D);

sub h2z {
    no warnings qw(uninitialized);
    my $r_str          = shift;
    my ($keep_dakuten) = @_;
    my $n              = 0;
    unless ($keep_dakuten) {
        $n = (
            $$r_str =~ s(
               ($RE{EUC_KANA}
                (?:\x8e[\xde\xdf])?)
               ){
          my $str = $1;
          $_D2Z{$str} || $_H2Z{$str} || 
              # in case dakuten and handakuten are side-by-side!
              $_H2Z{substr($str,0,2)} . $_H2Z{substr($str,2,2)};
          }eogx
        );
    }
    else {
        $n = (
            $$r_str =~ s(
               ($RE{EUC_KANA})
               ){
          $_H2Z{$1};
          }eogx
        );
    }
    $n;
}

sub z2h {
    my $r_str = shift;
    my $n     = (
        $$r_str =~ s(
              ($RE{EUC_C}|$RE{EUC_0212}|$RE{EUC_KANA})
              ){
         $_Z2D{$1} || $_Z2H{$1} || $1;
         }eogx
    );
    $n;
}

1;
__END__


=head1 NAME

Encode::JP::H2Z -- internally used by Encode::JP::2022_JP*

=cut
