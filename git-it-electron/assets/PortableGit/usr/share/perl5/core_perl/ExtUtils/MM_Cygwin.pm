package ExtUtils::MM_Cygwin;

use strict;

use ExtUtils::MakeMaker::Config;
use File::Spec;

require ExtUtils::MM_Unix;
require ExtUtils::MM_Win32;
our @ISA = qw( ExtUtils::MM_Unix );

our $VERSION = '7.04_01';


=head1 NAME

ExtUtils::MM_Cygwin - methods to override UN*X behaviour in ExtUtils::MakeMaker

=head1 SYNOPSIS

 use ExtUtils::MM_Cygwin; # Done internally by ExtUtils::MakeMaker if needed

=head1 DESCRIPTION

See ExtUtils::MM_Unix for a documentation of the methods provided there.

=over 4

=item os_flavor

We're Unix and Cygwin.

=cut

sub os_flavor {
    return('Unix', 'Cygwin');
}

=item cflags

if configured for dynamic loading, triggers #define EXT in EXTERN.h

=cut

sub cflags {
    my($self,$libperl)=@_;
    return $self->{CFLAGS} if $self->{CFLAGS};
    return '' unless $self->needs_linking();

    my $base = $self->SUPER::cflags($libperl);
    foreach (split /\n/, $base) {
        /^(\S*)\s*=\s*(\S*)$/ and $self->{$1} = $2;
    };
    $self->{CCFLAGS} .= " -DUSEIMPORTLIB" if ($Config{useshrplib} eq 'true');

    return $self->{CFLAGS} = qq{
CCFLAGS = $self->{CCFLAGS}
OPTIMIZE = $self->{OPTIMIZE}
PERLTYPE = $self->{PERLTYPE}
};

}


=item replace_manpage_separator

replaces strings '::' with '.' in MAN*POD man page names

=cut

sub replace_manpage_separator {
    my($self, $man) = @_;
    $man =~ s{/+}{.}g;
    return $man;
}

=item init_linker

points to libperl.a

=cut

sub init_linker {
    my $self = shift;

    if ($Config{useshrplib} eq 'true') {
        my $libperl = '$(PERL_INC)' .'/'. "$Config{libperl}";
        if( $] >= 5.006002 ) {
            $libperl =~ s/a$/dll.a/;
        }
        $self->{PERL_ARCHIVE} = $libperl;
    } else {
        $self->{PERL_ARCHIVE} =
          '$(PERL_INC)' .'/'. ("$Config{libperl}" or "libperl.a");
    }

    $self->{PERL_ARCHIVEDEP} ||= '';
    $self->{PERL_ARCHIVE_AFTER} ||= '';
    $self->{EXPORT_LIST}  ||= '';
}

=item maybe_command

Determine whether a file is native to Cygwin by checking whether it
resides inside the Cygwin installation (using Windows paths). If so,
use C<ExtUtils::MM_Unix> to determine if it may be a command.
Otherwise use the tests from C<ExtUtils::MM_Win32>.

=cut

sub maybe_command {
    my ($self, $file) = @_;

    my $cygpath = Cygwin::posix_to_win_path('/', 1);
    my $filepath = Cygwin::posix_to_win_path($file, 1);

    return (substr($filepath,0,length($cygpath)) eq $cygpath)
    ? $self->SUPER::maybe_command($file) # Unix
    : ExtUtils::MM_Win32->maybe_command($file); # Win32
}

=item dynamic_lib

Use the default to produce the *.dll's.
Add the dll size to F<$vendorarch/auto/.rebase>, which stores the
next available imagebase.

If an old dll exists and .rebase is empty, use the same rebase address
for new archdir dll's.

=cut

