package Module::CoreList::Utils;

use strict;
use warnings;
use vars qw[$VERSION %utilities];
use Module::CoreList;
use Module::CoreList::TieHashDelta;

$VERSION = '5.20150520';

sub utilities {
    my $perl = shift;
    $perl = shift if eval { $perl->isa(__PACKAGE__) };
    return unless $perl or exists $utilities{$perl};
    return sort keys %{ $utilities{$perl} };
}

sub _released_order {   # Sort helper, to make '?' sort after everything else
    (substr($Module::CoreList::released{$a}, 0, 1) eq "?")
    ? ((substr($Module::CoreList::released{$b}, 0, 1) eq "?")
        ? 0
        : 1)
    : ((substr($Module::CoreList::released{$b}, 0, 1) eq "?")
        ? -1
        : $Module::CoreList::released{$a} cmp $Module::CoreList::released{$b} )
}

sub first_release_raw {
    my $util = shift;
    $util = shift if eval { $util->isa(__PACKAGE__) };
      #and scalar @_ and $_[0] =~ m#\A[a-zA-Z_][0-9a-zA-Z_]*(?:(::|')[0-9a-zA-Z_]+)*\z#;
    my $version = shift;

    my @perls = $version
        ? grep { exists $utilities{$_}{ $util } &&
                        $utilities{$_}{ $util } ge $version } keys %utilities
        : grep { exists $utilities{$_}{ $util }             } keys %utilities;

    return grep { exists $Module::CoreList::released{$_} } @perls;
}

sub first_release_by_date {
    my @perls = &first_release_raw;
    return unless @perls;
    return (sort _released_order @perls)[0];
}

sub first_release {
    my @perls = &first_release_raw;
    return unless @perls;
    return (sort { $a cmp $b } @perls)[0];
}

sub removed_from {
  my @perls = &removed_raw;
  return shift @perls;
}

sub removed_from_by_date {
  my @perls = sort _released_order &removed_raw;
  return shift @perls;
}

sub removed_raw {
  my $util = shift;
  $util = shift if eval { $util->isa(__PACKAGE__) };
  return unless my @perls = sort { $a cmp $b } first_release_raw($util);
  @perls = grep { exists $Module::CoreList::released{$_} } @perls;
  my $last = pop @perls;
  my @removed = grep { $_ > $last } sort { $a cmp $b } keys %utilities;
  return @removed;
}

