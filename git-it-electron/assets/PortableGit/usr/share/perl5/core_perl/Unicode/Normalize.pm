package Unicode::Normalize;

BEGIN {
    unless ('A' eq pack('U', 0x41)) {
	die "Unicode::Normalize cannot stringify a Unicode code point\n";
    }
    unless (0x41 == unpack('U', 'A')) {
	die "Unicode::Normalize cannot get Unicode code point\n";
    }
}

use 5.006;
use strict;
use warnings;
use Carp;

no warnings 'utf8';

our $VERSION = '1.18';
our $PACKAGE = __PACKAGE__;

our @EXPORT = qw( NFC NFD NFKC NFKD );
our @EXPORT_OK = qw(
    normalize decompose reorder compose
    checkNFD checkNFKD checkNFC checkNFKC check
    getCanon getCompat getComposite getCombinClass
    isExclusion isSingleton isNonStDecomp isComp2nd isComp_Ex
    isNFD_NO isNFC_NO isNFC_MAYBE isNFKD_NO isNFKC_NO isNFKC_MAYBE
    FCD checkFCD FCC checkFCC composeContiguous splitOnLastStarter
    normalize_partial NFC_partial NFD_partial NFKC_partial NFKD_partial
);
our %EXPORT_TAGS = (
    all       => [ @EXPORT, @EXPORT_OK ],
    normalize => [ @EXPORT, qw/normalize decompose reorder compose/ ],
    check     => [ qw/checkNFD checkNFKD checkNFC checkNFKC check/ ],
    fast      => [ qw/FCD checkFCD FCC checkFCC composeContiguous/ ],
);

##
## utilities for tests
##

sub pack_U {
    return pack('U*', @_);
}

sub unpack_U {
    return unpack('U*', shift(@_).pack('U*'));
}

require Exporter;

our @ISA = qw(Exporter);
use File::Spec;

our %Combin;	# $codepoint => $number    : combination class
our %Canon;	# $codepoint => \@codepoints : canonical decomp.
our %Compat;	# $codepoint => \@codepoints : compat. decomp.
our %Compos;	# $1st,$2nd  => $codepoint : composite
our %Exclus;	# $codepoint => 1          : composition exclusions
our %Single;	# $codepoint => 1          : singletons
our %NonStD;	# $codepoint => 1          : non-starter decompositions
our %Comp2nd;	# $codepoint => 1          : may be composed with a prev char.

# from core Unicode database
our $Combin = do "unicore/CombiningClass.pl"
    || do "unicode/CombiningClass.pl"
    || croak "$PACKAGE: CombiningClass.pl not found";
our $Decomp = do "unicore/Decomposition.pl"
    || do "unicode/Decomposition.pl"
    || croak "$PACKAGE: Decomposition.pl not found";

# CompositionExclusions.txt since Unicode 3.2.0
our @CompEx = qw(
    0958 0959 095A 095B 095C 095D 095E 095F 09DC 09DD 09DF 0A33 0A36
    0A59 0A5A 0A5B 0A5E 0B5C 0B5D 0F43 0F4D 0F52 0F57 0F5C 0F69 0F76
    0F78 0F93 0F9D 0FA2 0FA7 0FAC 0FB9 FB1D FB1F FB2A FB2B FB2C FB2D
    FB2E FB2F FB30 FB31 FB32 FB33 FB34 FB35 FB36 FB38 FB39 FB3A FB3B
    FB3C FB3E FB40 FB41 FB43 FB44 FB46 FB47 FB48 FB49 FB4A FB4B FB4C
    FB4D FB4E 2ADC 1D15E 1D15F 1D160 1D161 1D162 1D163 1D164 1D1BB
    1D1BC 1D1BD 1D1BE 1D1BF 1D1C0
);

# definition of Hangul constants
use constant SBase  => 0xAC00;
use constant SFinal => 0xD7A3; # SBase -1 + SCount
use constant SCount =>  11172; # LCount * NCount
use constant NCount =>    588; # VCount * TCount
use constant LBase  => 0x1100;
use constant LFinal => 0x1112;
use constant LCount =>     19;
use constant VBase  => 0x1161;
use constant VFinal => 0x1175;
use constant VCount =>     21;
use constant TBase  => 0x11A7;
use constant TFinal => 0x11C2;
use constant TCount =>     28;

