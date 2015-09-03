package Locale::Codes;
# Copyright (C) 2001      Canon Research Centre Europe (CRE).
# Copyright (C) 2002-2009 Neil Bowers
# Copyright (c) 2010-2015 Sullivan Beck
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
require 5.006;
use warnings;

use Carp;
use Locale::Codes::Constants;

#=======================================================================
#       Public Global Variables
#=======================================================================

# This module is not called directly... %Data is filled in by the
# calling modules.

our($VERSION,%Data,%Retired);

# $Data{ TYPE }{ code2id   }{ CODESET } { CODE }  = [ ID, I ]
#              { id2code   }{ CODESET } { ID }    = CODE
#              { id2names  }{ ID }                = [ NAME, NAME, ... ]
#              { alias2id  }{ NAME }              = [ ID, I ]
#              { id        }                      = FIRST_UNUSED_ID
#              { codealias }{ CODESET } { ALIAS } = CODE
#
# $Retired{ TYPE }{ CODESET }{ code }{ CODE } = NAME
#                            { name }{ NAME } = [CODE,NAME]  (the key is lowercase)

$VERSION='3.34';

#=======================================================================
#
# _code ( TYPE,CODE,CODESET )
#
#=======================================================================

sub _code {
   return 1  if (@_ > 3);

   my($type,$code,$codeset) = @_;
   $code = ''  if (! $code);

   # Determine the codeset

   $codeset = $ALL_CODESETS{$type}{'default'}
     if (! defined($codeset)  ||  $codeset eq '');
   $codeset = lc($codeset);
   return 1  if (! exists $ALL_CODESETS{$type}{'codesets'}{$codeset});
   return (0,$code,$codeset)  if (! $code);

   # Determine the properties of the codeset

   my($op,@args) = @{ $ALL_CODESETS{$type}{'codesets'}{$codeset} };

   if      ($op eq 'lc') {
      $code = lc($code);

   } elsif ($op eq 'uc') {
      $code = uc($code);

   } elsif ($op eq 'ucfirst') {
      $code = ucfirst(lc($code));

   } elsif ($op eq 'numeric') {
      return (1)  unless ($code =~ /^\d+$/);
      my $l = $args[0];
      $code    = sprintf("%.${l}d", $code);
   }

   return (0,$code,$codeset);
}

#=======================================================================
#
# _code2name ( TYPE,CODE [,CODESET] [,'retired'] )
#
#=======================================================================