my %delta = (
    5 => {
        changed => {
            'a2p'                   => '1',
            'c2ph'                  => '1',
            'cppstdin'              => '1',
            'find2perl'             => '1',
            'pstruct'               => '1',
            's2p'                   => '1',
        },
        removed => {
        }
    },

    5.001 => {
        delta_from => 5,
        changed => {
            'h2xs'                  => '1',
        },
        removed => {
        }
    },

    5.002 => {
        delta_from => 5.001,
        changed => {
            'h2ph'                  => '1',
            'perlbug'               => '1',
            'perldoc'               => '1',
            'pod2html'              => '1',
            'pod2latex'             => '1',
            'pod2man'               => '1',
            'pod2text'              => '1',
        },
        removed => {
        }
    },

    5.00307 => {
        delta_from => 5.002,
        changed => {
            'pl2pm'                 => '1',
        },
        removed => {
           'cppstdin'              => 1,
           'pstruct'               => 1,
        }
    },

    5.004 => {
        delta_from => 5.00307,
        changed => {
            'splain'                => '1',
        },
        removed => {
        }
    },

    5.005 => {
        delta_from => 5.00405,
        changed => {
            'perlcc'                => '1',
        },
        removed => {
        }
    },

    5.00503 => {
        delta_from => 5.005,
        changed => {
        },
        removed => {
        }
    },

    5.00405 => {
        delta_from => 5.004,
        changed => {
        },
        removed => {
        }
    },

    5.006 => {
        delta_from => 5.00504,
        changed => {
            'dprofpp'               => '1',
            'pod2usage'             => '1',
            'podchecker'            => '1',
            'podselect'             => '1',
            'pstruct'               => '1',
        },
        removed => {
        }
    },

    5.006001 => {
        delta_from => 5.006,
        changed => {
        },
        removed => {
        }
    },

    5.007003 => {
        delta_from => 5.006002,
        changed => {
            'libnetcfg'             => '1',
            'perlivp'               => '1',
            'psed'                  => '1',
            'xsubpp'                => '1',
        },
        removed => {
        }
    },

    5.008 => {
        delta_from => 5.007003,
        changed => {
            'enc2xs'                => '1',
            'piconv'                => '1',
        },
        removed => {
        }
    },

    5.008001 => {
        delta_from => 5.008,
        changed => {
            'cpan'                  => '1',
        },
        removed => {
        }
    },

    5.009 => {
        delta_from => 5.008009,
        changed => {
        },
        removed => {
           'corelist'              => 1,
           'instmodsh'             => 1,
           'prove'                 => 1,
        }
    },

    5.008002 => {
        delta_from => 5.008001,
        changed => {
        },
        removed => {
        }
    },

    5.006002 => {
        delta_from => 5.006001,
        changed => {
        },
        removed => {
        }
    },

    5.008003 => {
        delta_from => 5.008002,
        changed => {
            'instmodsh'             => '1',
            'prove'                 => '1',
        },
        removed => {
        }
    },

    5.00504 => {
        delta_from => 5.00503,
        changed => {
        },
        removed => {
        }
    },

    5.009001 => {
        delta_from => 5.009,
        changed => {
            'instmodsh'             => '1',
            'prove'                 => '1',
        },
        removed => {
        }
    },

    5.008004 => {
        delta_from => 5.008003,
        changed => {
        },
        removed => {
        }
    },

    5.008005 => {
        delta_from => 5.008004,
        changed => {
        },
        removed => {
        }
    },

    5.008006 => {
        delta_from => 5.008005,
        changed => {
        },
        removed => {
        }
    },

    5.009002 => {
        delta_from => 5.009001,
        changed => {
            'corelist'              => '1',
        },
        removed => {
        }
    },

    5.008007 => {
        delta_from => 5.008006,
        changed => {
        },
        removed => {
        }
    },

    5.009003 => {
        delta_from => 5.009002,
        changed => {
            'ptar'                  => '1',
            'ptardiff'              => '1',
            'shasum'                => '1',
        },
        removed => {
        }
    },

    5.008008 => {
        delta_from => 5.008007,
        changed => {
        },
        removed => {
        }
    },

    5.009004 => {
        delta_from => 5.009003,
        changed => {
            'config_data'           => '1',
        },
        removed => {
        }
    },

    5.009005 => {
        delta_from => 5.009004,
        changed => {
            'cpan2dist'             => '1',
            'cpanp'                 => '1',
            'cpanp-run-perl'        => '1',
        },
        removed => {
           'perlcc'                => 1,
        }
    },

    5.010000 => {
        delta_from => 5.009005,
        changed => {
        },
        removed => {
        }
    },

    5.008009 => {
        delta_from => 5.008008,
        changed => {
            'corelist'              => '1',
        },
        removed => {
        }
    },

    5.010001 => {
        delta_from => 5.010000,
        changed => {
        },
        removed => {
        }
    },

    5.011 => {
        delta_from => 5.010001,
        changed => {
        },
        removed => {
        }
    },

    5.011001 => {
        delta_from => 5.011,
        changed => {
        },
        removed => {
        }
    },

    5.011002 => {
        delta_from => 5.011001,
        changed => {
            'perlthanks'            => '1',
        },
        removed => {
        }
    },

    5.011003 => {
        delta_from => 5.011002,
        changed => {
        },
        removed => {
        }
    },

    5.011004 => {
        delta_from => 5.011003,
        changed => {
        },
        removed => {
        }
    },

    5.011005 => {
        delta_from => 5.011004,
        changed => {
        },
        removed => {
        }
    },

    5.012 => {
        delta_from => 5.011005,
        changed => {
        },
        removed => {
        }
    },

    5.013 => {
        delta_from => 5.012005,
        changed => {
        },
        removed => {
        }
    },

    5.012001 => {
        delta_from => 5.012,
        changed => {
        },
        removed => {
        }
    },

    5.013001 => {
        delta_from => 5.013,
        changed => {
        },
        removed => {
        }
    },

    5.013002 => {
        delta_from => 5.013001,
        changed => {
        },
        removed => {
        }
    },

    5.013003 => {
        delta_from => 5.013002,
        changed => {
        },
        removed => {
        }
    },

    5.013004 => {
        delta_from => 5.013003,
        changed => {
        },
        removed => {
        }
    },

    5.012002 => {
        delta_from => 5.012001,
        changed => {
        },
        removed => {
        }
    },

    5.013005 => {
        delta_from => 5.013004,
        changed => {
        },
        removed => {
        }
    },

    5.013006 => {
        delta_from => 5.013005,
        changed => {
        },
        removed => {
        }
    },

    5.013007 => {
        delta_from => 5.013006,
        changed => {
            'ptargrep'              => '1',
        },
        removed => {
        }
    },

    5.013008 => {
        delta_from => 5.013007,
        changed => {
        },
        removed => {
        }
    },

    5.013009 => {
        delta_from => 5.013008,
        changed => {
            'json_pp'               => '1',
        },
        removed => {
        }
    },

    5.012003 => {
        delta_from => 5.012002,
        changed => {
        },
        removed => {
        }
    },

    5.013010 => {
        delta_from => 5.013009,
        changed => {
        },
        removed => {
        }
    },

    5.013011 => {
        delta_from => 5.013010,
        changed => {
        },
        removed => {
        }
    },

    5.014 => {
        delta_from => 5.013011,
        changed => {
        },
        removed => {
        }
    },

    5.014001 => {
        delta_from => 5.014,
        changed => {
        },
        removed => {
        }
    },

    5.015 => {
        delta_from => 5.014004,
        changed => {
        },
        removed => {
           'dprofpp'               => 1,
        }
    },

    5.012004 => {
        delta_from => 5.012003,
        changed => {
        },
        removed => {
        }
    },

    5.015001 => {
        delta_from => 5.015,
        changed => {
        },
        removed => {
        }
    },

    5.015002 => {
        delta_from => 5.015001,
        changed => {
        },
        removed => {
        }
    },

    5.015003 => {
        delta_from => 5.015002,
        changed => {
        },
        removed => {
        }
    },

    5.014002 => {
        delta_from => 5.014001,
        changed => {
        },
        removed => {
        }
    },

    5.015004 => {
        delta_from => 5.015003,
        changed => {
        },
        removed => {
        }
    },

    5.015005 => {
        delta_from => 5.015004,
        changed => {
        },
        removed => {
        }
    },

    5.015006 => {
        delta_from => 5.015005,
        changed => {
            'zipdetails'            => '1',
        },
        removed => {
        }
    },

    5.015007 => {
        delta_from => 5.015006,
        changed => {
        },
        removed => {
        }
    },

    5.015008 => {
        delta_from => 5.015007,
        changed => {
        },
        removed => {
        }
    },

    5.015009 => {
        delta_from => 5.015008,
        changed => {
        },
        removed => {
        }
    },

    5.016 => {
        delta_from => 5.015009,
        changed => {
        },
        removed => {
        }
    },

    5.017 => {
        delta_from => 5.016003,
        changed => {
        },
        removed => {
        }
    },

    5.017001 => {
        delta_from => 5.017,
        changed => {
        },
        removed => {
        }
    },

    5.017002 => {
        delta_from => 5.017001,
        changed => {
        },
        removed => {
        }
    },

    5.016001 => {
        delta_from => 5.016,
        changed => {
        },
        removed => {
        }
    },

    5.017003 => {
        delta_from => 5.017002,
        changed => {
        },
        removed => {
        }
    },

    5.017004 => {
        delta_from => 5.017003,
        changed => {
        },
        removed => {
        }
    },

    5.014003 => {
        delta_from => 5.014002,
        changed => {
        },
        removed => {
        }
    },

    5.017005 => {
        delta_from => 5.017004,
        changed => {
        },
        removed => {
        }
    },

    5.016002 => {
        delta_from => 5.016001,
        changed => {
        },
        removed => {
        }
    },

    5.012005 => {
        delta_from => 5.012004,
        changed => {
        },
        removed => {
        }
    },

    5.017006 => {
        delta_from => 5.017005,
        changed => {
        },
        removed => {
        }
    },

    5.017007 => {
        delta_from => 5.017006,
        changed => {
        },
        removed => {
        }
    },

    5.017008 => {
        delta_from => 5.017007,
        changed => {
        },
        removed => {
        }
    },

    5.017009 => {
        delta_from => 5.017008,
        changed => {
        },
        removed => {
        }
    },

    5.014004 => {
        delta_from => 5.014003,
        changed => {
        },
        removed => {
        }
    },

    5.016003 => {
        delta_from => 5.016002,
        changed => {
        },
        removed => {
        }
    },

    5.017010 => {
        delta_from => 5.017009,
        changed => {
        },
        removed => {
        }
    },

    5.017011 => {
        delta_from => 5.017010,
        changed => {
        },
        removed => {
        }
    },
    5.018000 => {
        delta_from => 5.017011,
        changed => {
        },
        removed => {
        }
    },
    5.018001 => {
        delta_from => 5.018000,
        changed => {
        },
        removed => {
        }
    },
    5.018002 => {
        delta_from => 5.018001,
        changed => {
        },
        removed => {
        }
    },
    5.018003 => {
        delta_from => 5.018000,
        changed => {
        },
        removed => {
        }
    },
    5.018004 => {
        delta_from => 5.018000,
        changed => {
        },
        removed => {
        }
    },
    5.019000 => {
        delta_from => 5.018000,
        changed => {
        },
        removed => {
            'cpan2dist'             => '1',
            'cpanp'                 => '1',
            'cpanp-run-perl'        => '1',
            'pod2latex'             => '1',
        }
    },
    5.019001 => {
        delta_from => 5.019000,
        changed => {
        },
        removed => {
        }
    },
    5.019002 => {
        delta_from => 5.019001,
        changed => {
        },
        removed => {
        }
    },
    5.019003 => {
        delta_from => 5.019002,
        changed => {
        },
        removed => {
        }
    },
    5.019004 => {
        delta_from => 5.019003,
        changed => {
        },
        removed => {
        }
    },
    5.019005 => {
        delta_from => 5.019004,
        changed => {
        },
        removed => {
        }
    },
    5.019006 => {
        delta_from => 5.019005,
        changed => {
        },
        removed => {
        }
    },
    5.019007 => {
        delta_from => 5.019006,
        changed => {
        },
        removed => {
        }
    },
    5.019008 => {
        delta_from => 5.019007,
        changed => {
        },
        removed => {
        }
    },
    5.019009 => {
        delta_from => 5.019008,
        changed => {
        },
        removed => {
        }
    },
    5.019010 => {
        delta_from => 5.019009,
        changed => {
        },
        removed => {
        }
    },
    5.019011 => {
        delta_from => 5.019010,
        changed => {
        },
        removed => {
        }
    },
    5.020000 => {
        delta_from => 5.019011,
        changed => {
        },
        removed => {
        }
    },
    5.021000 => {
        delta_from => 5.020000,
        changed => {
        },
        removed => {
        }
    },
    5.021001 => {
        delta_from => 5.021000,
        changed => {
        },
        removed => {
            'a2p'                   => 1,
            'config_data'           => 1,
            'find2perl'             => 1,
            'psed'                  => 1,
            's2p'                   => 1,
        }
    },
    5.021002 => {
        delta_from => 5.021001,
        changed => {
        },
        removed => {
        }
    },
    5.021003 => {
        delta_from => 5.021002,
        changed => {
        },
        removed => {
        }
    },
    5.020001 => {
        delta_from => 5.02,
        changed => {
        },
        removed => {
        }
    },
    5.021004 => {
        delta_from => 5.021003,
        changed => {
        },
        removed => {
        }
    },
    5.021005 => {
        delta_from => 5.021004,
        changed => {
        },
        removed => {
        }
    },
    5.021006 => {
        delta_from => 5.021005,
        changed => {
        },
        removed => {
        }
    },
    5.021007 => {
        delta_from => 5.021006,
        changed => {
        },
        removed => {
        }
    },
    5.021008 => {
        delta_from => 5.021007,
        changed => {
        },
        removed => {
        }
    },
    5.020002 => {
        delta_from => 5.020001,
        changed => {
        },
        removed => {
        }
    },
    5.021009 => {
        delta_from => 5.021008,
        changed => {
            'encguess'              => '1',
        },
        removed => {
        }
    },
    5.021010 => {
        delta_from => 5.021009,
        changed => {
        },
        removed => {
        }
    },
    5.021011 => {
        delta_from => 5.02101,
        changed => {
        },
        removed => {
        }
    },
    5.022000 => {
        delta_from => 5.021011,
        changed => {
        },
        removed => {
        }
    },
);