sub decomposeHangul {
    my $sindex = $_[0] - SBase;
    my $lindex = int( $sindex / NCount);
    my $vindex = int(($sindex % NCount) / TCount);
    my $tindex =      $sindex % TCount;
    my @ret = (
       LBase + $lindex,
       VBase + $vindex,
      $tindex ? (TBase + $tindex) : (),
    );
    return wantarray ? @ret : pack_U(@ret);
}

########## getting full decomposition ##########

## converts string "hhhh hhhh hhhh" to a numeric list
## (hex digits separated by spaces)
sub _getHexArray { map hex, $_[0] =~ /\G *([0-9A-Fa-f]+)/g }

while ($Combin =~ /(.+)/g) {
    my @tab = split /\t/, $1;
    my $ini = hex $tab[0];
    if ($tab[1] eq '') {
	$Combin{$ini} = $tab[2];
    } else {
	$Combin{$_} = $tab[2] foreach $ini .. hex($tab[1]);
    }
}

while ($Decomp =~ /(.+)/g) {
    my @tab = split /\t/, $1;
    my $compat = $tab[2] =~ s/<[^>]+>//;
    my $dec = [ _getHexArray($tab[2]) ]; # decomposition
    my $ini = hex($tab[0]); # initial decomposable character
    my $end = $tab[1] eq '' ? $ini : hex($tab[1]);
    # ($ini .. $end) is the range of decomposable characters.

    foreach my $u ($ini .. $end) {
	$Compat{$u} = $dec;
	$Canon{$u} = $dec if ! $compat;
    }
}

for my $s (@CompEx) {
    my $u = hex $s;
    next if !$Canon{$u}; # not assigned
    next if $u == 0xFB1D && !$Canon{0x1D15E}; # 3.0.1 before Corrigendum #2
    $Exclus{$u} = 1;
}

foreach my $u (keys %Canon) {
    my $dec = $Canon{$u};

    if (@$dec == 2) {
	if ($Combin{ $dec->[0] }) {
	    $NonStD{$u} = 1;
	} else {
	    $Compos{ $dec->[0] }{ $dec->[1] } = $u;
	    $Comp2nd{ $dec->[1] } = 1 if ! $Exclus{$u};
	}
    } elsif (@$dec == 1) {
	$Single{$u} = 1;
    } else {
	my $h = sprintf '%04X', $u;
	croak("Weird Canonical Decomposition of U+$h");
    }
}

# modern HANGUL JUNGSEONG and HANGUL JONGSEONG jamo
foreach my $j (0x1161..0x1175, 0x11A8..0x11C2) {
    $Comp2nd{$j} = 1;
}

sub getCanonList {
    my @src = @_;
    my @dec = map {
	(SBase <= $_ && $_ <= SFinal) ? decomposeHangul($_)
	    : $Canon{$_} ? @{ $Canon{$_} } : $_
		} @src;
    return join(" ",@src) eq join(" ",@dec) ? @dec : getCanonList(@dec);
    # condition @src == @dec is not ok.
}

sub getCompatList {
    my @src = @_;
    my @dec = map {
	(SBase <= $_ && $_ <= SFinal) ? decomposeHangul($_)
	    : $Compat{$_} ? @{ $Compat{$_} } : $_
		} @src;
    return join(" ",@src) eq join(" ",@dec) ? @dec : getCompatList(@dec);
    # condition @src == @dec is not ok.
}

# exhaustive decomposition
foreach my $key (keys %Canon) {
    $Canon{$key}  = [ getCanonList($key) ];
}

# exhaustive decomposition
foreach my $key (keys %Compat) {
    $Compat{$key} = [ getCompatList($key) ];
}

sub getHangulComposite ($$) {
    if ((LBase <= $_[0] && $_[0] <= LFinal)
     && (VBase <= $_[1] && $_[1] <= VFinal)) {
	my $lindex = $_[0] - LBase;
	my $vindex = $_[1] - VBase;
	return (SBase + ($lindex * VCount + $vindex) * TCount);
    }
    if ((SBase <= $_[0] && $_[0] <= SFinal && (($_[0] - SBase ) % TCount) == 0)
     && (TBase  < $_[1] && $_[1] <= TFinal)) {
	return($_[0] + $_[1] - TBase);
    }
    return undef;
}

##########

sub getCombinClass ($) {
    my $uv = 0 + shift;
    return $Combin{$uv} || 0;
}

sub getCanon ($) {
    my $uv = 0 + shift;
    return exists $Canon{$uv}
	? pack_U(@{ $Canon{$uv} })
	: (SBase <= $uv && $uv <= SFinal)
	    ? scalar decomposeHangul($uv)
	    : undef;
}

