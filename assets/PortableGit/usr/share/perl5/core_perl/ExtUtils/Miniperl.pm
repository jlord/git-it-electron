#!./perl -w
package ExtUtils::Miniperl;
use strict;
require Exporter;
use ExtUtils::Embed 1.31, qw(xsi_header xsi_protos xsi_body);

use vars qw($VERSION @ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(writemain);
$VERSION = '1.05';

# blead will run this with miniperl, hence we can't use autodie or File::Temp
my $temp;

END {
    return if !defined $temp || !-e $temp;
    unlink $temp or warn "Can't unlink '$temp': $!";
}

sub writemain{
    my ($fh, $real);

    if (ref $_[0] eq 'SCALAR') {
        $real = ${+shift};
        $temp = $real;
        $temp =~ s/(?:.c)?\z/.new/;
        open $fh, '>', $temp
            or die "Can't open '$temp' for writing: $!";
    } elsif (ref $_[0]) {
        $fh = shift;
    } else {
        $fh = \*STDOUT;
    }

    my(@exts) = @_;

    printf $fh <<'EOF!HEAD', xsi_header();
/*    miniperlmain.c
 *
 *    Copyright (C) 1994, 1995, 1996, 1997, 1999, 2000, 2001, 2002, 2003,
 *    2004, 2005, 2006, 2007, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 *      The Road goes ever on and on
 *          Down from the door where it began.
 *
 *     [Bilbo on p.35 of _The Lord of the Rings_, I/i: "A Long-Expected Party"]
 *     [Frodo on p.73 of _The Lord of the Rings_, I/iii: "Three Is Company"]
 */

/* This file contains the main() function for the perl interpreter.
 * Note that miniperlmain.c contains main() for the 'miniperl' binary,
 * while perlmain.c contains main() for the 'perl' binary.
 *
 * Miniperl is like perl except that it does not support dynamic loading,
 * and in fact is used to build the dynamic modules needed for the 'real'
 * perl executable.
 */

#ifdef OEMVS
#ifdef MYMALLOC
/* sbrk is limited to first heap segment so make it big */
#pragma runopts(HEAP(8M,500K,ANYWHERE,KEEP,8K,4K) STACK(,,ANY,) ALL31(ON))
#else
#pragma runopts(HEAP(2M,500K,ANYWHERE,KEEP,8K,4K) STACK(,,ANY,) ALL31(ON))
#endif
#endif

#define PERL_IN_MINIPERLMAIN_C
%s
static void xs_init (pTHX);
static PerlInterpreter *my_perl;

#if defined(PERL_GLOBAL_STRUCT_PRIVATE)
/* The static struct perl_vars* may seem counterproductive since the
 * whole idea PERL_GLOBAL_STRUCT_PRIVATE was to avoid statics, but note
 * that this static is not in the shared perl library, the globals PL_Vars
 * and PL_VarsPtr will stay away. */
static struct perl_vars* my_plvarsp;
struct perl_vars* Perl_GetVarsPrivate(void) { return my_plvarsp; }
#endif

#ifdef NO_ENV_ARRAY_IN_MAIN
extern char **environ;
int
main(int argc, char **argv)
#else
int
main(int argc, char **argv, char **env)
#endif
{
    int exitstatus, i;
#ifdef PERL_GLOBAL_STRUCT
    struct perl_vars *my_vars = init_global_struct();
#  ifdef PERL_GLOBAL_STRUCT_PRIVATE
    int veto;

    my_plvarsp = my_vars;
#  endif
#endif /* PERL_GLOBAL_STRUCT */
#ifndef NO_ENV_ARRAY_IN_MAIN
    PERL_UNUSED_ARG(env);
#endif
#ifndef PERL_USE_SAFE_PUTENV
    PL_use_safe_putenv = FALSE;
#endif /* PERL_USE_SAFE_PUTENV */

    /* if user wants control of gprof profiling off by default */
    /* noop unless Configure is given -Accflags=-DPERL_GPROF_CONTROL */
    PERL_GPROF_MONCONTROL(0);

#ifdef NO_ENV_ARRAY_IN_MAIN
    PERL_SYS_INIT3(&argc,&argv,&environ);
#else
    PERL_SYS_INIT3(&argc,&argv,&env);
#endif

#if defined(USE_ITHREADS)
    /* XXX Ideally, this should really be happening in perl_alloc() or
     * perl_construct() to keep libperl.a transparently fork()-safe.
     * It is currently done here only because Apache/mod_perl have
     * problems due to lack of a call to cancel pthread_atfork()
     * handlers when shared objects that contain the handlers may
     * be dlclose()d.  This forces applications that embed perl to
     * call PTHREAD_ATFORK() explicitly, but if and only if it hasn't
     * been called at least once before in the current process.
     * --GSAR 2001-07-20 */
    PTHREAD_ATFORK(Perl_atfork_lock,
                   Perl_atfork_unlock,
                   Perl_atfork_unlock);
#endif

    PERL_SYS_FPU_INIT;

    if (!PL_do_undump) {
	my_perl = perl_alloc();
	if (!my_perl)
	    exit(1);
	perl_construct(my_perl);
	PL_perl_destruct_level = 0;
    }
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    exitstatus = perl_parse(my_perl, xs_init, argc, argv, (char **)NULL);
    if (!exitstatus)
        perl_run(my_perl);

#ifndef PERL_MICRO
    /* Unregister our signal handler before destroying my_perl */
    for (i = 1; PL_sig_name[i]; i++) {
	if (rsignal_state(PL_sig_num[i]) == (Sighandler_t) PL_csighandlerp) {
	    rsignal(PL_sig_num[i], (Sighandler_t) SIG_DFL);
	}
    }
#endif

    exitstatus = perl_destruct(my_perl);

    perl_free(my_perl);

#if defined(USE_ENVIRON_ARRAY) && defined(PERL_TRACK_MEMPOOL) && !defined(NO_ENV_ARRAY_IN_MAIN)
    /*
     * The old environment may have been freed by perl_free()
     * when PERL_TRACK_MEMPOOL is defined, but without having
     * been restored by perl_destruct() before (this is only
     * done if destruct_level > 0).
     *
     * It is important to have a valid environment for atexit()
     * routines that are eventually called.
     */
    environ = env;
#endif

    PERL_SYS_TERM();

#ifdef PERL_GLOBAL_STRUCT
#  ifdef PERL_GLOBAL_STRUCT_PRIVATE
    veto = my_plvarsp->Gveto_cleanup;
#  endif
    free_global_struct(my_vars);
#  ifdef PERL_GLOBAL_STRUCT_PRIVATE
    if (!veto)
        my_plvarsp = NULL;
    /* Remember, functions registered with atexit() can run after this point,
       and may access "global" variables, and hence end up calling
       Perl_GetVarsPrivate()  */
#endif
#endif /* PERL_GLOBAL_STRUCT */

    exit(exitstatus);
}

/* Register any extra external extensions */

EOF!HEAD

    print $fh xsi_protos(@exts), <<'EOT', xsi_body(@exts), "}\n";

static void
xs_init(pTHX)
{
EOT

    if ($real) {
        close $fh or die "Can't close '$temp': $!";
        rename $temp, $real or die "Can't rename '$temp' to '$real': $!";
    }
}

1;
__END__

=head1 NAME

ExtUtils::Miniperl - write the C code for perlmain.c

=head1 SYNOPSIS

    use ExtUtils::Miniperl;
    writemain(@directories);
    # or
    writemain($fh, @directories);
    # or
    writemain(\$filename, @directories);

=head1 DESCRIPTION

C<writemain()> takes an argument list of directories containing archive
libraries that relate to perl modules and should be linked into a new
perl binary. It writes a corresponding F<perlmain.c> file that
is a plain C file containing all the bootstrap code to make the
modules associated with the libraries available from within perl.
If the first argument to C<writemain()> is a reference to a scalar it is
used as the filename to open for output. Any other reference is used as
the filehandle to write to. Otherwise output defaults to C<STDOUT>.

The typical usage is from within a Makefile generated by
L<ExtUtils::MakeMaker>. So under normal circumstances you won't have to
deal with this module directly.

=head1 SEE ALSO

L<ExtUtils::MakeMaker>

=cut

# ex: set ts=8 sts=4 sw=4 et:
