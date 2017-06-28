package Locale::Codes::Country;
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
use Locale::Codes::Country_Codes;
use Locale::Codes::Country_Retired;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.34';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2country
                country2code
                all_country_codes
                all_country_names
                country_code2code
                LOCALE_CODE_ALPHA_2
                LOCALE_CODE_ALPHA_3
                LOCALE_CODE_NUMERIC
                LOCALE_CODE_DOM
               );

sub code2country {
   return Locale::Codes::_code2name('country',@_);
}

sub country2code {
   return Locale::Codes::_name2code('country',@_);
}

sub country_code2code {
   return Locale::Codes::_code2code('country',@_);
}

sub all_country_codes {
   return Locale::Codes::_all_codes('country',@_);
}

sub all_country_names {
   return Locale::Codes::_all_names('country',@_);
}

sub rename_country {
   return Locale::Codes::_rename('country',@_);
}

sub add_country {
   return Locale::Codes::_add_code('country',@_);
}

sub delete_country {
   return Locale::Codes::_delete_code('country',@_);
}

sub add_country_alias {
   return Locale::Codes::_add_alias('country',@_);
}

sub delete_country_alias {
   return Locale::Codes::_delete_alias('country',@_);
}

sub rename_country_code {
   return Locale::Codes::_rename_code('country',@_);
}

sub add_country_code_alias {
   return Locale::Codes::_add_code_alias('country',@_);
}

sub delete_country_code_alias {
   return Locale::Codes::_delete_code_alias('country',@_);
}

#=======================================================================
#
# Old function for backward compatibility
#
#=======================================================================

sub alias_code {
   my($alias,$code,@args) = @_;
   my $success = rename_country_code($code,$alias,@args);
   return 0  if (! $success);
   return $alias;
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