sub getCompat ($) {
    my $uv = 0 + shift;
    return exists $Compat{$uv}
	? pack_U(@{ $Compat{$uv} })
	: (SBase <= $uv && $uv <= SFinal)
	    ? scalar decomposeHangul($uv)
	    : undef;
}

sub getComposite ($$) {
    my $uv1 = 0 + shift;
    my $uv2 = 0 + shift;
    my $hangul = getHangulComposite($uv1, $uv2);
    return $hangul if $hangul;
    return $Compos{ $uv1 } && $Compos{ $uv1 }{ $uv2 };
}

sub isExclusion  ($) {
    my $uv = 0 + shift;
    return exists $Exclus{$uv};
}

sub isSingleton  ($) {
    my $uv = 0 + shift;
    return exists $Single{$uv};
}

sub isNonStDecomp($) {
    my $uv = 0 + shift;
    return exists $NonStD{$uv};
}

sub isComp2nd ($) {
    my $uv = 0 + shift;
    return exists $Comp2nd{$uv};
}

sub isNFC_MAYBE ($) {
    my $uv = 0 + shift;
    return exists $Comp2nd{$uv};
}

sub isNFKC_MAYBE($) {
    my $uv = 0 + shift;
    return exists $Comp2nd{$uv};
}

sub isNFD_NO ($) {
    my $uv = 0 + shift;
    return exists $Canon {$uv} || (SBase <= $uv && $uv <= SFinal);
}

sub isNFKD_NO ($) {
    my $uv = 0 + shift;
    return exists $Compat{$uv} || (SBase <= $uv && $uv <= SFinal);
}

sub isComp_Ex ($) {
    my $uv = 0 + shift;
    return exists $Exclus{$uv} || exists $Single{$uv} || exists $NonStD{$uv};
}

sub isNFC_NO ($) {
    my $uv = 0 + shift;
    return exists $Exclus{$uv} || exists $Single{$uv} || exists $NonStD{$uv};
}

sub isNFKC_NO ($) {
    my $uv = 0 + shift;
    return 1  if $Exclus{$uv} || $Single{$uv} || $NonStD{$uv};
    return '' if (SBase <= $uv && $uv <= SFinal) || !exists $Compat{$uv};
    return 1  if ! exists $Canon{$uv};
    return pack('N*', @{ $Canon{$uv} }) ne pack('N*', @{ $Compat{$uv} });
}

##
## string decompose(string, compat?)
##
sub decompose ($;$)
{
    my $hash = $_[1] ? \%Compat : \%Canon;
    return pack_U map {
	$hash->{ $_ } ? @{ $hash->{ $_ } } :
	    (SBase <= $_ && $_ <= SFinal) ? decomposeHangul($_) : $_
    } unpack_U($_[0]);
}

##
## string reorder(string)
##
sub reorder ($)
{
    my @src = unpack_U($_[0]);

    for (my $i=0; $i < @src;) {
	$i++, next if ! $Combin{ $src[$i] };

	my $ini = $i;
	$i++ while $i < @src && $Combin{ $src[$i] };

        my @tmp = sort {
		$Combin{ $src[$a] } <=> $Combin{ $src[$b] } || $a <=> $b
	    } $ini .. $i - 1;

	@src[ $ini .. $i - 1 ] = @src[ @tmp ];
    }
    return pack_U(@src);
}


##
## string compose(string)
##
## S : starter; NS : not starter;
##
## composable sequence begins at S.
## S + S or (S + S) + S may be composed.
## NS + NS must not be composed.
##
sub compose ($)
{
    my @src = unpack_U($_[0]);

    for (my $s = 0; $s+1 < @src; $s++) {
	next unless defined $src[$s] && ! $Combin{ $src[$s] };
	 # S only; removed or combining are skipped as a starter.

	my($c, $blocked, $uncomposed_cc);
	for (my $j = $s+1; $j < @src && !$blocked; $j++) {
	    ($Combin{ $src[$j] } ? $uncomposed_cc : $blocked) = 1;

	    # S + C + S => S-S + C would be blocked.
	    next if $blocked && $uncomposed_cc;

	    # blocked by same CC (and higher CC: revised D2)
	    next if defined $src[$j-1]   && $Combin{ $src[$j-1] }
		&& $Combin{ $src[$j-1] } >= $Combin{ $src[$j] };

	    $c = getComposite($src[$s], $src[$j]);

	    # no composite or is exclusion
	    next if !$c || $Exclus{$c};

	    # replace by composite
	    $src[$s] = $c; $src[$j] = undef;
	    if ($blocked) { $blocked = 0 } else { -- $uncomposed_cc }
	}
    }
    return pack_U(grep defined, @src);
}


