##
## English tables
##

package Date::Language::Chinese_GB;

use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION);
@ISA = qw(Date::Language);
$VERSION = "1.01";

@DoW = qw(������ ����һ ���ڶ� ������ ������ ������ ������);
@MoY = qw(һ�� ���� ���� ���� ���� ����
	  ���� ���� ���� ʮ�� ʮһ�� ʮ����);
@DoWs = map { $_ } @DoW;
@MoYs = map { $_ } @MoY;
@AMPM = qw(���� ����);

@Dsuf = (qw(�� �� �� �� �� �� �� �� �� ��)) x 3;

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

sub format_o { sprintf("%2d%s",$_[0]->[3],"��") }
1;
