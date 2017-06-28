package deprecate;
use strict;
use warnings;
our $VERSION = 0.03;

# our %Config can ignore %Config::Config, e.g. for testing
our %Config;
unless (%Config) { require Config; *Config = \%Config::Config; }

# This isn't a public API. It's internal to code maintained by the perl-porters
# If you would like it to be a public API, please send a patch with
# documentation and tests. Until then, it may change without warning.
sub __loaded_from_core {
    my ($package, $file, $expect_leaf) = @_;

    foreach my $pair ([qw(sitearchexp archlibexp)],
		      [qw(sitelibexp privlibexp)]) {
	my ($site, $priv) = @Config{@$pair};
	if ($^O eq 'VMS') {
	    for my $d ($site, $priv) { $d = VMS::Filespec::unixify($d) };
	}
	# Just in case anyone managed to configure with trailing /s
	s!/*$!!g foreach $site, $priv;

	next if $site eq $priv;
	if (uc("$priv/$expect_leaf") eq uc($file)) {
	    return 1;
	}
    }
    return 0;
}

sub import {
    my ($package, $file) = caller;

    my $expect_leaf = "$package.pm";
    $expect_leaf =~ s!::!/!g;

    if (__loaded_from_core($package, $file, $expect_leaf)) {
	my $call_depth=1;
	my @caller;
	while (@caller = caller $call_depth++) {
	    last if $caller[7]			# use/require
		and $caller[6] eq $expect_leaf;	# the package file
	}
	unless (@caller) {
	    require Carp;
	    Carp::cluck(<<"EOM");
Can't find use/require $expect_leaf in caller stack
EOM
	    return;
	}

	# This is fragile, because it
	# is directly poking in the internals of warnings.pm
	my ($call_file, $call_line, $callers_bitmask) = @caller[1,2,9];

	if (defined $callers_bitmask
	    && (vec($callers_bitmask, $warnings::Offsets{deprecated}, 1)
		|| vec($callers_bitmask, $warnings::Offsets{all}, 1))) {
	    warn <<"EOM";
$package will be removed from the Perl core distribution in the next major release. Please install it from CPAN. It is being used at $call_file, line $call_line.
EOM
	}
    }
}

1;

__END__

=head1 NAME

deprecate - Perl pragma for deprecating the core version of a module

=head1 SYNOPSIS

    use deprecate;  # always deprecate the module in which this occurs

    use if $] > 5.010, 'deprecate'; # conditionally deprecate the module


=head1 DESCRIPTION

This module is used using C<use deprecate;> (or something that calls
C<< deprecate->import() >>, for example C<use if COND, deprecate;>).

If the module that includes C<use deprecate> is located in a core library
directory, a deprecation warning is issued, encouraging the user to use
the version on CPAN.  If that module is located in a site library, it is
the CPAN version, and no warning is issued.

=head2 EXPORT

None by default.  The only method is C<import>, called by C<use deprecate;>.


=head1 SEE ALSO

First example to C<use deprecate;> was L<Switch>.


=head1 AUTHOR

Original version by Nicholas Clark


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2011

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