for my $version (sort { $a <=> $b } keys %delta) {
    my $data = $delta{$version};

    tie %{$utilities{$version}}, 'Module::CoreList::TieHashDelta',
        $data->{changed}, $data->{removed},
        $data->{delta_from} ? $utilities{$data->{delta_from}} : undef;
}

# Create aliases with trailing zeros for $] use

$utilities{'5.000'} = $utilities{5};

_create_aliases(\%utilities);

sub _create_aliases {
    my ($hash) = @_;

    for my $version (keys %$hash) {
        next unless $version >= 5.010;

        my $padded = sprintf "%0.6f", $version;

        # If the version in string form isn't the same as the numeric version,
        # alias it.
        if ($padded ne $version && $version == $padded) {
            $hash->{$padded} = $hash->{$version};
        }
    }
}

'foo';

=pod

=head1 NAME

Module::CoreList::Utils - what utilities shipped with versions of perl

=head1 SYNOPSIS

 use Module::CoreList::Utils;

 print $Module::CoreList::Utils::utilities{5.009003}{ptar}; # prints 1

 print Module::CoreList::Utils->first_release('corelist');           # prints 5.008009
 print Module::CoreList::Utils->first_release_by_date('corelist');   # prints 5.009002

=head1 DESCRIPTION

Module::CoreList::Utils provides information on which core and dual-life utilities shipped
with each version of L<perl>.

