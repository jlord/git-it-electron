package Locale::Codes::Currency;
# Copyright (C) 2001      Canon Research Centre Europe (CRE).
# Copyright (C) 2002-2009 Neil Bowers
# Copyright (c) 2010-2015 Sullivan Beck
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
require 5.006;
use warnings;

require Exporter;
use Carp;
use Locale::Codes;
use Locale::Codes::Constants;
use Locale::Codes::Currency_Codes;
use Locale::Codes::Currency_Retired;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.34';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2currency
                currency2code
                all_currency_codes
                all_currency_names
                currency_code2code
                LOCALE_CURR_ALPHA
                LOCALE_CURR_NUMERIC
               );

sub code2currency {
   return Locale::Codes::_code2name('currency',@_);
}

sub currency2code {
   return Locale::Codes::_name2code('currency',@_);
}

sub currency_code2code {
   return Locale::Codes::_code2code('currency',@_);
}

sub all_currency_codes {
   return Locale::Codes::_all_codes('currency',@_);
}

sub all_currency_names {
   return Locale::Codes::_all_names('currency',@_);
}

sub rename_currency {
   return Locale::Codes::_rename('currency',@_);
}

sub add_currency {
   return Locale::Codes::_add_code('currency',@_);
}

sub delete_currency {
   return Locale::Codes::_delete_code('currency',@_);
}

sub add_currency_alias {
   return Locale::Codes::_add_alias('currency',@_);
}

sub delete_currency_alias {
   return Locale::Codes::_delete_alias('currency',@_);
}

sub rename_currency_code {
   return Locale::Codes::_rename_code('currency',@_);
}

sub add_currency_code_alias {
   return Locale::Codes::_add_code_alias('currency',@_);
}

sub delete_currency_code_alias {
   return Locale::Codes::_delete_code_alias('currency',@_);
}

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
