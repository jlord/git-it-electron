package Pod::Perldoc::ToTerm;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '3.25';

use parent qw(Pod::Perldoc::BaseTo);

sub is_pageable        { 1 }
sub write_with_binmode { 0 }
sub output_extension   { 'txt' }

use Pod::Text::Termcap ();

sub alt       { shift->_perldoc_elem('alt'     , @_) }
sub indent    { shift->_perldoc_elem('indent'  , @_) }
sub loose     { shift->_perldoc_elem('loose'   , @_) }
sub quotes    { shift->_perldoc_elem('quotes'  , @_) }
sub sentence  { shift->_perldoc_elem('sentence', @_) }
sub width     { 
    my $self = shift;
    $self->_perldoc_elem('width' , @_) ||
    $self->_get_columns_from_manwidth  ||
	$self->_get_columns_from_stty      ||
	$self->_get_default_width;
}

sub _get_stty { `stty -a` }

sub _get_columns_from_stty {
	my $output = $_[0]->_get_stty;

	if(    $output =~ /\bcolumns\s+(\d+)/ )    { return $1; }
	elsif( $output =~ /;\s*(\d+)\s+columns;/ ) { return $1; }
	else                                       { return  0 }
	}

sub _get_columns_from_manwidth {
	my( $self ) = @_;

	return 0 unless defined $ENV{MANWIDTH};

	unless( $ENV{MANWIDTH} =~ m/\A\d+\z/ ) {
		$self->warn( "Ignoring non-numeric MANWIDTH ($ENV{MANWIDTH})\n" );
		return 0;
		}

	if( $ENV{MANWIDTH} == 0 ) {
		$self->warn( "Ignoring MANWIDTH of 0. Really? Why even run the program? :)\n" );
		return 0;
		}

	if( $ENV{MANWIDTH} =~ m/\A(\d+)\z/ ) { return $1 }

	return 0;
	}

sub _get_default_width {
	76
	}


sub new { return bless {}, ref($_[0]) || $_[0] }

sub parse_from_file {
  my $self = shift;

  $self->{width} = $self->width();

  my @options =
    map {; $_, $self->{$_} }
      grep !m/^_/s,
        keys %$self
  ;

  defined(&Pod::Perldoc::DEBUG)
   and Pod::Perldoc::DEBUG()
   and print "About to call new Pod::Text::Termcap ",
    $Pod::Text::VERSION ? "(v$Pod::Text::Termcap::VERSION) " : '',
    "with options: ",
    @options ? "[@options]" : "(nil)", "\n";
  ;

  Pod::Text::Termcap->new(@options)->parse_from_file(@_);
}

1;

=head1 NAME

Pod::Perldoc::ToTerm - render Pod with terminal escapes 

=head1 SYNOPSIS

  perldoc -o term Some::Modulename

=head1 DESCRIPTION

This is a "plug-in" class that allows Perldoc to use
Pod::Text as a formatter class.

It supports the following options, which are explained in
L<Pod::Text>: alt, indent, loose, quotes, sentence, width

For example:

  perldoc -o term -w indent:5 Some::Modulename

=head1 CAVEAT

This module may change to use a different text formatter class in the
future, and this may change what options are supported.

=head1 SEE ALSO

L<Pod::Text>, L<Pod::Text::Termcap>, L<Pod::Perldoc>

=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2011 Mark Allen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Mark Allen C<< <mallen@cpan.org> >>

=cut
