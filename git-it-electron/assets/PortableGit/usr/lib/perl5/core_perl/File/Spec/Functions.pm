package File::Spec::Functions;

use File::Spec;
use strict;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

$VERSION = '3.56';
$VERSION =~ tr/_//;

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw(
	canonpath
	catdir
	catfile
	curdir
	rootdir
	updir
	no_upwards
	file_name_is_absolute
	path
);

@EXPORT_OK = qw(
	devnull
	tmpdir
	splitpath
	splitdir
	catpath
	abs2rel
	rel2abs
	case_tolerant
);

%EXPORT_TAGS = ( ALL => [ @EXPORT_OK, @EXPORT ] );

require File::Spec::Unix;
my %udeps = (
    canonpath => [],
    catdir => [qw(canonpath)],
    catfile => [qw(canonpath catdir)],
    case_tolerant => [],
    curdir => [],
    devnull => [],
    rootdir => [],
    updir => [],
);

foreach my $meth (@EXPORT, @EXPORT_OK) {
    my $sub = File::Spec->can($meth);
    no strict 'refs';
    if (exists($udeps{$meth}) && $sub == File::Spec::Unix->can($meth) &&
	    !(grep {
		File::Spec->can($_) != File::Spec::Unix->can($_)
	    } @{$udeps{$meth}}) &&
	    defined(&{"File::Spec::Unix::_fn_$meth"})) {
	*{$meth} = \&{"File::Spec::Unix::_fn_$meth"};
    } else {
	*{$meth} = sub {&$sub('File::Spec', @_)};
    }
}


1;
__END__

=head1 NAME

File::Spec::Functions - portably perform operations on file names

=head1 SYNOPSIS

	use File::Spec::Functions;
	$x = catfile('a','b');

=head1 DESCRIPTION

This module exports convenience functions for all of the class methods
provided by File::Spec.

For a reference of available functions, please consult L<File::Spec::Unix>,
which contains the entire set, and which is inherited by the modules for
other platforms. For further information, please see L<File::Spec::Mac>,
L<File::Spec::OS2>, L<File::Spec::Win32>, or L<File::Spec::VMS>.

=head2 Exports

The following functions are exported by default.

	canonpath
	catdir
	catfile
	curdir
	rootdir
	updir
	no_upwards
	file_name_is_absolute
	path


The following functions are exported only by request.

	devnull
	tmpdir
	splitpath
	splitdir
	catpath
	abs2rel
	rel2abs
	case_tolerant

All the functions may be imported using the C<:ALL> tag.

=head1 COPYRIGHT

Copyright (c) 2004 by the Perl 5 Porters.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

File::Spec, File::Spec::Unix, File::Spec::Mac, File::Spec::OS2,
File::Spec::Win32, File::Spec::VMS, ExtUtils::MakeMaker

=cut

