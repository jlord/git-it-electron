##
## Czech tables
##
## Contributed by Honza Pazdziora 

package Date::Language::Czech;

use vars qw(@ISA @DoW @DoWs @MoY @MoYs @MoY2 @AMPM %MoY %DoW $VERSION);
@ISA = qw(Date::Language Date::Format::Generic);
$VERSION = "1.01";

@MoY = qw(leden �nor b�ezen duben kv�ten �erven �ervenec srpen z���
	      ��jen listopad prosinec);
@MoYs = qw(led �nor b�e dub kv� �vn �ec srp z��� ��j lis pro);
@MoY2 = @MoY;
for (@MoY2)
      { s!en$!na! or s!ec$!ce! or s!ad$!adu! or s!or$!ora!; }

@DoW = qw(ned�le pond�l� �ter� st�eda �tvrtek p�tek sobota);
@DoWs = qw(Ne Po �t St �t P� So);

@AMPM = qw(dop. odp.);

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

sub time2str {
      my $ref = shift;
      my @a = @_;
      $a[0] =~ s/(%[do]\.?\s?)%B/$1%Q/;
      $ref->SUPER::time2str(@a);
      }

sub strftime {
      my $ref = shift;
      my @a = @_;
      $a[0] =~ s/(%[do]\.?\s?)%B/$1%Q/;
      $ref->SUPER::time2str(@a);
      }

1;
