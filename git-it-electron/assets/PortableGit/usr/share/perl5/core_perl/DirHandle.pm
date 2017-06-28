package DirHandle;

our $VERSION = '1.04';

=head1 NAME 

DirHandle - supply object methods for directory handles

=head1 SYNOPSIS

    use DirHandle;
    $d = DirHandle->new(".");
    if (defined $d) {
        while (defined($_ = $d->read)) { something($_); }
        $d->rewind;
        while (defined($_ = $d->read)) { something_else($_); }
        undef $d;
    }

=head1 DESCRIPTION

The C<DirHandle> method provide an alternative interface to the
opendir(), closedir(), readdir(), and rewinddir() functions.

The only objective benefit to using C<DirHandle> is that it avoids
namespace pollution by creating globs to hold directory handles.

=cut

require 5.000;
use Carp;
use Symbol;

sub new {
    @_ >= 1 && @_ <= 2 or croak 'usage: DirHandle->new( [DIRNAME] )';
    my $class = shift;
    my $dh = gensym;
    if (@_) {
	DirHandle::open($dh, $_[0])
	    or return undef;
    }
    bless $dh, $class;
}

sub DESTROY {
    my ($dh) = @_;
    # Don't warn about already being closed as it may have been closed 
    # correctly, or maybe never opened at all.
    local($., $@, $!, $^E, $?);
    no warnings 'io';
    closedir($dh);
}

sub open {
    @_ == 2 or croak 'usage: $dh->open(DIRNAME)';
    my ($dh, $dirname) = @_;
    opendir($dh, $dirname);
}

sub close {
    @_ == 1 or croak 'usage: $dh->close()';
    my ($dh) = @_;
    closedir($dh);
}

sub read {
    @_ == 1 or croak 'usage: $dh->read()';
    my ($dh) = @_;
    readdir($dh);
}

sub rewind {
    @_ == 1 or croak 'usage: $dh->rewind()';
    my ($dh) = @_;
    rewinddir($dh);
}

1;
