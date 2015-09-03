package Locale::Codes::Language;
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
use Locale::Codes::Language_Codes;
use Locale::Codes::Language_Retired;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.34';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2language
                language2code
                all_language_codes
                all_language_names
                language_code2code
                LOCALE_LANG_ALPHA_2
                LOCALE_LANG_ALPHA_3
                LOCALE_LANG_TERM
               );

sub code2language {
   return Locale::Codes::_code2name('language',@_);
}

sub language2code {
   return Locale::Codes::_name2code('language',@_);
}

sub language_code2code {
   return Locale::Codes::_code2code('language',@_);
}

sub all_language_codes {
   return Locale::Codes::_all_codes('language',@_);
}

sub all_language_names {
   return Locale::Codes::_all_names('language',@_);
}

sub rename_language {
   return Locale::Codes::_rename('language',@_);
}

sub add_language {
   return Locale::Codes::_add_code('language',@_);
}

sub delete_language {
   return Locale::Codes::_delete_code('language',@_);
}

sub add_language_alias {
   return Locale::Codes::_add_alias('language',@_);
}

sub delete_language_alias {
   return Locale::Codes::_delete_alias('language',@_);
}

sub rename_language_code {
   return Locale::Codes::_rename_code('language',@_);
}

sub add_language_code_alias {
   return Locale::Codes::_add_code_alias('language',@_);
}

sub delete_language_code_alias {
   return Locale::Codes::_delete_code_alias('language',@_);
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