##
## string composeContiguous(string)
##
sub composeContiguous ($)
{
    my @src = unpack_U($_[0]);

    for (my $s = 0; $s+1 < @src; $s++) {
	next unless defined $src[$s] && ! $Combin{ $src[$s] };
	 # S only; removed or combining are skipped as a starter.

	for (my $j = $s+1; $j < @src; $j++) {
	    my $c = getComposite($src[$s], $src[$j]);

	    # no composite or is exclusion
	    last if !$c || $Exclus{$c};

	    # replace by composite
	    $src[$s] = $c; $src[$j] = undef;
	}
    }
    return pack_U(grep defined, @src);
}


##
## normalization forms
##

use constant COMPAT => 1;

sub NFD  ($) { reorder(decompose($_[0])) }
sub NFKD ($) { reorder(decompose($_[0], COMPAT)) }
sub NFC  ($) { compose(reorder(decompose($_[0]))) }
sub NFKC ($) { compose(reorder(decompose($_[0], COMPAT))) }
sub FCC  ($) { composeContiguous(reorder(decompose($_[0]))) }

##
## quick check
##

sub checkNFD ($)
{
    my $preCC = 0;
    my $curCC;
    for my $uv (unpack_U($_[0])) {
	$curCC = $Combin{ $uv } || 0;
	return '' if $preCC > $curCC && $curCC != 0;
	return '' if exists $Canon{$uv} || (SBase <= $uv && $uv <= SFinal);
	$preCC = $curCC;
    }
    return 1;
}

sub checkNFKD ($)
{
    my $preCC = 0;
    my $curCC;
    for my $uv (unpack_U($_[0])) {
	$curCC = $Combin{ $uv } || 0;
	return '' if $preCC > $curCC && $curCC != 0;
	return '' if exists $Compat{$uv} || (SBase <= $uv && $uv <= SFinal);
	$preCC = $curCC;
    }
    return 1;
}

sub checkNFC ($)
{
    my $preCC = 0;
    my($curCC, $isMAYBE);
    for my $uv (unpack_U($_[0])) {
	$curCC = $Combin{ $uv } || 0;
	return '' if $preCC > $curCC && $curCC != 0;

	if (isNFC_MAYBE($uv)) {
	    $isMAYBE = 1;
	} elsif (isNFC_NO($uv)) {
	    return '';
	}
	$preCC = $curCC;
    }
    return $isMAYBE ? undef : 1;
}

sub checkNFKC ($)
{
    my $preCC = 0;
    my($curCC, $isMAYBE);
    for my $uv (unpack_U($_[0])) {
	$curCC = $Combin{ $uv } || 0;
	return '' if $preCC > $curCC && $curCC != 0;

	if (isNFKC_MAYBE($uv)) {
	    $isMAYBE = 1;
	} elsif (isNFKC_NO($uv)) {
	    return '';
	}
	$preCC = $curCC;
    }
    return $isMAYBE ? undef : 1;
}

sub checkFCD ($)
{
    my $preCC = 0;
    my $curCC;
    for my $uv (unpack_U($_[0])) {
	# Hangul syllable need not decomposed since cc[any Jamo] == 0;
	my @uvCan = exists $Canon{$uv} ? @{ $Canon{$uv} } : ($uv);

	$curCC = $Combin{ $uvCan[0] } || 0;
	return '' if $curCC != 0 && $curCC < $preCC;
	$preCC = $Combin{ $uvCan[-1] } || 0;
    }
    return 1;
}

sub checkFCC ($)
{
    my $preCC = 0;
    my($curCC, $isMAYBE);
    for my $uv (unpack_U($_[0])) {
	# Hangul syllable need not decomposed since cc[any Jamo] == 0;
	my @uvCan = exists $Canon{$uv} ? @{ $Canon{$uv} } : ($uv);

	$curCC = $Combin{ $uvCan[0] } || 0;
	return '' if $curCC != 0 && $curCC < $preCC;

	if (isNFC_MAYBE($uv)) {
	    $isMAYBE = 1;
	} elsif (isNFC_NO($uv)) {
	    return '';
	}

	$preCC = $Combin{ $uvCan[-1] } || 0;
    }
    return $isMAYBE ? undef : 1;
}

##
## split on last starter
##

