package Locale::Country;
# Copyright (C) 2001      Canon Research Centre Europe (CRE).
# Copyright (C) 2002-2009 Neil Bowers
# Copyright (c) 2010-2015 Sullivan Beck
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use warnings;
use Exporter;

our $VERSION;
$VERSION='3.34';

our (@ISA,@EXPORT);

my $backend     = 'Locale::Codes::Country';
my $backend_exp = $backend . "::EXPORT";

eval "require $backend; $backend->import(); return 1;";

{
   no strict 'refs';
   @EXPORT = @{ $backend_exp };
}

unshift (@ISA, $backend);

sub alias_code                { Locale::Codes::Country::alias_code(@_) }

sub rename_country            { Locale::Codes::Country::rename_country(@_) }
sub add_country               { Locale::Codes::Country::add_country(@_) }
sub delete_country            { Locale::Codes::Country::delete_country(@_) }
sub add_country_alias         { Locale::Codes::Country::add_country_alias(@_) }
sub delete_country_alias      { Locale::Codes::Country::delete_country_alias(@_) }
sub rename_country_code       { Locale::Codes::Country::rename_country_code(@_) }
sub add_country_code_alias    { Locale::Codes::Country::add_country_code_alias(@_) }
sub delete_country_code_alias { Locale::Codes::Country::delete_country_code_alias(@_) }

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:
