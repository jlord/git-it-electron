package ExtUtils::Embed;
require Exporter;
use Config;
require File::Spec;

use vars qw(@ISA @EXPORT $VERSION
	    @Extensions $Verbose $lib_ext
	    $opt_o $opt_s 
	    );
use strict;

# This is not a dual-life module, so no need for development version numbers
$VERSION = '1.32';

@ISA = qw(Exporter);
@EXPORT = qw(&xsinit &ldopts 
	     &ccopts &ccflags &ccdlflags &perl_inc
	     &xsi_header &xsi_protos &xsi_body);

$Verbose = 0;
$lib_ext = $Config{lib_ext} || '.a';

sub is_cmd { $0 eq '-e' }

sub my_return {
    my $val = shift;
    if(is_cmd) {
	print $val;
    }
    else {
	return $val;
    }
}

sub xsinit { 
    my($file, $std, $mods) = @_;
    my($fh,@mods,%seen);
    $file ||= "perlxsi.c";
    my $xsinit_proto = "pTHX";

    if (@_) {
       @mods = @$mods if $mods;
    }
    else {
       require Getopt::Std;
       Getopt::Std::getopts('o:s:');
       $file = $opt_o if defined $opt_o;
       $std  = $opt_s  if defined $opt_s;
       @mods = @ARGV;
    }
    $std = 1 unless scalar @mods;

    if ($file eq "STDOUT") {
	$fh = \*STDOUT;
    }
    else {
        open $fh, '>', $file
            or die "Can't open '$file': $!";
    }

    push(@mods, static_ext()) if defined $std;
    @mods = grep(!$seen{$_}++, @mods);

    print $fh &xsi_header();
    print $fh "\nEXTERN_C void xs_init ($xsinit_proto);\n\n";
    print $fh &xsi_protos(@mods);

    print $fh "\nEXTERN_C void\nxs_init($xsinit_proto)\n{\n";
    print $fh &xsi_body(@mods);
    print $fh "}\n";

}

sub xsi_header {
    return <<EOF;
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
EOF
}    

sub xsi_protos {
    my @exts = @_;
    my %seen;
    my $retval = '';
    foreach my $cname (canon('__', @exts)) {
        my $ccode = "EXTERN_C void boot_${cname} (pTHX_ CV* cv);\n";
        $retval .= $ccode
            unless $seen{$ccode}++;
    }
    return $retval;
}

sub xsi_body {
    my @exts = @_;
    my %seen;
    my $retval;
    $retval .= "    static const char file[] = __FILE__;\n"
        if @exts;
    $retval .= <<'EOT';
    dXSUB_SYS;
    PERL_UNUSED_CONTEXT;
EOT
    $retval .= "\n"
        if @exts;

    foreach my $pname (canon('/', @exts)) {
        next
            if $seen{$pname}++;
        (my $mname = $pname) =~ s!/!::!g;
        (my $cname = $pname) =~ s!/!__!g;
        my $fname;
        if ($pname eq 'DynaLoader'){
            # Must NOT install 'DynaLoader::boot_DynaLoader' as 'bootstrap'!
            # boot_DynaLoader is called directly in DynaLoader.pm
            $retval .= "    /* DynaLoader is a special case */\n";
            $fname = "${mname}::boot_DynaLoader";
        } else {
            $fname = "${mname}::bootstrap";
        }
        $retval .= "    newXS(\"$fname\", boot_${cname}, file);\n"
    }
    return $retval;
}

sub static_ext {
    @Extensions = ('DynaLoader', sort $Config{static_ext} =~ /(\S+)/g)
        unless @Extensions;
    @Extensions;
}

sub _escape {
    my $arg = shift;
    return $$arg if $^O eq 'VMS'; # parens legal in qualifier lists
    $$arg =~ s/([\(\)])/\\$1/g;
}

sub _ldflags {
    my $ldflags = $Config{ldflags};
    _escape(\$ldflags);
    return $ldflags;
}

sub _ccflags {
    my $ccflags = $Config{ccflags};
    _escape(\$ccflags);
    return $ccflags;
}

sub _ccdlflags {
    my $ccdlflags = $Config{ccdlflags};
    _escape(\$ccdlflags);
    return $ccdlflags;
}

