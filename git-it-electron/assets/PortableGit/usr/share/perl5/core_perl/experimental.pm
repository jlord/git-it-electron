package experimental;
$experimental::VERSION = '0.013';
use strict;
use warnings;
use version ();

use feature ();
use Carp qw/croak carp/;

my %warnings = map { $_ => 1 } grep { /^experimental::/ } keys %warnings::Offsets;
my %features = map { $_ => 1 } $] > 5.015006 ? keys %feature::feature : do {
	my @features;
	if ($] >= 5.010) {
		push @features, qw/switch say state/;
		push @features, 'unicode_strings' if $] > 5.011002;
	}
	@features;
};

my %min_version = (
	array_base      => '5',
	autoderef       => '5.14.0',
	current_sub     => '5.16.0',
	evalbytes       => '5.16.0',
	fc              => '5.16.0',
	lexical_topic   => '5.10.0',
	lexical_subs    => '5.18.0',
	postderef       => '5.20.0',
	postderef_qq    => '5.20.0',
	refaliasing     => '5.21.5',
	regex_sets      => '5.18.0',
	say             => '5.10.0',
	smartmatch      => '5.10.0',
	signatures      => '5.20.0',
	state           => '5.10.0',
	switch          => '5.10.0',
	unicode_eval    => '5.16.0',
	unicode_strings => '5.12.0',
);
$_ = version->new($_) for values %min_version;

my %additional = (
	postderef  => ['postderef_qq'],
	switch     => ['smartmatch'],
);

sub _enable {
	my $pragma = shift;
	if ($warnings{"experimental::$pragma"}) {
		warnings->unimport("experimental::$pragma");
		feature->import($pragma) if exists $features{$pragma};
		_enable(@{ $additional{$pragma} }) if $additional{$pragma};
	}
	elsif ($features{$pragma}) {
		feature->import($pragma);
		_enable(@{ $additional{$pragma} }) if $additional{$pragma};
	}
	elsif (not exists $min_version{$pragma}) {
		croak "Can't enable unknown feature $pragma";
	}
	elsif ($min_version{$pragma} > $]) {
		my $stable = $min_version{$pragma};
		if ($stable->{version}[1] % 2) {
			$stable = version->new(
				"5.".($stable->{version}[1]+1).'.0'
			);
		}
		croak "Need perl $stable or later for feature $pragma";
	}
}

sub import {
	my ($self, @pragmas) = @_;

	for my $pragma (@pragmas) {
		_enable($pragma);
	}
	return;
}

sub _disable {
	my $pragma = shift;
	if ($warnings{"experimental::$pragma"}) {
		warnings->import("experimental::$pragma");
		feature->unimport($pragma) if exists $features{$pragma};
		_disable(@{ $additional{$pragma} }) if $additional{$pragma};
	}
	elsif ($features{$pragma}) {
		feature->unimport($pragma);
		_disable(@{ $additional{$pragma} }) if $additional{$pragma};
	}
	elsif (not exists $min_version{$pragma}) {
		carp "Can't disable unknown feature $pragma, ignoring";
	}
}

sub unimport {
	my ($self, @pragmas) = @_;

	for my $pragma (@pragmas) {
		_disable($pragma);
	}
	return;
}

1;

#ABSTRACT: Experimental features made easy

__END__

=pod

=encoding UTF-8

=head1 NAME

experimental - Experimental features made easy

=head1 VERSION

version 0.013

=head1 SYNOPSIS

 use experimental 'lexical_subs', 'smartmatch';
 my sub foo { $_[0] ~~ 1 }

=head1 DESCRIPTION

This pragma provides an easy and convenient way to enable or disable
experimental features.

Every version of perl has some number of features present but considered
"experimental."  For much of the life of Perl 5, this was only a designation
found in the documentation.  Starting in Perl v5.10.0, and more aggressively in
v5.18.0, experimental features were placed behind pragmata used to enable the
feature and disable associated warnings.

The C<experimental> pragma exists to combine the required incantations into a
single interface stable across releases of perl.  For every experimental
feature, this should enable the feature and silence warnings for the enclosing
lexical scope:

  use experimental 'feature-name';

To disable the feature and, if applicable, re-enable any warnings, use:

  no experimental 'feature-name';

The supported features, documented further below, are:

	array_base    - allow the use of $[ to change the starting index of @array
	autoderef     - allow push, each, keys, and other built-ins on references
	lexical_topic - allow the use of lexical $_ via "my $_"
	postderef     - allow the use of postfix dereferencing expressions, including
	                in interpolating strings
	refaliasing   - allow aliasing via \$x = \$y
	regex_sets    - allow extended bracketed character classes in regexps
	signatures    - allow subroutine signatures (for named arguments)
	smartmatch    - allow the use of ~~
	switch        - allow the use of ~~, given, and when

=head2 Ordering matters

Using this pragma to 'enable an experimental feature' is another way of saying
that this pragma will disable the warnings which would result from using that
feature.  Therefore, the order in which pragmas are applied is important.  In
particular, you probably want to enable experimental features I<after> you
enable warnings:

  use warnings;
  use experimental 'smartmatch';

You also need to take care with modules that enable warnings for you.  A common
example being Moose.  In this example, warnings for the 'smartmatch' feature are
first turned on by the warnings pragma, off by the experimental pragma and back
on again by the Moose module (fix is to switch the last two lines):

  use warnings;
  use experimental 'smartmatch';
  use Moose;

=head2 Disclaimer

Because of the nature of the features it enables, forward compatibility can not
be guaranteed in any way.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
