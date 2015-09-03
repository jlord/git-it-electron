package Locale::Codes::LangExt;
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
use Locale::Codes::LangExt_Codes;
use Locale::Codes::LangExt_Retired;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.34';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2langext
                langext2code
                all_langext_codes
                all_langext_names
                langext_code2code
                LOCALE_LANGEXT_ALPHA
               );

sub code2langext {
   return Locale::Codes::_code2name('langext',@_);
}

sub langext2code {
   return Locale::Codes::_name2code('langext',@_);
}

sub langext_code2code {
   return Locale::Codes::_code2code('langext',@_);
}

sub all_langext_codes {
   return Locale::Codes::_all_codes('langext',@_);
}

sub all_langext_names {
   return Locale::Codes::_all_names('langext',@_);
}

sub rename_langext {
   return Locale::Codes::_rename('langext',@_);
}

sub add_langext {
   return Locale::Codes::_add_code('langext',@_);
}

sub delete_langext {
   return Locale::Codes::_delete_code('langext',@_);
}

sub add_langext_alias {
   return Locale::Codes::_add_alias('langext',@_);
}

sub delete_langext_alias {
   return Locale::Codes::_delete_alias('langext',@_);
}

sub rename_langext_code {
   return Locale::Codes::_rename_code('langext',@_);
}

sub add_langext_code_alias {
   return Locale::Codes::_add_code_alias('langext',@_);
}

sub delete_langext_code_alias {
   return Locale::Codes::_delete_code_alias('langext',@_);
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
