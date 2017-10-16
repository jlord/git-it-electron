# Generated from XSLoader.pm.PL (resolved %Config::Config value)

package XSLoader;

$VERSION = "0.20";

#use strict;

package DynaLoader;

# No prizes for guessing why we don't say 'bootstrap DynaLoader;' here.
# NOTE: All dl_*.xs (including dl_none.xs) define a dl_error() XSUB
boot_DynaLoader('DynaLoader') if defined(&boot_DynaLoader) &&
                                !defined(&dl_error);
package XSLoader;

sub load {
    package DynaLoader;

    my ($caller, $modlibname) = caller();
    my $module = $caller;

    if (@_) {
        $module = $_[0];
    } else {
        $_[0] = $module;
    }

    # work with static linking too
    my $boots = "$module\::bootstrap";
    goto &$boots if defined &$boots;

    goto \&XSLoader::bootstrap_inherit unless $module and defined &dl_load_file;

    my @modparts = split(/::/,$module);
    my $modfname = $modparts[-1];

    my $modpname = join('/',@modparts);
    my $c = () = split(/::/,$caller,-1);
    $modlibname =~ s,[\\/][^\\/]+$,, while $c--;    # Q&D basename
    my $file = "$modlibname/auto/$modpname/$modfname.dll";

#   print STDERR "XSLoader::load for $module ($file)\n" if $dl_debug;

    my $bs = $file;
    $bs =~ s/(\.\w+)?(;\d*)?$/\.bs/; # look for .bs 'beside' the library

    if (-s $bs) { # only read file if it's not empty
#       print STDERR "BS: $bs ($^O, $dlsrc)\n" if $dl_debug;
        eval { do $bs; };
        warn "$bs: $@\n" if $@;
	goto \&XSLoader::bootstrap_inherit;
    }

    goto \&XSLoader::bootstrap_inherit if not -f $file;

    my $bootname = "boot_$module";
    $bootname =~ s/\W/_/g;
    @DynaLoader::dl_require_symbols = ($bootname);

    my $boot_symbol_ref;

    # Many dynamic extension loading problems will appear to come from
    # this section of code: XYZ failed at line 123 of DynaLoader.pm.
    # Often these errors are actually occurring in the initialisation
    # C code of the extension XS file. Perl reports the error as being
    # in this perl code simply because this was the last perl code
    # it executed.

    my $libref = dl_load_file($file, 0) or do { 
        require Carp;
        Carp::croak("Can't load '$file' for module $module: " . dl_error());
    };
    push(@DynaLoader::dl_librefs,$libref);  # record loaded object

    my @unresolved = dl_undef_symbols();
    if (@unresolved) {
        require Carp;
        Carp::carp("Undefined symbols present after loading $file: @unresolved\n");
    }

    $boot_symbol_ref = dl_find_symbol($libref, $bootname) or do {
        require Carp;
        Carp::croak("Can't find '$bootname' symbol in $file\n");
    };

    push(@DynaLoader::dl_modules, $module); # record loaded module

  boot:
    my $xs = dl_install_xsub($boots, $boot_symbol_ref, $file);

    # See comment block above
    push(@DynaLoader::dl_shared_objects, $file); # record files loaded
    return &$xs(@_);
}

sub bootstrap_inherit {
    require DynaLoader;
    goto \&DynaLoader::bootstrap_inherit;
}

1;


__END__

=head1 NAME

XSLoader - Dynamically load C libraries into Perl code

=head1 VERSION

Version 0.17

=head1 SYNOPSIS

    package YourPackage;
    require XSLoader;

    XSLoader::load();

=head1 DESCRIPTION

This module defines a standard I<simplified> interface to the dynamic
linking mechanisms available on many platforms.  Its primary purpose is
to implement cheap automatic dynamic loading of Perl modules.

For a more complicated interface, see L<DynaLoader>.  Many (most)
features of C<DynaLoader> are not implemented in C<XSLoader>, like for
example the C<dl_load_flags>, not honored by C<XSLoader>.

=head2 Migration from C<DynaLoader>

A typical module using L<DynaLoader|DynaLoader> starts like this:

    package YourPackage;
    require DynaLoader;

    our @ISA = qw( OnePackage OtherPackage DynaLoader );
    our $VERSION = '0.01';
    bootstrap YourPackage $VERSION;

Change this to

    package YourPackage;
    use XSLoader;

    our @ISA = qw( OnePackage OtherPackage );
    our $VERSION = '0.01';
    XSLoader::load 'YourPackage', $VERSION;

In other words: replace C<require DynaLoader> by C<use XSLoader>, remove
C<DynaLoader> from C<@ISA>, change C<bootstrap> by C<XSLoader::load>.  Do not
forget to quote the name of your package on the C<XSLoader::load> line,
and add comma (C<,>) before the arguments (C<$VERSION> above).

Of course, if C<@ISA> contained only C<DynaLoader>, there is no need to have
the C<@ISA> assignment at all; moreover, if instead of C<our> one uses the
more backward-compatible

    use vars qw($VERSION @ISA);

one can remove this reference to C<@ISA> together with the C<@ISA> assignment.

If no C<$VERSION> was specified on the C<bootstrap> line, the last line becomes

    XSLoader::load 'YourPackage';

If the call to C<load> is from C<YourPackage>, then that can be further
simplified to

    XSLoader::load();

as C<load> will use C<caller> to determine the package.