sub ldopts {
    require ExtUtils::MakeMaker;
    require ExtUtils::Liblist;
    my($std,$mods,$link_args,$path) = @_;
    my(@mods,@link_args,@argv);
    my($dllib,$config_libs,@potential_libs,@path);
    local($") = ' ' unless $" eq ' ';
    if (scalar @_) {
       @link_args = @$link_args if $link_args;
       @mods = @$mods if $mods;
    }
    else {
       @argv = @ARGV;
       #hmm
       while($_ = shift @argv) {
	   /^-std$/  && do { $std = 1; next; };
	   /^--$/    && do { @link_args = @argv; last; };
	   /^-I(.*)/ && do { $path = $1 || shift @argv; next; };
	   push(@mods, $_); 
       }
    }
    $std = 1 unless scalar @link_args;
    my $sep = $Config{path_sep} || ':';
    @path = $path ? split(/\Q$sep/, $path) : @INC;

    push(@potential_libs, @link_args)    if scalar @link_args;
    # makemaker includes std libs on windows by default
    if ($^O ne 'MSWin32' and defined($std)) {
	push(@potential_libs, $Config{perllibs});
    }

    push(@mods, static_ext()) if $std;

    my($mod,@ns,$root,$sub,$extra,$archive,@archives);
    print STDERR "Searching (@path) for archives\n" if $Verbose;
    foreach $mod (@mods) {
	@ns = split(/::|\/|\\/, $mod);
	$sub = $ns[-1];
	$root = File::Spec->catdir(@ns);
	
	print STDERR "searching for '$sub${lib_ext}'\n" if $Verbose;
	foreach (@path) {
	    next unless -e ($archive = File::Spec->catdir($_,"auto",$root,"$sub$lib_ext"));
	    push @archives, $archive;
	    if(-e ($extra = File::Spec->catdir($_,"auto",$root,"extralibs.ld"))) {
		local(*FH); 
		if(open(FH, $extra)) {
		    my($libs) = <FH>; chomp $libs;
		    push @potential_libs, split /\s+/, $libs;
		}
		else {  
		    warn "Couldn't open '$extra'"; 
		}
	    }
	    last;
	}
    }
    #print STDERR "\@potential_libs = @potential_libs\n";

    my $libperl;
    if ($^O eq 'MSWin32') {
	$libperl = $Config{libperl};
    }
    elsif ($^O eq 'os390' && $Config{usedl}) {
	# Nothing for OS/390 (z/OS) dynamic.
    } else {
	$libperl = (grep(/^-l\w*perl\w*$/, @link_args))[0]
	    || ($Config{libperl} =~ /^lib(\w+)(\Q$lib_ext\E|\.\Q$Config{dlext}\E)$/
		? "-l$1" : '')
		|| "-lperl";
    }

    my $lpath = File::Spec->catdir($Config{archlibexp}, 'CORE');
    $lpath = qq["$lpath"] if $^O eq 'MSWin32';
    my($extralibs, $bsloadlibs, $ldloadlibs, $ld_run_path) =
	MM->ext(join ' ', "-L$lpath", $libperl, @potential_libs);

    my $ld_or_bs = $bsloadlibs || $ldloadlibs;
    print STDERR "bs: $bsloadlibs ** ld: $ldloadlibs" if $Verbose;
    my $ccdlflags = _ccdlflags();
    my $ldflags   = _ldflags();
    my $linkage = "$ccdlflags $ldflags @archives $ld_or_bs";
    print STDERR "ldopts: '$linkage'\n" if $Verbose;

    return $linkage if scalar @_;
    my_return("$linkage\n");
}

sub ccflags {
    my $ccflags = _ccflags();
    my_return(" $ccflags ");
}

sub ccdlflags {
    my $ccdlflags = _ccdlflags();
    my_return(" $ccdlflags ");
}

sub perl_inc {
    my $dir = File::Spec->catdir($Config{archlibexp}, 'CORE');
    $dir = qq["$dir"] if $^O eq 'MSWin32';
    my_return(" -I$dir ");
}

sub ccopts {
   ccflags . perl_inc;
}

sub canon {
    my($as, @ext) = @_;
    foreach(@ext) {
        # might be X::Y or lib/auto/X/Y/Y.a
        next
            if s!::!/!g;
        s!^(?:lib|ext|dist|cpan)/(?:auto/)?!!;
        s!/\w+\.\w+$!!;
    }
    if ($as ne '/') {
        s!/!$as!g
            foreach @ext;
    }
    @ext;
}

__END__

=head1 NAME

ExtUtils::Embed - Utilities for embedding Perl in C/C++ applications

=head1 SYNOPSIS

 perl -MExtUtils::Embed -e xsinit 
 perl -MExtUtils::Embed -e ccopts 
 perl -MExtUtils::Embed -e ldopts 

=head1 DESCRIPTION

C<ExtUtils::Embed> provides utility functions for embedding a Perl interpreter
and extensions in your C/C++ applications.  
Typically, an application F<Makefile> will invoke C<ExtUtils::Embed>
functions while building your application.  

=head1 @EXPORT

C<ExtUtils::Embed> exports the following functions:

xsinit(), ldopts(), ccopts(), perl_inc(), ccflags(), 
ccdlflags(), xsi_header(), xsi_protos(), xsi_body()

=head1 FUNCTIONS

=over 4

=item xsinit()

Generate C/C++ code for the XS initializer function.

When invoked as C<`perl -MExtUtils::Embed -e xsinit --`>
the following options are recognized:

B<-o> E<lt>output filenameE<gt> (Defaults to B<perlxsi.c>)

B<-o STDOUT> will print to STDOUT.

B<-std> (Write code for extensions that are linked with the current Perl.)

Any additional arguments are expected to be names of modules
to generate code for.

When invoked with parameters the following are accepted and optional:

C<xsinit($filename,$std,[@modules])>

Where,

B<$filename> is equivalent to the B<-o> option.

B<$std> is boolean, equivalent to the B<-std> option.  

B<[@modules]> is an array ref, same as additional arguments mentioned above.

=item Examples

 perl -MExtUtils::Embed -e xsinit -- -o xsinit.c Socket

This will generate code with an C<xs_init> function that glues the perl C<Socket::bootstrap> function 
to the C C<boot_Socket> function and writes it to a file named F<xsinit.c>.

Note that L<DynaLoader> is a special case where it must call C<boot_DynaLoader> directly.

 perl -MExtUtils::Embed -e xsinit

This will generate code for linking with C<DynaLoader> and
each static extension found in C<$Config{static_ext}>.
The code is written to the default file name F<perlxsi.c>.

 perl -MExtUtils::Embed -e xsinit -- -o xsinit.c -std DBI DBD::Oracle

Here, code is written for all the currently linked extensions along with code
for C<DBI> and C<DBD::Oracle>.

If you have a working C<DynaLoader> then there is rarely any need to statically link in any 
other extensions.

=item ldopts()

Output arguments for linking the Perl library and extensions to your
application.

When invoked as C<`perl -MExtUtils::Embed -e ldopts --`>
the following options are recognized:

B<-std> 

Output arguments for linking the Perl library and any extensions linked
with the current Perl.

B<-I> E<lt>path1:path2E<gt>

Search path for ModuleName.a archives.  
Default path is C<@INC>.
Library archives are expected to be found as 
F</some/path/auto/ModuleName/ModuleName.a>
For example, when looking for F<Socket.a> relative to a search path,
we should find F<auto/Socket/Socket.a>

When looking for C<DBD::Oracle> relative to a search path,
we should find F<auto/DBD/Oracle/Oracle.a>

Keep in mind that you can always supply F</my/own/path/ModuleName.a>
as an additional linker argument.

B<-->  E<lt>list of linker argsE<gt>

Additional linker arguments to be considered.

Any additional arguments found before the B<--> token 
are expected to be names of modules to generate code for.

When invoked with parameters the following are accepted and optional:

C<ldopts($std,[@modules],[@link_args],$path)>

Where:

B<$std> is boolean, equivalent to the B<-std> option.  

B<[@modules]> is equivalent to additional arguments found before the B<--> token.

B<[@link_args]> is equivalent to arguments found after the B<--> token.

B<$path> is equivalent to the B<-I> option.

In addition, when ldopts is called with parameters, it will return the argument string
rather than print it to STDOUT.

=item Examples

 perl -MExtUtils::Embed -e ldopts

This will print arguments for linking with C<libperl> and
extensions found in C<$Config{static_ext}>.  This includes libraries
found in C<$Config{libs}> and the first ModuleName.a library
for each extension that is found by searching C<@INC> or the path
specified by the B<-I> option.
In addition, when ModuleName.a is found, additional linker arguments
are picked up from the F<extralibs.ld> file in the same directory.

 perl -MExtUtils::Embed -e ldopts -- -std Socket

This will do the same as the above example, along with printing additional arguments for linking with the C<Socket> extension.

 perl -MExtUtils::Embed -e ldopts -- -std Msql -- -L/usr/msql/lib -lmsql

Any arguments after the second '--' token are additional linker
arguments that will be examined for potential conflict.  If there is no
conflict, the additional arguments will be part of the output.  

=item perl_inc()

For including perl header files this function simply prints:

 -I$Config{archlibexp}/CORE  

So, rather than having to say:

 perl -MConfig -e 'print "-I$Config{archlibexp}/CORE"'

Just say:

 perl -MExtUtils::Embed -e perl_inc

=item ccflags(), ccdlflags()

These functions simply print $Config{ccflags} and $Config{ccdlflags}

=item ccopts()

This function combines C<perl_inc()>, C<ccflags()> and C<ccdlflags()> into one.

=item xsi_header()

This function simply returns a string defining the same C<EXTERN_C> macro as
F<perlmain.c> along with #including F<perl.h> and F<EXTERN.h>.

=item xsi_protos(@modules)

This function returns a string of C<boot_$ModuleName> prototypes for each @modules.

=item xsi_body(@modules)

This function returns a string of calls to C<newXS()> that glue the module I<bootstrap>
function to I<boot_ModuleName> for each @modules.

C<xsinit()> uses the xsi_* functions to generate most of its code.

=back

=head1 EXAMPLES

For examples on how to use C<ExtUtils::Embed> for building C/C++ applications
with embedded perl, see L<perlembed>.

=head1 SEE ALSO

L<perlembed>

=head1 AUTHOR

Doug MacEachern E<lt>C<dougm@osf.org>E<gt>

Based on ideas from Tim Bunce E<lt>C<Tim.Bunce@ig.co.uk>E<gt> and
F<minimod.pl> by Andreas Koenig E<lt>C<k@anna.in-berlin.de>E<gt> and Tim Bunce.

=cut
