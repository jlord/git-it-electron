package Locale::Codes::Script;
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
use Locale::Codes::Script_Codes;
use Locale::Codes::Script_Retired;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.34';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2script
                script2code
                all_script_codes
                all_script_names
                script_code2code
                LOCALE_SCRIPT_ALPHA
                LOCALE_SCRIPT_NUMERIC
               );

sub code2script {
   return Locale::Codes::_code2name('script',@_);
}

sub script2code {
   return Locale::Codes::_name2code('script',@_);
}

sub script_code2code {
   return Locale::Codes::_code2code('script',@_);
}

sub all_script_codes {
   return Locale::Codes::_all_codes('script',@_);
}

sub all_script_names {
   return Locale::Codes::_all_names('script',@_);
}

sub rename_script {
   return Locale::Codes::_rename('script',@_);
}

sub add_script {
   return Locale::Codes::_add_code('script',@_);
}

sub delete_script {
   return Locale::Codes::_delete_code('script',@_);
}

sub add_script_alias {
   return Locale::Codes::_add_alias('script',@_);
}

sub delete_script_alias {
   return Locale::Codes::_delete_alias('script',@_);
}

sub rename_script_code {
   return Locale::Codes::_rename_code('script',@_);
}

sub add_script_code_alias {
   return Locale::Codes::_add_code_alias('script',@_);
}

sub delete_script_code_alias {
   return Locale::Codes::_delete_code_alias('script',@_);
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