sub splitOnLastStarter
{
    my $str = pack_U(unpack_U(shift));
    if ($str eq '') {
	return ('', '');
    }

    my $ch;
    my $unproc = "";
    do {
	$ch = chop($str);
	$unproc = $ch.$unproc;
    } while (getCombinClass(unpack 'U', $ch) && $str ne "");
    return ($str, $unproc);
}

##
## normalize
##

sub FCD ($) {
    my $str = shift;
    return checkFCD($str) ? $str : NFD($str);
}

our %formNorm = (
    NFC  => \&NFC,	C  => \&NFC,
    NFD  => \&NFD,	D  => \&NFD,
    NFKC => \&NFKC,	KC => \&NFKC,
    NFKD => \&NFKD,	KD => \&NFKD,
    FCD  => \&FCD,	FCC => \&FCC,
);

sub normalize($$)
{
    my $form = shift;
    my $str = shift;
    if (exists $formNorm{$form}) {
	return $formNorm{$form}->($str);
    }
    croak($PACKAGE."::normalize: invalid form name: $form");
}

##
## partial
##

sub normalize_partial ($$) {
    if (exists $formNorm{$_[0]}) {
	my $n = normalize($_[0], $_[1]);
	my($p, $u) = splitOnLastStarter($n);
	$_[1] = $u;
	return $p;
    }
    croak($PACKAGE."::normalize_partial: invalid form name: $_[0]");
}

sub NFD_partial ($) { return normalize_partial('NFD', $_[0]) }
sub NFC_partial ($) { return normalize_partial('NFC', $_[0]) }
sub NFKD_partial($) { return normalize_partial('NFKD',$_[0]) }
sub NFKC_partial($) { return normalize_partial('NFKC',$_[0]) }

##
## check
##

our %formCheck = (
    NFC  => \&checkNFC, 	C  => \&checkNFC,
    NFD  => \&checkNFD, 	D  => \&checkNFD,
    NFKC => \&checkNFKC,	KC => \&checkNFKC,
    NFKD => \&checkNFKD,	KD => \&checkNFKD,
    FCD  => \&checkFCD, 	FCC => \&checkFCC,
);

sub check($$)
{
    my $form = shift;
    my $str = shift;
    if (exists $formCheck{$form}) {
	return $formCheck{$form}->($str);
    }
    croak($PACKAGE."::check: invalid form name: $form");
}

1;
__END__

=head1 NAME

Unicode::Normalize - Unicode Normalization Forms

=head1 SYNOPSIS

(1) using function names exported by default:

  use Unicode::Normalize;

  $NFD_string  = NFD($string);  # Normalization Form D
  $NFC_string  = NFC($string);  # Normalization Form C
  $NFKD_string = NFKD($string); # Normalization Form KD
  $NFKC_string = NFKC($string); # Normalization Form KC

(2) using function names exported on request:

  use Unicode::Normalize 'normalize';

  $NFD_string  = normalize('D',  $string);  # Normalization Form D
  $NFC_string  = normalize('C',  $string);  # Normalization Form C
  $NFKD_string = normalize('KD', $string);  # Normalization Form KD
  $NFKC_string = normalize('KC', $string);  # Normalization Form KC

=head1 DESCRIPTION

Parameters:

C<$string> is used as a string under character semantics (see F<perlunicode>).

C<$code_point> should be an unsigned integer representing a Unicode code point.

Note: Do not use a floating point nor a negative sign in C<$code_point>.

=head2 Normalization Forms

=over 4

=item C<$NFD_string = NFD($string)>

It returns the Normalization Form D (formed by canonical decomposition).

=item C<$NFC_string = NFC($string)>

It returns the Normalization Form C (formed by canonical decomposition
followed by canonical composition).

=item C<$NFKD_string = NFKD($string)>

It returns the Normalization Form KD (formed by compatibility decomposition).

=item C<$NFKC_string = NFKC($string)>

It returns the Normalization Form KC (formed by compatibility decomposition
followed by B<canonical> composition).

=item C<$FCD_string = FCD($string)>

