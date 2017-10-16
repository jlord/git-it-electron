package Locale::Script;
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

my $backend     = 'Locale::Codes::Script';
my $backend_exp = $backend . "::EXPORT";

eval "require $backend; $backend->import(); return 1;";

{
   no strict 'refs';
   @EXPORT = @{ $backend_exp };
}

unshift (@ISA, $backend);

sub rename_script            { Locale::Codes::Script::rename_script(@_) }
sub add_script               { Locale::Codes::Script::add_script(@_) }
sub delete_script            { Locale::Codes::Script::delete_script(@_) }
sub add_script_alias         { Locale::Codes::Script::add_script_alias(@_) }
sub delete_script_alias      { Locale::Codes::Script::delete_script_alias(@_) }
sub rename_script_code       { Locale::Codes::Script::rename_script_code(@_) }
sub add_script_code_alias    { Locale::Codes::Script::add_script_code_alias(@_) }
sub delete_script_code_alias { Locale::Codes::Script::delete_script_code_alias(@_) }

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