sub dynamic_lib {
    my($self, %attribs) = @_;
    my $s = ExtUtils::MM_Unix::dynamic_lib($self, %attribs);
    return '' unless $s;
    return $s unless %{$self->{XS}};

    my $ori = "$self->{INSTALLARCHLIB}/auto/$self->{FULLEXT}/$self->{BASEEXT}.$self->{DLEXT}";
    my $rebase = "$self->{INSTALLVENDORARCH}/auto/.rebase";
    my $imagebase = '';
    my $rebaseverstr = -f '/usr/bin/rebase' ? `/usr/bin/rebase -V 2>&1` : '0';
    my ($rebasever) = $rebaseverstr =~ /rebase version ([0-9.]+)/;
    $rebasever =~ s/(\d\.\d+)\./$1/;
    if (-f $rebase and $rebasever < 3.02) {
      $imagebase = `/bin/cat $rebase`;
      chomp $imagebase;
    }
    if (-e $ori) {
      $imagebase = `/usr/bin/objdump -p $ori | /usr/bin/grep ImageBase | /usr/bin/cut -c12-`;
      chomp $imagebase;
      if ($imagebase gt "40000000" and $imagebase lt "80000000") {
        my $LDDLFLAGS = $self->{LDDLFLAGS};
        $LDDLFLAGS =~ s/-Wl,--enable-auto-image-base/-Wl,--image-base=0x$imagebase/;
        $s =~ s/ \$\(LDDLFLAGS\) / $LDDLFLAGS /m;
      }
    } elsif ($imagebase gt "40000000" and $imagebase lt "80000000") {
      my $LDDLFLAGS = $self->{LDDLFLAGS};
      $LDDLFLAGS =~ s/-Wl,--enable-auto-image-base/-Wl,--image-base=0x$imagebase/ or
        $LDDLFLAGS .= " -Wl,--image-base=0x$imagebase";
      $s =~ s/ \$\(INST_DYNAMIC_DEP\)/ \$(INST_DYNAMIC_DEP) _rebase/;
      $s =~ s/ \$\(LDDLFLAGS\) / $LDDLFLAGS /m;
      # Here we create all DLL's per project with the same imagebase. With rebase 3.0.2 we do better
      $s .= "\t/usr/bin/rebase -v -b 0x$imagebase \$@ | ";
      $s .= "\$(FULLPERL) -n _rebase > \$(INSTALLVENDORARCH)/auto/.rebase\n";
      # Need a tempfile, because gmake expands $_ in the perl cmdline
      $s .= "\n_rebase : \$(OBJECT)\n";
      $s .= "\t\$(NOECHO) \$(ECHO) '/new base = (.+), new size = (.+)/ && printf \"%x\\n\",hex(\$1)+hex(\$2);' > _rebase\n";
    } else {
      if ($rebasever < 3.02) {  # new rebase 3.0.2 with database
        warn "Hint: run perlrebase to initialize $rebase or upgrade to rebase 3.0.2\n";
      }
    }
    $s;
}

=item install

Rebase dll's with the global rebase database after installation.

=cut

sub install {
    my($self, %attribs) = @_;
    my $s = ExtUtils::MM_Unix::install($self, %attribs);
    return '' unless $s;
    return $s unless %{$self->{XS}};

    my $rebaseverstr = -f '/usr/bin/rebase' ? `/usr/bin/rebase -V 2>&1` : '0';
    my ($rebasever) = $rebaseverstr =~ /rebase version ([0-9.]+)/;
    $rebasever =~ s/(\d\.\d+)\./$1/;
    if ($rebasever > 3.01) {  # new rebase 3.0.2 with database
      my $INSTALLDIRS = $self->{INSTALLDIRS};
      my $INSTALLLIB = $self->{"INSTALL". ($INSTALLDIRS eq 'perl' ? 'ARCHLIB' : uc($INSTALLDIRS)."ARCH")};
      my $dll = "$INSTALLLIB/auto/$self->{FULLEXT}/$self->{BASEEXT}.$self->{DLEXT}";
      $s =~ s|^(pure_install :: pure_\$\(INSTALLDIRS\)_install\n\t)\$\(NOECHO\) \$\(NOOP\)\n|$1\$(CHMOD) \$(PERM_RWX) \$(DESTDIR)$dll\n\ttest -n "\$(DESTDIR)\" \|\| /bin/rebase -s $dll\n|m;
    }
    $s;
}

=item all_target

Build man pages, too

=cut

sub all_target {
    ExtUtils::MM_Unix::all_target(shift);
}

=back

=cut

1;