If the given string is in FCD ("Fast C or D" form; cf. UTN #5),
it returns the string without modification; otherwise it returns an FCD string.

Note: FCD is not always unique, then plural forms may be equivalent
each other. C<FCD()> will return one of these equivalent forms.

=item C<$FCC_string = FCC($string)>

It returns the FCC form ("Fast C Contiguous"; cf. UTN #5).

Note: FCC is unique, as well as four normalization forms (NF*).

=item C<$normalized_string = normalize($form_name, $string)>

It returns the normalization form of C<$form_name>.

As C<$form_name>, one of the following names must be given.

  'C'  or 'NFC'  for Normalization Form C  (UAX #15)
  'D'  or 'NFD'  for Normalization Form D  (UAX #15)
  'KC' or 'NFKC' for Normalization Form KC (UAX #15)
  'KD' or 'NFKD' for Normalization Form KD (UAX #15)

  'FCD'          for "Fast C or D" Form  (UTN #5)
  'FCC'          for "Fast C Contiguous" (UTN #5)

=back

=head2 Decomposition and Composition

=over 4

=item C<$decomposed_string = decompose($string [, $useCompatMapping])>

It returns the concatenation of the decomposition of each character
in the string.

If the second parameter (a boolean) is omitted or false,
the decomposition is canonical decomposition;
if the second parameter (a boolean) is true,
the decomposition is compatibility decomposition.

The string returned is not always in NFD/NFKD. Reordering may be required.

    $NFD_string  = reorder(decompose($string));       # eq. to NFD()
    $NFKD_string = reorder(decompose($string, TRUE)); # eq. to NFKD()

=item C<$reordered_string = reorder($string)>

It returns the result of reordering the combining characters
according to Canonical Ordering Behavior.

For example, when you have a list of NFD/NFKD strings,
you can get the concatenated NFD/NFKD string from them, by saying

    $concat_NFD  = reorder(join '', @NFD_strings);
    $concat_NFKD = reorder(join '', @NFKD_strings);

=item C<$composed_string = compose($string)>

It returns the result of canonical composition
without applying any decomposition.

For example, when you have a NFD/NFKD string,
you can get its NFC/NFKC string, by saying

    $NFC_string  = compose($NFD_string);
    $NFKC_string = compose($NFKD_string);

=item C<($processed, $unprocessed) = splitOnLastStarter($normalized)>

It returns two strings: the first one, C<$processed>, is a part
before the last starter, and the second one, C<$unprocessed> is
another part after the first part. A starter is a character having
a combining class of zero (see UAX #15).

Note that C<$processed> may be empty (when C<$normalized> contains no
starter or starts with the last starter), and then C<$unprocessed>
should be equal to the entire C<$normalized>.

When you have a C<$normalized> string and an C<$unnormalized> string
following it, a simple concatenation is wrong:

    $concat = $normalized . normalize($form, $unnormalized); # wrong!

Instead of it, do like this:

    ($processed, $unprocessed) = splitOnLastStarter($normalized);
     $concat = $processed . normalize($form, $unprocessed.$unnormalized);

C<splitOnLastStarter()> should be called with a pre-normalized parameter
C<$normalized>, that is in the same form as C<$form> you want.

If you have an array of C<@string> that should be concatenated and then
normalized, you can do like this:

    my $result = "";
    my $unproc = "";
    foreach my $str (@string) {
        $unproc .= $str;
        my $n = normalize($form, $unproc);
        my($p, $u) = splitOnLastStarter($n);
        $result .= $p;
        $unproc  = $u;
    }
    $result .= $unproc;
    # instead of normalize($form, join('', @string))

=item C<$processed = normalize_partial($form, $unprocessed)>

A wrapper for the combination of C<normalize()> and C<splitOnLastStarter()>.
Note that C<$unprocessed> will be modified as a side-effect.

If you have an array of C<@string> that should be concatenated and then
normalized, you can do like this:

    my $result = "";
    my $unproc = "";
    foreach my $str (@string) {
        $unproc .= $str;
        $result .= normalize_partial($form, $unproc);
    }
    $result .= $unproc;
    # instead of normalize($form, join('', @string))

=item C<$processed = NFD_partial($unprocessed)>

It does like C<normalize_partial('NFD', $unprocessed)>.
Note that C<$unprocessed> will be modified as a side-effect.

=item C<$processed = NFC_partial($unprocessed)>

It does like C<normalize_partial('NFC', $unprocessed)>.
Note that C<$unprocessed> will be modified as a side-effect.

=item C<$processed = NFKD_partial($unprocessed)>

It does like C<normalize_partial('NFKD', $unprocessed)>.
Note that C<$unprocessed> will be modified as a side-effect.

=item C<$processed = NFKC_partial($unprocessed)>

It does like C<normalize_partial('NFKC', $unprocessed)>.
Note that C<$unprocessed> will be modified as a side-effect.

=back

=head2 Quick Check

(see Annex 8, UAX #15; and F<DerivedNormalizationProps.txt>)

The following functions check whether the string is in that normalization form.

The result returned will be one of the following:

    YES     The string is in that normalization form.
    NO      The string is not in that normalization form.
    MAYBE   Dubious. Maybe yes, maybe no.

=over 4

=item C<$result = checkNFD($string)>

It returns true (C<1>) if C<YES>; false (C<empty string>) if C<NO>.

=item C<$result = checkNFC($string)>

It returns true (C<1>) if C<YES>; false (C<empty string>) if C<NO>;
C<undef> if C<MAYBE>.

=item C<$result = checkNFKD($string)>

It returns true (C<1>) if C<YES>; false (C<empty string>) if C<NO>.

=item C<$result = checkNFKC($string)>

It returns true (C<1>) if C<YES>; false (C<empty string>) if C<NO>;
C<undef> if C<MAYBE>.

=item C<$result = checkFCD($string)>

It returns true (C<1>) if C<YES>; false (C<empty string>) if C<NO>.

=item C<$result = checkFCC($string)>

It returns true (C<1>) if C<YES>; false (C<empty string>) if C<NO>;
C<undef> if C<MAYBE>.

Note: If a string is not in FCD, it must not be in FCC.
So C<checkFCC($not_FCD_string)> should return C<NO>.

=item C<$result = check($form_name, $string)>

It returns true (C<1>) if C<YES>; false (C<empty string>) if C<NO>;
C<undef> if C<MAYBE>.

As C<$form_name>, one of the following names must be given.

  'C'  or 'NFC'  for Normalization Form C  (UAX #15)
  'D'  or 'NFD'  for Normalization Form D  (UAX #15)
  'KC' or 'NFKC' for Normalization Form KC (UAX #15)
  'KD' or 'NFKD' for Normalization Form KD (UAX #15)

  'FCD'          for "Fast C or D" Form  (UTN #5)
  'FCC'          for "Fast C Contiguous" (UTN #5)

=back

B<Note>

In the cases of NFD, NFKD, and FCD, the answer must be
either C<YES> or C<NO>. The answer C<MAYBE> may be returned
in the cases of NFC, NFKC, and FCC.

A C<MAYBE> string should contain at least one combining character
or the like. For example, C<COMBINING ACUTE ACCENT> has
the MAYBE_NFC/MAYBE_NFKC property.

Both C<checkNFC("A\N{COMBINING ACUTE ACCENT}")>
and C<checkNFC("B\N{COMBINING ACUTE ACCENT}")> will return C<MAYBE>.
C<"A\N{COMBINING ACUTE ACCENT}"> is not in NFC
(its NFC is C<"\N{LATIN CAPITAL LETTER A WITH ACUTE}">),
while C<"B\N{COMBINING ACUTE ACCENT}"> is in NFC.

If you want to check exactly, compare the string with its NFC/NFKC/FCC.

    if ($string eq NFC($string)) {
        # $string is exactly normalized in NFC;
    } else {
        # $string is not normalized in NFC;
    }

    if ($string eq NFKC($string)) {
        # $string is exactly normalized in NFKC;
    } else {
        # $string is not normalized in NFKC;
    }

=head2 Character Data

These functions are interface of character data used internally.
If you want only to get Unicode normalization forms, you don't need
call them yourself.

=over 4

=item C<$canonical_decomposition = getCanon($code_point)>

If the character is canonically decomposable (including Hangul Syllables),
it returns the (full) canonical decomposition as a string.
Otherwise it returns C<undef>.

B<Note:> According to the Unicode standard, the canonical decomposition
of the character that is not canonically decomposable is same as
the character itself.

=item C<$compatibility_decomposition = getCompat($code_point)>

If the character is compatibility decomposable (including Hangul Syllables),
it returns the (full) compatibility decomposition as a string.
Otherwise it returns C<undef>.

B<Note:> According to the Unicode standard, the compatibility decomposition
of the character that is not compatibility decomposable is same as
the character itself.

=item C<$code_point_composite = getComposite($code_point_here, $code_point_next)>

If two characters here and next (as code points) are composable
(including Hangul Jamo/Syllables and Composition Exclusions),
it returns the code point of the composite.

If they are not composable, it returns C<undef>.

=item C<$combining_class = getCombinClass($code_point)>

It returns the combining class (as an integer) of the character.

=item C<$may_be_composed_with_prev_char = isComp2nd($code_point)>

It returns a boolean whether the character of the specified codepoint
may be composed with the previous one in a certain composition
(including Hangul Compositions, but excluding
Composition Exclusions and Non-Starter Decompositions).

=item C<$is_exclusion = isExclusion($code_point)>

It returns a boolean whether the code point is a composition exclusion.

=item C<$is_singleton = isSingleton($code_point)>

It returns a boolean whether the code point is a singleton

=item C<$is_non_starter_decomposition = isNonStDecomp($code_point)>

It returns a boolean whether the code point has Non-Starter Decomposition.

=item C<$is_Full_Composition_Exclusion = isComp_Ex($code_point)>

It returns a boolean of the derived property Comp_Ex
(Full_Composition_Exclusion). This property is generated from
Composition Exclusions + Singletons + Non-Starter Decompositions.

=item C<$NFD_is_NO = isNFD_NO($code_point)>

It returns a boolean of the derived property NFD_NO
(NFD_Quick_Check=No).

=item C<$NFC_is_NO = isNFC_NO($code_point)>

It returns a boolean of the derived property NFC_NO
(NFC_Quick_Check=No).

=item C<$NFC_is_MAYBE = isNFC_MAYBE($code_point)>

It returns a boolean of the derived property NFC_MAYBE
(NFC_Quick_Check=Maybe).

=item C<$NFKD_is_NO = isNFKD_NO($code_point)>

It returns a boolean of the derived property NFKD_NO
(NFKD_Quick_Check=No).

=item C<$NFKC_is_NO = isNFKC_NO($code_point)>

It returns a boolean of the derived property NFKC_NO
(NFKC_Quick_Check=No).

=item C<$NFKC_is_MAYBE = isNFKC_MAYBE($code_point)>

It returns a boolean of the derived property NFKC_MAYBE
(NFKC_Quick_Check=Maybe).

=back

=head1 EXPORT

C<NFC>, C<NFD>, C<NFKC>, C<NFKD>: by default.

C<normalize> and other some functions: on request.

=head1 CAVEATS

=over 4

=item Perl's version vs. Unicode version

Since this module refers to perl core's Unicode database in the directory
F</lib/unicore> (or formerly F</lib/unicode>), the Unicode version of
normalization implemented by this module depends on your perl's version.

    perl's version     implemented Unicode version
       5.6.1              3.0.1
       5.7.2              3.1.0
       5.7.3              3.1.1 (normalization is same as 3.1.0)
       5.8.0              3.2.0
     5.8.1-5.8.3          4.0.0
     5.8.4-5.8.6          4.0.1 (normalization is same as 4.0.0)
     5.8.7-5.8.8          4.1.0
       5.10.0             5.0.0
    5.8.9, 5.10.1         5.1.0
       5.12.x             5.2.0
       5.14.x             6.0.0
       5.16.x             6.1.0
       5.18.x             6.2.0

=item Correction of decomposition mapping

In older Unicode versions, a small number of characters (all of which are
CJK compatibility ideographs as far as they have been found) may have
an erroneous decomposition mapping (see F<NormalizationCorrections.txt>).
Anyhow, this module will neither refer to F<NormalizationCorrections.txt>
nor provide any specific version of normalization. Therefore this module
running on an older perl with an older Unicode database may use
the erroneous decomposition mapping blindly conforming to the Unicode database.

=item Revised definition of canonical composition

In Unicode 4.1.0, the definition D2 of canonical composition (which
affects NFC and NFKC) has been changed (see Public Review Issue #29
and recent UAX #15). This module has used the newer definition
since the version 0.07 (Oct 31, 2001).
This module will not support the normalization according to the older
definition, even if the Unicode version implemented by perl is
lower than 4.1.0.

=back

=head1 AUTHOR

SADAHIRO Tomoyuki <SADAHIRO@cpan.org>

Copyright(C) 2001-2012, SADAHIRO Tomoyuki. Japan. All rights reserved.

This module is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item http://www.unicode.org/reports/tr15/

Unicode Normalization Forms - UAX #15

=item http://www.unicode.org/Public/UNIDATA/CompositionExclusions.txt

Composition Exclusion Table

=item http://www.unicode.org/Public/UNIDATA/DerivedNormalizationProps.txt

Derived Normalization Properties

=item http://www.unicode.org/Public/UNIDATA/NormalizationCorrections.txt

Normalization Corrections

=item http://www.unicode.org/review/pr-29.html

Public Review Issue #29: Normalization Issue

=item http://www.unicode.org/notes/tn5/

Canonical Equivalence in Applications - UTN #5

=back

=cut
