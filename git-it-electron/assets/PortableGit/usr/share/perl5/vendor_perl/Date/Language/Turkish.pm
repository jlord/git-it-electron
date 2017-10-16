#----------------------------------------------------#
#
# Turkish tables
# Burak G�rsoy <burak@cpan.org>
# Last modified: Sat Nov 15 20:28:32 2003
#
# use Date::Language;
# my $turkish = Date::Language->new('Turkish');
# print $turkish->time2str("%e %b %Y, %a %T\n", time);
# print $turkish->str2time("25 Haz 1996 21:09:55 +0100");
#----------------------------------------------------#

package Date::Language::Turkish;
use Date::Language ();
use vars qw(@ISA @DoW @DoWs @MoY @MoYs @AMPM @Dsuf %MoY %DoW $VERSION %DsufMAP);
@ISA     = qw(Date::Language);
$VERSION = "1.0";

@DoW = qw(Pazar Pazartesi Sal� �ar�amba Per�embe Cuma Cumartesi);
@MoY = qw(Ocak �ubat Mart  Nisan May�s Haziran Temmuz A�ustos Eyl�l Ekim Kas�m Aral�k);
@DoWs     = map { substr($_,0,3) } @DoW;
$DoWs[1]  = 'Pzt'; # Since we'll get two 'Paz' s
$DoWs[-1] = 'Cmt'; # Since we'll get two 'Cum' s
@MoYs     = map { substr($_,0,3) } @MoY;
@AMPM     = ('',''); # no am-pm thingy

# not easy as in english... maybe we can just use a dot "." ? :)
%DsufMAP = (
(map {$_ => 'inci', $_+10 => 'inci', $_+20 => 'inci' } 1,2,5,8 ),
(map {$_ =>  'nci', $_+10 =>  'nci', $_+20 =>  'nci' } 7       ),
(map {$_ =>  'nci', $_+10 =>  'nci', $_+20 =>  'nci' } 2       ),
(map {$_ => '�nc�', $_+10 => '�nc�', $_+20 => '�nc�' } 3,4     ),
(map {$_ => 'uncu', $_+10 => 'uncu', $_+20 => 'uncu' } 9       ),
(map {$_ =>  'nc�', $_+10 =>  'nc�', $_+20 =>  'nc�' } 6       ),
(map {$_ => 'uncu',                                  } 10,30   ),
      20 =>  'nci',
      31 => 'inci',
);

@Dsuf       = map{ $DsufMAP{$_} } sort {$a <=> $b} keys %DsufMAP;
@MoY{@MoY}  = (0 .. scalar(@MoY));
@MoY{@MoYs} = (0 .. scalar(@MoYs));
@DoW{@DoW}  = (0 .. scalar(@DoW));
@DoW{@DoWs} = (0 .. scalar(@DoWs));

# Formatting routines

sub format_a { $DoWs[$_[0]->[6]] }
sub format_A { $DoW[ $_[0]->[6]] }
sub format_b { $MoYs[$_[0]->[4]] }
sub format_B { $MoY[ $_[0]->[4]] }
sub format_h { $MoYs[$_[0]->[4]] }
sub format_p { '' } # disable
sub format_P { '' } # disable
sub format_o { sprintf("%2d%s",$_[0]->[3],$Dsuf[$_[0]->[3]-1]) }

1;

__END__
