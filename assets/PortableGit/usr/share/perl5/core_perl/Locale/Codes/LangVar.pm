package Locale::Codes::LangVar;
# Copyright (c) 2011-2015 Sullivan Beck
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
require 5.006;
use warnings;

require Exporter;
use Carp;
use Locale::Codes;
use Locale::Codes::Constants;
use Locale::Codes::LangVar_Codes;
use Locale::Codes::LangVar_Retired;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.34';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2langvar
                langvar2code
                all_langvar_codes
                all_langvar_names
                langvar_code2code
                LOCALE_LANGVAR_ALPHA
               );

sub code2langvar {
   return Locale::Codes::_code2name('langvar',@_);
}

sub langvar2code {
   return Locale::Codes::_name2code('langvar',@_);
}

sub langvar_code2code {

   return Locale::Codes::_code2code('langvar',@_);
}

sub all_langvar_codes {
   return Locale::Codes::_all_codes('langvar',@_);
}

sub all_langvar_names {
   return Locale::Codes::_all_names('langvar',@_);
}

sub rename_langvar {
   return Locale::Codes::_rename('langvar',@_);
}

sub add_langvar {
   return Locale::Codes::_add_code('langvar',@_);
}

sub delete_langvar {
   return Locale::Codes::_delete_code('langvar',@_);
}

sub add_langvar_alias {
   return Locale::Codes::_add_alias('langvar',@_);
}

sub delete_langvar_alias {
   return Locale::Codes::_delete_alias('langvar',@_);
}

sub rename_langvar_code {
   return Locale::Codes::_rename_code('langvar',@_);
}

sub add_langvar_code_alias {
   return Locale::Codes::_add_code_alias('langvar',@_);
}

sub delete_langvar_code_alias {
   return Locale::Codes::_delete_code_alias('langvar',@_);
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