It provides a number of mechanisms for querying this information.

There is a functional programming API available for programmers to query
information.

Programmers may also query the contained hash structure to find relevant
information.

=head1 FUNCTIONS API

These are the functions that are available, they may either be called as functions or class methods:

  Module::CoreList::Utils::first_release('corelist'); # as a function

  Module::CoreList::Utils->first_release('corelist'); # class method

=over

=item C<utilities>

Requires a perl version as an argument, returns a list of utilities that shipped with
that version of perl, or undef/empty list if that perl doesn't exist.

=item C<first_release( UTILITY )>

Requires a UTILITY name as an argument, returns the perl version when that utility first
appeared in core as ordered by perl version number or undef ( in scalar context )
or an empty list ( in list context ) if that utility is not in core.

=item C<first_release_by_date( UTILITY )>

Requires a UTILITY name as an argument, returns the perl version when that utility first
appeared in core as ordered by release date or undef ( in scalar context )
or an empty list ( in list context ) if that utility is not in core.

=item C<removed_from( UTILITY )>

Takes a UTILITY name as an argument, returns the first perl version where that utility
was removed from core. Returns undef if the given utility was never in core or remains
in core.

=item C<removed_from_by_date( UTILITY )>

Takes a UTILITY name as an argument, returns the first perl version by release date where that
utility was removed from core. Returns undef if the given utility was never in core or remains
in core.

=back

=head1 DATA STRUCTURES

These are the hash data structures that are available:

=over

=item C<%Module::CoreList::Utils::utilities>

A hash of hashes that is keyed on perl version as indicated
in $].  The second level hash is utility / defined pairs.

=back

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

Currently maintained by the perl 5 porters E<lt>perl5-porters@perl.orgE<gt>.

This module is the result of archaeology undertaken during QA Hackathon
in Lancaster, April 2013.

=head1 LICENSE

Copyright (C) 2013 Chris Williams.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<corelist>, L<Module::CoreList>, L<perl>, L<http://perlpunks.de/corelist>

=cut
