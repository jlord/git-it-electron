use strict;
use warnings;

package CPAN::Meta::Merge;

our $VERSION = '2.150001';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use CPAN::Meta::Converter 2.141170;

sub _identical {
  my ($left, $right, $path) = @_;
  croak sprintf "Can't merge attribute %s: '%s' does not equal '%s'", join('.', @{$path}), $left, $right unless $left eq $right;
  return $left;
}

sub _merge {
  my ($current, $next, $mergers, $path) = @_;
  for my $key (keys %{$next}) {
    if (not exists $current->{$key}) {
      $current->{$key} = $next->{$key};
    }
    elsif (my $merger = $mergers->{$key}) {
      $current->{$key} = $merger->($current->{$key}, $next->{$key}, [ @{$path}, $key ]);
    }
    elsif ($merger = $mergers->{':default'}) {
      $current->{$key} = $merger->($current->{$key}, $next->{$key}, [ @{$path}, $key ]);
    }
    else {
      croak sprintf "Can't merge unknown attribute '%s'", join '.', @{$path}, $key;
    }
  }
  return $current;
}

sub _uniq {
  my %seen = ();
  return grep { not $seen{$_}++ } @_;
}

sub _set_addition {
  my ($left, $right) = @_;
  return [ +_uniq(@{$left}, @{$right}) ];
}

sub _uniq_map {
  my ($left, $right, $path) = @_;
  for my $key (keys %{$right}) {
    if (not exists $left->{$key}) {
      $left->{$key} = $right->{$key};
    }
    else {
      croak 'Duplication of element ' . join '.', @{$path}, $key;
    }
  }
  return $left;
}

sub _improvize {
  my ($left, $right, $path) = @_;
  my ($name) = reverse @{$path};
  if ($name =~ /^x_/) {
    if (ref($left) eq 'ARRAY') {
      return _set_addition($left, $right, $path);
    }
    elsif (ref($left) eq 'HASH') {
      return _uniq_map($left, $right, $path);
    }
    else {
      return _identical($left, $right, $path);
    }
  }
  croak sprintf "Can't merge '%s'", join '.', @{$path};
}

sub _optional_features {
  my ($left, $right, $path) = @_;

  for my $key (keys %{$right}) {
    if (not exists $left->{$key}) {
      $left->{$key} = $right->{$key};
    }
    else {
      for my $subkey (keys %{ $right->{$key} }) {
        next if $subkey eq 'prereqs';
        if (not exists $left->{$key}{$subkey}) {
          $left->{$key}{$subkey} = $right->{$key}{$subkey};
        }
        else {
          Carp::croak "Cannot merge two optional_features named '$key' with different '$subkey' values"
            if do { no warnings 'uninitialized'; $left->{$key}{$subkey} ne $right->{$key}{$subkey} };
        }
      }

      require CPAN::Meta::Prereqs;
      $left->{$key}{prereqs} =
        CPAN::Meta::Prereqs->new($left->{$key}{prereqs})
          ->with_merged_prereqs(CPAN::Meta::Prereqs->new($right->{$key}{prereqs}))
          ->as_string_hash;
    }
  }
  return $left;
}


my %default = (
  abstract       => \&_identical,
  author         => \&_set_addition,
  dynamic_config => sub {
    my ($left, $right) = @_;
    return $left || $right;
  },
  generated_by => sub {
    my ($left, $right) = @_;
    return join ', ', _uniq(split(/, /, $left), split(/, /, $right));
  },
  license     => \&_set_addition,
  'meta-spec' => {
    version => \&_identical,
    url     => \&_identical
  },
  name              => \&_identical,
  release_status    => \&_identical,
  version           => \&_identical,
  description       => \&_identical,
  keywords          => \&_set_addition,
  no_index          => { map { ($_ => \&_set_addition) } qw/file directory package namespace/ },
  optional_features => \&_optional_features,
  prereqs           => sub {
    require CPAN::Meta::Prereqs;
    my ($left, $right) = map { CPAN::Meta::Prereqs->new($_) } @_[0,1];
    return $left->with_merged_prereqs($right)->as_string_hash;
  },
  provides  => \&_uniq_map,
  resources => {
    license    => \&_set_addition,
    homepage   => \&_identical,
    bugtracker => \&_uniq_map,
    repository => \&_uniq_map,
    ':default' => \&_improvize,
  },
  ':default' => \&_improvize,
);

sub new {
  my ($class, %arguments) = @_;
  croak 'default version required' if not exists $arguments{default_version};
  my %mapping = %default;
  my %extra = %{ $arguments{extra_mappings} || {} };
  for my $key (keys %extra) {
    if (ref($mapping{$key}) eq 'HASH') {
      $mapping{$key} = { %{ $mapping{$key} }, %{ $extra{$key} } };
    }
    else {
      $mapping{$key} = $extra{$key};
    }
  }
  return bless {
    default_version => $arguments{default_version},
    mapping => _coerce_mapping(\%mapping, []),
  }, $class;
}

my %coderef_for = (
  set_addition => \&_set_addition,
  uniq_map     => \&_uniq_map,
  identical    => \&_identical,
  improvize    => \&_improvize,
);

sub _coerce_mapping {
  my ($orig, $map_path) = @_;
  my %ret;
  for my $key (keys %{$orig}) {
    my $value = $orig->{$key};
    if (ref($orig->{$key}) eq 'CODE') {
      $ret{$key} = $value;
    }
    elsif (ref($value) eq 'HASH') {
      my $mapping = _coerce_mapping($value, [ @{$map_path}, $key ]);
      $ret{$key} = sub {
        my ($left, $right, $path) = @_;
        return _merge($left, $right, $mapping, [ @{$path} ]);
      };
    }
    elsif ($coderef_for{$value}) {
      $ret{$key} = $coderef_for{$value};
    }
    else {
      croak "Don't know what to do with " . join '.', @{$map_path}, $key;
    }
  }
  return \%ret;
}

sub merge {
  my ($self, @items) = @_;
  my $current = {};
  for my $next (@items) {
    if ( blessed($next) && $next->isa('CPAN::Meta') ) {
      $next = $next->as_struct;
    }
    elsif ( ref($next) eq 'HASH' ) {
      my $cmc = CPAN::Meta::Converter->new(
        $next, default_version => $self->{default_version}
      );
      $next = $cmc->upgrade_fragment;
    }
    else {
      croak "Don't know how to merge '$next'";
    }
    $current = _merge($current, $next, $self->{mapping}, []);
  }
  return $current;
}

1;

# ABSTRACT: Merging CPAN Meta fragments

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Meta::Merge - Merging CPAN Meta fragments

=head1 VERSION

version 2.150001

=head1 SYNOPSIS

 my $merger = CPAN::Meta::Merge->new(default_version => "2");
 my $meta = $merger->merge($base, @additional);

=head1 DESCRIPTION

=head1 METHODS

=head2 new

This creates a CPAN::Meta::Merge object. It takes one mandatory named
argument, C<version>, declaring the version of the meta-spec that must be
used for the merge. It can optionally take an C<extra_mappings> argument
that allows one to add additional merging functions for specific elements.

=head2 merge(@fragments)

Merge all C<@fragments> together. It will accept both CPAN::Meta objects and
(possibly incomplete) hashrefs of metadata.

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by David Golden and Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
