package IO::InnerFile;

=head1 NAME

IO::InnerFile - define a file inside another file


=head1 SYNOPSIS


    ### Read a subset of a file:
    $inner = IO::InnerFile->new($fh, $start, $length);
    while (<$inner>) {
	...
    }


=head1 DESCRIPTION

If you have a filehandle that can seek() and tell(), then you 
can open an IO::InnerFile on a range of the underlying file.


=head1 PUBLIC INTERFACE

=over

=cut

use Symbol;

# The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = "2.111";

#------------------------------

=item new FILEHANDLE, [START, [LENGTH]]

I<Class method, constructor.>
Create a new inner-file opened on the given FILEHANDLE,
from bytes START to START+LENGTH.  Both START and LENGTH
default to 0; negative values are silently coerced to zero.

Note that FILEHANDLE must be able to seek() and tell(), in addition
to whatever other methods you may desire for reading it.

=cut

sub new {
   my ($class, $fh, $start, $lg) = @_;
   $start = 0 if (!$start or ($start < 0));
   $lg    = 0 if (!$lg    or ($lg    < 0));

   ### Create the underlying "object":
   my $a = {
      FH 	=> 	$fh,
      CRPOS 	=> 	0,
      START	=>	$start,
      LG	=>	$lg,
   };

   ### Create a new filehandle tied to this object:
   $fh = gensym;
   tie(*$fh, $class, $a); 
   return bless($fh, $class);
}

sub TIEHANDLE { 
   my ($class, $data) = @_;
   return bless($data, $class);
}

sub DESTROY { 
   my ($self) = @_;
   $self->close() if (ref($self) eq 'SCALAR'); 
}

#------------------------------

=item set_length LENGTH

=item get_length 

=item add_length NBYTES

I<Instance methods.>
Get/set the virtual length of the inner file.

=cut

sub set_length { tied(${$_[0]})->{LG} = $_[1]; }
sub get_length { tied(${$_[0]})->{LG}; }
sub add_length { tied(${$_[0]})->{LG} += $_[1]; }

#------------------------------

=item set_start START

=item get_start 

=item add_start NBYTES

I<Instance methods.>
Get/set the virtual start position of the inner file.

=cut

sub set_start  { tied(${$_[0]})->{START} = $_[1]; }
sub get_start  { tied(${$_[0]})->{START}; } 
sub set_end    { tied(${$_[0]})->{LG} =  $_[1] - tied(${$_[0]})->{START}; }
sub get_end    { tied(${$_[0]})->{LG} + tied(${$_[0]})->{START}; }


#------------------------------

=item binmode

=item close

=item flush

=item getc

=item getline

=item print LIST

=item printf LIST

=item read BUF, NBYTES

=item readline

=item seek OFFFSET, WHENCE

=item tell

=item write ARGS...

I<Instance methods.>
Standard filehandle methods.

=cut

sub write    { shift->WRITE(@_) }
sub print    { shift->PRINT(@_) }
sub printf   { shift->PRINTF(@_) }
sub flush    { "0 but true"; }
sub fileno   { }
sub binmode  { 1; }
sub getc     { return GETC(tied(${$_[0]}) ); }
sub read     { return READ(     tied(${$_[0]}), @_[1,2,3] ); }
sub readline { return READLINE( tied(${$_[0]}) ); }

sub getline  { return READLINE( tied(${$_[0]}) ); }
sub close    { return CLOSE(tied(${$_[0]}) ); }

sub seek {
   my ($self, $ofs, $whence) = @_;
   $self = tied( $$self );

   $self->{CRPOS} = $ofs if ($whence == 0);
   $self->{CRPOS}+= $ofs if ($whence == 1);
   $self->{CRPOS} = $self->{LG} + $ofs if ($whence == 2);

   $self->{CRPOS} = 0 if ($self->{CRPOS} < 0);
   $self->{CRPOS} = $self->{LG} if ($self->{CRPOS} > $self->{LG});
   return 1;
}

sub tell { 
    return tied(${$_[0]})->{CRPOS}; 
}

sub WRITE  { 
    die "inner files can only open for reading\n";
}

sub PRINT  {
    die "inner files can only open for reading\n";
}

sub PRINTF { 
    die "inner files can only open for reading\n";
}

sub GETC   { 
    my ($self) = @_;
    return 0 if ($self->{CRPOS} >= $self->{LG});

    my $data;

    ### Save and seek...
    my $old_pos = $self->{FH}->tell;
    $self->{FH}->seek($self->{CRPOS}+$self->{START}, 0);

    ### ...read...
    my $lg = $self->{FH}->read($data, 1);
    $self->{CRPOS} += $lg;

    ### ...and restore:
    $self->{FH}->seek($old_pos, 0);

    $self->{LG} = $self->{CRPOS} unless ($lg); 
    return ($lg ? $data : undef);
}

sub READ   { 
    my ($self, $undefined, $lg, $ofs) = @_;
    $undefined = undef;

    return 0 if ($self->{CRPOS} >= $self->{LG});
    $lg = $self->{LG} - $self->{CRPOS} if ($self->{CRPOS} + $lg > $self->{LG});
    return 0 unless ($lg);

    ### Save and seek...
    my $old_pos = $self->{FH}->tell;
    $self->{FH}->seek($self->{CRPOS}+$self->{START}, 0);

    ### ...read...
    $lg = $self->{FH}->read($_[1], $lg, $_[3] );
    $self->{CRPOS} += $lg;

    ### ...and restore:
    $self->{FH}->seek($old_pos, 0);

    $self->{LG} = $self->{CRPOS} unless ($lg); 
    return $lg;
}

sub READLINE {
    my ($self) = @_;
    return $self->_readline_helper() unless wantarray;
    my @arr;
    while(defined(my $line = $self->_readline_helper())) {
	    push(@arr, $line);
    }
    return @arr;
}

sub _readline_helper { 
    my ($self) = @_;
    return undef if ($self->{CRPOS} >= $self->{LG});

    # Handle slurp mode (CPAN ticket #72710)
    if (! defined($/)) {
	    my $text;
	    $self->READ($text, $self->{LG} - $self->{CRPOS});
	    return $text;
    }

    ### Save and seek...
    my $old_pos = $self->{FH}->tell;
    $self->{FH}->seek($self->{CRPOS}+$self->{START}, 0);

    ### ...read...
    my $text = $self->{FH}->getline;

    ### ...and restore:
    $self->{FH}->seek($old_pos, 0);

    #### If we detected a new EOF ...
    unless (defined $text) {  
       $self->{LG} = $self->{CRPOS};
       return undef;
    }

    my $lg=length($text);

    $lg = $self->{LG} - $self->{CRPOS} if ($self->{CRPOS} + $lg > $self->{LG});
    $self->{CRPOS} += $lg;

    return substr($text, 0,$lg);
}

sub CLOSE { %{$_[0]}=(); }



1;
__END__

=back


=head1 VERSION

$Id: InnerFile.pm,v 1.4 2005/02/10 21:21:53 dfs Exp $


=head1 AUTHOR

Original version by Doru Petrescu (pdoru@kappa.ro).

Documentation and by Eryq (eryq@zeegee.com).

Currently maintained by Dianne Skoll (dfs@roaringpenguin.com).

=cut