=head2 Backward compatible boilerplate

If you want to have your cake and eat it too, you need a more complicated
boilerplate.

    package YourPackage;
    use vars qw($VERSION @ISA);

    @ISA = qw( OnePackage OtherPackage );
    $VERSION = '0.01';
    eval {
       require XSLoader;
       XSLoader::load('YourPackage', $VERSION);
       1;
    } or do {
       require DynaLoader;
       push @ISA, 'DynaLoader';
       bootstrap YourPackage $VERSION;
    };

The parentheses about C<XSLoader::load()> arguments are needed since we replaced
C<use XSLoader> by C<require>, so the compiler does not know that a function
C<XSLoader::load()> is present.

This boilerplate uses the low-overhead C<XSLoader> if present; if used with
an antique Perl which has no C<XSLoader>, it falls back to using C<DynaLoader>.

=head1 Order of initialization: early load()

I<Skip this section if the XSUB functions are supposed to be called from other
modules only; read it only if you call your XSUBs from the code in your module,
or have a C<BOOT:> section in your XS file (see L<perlxs/"The BOOT: Keyword">).
What is described here is equally applicable to the L<DynaLoader|DynaLoader>
interface.>

A sufficiently complicated module using XS would have both Perl code (defined
in F<YourPackage.pm>) and XS code (defined in F<YourPackage.xs>).  If this
Perl code makes calls into this XS code, and/or this XS code makes calls to
the Perl code, one should be careful with the order of initialization.

The call to C<XSLoader::load()> (or C<bootstrap()>) calls the module's
bootstrap code. For modules build by F<xsubpp> (nearly all modules) this
has three side effects:

=over

=item *

A sanity check is done to ensure that the versions of the F<.pm> and the
(compiled) F<.xs> parts are compatible. If C<$VERSION> was specified, this
is used for the check. If not specified, it defaults to
C<$XS_VERSION // $VERSION> (in the module's namespace)

=item *

the XSUBs are made accessible from Perl

=item *

if a C<BOOT:> section was present in the F<.xs> file, the code there is called.

=back

Consequently, if the code in the F<.pm> file makes calls to these XSUBs, it is
convenient to have XSUBs installed before the Perl code is defined; for
example, this makes prototypes for XSUBs visible to this Perl code.
Alternatively, if the C<BOOT:> section makes calls to Perl functions (or
uses Perl variables) defined in the F<.pm> file, they must be defined prior to
the call to C<XSLoader::load()> (or C<bootstrap()>).

The first situation being much more frequent, it makes sense to rewrite the
boilerplate as

    package YourPackage;
    use XSLoader;
    use vars qw($VERSION @ISA);

    BEGIN {
       @ISA = qw( OnePackage OtherPackage );
       $VERSION = '0.01';

       # Put Perl code used in the BOOT: section here

       XSLoader::load 'YourPackage', $VERSION;
    }

    # Put Perl code making calls into XSUBs here

=head2 The most hairy case

If the interdependence of your C<BOOT:> section and Perl code is
more complicated than this (e.g., the C<BOOT:> section makes calls to Perl
functions which make calls to XSUBs with prototypes), get rid of the C<BOOT:>
section altogether.  Replace it with a function C<onBOOT()>, and call it like
this:

    package YourPackage;
    use XSLoader;
    use vars qw($VERSION @ISA);

    BEGIN {
       @ISA = qw( OnePackage OtherPackage );
       $VERSION = '0.01';
       XSLoader::load 'YourPackage', $VERSION;
    }

    # Put Perl code used in onBOOT() function here; calls to XSUBs are
    # prototype-checked.

    onBOOT;

    # Put Perl initialization code assuming that XS is initialized here


=head1 DIAGNOSTICS

=over

=item C<Can't find '%s' symbol in %s>

B<(F)> The bootstrap symbol could not be found in the extension module.

=item C<Can't load '%s' for module %s: %s>

B<(F)> The loading or initialisation of the extension module failed.
The detailed error follows.

=item C<Undefined symbols present after loading %s: %s>

B<(W)> As the message says, some symbols stay undefined although the
extension module was correctly loaded and initialised. The list of undefined
symbols follows.

=back

=head1 LIMITATIONS

To reduce the overhead as much as possible, only one possible location
is checked to find the extension DLL (this location is where C<make install>
would put the DLL).  If not found, the search for the DLL is transparently
delegated to C<DynaLoader>, which looks for the DLL along the C<@INC> list.

In particular, this is applicable to the structure of C<@INC> used for testing
not-yet-installed extensions.  This means that running uninstalled extensions
may have much more overhead than running the same extensions after
C<make install>.


=head1 KNOWN BUGS

The new simpler way to call C<XSLoader::load()> with no arguments at all
does not work on Perl 5.8.4 and 5.8.5.


=head1 BUGS

Please report any bugs or feature requests via the perlbug(1) utility.


=head1 SEE ALSO

L<DynaLoader>


=head1 AUTHORS

Ilya Zakharevich originally extracted C<XSLoader> from C<DynaLoader>.

CPAN version is currently maintained by SE<eacute>bastien Aperghis-Tramoni
E<lt>sebastien@aperghis.netE<gt>.

Previous maintainer was Michael G Schwern <schwern@pobox.com>.


=head1 COPYRIGHT & LICENSE

Copyright (C) 1990-2011 by Larry Wall and others.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
