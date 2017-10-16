##
## Icelandic tables
##

package Date::Language::Icelandic;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.01";

@MoY  = qw(Jan�ar Febr�ar Mars Apr�l Ma� J�ni
	   J�li �g�st September Okt�ber N�vember Desember);
@MoYs = qw(Jan Feb Mar Apr Ma� J�n J�l �g� Sep Okt N�v Des);
@DoW  = qw(Sunnudagur M�nudagur �ri�judagur Mi�vikudagur Fimmtudagur F�studagur Laugardagur Sunnudagur);
@DoWs = qw(Sun M�n �ri Mi� Fim F�s Lau Sun);

use Date::Language::English ();
@AMPM =   @{Date::Language::English::AMPM};
@Dsuf =   @{Date::Language::English::Dsuf};

@MoY{@MoY}  = (0 .. scalar(@MoY));
@MoY{@MoYs} = (0 .. scalar(@MoYs));
@DoW{@DoW}  = (0 .. scalar(@DoW));
@DoW{@DoWs} = (0 .. scalar(@DoWs));

# Formatting routines

sub format_a { $DoWs[$_[0]->[6]] }
sub format_A { $DoW[$_[0]->[6]] }
sub format_b { $MoYs[$_[0]->[4]] }
sub format_B { $MoY[$_[0]->[4]] }
sub format_h { $MoYs[$_[0]->[4]] }
sub format_p { $_[0]->[2] >= 12 ?  $AMPM[1] : $AMPM[0] }

1;