sub _code2name {
   my($type,@args)         = @_;
   my $retired             = 0;
   if (@args > 0  &&  $args[$#args]  &&  $args[$#args] eq 'retired') {
      pop(@args);
      $retired             = 1;
   }

   my($err,$code,$codeset) = _code($type,@args);
   return undef  if ($err  ||
                     ! defined $code);

   $code = $Data{$type}{'codealias'}{$codeset}{$code}
     if (exists $Data{$type}{'codealias'}{$codeset}{$code});

   if (exists $Data{$type}{'code2id'}{$codeset}  &&
       exists $Data{$type}{'code2id'}{$codeset}{$code}) {
      my ($id,$i) = @{ $Data{$type}{'code2id'}{$codeset}{$code} };
      my $name    = $Data{$type}{'id2names'}{$id}[$i];
      return $name;

   } elsif ($retired  &&  exists $Retired{$type}{$codeset}{'code'}{$code}) {
      return $Retired{$type}{$codeset}{'code'}{$code};

   } else {
      return undef;
   }
}

#=======================================================================
#
# _name2code ( TYPE,NAME [,CODESET] [,'retired'] )
#
#=======================================================================

sub _name2code {
   my($type,$name,@args)   = @_;
   return undef  if (! $name);
   $name                   = lc($name);

   my $retired             = 0;
   if (@args > 0  &&  $args[$#args]  &&  $args[$#args] eq 'retired') {
      pop(@args);
      $retired             = 1;
   }

   my($err,$tmp,$codeset) = _code($type,'',@args);
   return undef  if ($err);

   if (exists $Data{$type}{'alias2id'}{$name}) {
      my $id = $Data{$type}{'alias2id'}{$name}[0];
      if (exists $Data{$type}{'id2code'}{$codeset}{$id}) {
         return $Data{$type}{'id2code'}{$codeset}{$id};
      }

   } elsif ($retired  &&  exists $Retired{$type}{$codeset}{'name'}{$name}) {
      return $Retired{$type}{$codeset}{'name'}{$name}[0];
   }

   return undef;
}

#=======================================================================
#
# _code2code ( TYPE,CODE,CODESET )
#
#=======================================================================

sub _code2code {
   my($type,@args) = @_;
   (@args == 3) or croak "${type}_code2code() takes 3 arguments!";

   my($code,$inset,$outset) = @args;
   my($err,$tmp);
   ($err,$code,$inset) = _code($type,$code,$inset);
   return undef  if ($err);
   ($err,$tmp,$outset) = _code($type,'',$outset);
   return undef  if ($err);

   my $name    = _code2name($type,$code,$inset);
   my $outcode = _name2code($type,$name,$outset);
   return $outcode;
}

#=======================================================================
#
# _all_codes ( TYPE [,CODESET] [,'retired'] )
#
#=======================================================================

sub _all_codes {
   my($type,@args)         = @_;
   my $retired             = 0;
   if (@args > 0  &&  $args[$#args]  &&  $args[$#args] eq 'retired') {
      pop(@args);
      $retired             = 1;
   }

   my ($err,$tmp,$codeset) = _code($type,'',@args);
   return ()  if ($err);

   if (! exists $Data{$type}{'code2id'}{$codeset}) {
      return ();
   }
   my @codes = keys %{ $Data{$type}{'code2id'}{$codeset} };
   push(@codes,keys %{ $Retired{$type}{$codeset}{'code'} })  if ($retired);
   return (sort @codes);
}

#=======================================================================
#
# _all_names ( TYPE [,CODESET] [,'retired'] )
#
#=======================================================================

sub _all_names {
   my($type,@args)         = @_;
   my $retired             = 0;
   if (@args > 0  &&  $args[$#args]  &&  $args[$#args] eq 'retired') {
      pop(@args);
      $retired             = 1;
   }

   my ($err,$tmp,$codeset) = _code($type,'',@args);
   return ()  if ($err);

   my @codes = _all_codes($type,$codeset);
   my @names;

   foreach my $code (@codes) {
      my($id,$i) = @{ $Data{$type}{'code2id'}{$codeset}{$code} };
      my $name   = $Data{$type}{'id2names'}{$id}[$i];
      push(@names,$name);
   }
   if ($retired) {
      foreach my $lc (keys %{ $Retired{$type}{$codeset}{'name'} }) {
         my $name = $Retired{$type}{$codeset}{'name'}{$lc}[1];
         push @names,$name;
      }
   }
   return (sort @names);
}

#=======================================================================
#
# _rename ( TYPE,CODE,NAME,CODESET )
#
# Change the official name for a code. The original is retained
# as an alias, but the new name will be returned if you lookup the
# name from code.
#
#=======================================================================

sub _rename {
   my($type,$code,$new_name,@args) = @_;

   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");

   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($type,$code,$codeset);

   if (! $codeset) {
      carp "rename_$type(): unknown codeset\n"  unless ($nowarn);
      return 0;
   }

   $code = $Data{$type}{'codealias'}{$codeset}{$code}
     if (exists $Data{$type}{'codealias'}{$codeset}{$code});

   # Check that $code exists in the codeset.

   my $id;
   if (exists $Data{$type}{'code2id'}{$codeset}{$code}) {
      $id = $Data{$type}{'code2id'}{$codeset}{$code}[0];
   } else {
      carp "rename_$type(): unknown code: $code\n"  unless ($nowarn);
      return 0;
   }

   # Cases:
   #   1. Renaming to a name which exists with a different ID
   #      Error
   #
   #   2. Renaming to a name which exists with the same ID
   #      Just change code2id (I value)
   #
   #   3. Renaming to a new name
   #      Create a new alias
   #      Change code2id (I value)

   if (exists $Data{$type}{'alias2id'}{lc($new_name)}) {
      # Existing name (case 1 and 2)

      my ($new_id,$i) = @{ $Data{$type}{'alias2id'}{lc($new_name)} };
      if ($new_id != $id) {
         # Case 1
         carp "rename_$type(): rename to an existing $type not allowed\n"
           unless ($nowarn);
         return 0;
      }

      # Case 2

      $Data{$type}{'code2id'}{$codeset}{$code}[1] = $i;

   } else {

      # Case 3

      push @{ $Data{$type}{'id2names'}{$id} },$new_name;
      my $i = $#{ $Data{$type}{'id2names'}{$id} };
      $Data{$type}{'alias2id'}{lc($new_name)} = [ $id,$i ];
      $Data{$type}{'code2id'}{$codeset}{$code}[1] = $i;
   }

   return 1;
}

#=======================================================================
#
# _add_code ( TYPE,CODE,NAME,CODESET )
#
# Add a new code to the codeset. Both CODE and NAME must be
# unused in the code set.
#
#=======================================================================

sub _add_code {
   my($type,$code,$name,@args) = @_;

   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");

   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($type,$code,$codeset);

   if (! $codeset) {
      carp "add_$type(): unknown codeset\n"  unless ($nowarn);
      return 0;
   }

   # Check that $code is unused.

   if (exists $Data{$type}{'code2id'}{$codeset}{$code}  ||
       exists $Data{$type}{'codealias'}{$codeset}{$code}) {
      carp "add_$type(): code already in use: $code\n"  unless ($nowarn);
      return 0;
   }

   # Check to see that $name is unused in this code set.  If it is
   # used (but not in this code set), we'll use that ID.  Otherwise,
   # we'll need to get the next available ID.

   my ($id,$i);
   if (exists $Data{$type}{'alias2id'}{lc($name)}) {
      ($id,$i) = @{ $Data{$type}{'alias2id'}{lc($name)} };
      if (exists $Data{$type}{'id2code'}{$codeset}{$id}) {
         carp "add_$type(): name already in use: $name\n"  unless ($nowarn);
         return 0;
      }

   } else {
      $id = $Data{$type}{'id'}++;
      $i  = 0;
      $Data{$type}{'alias2id'}{lc($name)} = [ $id,$i ];
      $Data{$type}{'id2names'}{$id}       = [ $name ];
   }

   # Add the new code

   $Data{$type}{'code2id'}{$codeset}{$code} = [ $id,$i ];
   $Data{$type}{'id2code'}{$codeset}{$id}   = $code;

   return 1;
}

#=======================================================================
#
# _delete_code ( TYPE,CODE,CODESET )
#
# Delete a code from the codeset.
#
#=======================================================================

sub _delete_code {
   my($type,$code,@args) = @_;

   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");

   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset) = _code($type,$code,$codeset);

   if (! $codeset) {
      carp "delete_$type(): unknown codeset\n"  unless ($nowarn);
      return 0;
   }

   $code = $Data{$type}{'codealias'}{$codeset}{$code}
     if (exists $Data{$type}{'codealias'}{$codeset}{$code});

   # Check that $code is valid.

   if (! exists $Data{$type}{'code2id'}{$codeset}{$code}) {
      carp "delete_$type(): code does not exist: $code\n"  unless ($nowarn);
      return 0;
   }

   # Delete the code

   my $id = $Data{$type}{'code2id'}{$codeset}{$code}[0];
   delete $Data{$type}{'code2id'}{$codeset}{$code};
   delete $Data{$type}{'id2code'}{$codeset}{$id};

   # Delete any aliases that are linked to this code

   foreach my $alias (keys %{ $Data{$type}{'codealias'}{$codeset} }) {
      next  if ($Data{$type}{'codealias'}{$codeset}{$alias} ne $code);
      delete $Data{$type}{'codealias'}{$codeset}{$alias};
   }

   # If this ID is not used in any other codeset, delete it completely.

   foreach my $c (keys %{ $Data{$type}{'id2code'} }) {
      return 1  if (exists $Data{$type}{'id2code'}{$c}{$id});
   }

   my @names = @{ $Data{$type}{'id2names'}{$id} };
   delete $Data{$type}{'id2names'}{$id};

   foreach my $name (@names) {
      delete $Data{$type}{'alias2id'}{lc($name)};
   }

   return 1;
}

#=======================================================================
#
# _add_alias ( TYPE,NAME,NEW_NAME )
#
# Add a new alias. NAME must exist, and NEW_NAME must be unused.
#
#=======================================================================

sub _add_alias {
   my($type,$name,$new_name,$nowarn) = @_;

   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   # Check that $name is used and $new_name is new.

   my($id);
   if (exists $Data{$type}{'alias2id'}{lc($name)}) {
      $id = $Data{$type}{'alias2id'}{lc($name)}[0];
   } else {
      carp "add_${type}_alias(): name does not exist: $name\n"  unless ($nowarn);
      return 0;
   }

   if (exists $Data{$type}{'alias2id'}{lc($new_name)}) {
      carp "add_${type}_alias(): alias already in use: $new_name\n"  unless ($nowarn);
      return 0;
   }

   # Add the new alias

   push @{ $Data{$type}{'id2names'}{$id} },$new_name;
   my $i = $#{ $Data{$type}{'id2names'}{$id} };
   $Data{$type}{'alias2id'}{lc($new_name)} = [ $id,$i ];

   return 1;
}

#=======================================================================
#
# _delete_alias ( TYPE,NAME )
#
# This deletes a name from the list of names used by an element.
# NAME must be used, but must NOT be the only name in the list.
#
# Any id2name that references this name will be changed to
# refer to the first name in the list.
#
#=======================================================================

sub _delete_alias {
   my($type,$name,$nowarn) = @_;

   $nowarn   = (defined($nowarn)  &&  $nowarn eq "nowarn" ? 1 : 0);

   # Check that $name is used.

   my($id,$i);
   if (exists $Data{$type}{'alias2id'}{lc($name)}) {
      ($id,$i) = @{ $Data{$type}{'alias2id'}{lc($name)} };
   } else {
      carp "delete_${type}_alias(): name does not exist: $name\n"  unless ($nowarn);
      return 0;
   }

   my $n = $#{ $Data{$type}{'id2names'}{$id} } + 1;
   if ($n == 1) {
      carp "delete_${type}_alias(): only one name defined (use _delete_${type} instead)\n"
        unless ($nowarn);
      return 0;
   }

   # Delete the alias.

   splice (@{ $Data{$type}{'id2names'}{$id} },$i,1);
   delete $Data{$type}{'alias2id'}{lc($name)};

   # Every element that refers to this ID:
   #   Ignore     if I < $i
   #   Set to 0   if I = $i
   #   Decrement  if I > $i

   foreach my $codeset (keys %{ $Data{'code2id'} }) {
      foreach my $code (keys %{ $Data{'code2id'}{$codeset} }) {
         my($jd,$j) = @{ $Data{'code2id'}{$codeset}{$code} };
         next  if ($jd ne $id  ||
                   $j < $i);
         if ($i == $j) {
            $Data{'code2id'}{$codeset}{$code}[1] = 0;
         } else {
            $Data{'code2id'}{$codeset}{$code}[1]--;
         }
      }
   }

   return 1;
}

#=======================================================================
#
# _rename_code ( TYPE,CODE,NEW_CODE,CODESET )
#
# Change the official code. The original is retained as an alias, but
# the new name will be returned if you lookup the code from name.
#
#=======================================================================

sub _rename_code {
   my($type,$code,$new_code,@args) = @_;

   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");

   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($type,$code,$codeset);
   ($err,$new_code,$codeset) = _code($type,$new_code,$codeset)
     if (! $err);

   if (! $codeset) {
      carp "rename_$type(): unknown codeset\n"  unless ($nowarn);
      return 0;
   }

   $code = $Data{$type}{'codealias'}{$codeset}{$code}
     if (exists $Data{$type}{'codealias'}{$codeset}{$code});

   # Check that $code exists in the codeset.

   if (! exists $Data{$type}{'code2id'}{$codeset}{$code}) {
      carp "rename_$type(): unknown code: $code\n"  unless ($nowarn);
      return 0;
   }

   # Cases:
   #   1. Renaming code to an existing alias of this code:
   #      Make the alias real and the code an alias
   #
   #   2. Renaming code to some other existing alias:
   #      Error
   #
   #   3. Renaming code to some other code:
   #      Error (
   #
   #   4. Renaming code to a new code:
   #      Make code into an alias
   #      Replace code with new_code.

   if (exists $Data{$type}{'codealias'}{$codeset}{$new_code}) {
      # Cases 1 and 2
      if ($Data{$type}{'codealias'}{$codeset}{$new_code} eq $code) {
         # Case 1

         delete $Data{$type}{'codealias'}{$codeset}{$new_code};

      } else {
         # Case 2
         carp "rename_$type(): new code already in use: $new_code\n"  unless ($nowarn);
         return 0;
      }

   } elsif (exists $Data{$type}{'code2id'}{$codeset}{$new_code}) {
      # Case 3
      carp "rename_$type(): new code already in use: $new_code\n"  unless ($nowarn);
      return 0;
   }

   # Cases 1 and 4

   $Data{$type}{'codealias'}{$codeset}{$code} = $new_code;

   my $id = $Data{$type}{'code2id'}{$codeset}{$code}[0];
   $Data{$type}{'code2id'}{$codeset}{$new_code} = $Data{$type}{'code2id'}{$codeset}{$code};
   delete $Data{$type}{'code2id'}{$codeset}{$code};

   $Data{$type}{'id2code'}{$codeset}{$id} = $new_code;

   return 1;
}

#=======================================================================
#
# _add_code_alias ( TYPE,CODE,NEW_CODE,CODESET )
#
# Adds an alias for the code.
#
#=======================================================================

sub _add_code_alias {
   my($type,$code,$new_code,@args) = @_;

   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");

   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = _code($type,$code,$codeset);
   ($err,$new_code,$codeset) = _code($type,$new_code,$codeset)
     if (! $err);

   if (! $codeset) {
      carp "add_${type}_code_alias(): unknown codeset\n"  unless ($nowarn);
      return 0;
   }

   $code = $Data{$type}{'codealias'}{$codeset}{$code}
     if (exists $Data{$type}{'codealias'}{$codeset}{$code});

   # Check that $code exists in the codeset and that $new_code
   # does not exist.

   if (! exists $Data{$type}{'code2id'}{$codeset}{$code}) {
      carp "add_${type}_code_alias(): unknown code: $code\n"  unless ($nowarn);
      return 0;
   }

   if (exists $Data{$type}{'code2id'}{$codeset}{$new_code}  ||
       exists $Data{$type}{'codealias'}{$codeset}{$new_code}) {
      carp "add_${type}_code_alias(): code already in use: $new_code\n"  unless ($nowarn);
      return 0;
   }

   # Add the alias

   $Data{$type}{'codealias'}{$codeset}{$new_code} = $code;

   return 1;
}

#=======================================================================
#
# _delete_code_alias ( TYPE,CODE,CODESET )
#
# Deletes an alias for the code.
#
#=======================================================================

sub _delete_code_alias {
   my($type,$code,@args) = @_;

   my $nowarn   = 0;
   $nowarn      = 1, pop(@args)  if (@args  &&  $args[$#args] eq "nowarn");

   my $codeset  = shift(@args);
   my $err;
   ($err,$code,$codeset)     = Locale::Codes::_code($type,$code,$codeset);

   if (! $codeset) {
      carp "delete_${type}_code_alias(): unknown codeset\n"  unless ($nowarn);
      return 0;
   }

   # Check that $code exists in the codeset as an alias.

   if (! exists $Data{$type}{'codealias'}{$codeset}{$code}) {
      carp "delete_${type}_code_alias(): no alias defined: $code\n"  unless ($nowarn);
      return 0;
   }

   # Delete the alias

   delete $Data{$type}{'codealias'}{$codeset}{$code};

   return 1;
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
