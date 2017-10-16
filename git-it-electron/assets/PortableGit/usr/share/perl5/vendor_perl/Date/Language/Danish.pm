##
## Danish tables
##

package Date::Language::Danish;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.01";

@MoY  = qw(Januar Februar Marts April Maj Juni
	   Juli August September Oktober November December);
@MoYs = qw(Jan Feb Mar Apr Maj Jun Jul Aug Sep Okt Nov Dec);
@DoW  = qw(S�ndag Mandag Tirsdag Onsdag Torsdag Fredag L�rdag S�ndag);
@DoWs = qw(S�n Man Tir Ons Tor Fre L�r S�n);

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
