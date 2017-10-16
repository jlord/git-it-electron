##
## Russian tables
##
## Contributed by Danil Pismenny <dapi@mail.ru>

package Date::Language::Russian;

use vars qw(@ISA @DoW @DoWs @MoY @MoYs @MoY2 @AMPM %MoY %DoW $VERSION);
@ISA = qw(Date::Language Date::Format::Generic);
$VERSION = "1.01";

@MoY = qw(������ ������� ����� ������ ��� ���� ���� ������� �������� ������� ������ �������);
@MoY2 = qw(������ ������� ���� ������ ��� ���� ���� ������ �������� ������� ������ �������);
@MoYs = qw(��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ��� ���);

@DoW = qw(����������� ������� ����� ������� ������� ������� �����������);
@DoWs = qw(�� �� �� �� �� �� ��);
@DoWs2 = qw(��� ��� ��� ��� ��� ��� ���);

@AMPM = qw(�� ��);

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

sub format_d { $_[0]->[3] }
sub format_m { $_[0]->[4] + 1 }
sub format_o { $_[0]->[3] . '.' }

sub format_Q { $MoY2[$_[0]->[4]] }

sub str2time {
  my ($self,$value) = @_;
  map {$value=~s/(\s|^)$DoWs2[$_](\s)/$DoWs[$_]$2/ig} (0..6);
  $value=~s/(\s+|^)���(\s+)/$1���$2/;
  return $self->SUPER::str2time($value);
}

1;
