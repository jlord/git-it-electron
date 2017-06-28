package Locale::Codes::LangFam;
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
use Locale::Codes::LangFam_Codes;
use Locale::Codes::LangFam_Retired;

#=======================================================================
#       Public Global Variables
#=======================================================================

our($VERSION,@ISA,@EXPORT,@EXPORT_OK);

$VERSION='3.34';
@ISA       = qw(Exporter);
@EXPORT    = qw(code2langfam
                langfam2code
                all_langfam_codes
                all_langfam_names
                langfam_code2code
                LOCALE_LANGFAM_ALPHA
               );

sub code2langfam {
   return Locale::Codes::_code2name('langfam',@_);
}

sub langfam2code {
   return Locale::Codes::_name2code('langfam',@_);
}

sub langfam_code2code {
   return Locale::Codes::_code2code('langfam',@_);
}

sub all_langfam_codes {
   return Locale::Codes::_all_codes('langfam',@_);
}

sub all_langfam_names {
   return Locale::Codes::_all_names('langfam',@_);
}

sub rename_langfam {
   return Locale::Codes::_rename('langfam',@_);
}

sub add_langfam {
   return Locale::Codes::_add_code('langfam',@_);
}

sub delete_langfam {
   return Locale::Codes::_delete_code('langfam',@_);
}

sub add_langfam_alias {
   return Locale::Codes::_add_alias('langfam',@_);
}

sub delete_langfam_alias {
   return Locale::Codes::_delete_alias('langfam',@_);
}

sub rename_langfam_code {
   return Locale::Codes::_rename_code('langfam',@_);
}

sub add_langfam_code_alias {
   return Locale::Codes::_add_code_alias('langfam',@_);
}

sub delete_langfam_code_alias {
   return Locale::Codes::_delete_code_alias('langfam',@_);
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
