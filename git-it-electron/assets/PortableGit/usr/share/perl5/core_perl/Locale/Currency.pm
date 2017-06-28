package Locale::Currency;
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

my $backend     = 'Locale::Codes::Currency';
my $backend_exp = $backend . "::EXPORT";

eval "require $backend; $backend->import(); return 1;";

{
   no strict 'refs';
   @EXPORT = @{ $backend_exp };
}

unshift (@ISA, $backend);

sub rename_currency            { Locale::Codes::Currency::rename_currency(@_) }
sub add_currency               { Locale::Codes::Currency::add_currency(@_) }
sub delete_currency            { Locale::Codes::Currency::delete_currency(@_) }
sub add_currency_alias         { Locale::Codes::Currency::add_currency_alias(@_) }
sub delete_currency_alias      { Locale::Codes::Currency::delete_currency_alias(@_) }
sub rename_currency_code       { Locale::Codes::Currency::rename_currency_code(@_) }
sub add_currency_code_alias    { Locale::Codes::Currency::add_currency_code_alias(@_) }
sub delete_currency_code_alias { Locale::Codes::Currency::delete_currency_code_alias(@_) }

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
