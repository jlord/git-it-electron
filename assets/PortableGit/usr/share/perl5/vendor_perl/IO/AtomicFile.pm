package IO::AtomicFile;

### DOCUMENTATION AT BOTTOM OF FILE

# Be strict:
use strict;

# External modules:
use IO::File;


#------------------------------
#
# GLOBALS...
#
#------------------------------
use vars qw($VERSION @ISA);

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "2.111";

# Inheritance:
@ISA = qw(IO::File);


#------------------------------
# new ARGS...
#------------------------------
# Class method, constructor.
# Any arguments are sent to open().
#
sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    ${*$self}{'io_atomicfile_suffix'} = '';
    $self->open(@_) if @_;
    $self;
}

#------------------------------
# DESTROY 
#------------------------------
# Destructor.
#
sub DESTROY {
    shift->close(1);   ### like close, but raises fatal exception on failure
}

#------------------------------
# open PATH, MODE
#------------------------------
# Class/instance method.
#
sub open {
    my ($self, $path, $mode) = @_;
    ref($self) or $self = $self->new;    ### now we have an instance! 

    ### Create tmp path, and remember this info: 
    my $temp = "${path}..TMP" . ${*$self}{'io_atomicfile_suffix'};
    ${*$self}{'io_atomicfile_temp'} = $temp;
    ${*$self}{'io_atomicfile_path'} = $path;

    ### Open the file!  Returns filehandle on success, for use as a constructor: 
    $self->SUPER::open($temp, $mode) ? $self : undef;
}

#------------------------------
# _closed [YESNO]
#------------------------------
# Instance method, private.
# Are we already closed?  Argument sets new value, returns previous one.
#
sub _closed {
    my $self = shift;
    my $oldval = ${*$self}{'io_atomicfile_closed'};
    ${*$self}{'io_atomicfile_closed'} = shift if @_;
    $oldval;
}

#------------------------------
# close
#------------------------------
# Instance method.
# Close the handle, and rename the temp file to its final name.
#
sub close {
    my ($self, $die) = @_;
    unless ($self->_closed(1)) {             ### sentinel...
	    if ($self->SUPER::close()) {
		    rename(${*$self}{'io_atomicfile_temp'},
			   ${*$self}{'io_atomicfile_path'})
			or ($die ? die "close (rename) atomic file: $!\n" : return undef);
	    } else {
		    ($die ? die "close atomic file: $!\n" : return undef);
	    }
    }
    1;
}

#------------------------------
# delete
#------------------------------
# Instance method.
# Close the handle, and delete the temp file.
#
sub delete {
    my $self = shift;
    unless ($self->_closed(1)) {             ### sentinel...
        $self->SUPER::close();    
        return unlink(${*$self}{'io_atomicfile_temp'});
    }
    1;
}

#------------------------------
# detach
#------------------------------
# Instance method.
# Close the handle, but DO NOT delete the temp file.
#
sub detach {
    my $self = shift;
    $self->SUPER::close() unless ($self->_closed(1));
    1;
}

#------------------------------
1;
__END__


=head1 NAME

IO::AtomicFile - write a file which is updated atomically


=head1 SYNOPSIS

    use IO::AtomicFile;

    ### Write a temp file, and have it install itself when closed:
    my $FH = IO::AtomicFile->open("bar.dat", "w");
    print $FH "Hello!\n";
    $FH->close || die "couldn't install atomic file: $!";    

    ### Write a temp file, but delete it before it gets installed:
    my $FH = IO::AtomicFile->open("bar.dat", "w");
    print $FH "Hello!\n";
    $FH->delete; 

    ### Write a temp file, but neither install it nor delete it:
    my $FH = IO::AtomicFile->open("bar.dat", "w");
    print $FH "Hello!\n";
    $FH->detach;   


=head1 DESCRIPTION

This module is intended for people who need to update files 
reliably in the face of unexpected program termination.  

For example, you generally don't want to be halfway in the middle of
writing I</etc/passwd> and have your program terminate!  Even
the act of writing a single scalar to a filehandle is I<not> atomic.

But this module gives you true atomic updates, via rename().
When you open a file I</foo/bar.dat> via this module, you are I<actually> 
opening a temporary file I</foo/bar.dat..TMP>, and writing your
output there.   The act of closing this file (either explicitly
via close(), or implicitly via the destruction of the object)
will cause rename() to be called... therefore, from the point
of view of the outside world, the file's contents are updated
in a single time quantum.

To ensure that problems do not go undetected, the "close" method
done by the destructor will raise a fatal exception if the rename()
fails.  The explicit close() just returns undef.   

You can also decide at any point to trash the file you've been 
building.


=head1 AUTHOR

=head2 Primary Maintainer

Dianne Skoll (F<dfs@roaringpenguin.com>).

=head2 Original Author

Eryq (F<eryq@zeegee.com>).
President, ZeeGee Software Inc (F<http://www.zeegee.com>).


=head1 REVISION

$Revision: 1.2 $

=cut 
