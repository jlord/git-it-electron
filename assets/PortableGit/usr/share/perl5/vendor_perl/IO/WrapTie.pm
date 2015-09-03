# SEE DOCUMENTATION AT BOTTOM OF FILE


#------------------------------------------------------------
package IO::WrapTie;
#------------------------------------------------------------
require 5.004;              ### for tie
use strict;
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;

# Inheritance, exporting, and package version:
@ISA     = qw(Exporter);
@EXPORT  = qw(wraptie);
$VERSION = "2.111";

# Function, exported.
sub wraptie {
    IO::WrapTie::Master->new(@_);
}

# Class method; BACKWARDS-COMPATIBILITY ONLY!
sub new { 
    shift; 
    IO::WrapTie::Master->new(@_);
}



#------------------------------------------------------------
package IO::WrapTie::Master;
#------------------------------------------------------------

use strict;
use vars qw(@ISA $AUTOLOAD);
use IO::Handle;

# We inherit from IO::Handle to get methods which invoke i/o operators,
# like print(), on our tied handle:
@ISA = qw(IO::Handle);

#------------------------------
# new SLAVE, TIEARGS...
#------------------------------
# Create a new subclass of IO::Handle which...
#
#   (1) Handles i/o OPERATORS because it is tied to an instance of 
#       an i/o-like class, like IO::Scalar.
#
#   (2) Handles i/o METHODS by delegating them to that same tied object!.
#
# Arguments are the slave class (e.g., IO::Scalar), followed by all 
# the arguments normally sent into that class's TIEHANDLE method.
# In other words, much like the arguments to tie().  :-)
#
# NOTE:
# The thing $x we return must be a BLESSED REF, for ($x->print()).
# The underlying symbol must be a FILEHANDLE, for (print $x "foo").
# It has to have a way of getting to the "real" back-end object...
#
sub new {
    my $master = shift;
    my $io = IO::Handle->new;   ### create a new handle
    my $slave = shift;
    tie *$io, $slave, @_;       ### tie: will invoke slave's TIEHANDLE
    bless $io, $master;         ### return a master
}

#------------------------------
# AUTOLOAD
#------------------------------
# Delegate method invocations on the master to the underlying slave.
#
sub AUTOLOAD {
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    my $self = shift; tied(*$self)->$method(\@_);
}

#------------------------------
# PRELOAD
#------------------------------
# Utility.
#
# Most methods like print(), getline(), etc. which work on the tied object 
# via Perl's i/o operators (like 'print') are inherited from IO::Handle.
#
# Other methods, like seek() and sref(), we must delegate ourselves.
# AUTOLOAD takes care of these.
#
# However, it may be necessary to preload delegators into your
# own class.  PRELOAD will do this.
#
sub PRELOAD {
    my $class = shift;
    foreach (@_) {
	eval "sub ${class}::$_ { my \$s = shift; tied(*\$s)->$_(\@_) }";
    }    
}

# Preload delegators for some standard methods which we can't simply
# inherit from IO::Handle... for example, some IO::Handle methods 
# assume that there is an underlying file descriptor.
#
PRELOAD IO::WrapTie::Master 
    qw(open opened close read clearerr eof seek tell setpos getpos);



#------------------------------------------------------------
package IO::WrapTie::Slave;
#------------------------------------------------------------
# Teeny private class providing a new_tie constructor...
#
# HOW IT ALL WORKS:
# 
# Slaves inherit from this class.
#
# When you send a new_tie() message to a tie-slave class (like IO::Scalar),
# it first determines what class should provide its master, via TIE_MASTER.
# In this case, IO::Scalar->TIE_MASTER would return IO::Scalar::Master.
# Then, we create a new master (an IO::Scalar::Master) with the same args
# sent to new_tie.
#
# In general, the new() method of the master is inherited directly 
# from IO::WrapTie::Master.
#
sub new_tie {
    my $self = shift;
    $self->TIE_MASTER->new($self,@_);     ### e.g., IO::Scalar::Master->new(@_)
}

# Default class method for new_tie().
# All your tie-slave class (like IO::Scalar) has to do is override this 
# method with a method that returns the name of an appropriate "master"
# class for tying that slave.
#
sub TIE_MASTER { 'IO::WrapTie::Master' }

#------------------------------
1;
__END__


package IO::WrapTie;      ### for doc generator


=head1 NAME

IO::WrapTie - wrap tieable objects in IO::Handle interface

I<This is currently Alpha code, released for comments.  
  Please give me your feedback!>


=head1 SYNOPSIS

First of all, you'll need tie(), so:

   require 5.004;

I<Function interface (experimental).>
Use this with any existing class...

   use IO::WrapTie;
   use FooHandle;                  ### implements TIEHANDLE interface

   ### Suppose we want a "FooHandle->new(&FOO_RDWR, 2)".
   ### We can instead say...

   $FH = wraptie('FooHandle', &FOO_RDWR, 2); 

   ### Now we can use...    
   print $FH "Hello, ";            ### traditional operator syntax...
   $FH->print("world!\n");         ### ...and OO syntax as well!

I<OO interface (preferred).>
You can inherit from the IO::WrapTie::Slave mixin to get a
nifty C<new_tie()> constructor...

   #------------------------------    
   package FooHandle;                        ### a class which can TIEHANDLE

   use IO::WrapTie;  
   @ISA = qw(IO::WrapTie::Slave);            ### inherit new_tie()
   ...


   #------------------------------    
   package main; 

   $FH = FooHandle->new_tie(&FOO_RDWR, 2);   ### $FH is an IO::WrapTie::Master
   print $FH "Hello, ";                      ### traditional operator syntax
   $FH->print("world!\n");                   ### OO syntax

See IO::Scalar as an example.  It also shows you how to create classes
which work both with and without 5.004.


=head1 DESCRIPTION

Suppose you have a class C<FooHandle>, where...

=over 4

=item *

B<FooHandle does not inherit from IO::Handle;> that is, it performs
filehandle-like I/O, but to something other than an underlying
file descriptor.  Good examples are IO::Scalar (for printing to a
string) and IO::Lines (for printing to an array of lines).

=item *

B<FooHandle implements the TIEHANDLE interface> (see L<perltie>);
that is, it provides methods TIEHANDLE, GETC, PRINT, PRINTF,
READ, and READLINE.

=item *

B<FooHandle implements the traditional OO interface> of
FileHandle and IO::Handle; i.e., it contains methods like getline(), 
read(), print(), seek(), tell(), eof(), etc.

=back


Normally, users of your class would have two options:


=over 4

=item *

B<Use only OO syntax,> and forsake named I/O operators like 'print'.

=item * 

B<Use with tie,> and forsake treating it as a first-class object 
(i.e., class-specific methods can only be invoked through the underlying
object via tied()... giving the object a "split personality").

=back


But now with IO::WrapTie, you can say:

    $WT = wraptie('FooHandle', &FOO_RDWR, 2);
    $WT->print("Hello, world\n");   ### OO syntax
    print $WT "Yes!\n";             ### Named operator syntax too!
    $WT->weird_stuff;               ### Other methods!

And if you're authoring a class like FooHandle, just have it inherit 
from C<IO::WrapTie::Slave> and that first line becomes even prettier:

    $WT = FooHandle->new_tie(&FOO_RDWR, 2);

B<The bottom line:> now, almost any class can look and work exactly like
an IO::Handle... and be used both with OO and non-OO filehandle syntax.


=head1 HOW IT ALL WORKS


=head2 The data structures

Consider this example code, using classes in this distribution:

    use IO::Scalar;
    use IO::WrapTie;

    $WT = wraptie('IO::Scalar',\$s);
    print $WT "Hello, ";
    $WT->print("world!\n");

In it, the wraptie() function creates a data structure as follows:

                          * $WT is a blessed reference to a tied filehandle
              $WT           glob; that glob is tied to the "Slave" object.
               |          * You would do all your i/o with $WT directly.
               |       
               |
               |     ,---isa--> IO::WrapTie::Master >--isa--> IO::Handle
               V    /
        .-------------. 
        |             | 
        |             |   * Perl i/o operators work on the tied object,  
        |  "Master"   |     invoking the TIEHANDLE methods.
        |             |   * Method invocations are delegated to the tied 
        |             |     slave.
        `-------------' 
               |    
    tied(*$WT) |     .---isa--> IO::WrapTie::Slave
               V    /   
        .-------------.
        |             |
        |   "Slave"   |   * Instance of FileHandle-like class which doesn't
        |             |     actually use file descriptors, like IO::Scalar.
        |  IO::Scalar |   * The slave can be any kind of object.
        |             |   * Must implement the TIEHANDLE interface.
        `-------------'


I<NOTE:> just as an IO::Handle is really just a blessed reference to a 
I<traditional> filehandle glob... so also, an IO::WrapTie::Master 
is really just a blessed reference to a filehandle 
glob I<which has been tied to some "slave" class.>


=head2 How wraptie() works

=over 4

=item 1.

The call to function C<wraptie(SLAVECLASS, TIEARGS...)> is 
passed onto C<IO::WrapTie::Master::new()>.  
Note that class IO::WrapTie::Master is a subclass of IO::Handle.

=item 2.

The C<IO::WrapTie::Master::new> method creates a new IO::Handle object,
reblessed into class IO::WrapTie::Master.  This object is the I<master>, 
which will be returned from the constructor.  At the same time...

=item 3.

The C<new> method also creates the I<slave>: this is an instance 
of SLAVECLASS which is created by tying the master's IO::Handle 
to SLAVECLASS via C<tie(HANDLE, SLAVECLASS, TIEARGS...)>.  
This call to C<tie()> creates the slave in the following manner:

=item 4.

Class SLAVECLASS is sent the message C<TIEHANDLE(TIEARGS...)>; it 
will usually delegate this to C<SLAVECLASS::new(TIEARGS...)>, resulting
in a new instance of SLAVECLASS being created and returned.

=item 5.

Once both master and slave have been created, the master is returned
to the caller.  

=back


=head2 How I/O operators work (on the master)

Consider using an i/o operator on the master:

    print $WT "Hello, world!\n";   

Since the master ($WT) is really a [blessed] reference to a glob, 
the normal Perl i/o operators like C<print> may be used on it.
They will just operate on the symbol part of the glob.

Since the glob is tied to the slave, the slave's PRINT method 
(part of the TIEHANDLE interface) will be automatically invoked.  

If the slave is an IO::Scalar, that means IO::Scalar::PRINT will be 
invoked, and that method happens to delegate to the C<print()> method 
of the same class.  So the I<real> work is ultimately done by 
IO::Scalar::print().


=head2 How methods work (on the master)

Consider using a method on the master:

    $WT->print("Hello, world!\n");

Since the master ($WT) is blessed into the class IO::WrapTie::Master,
Perl first attempts to find a C<print()> method there.  Failing that,
Perl next attempts to find a C<print()> method in the superclass,
IO::Handle.  It just so happens that there I<is> such a method;
that method merely invokes the C<print> i/o operator on the self object...
and for that, see above!

But let's suppose we're dealing with a method which I<isn't> part
of IO::Handle... for example:

    my $sref = $WT->sref;

In this case, the intuitive behavior is to have the master delegate the
method invocation to the slave (now do you see where the designations
come from?).  This is indeed what happens: IO::WrapTie::Master contains
an AUTOLOAD method which performs the delegation.  

So: when C<sref()> can't be found in IO::Handle, the AUTOLOAD method
of IO::WrapTie::Master is invoked, and the standard behavior of
delegating the method to the underlying slave (here, an IO::Scalar)
is done.

Sometimes, to get this to work properly, you may need to create 
a subclass of IO::WrapTie::Master which is an effective master for
I<your> class, and do the delegation there.




=head1 NOTES

B<Why not simply use the object's OO interface?> 
    Because that means forsaking the use of named operators
like print(), and you may need to pass the object to a subroutine
which will attempt to use those operators:

    $O = FooHandle->new(&FOO_RDWR, 2);
    $O->print("Hello, world\n");  ### OO syntax is okay, BUT....

    sub nope { print $_[0] "Nope!\n" }
 X  nope($O);                     ### ERROR!!! (not a glob ref)


B<Why not simply use tie()?> 
    Because (1) you have to use tied() to invoke methods in the
object's public interface (yuck), and (2) you may need to pass 
the tied symbol to another subroutine which will attempt to treat 
it in an OO-way... and that will break it:

    tie *T, 'FooHandle', &FOO_RDWR, 2; 
    print T "Hello, world\n";   ### Operator is okay, BUT... 

    tied(*T)->other_stuff;      ### yuck! AND...

    sub nope { shift->print("Nope!\n") }
 X  nope(\*T);                  ### ERROR!!! (method "print" on unblessed ref)


B<Why a master and slave? 
  Why not simply write FooHandle to inherit from IO::Handle?>
    I tried this, with an implementation similar to that of IO::Socket.  
The problem is that I<the whole point is to use this with objects
that don't have an underlying file/socket descriptor.>.
Subclassing IO::Handle will work fine for the OO stuff, and fine with 
named operators I<if> you tie()... but if you just attempt to say:

    $IO = FooHandle->new(&FOO_RDWR, 2);
    print $IO "Hello!\n";

you get a warning from Perl like:

    Filehandle GEN001 never opened

because it's trying to do system-level i/o on an (unopened) file 
descriptor.  To avoid this, you apparently have to tie() the handle...
which brings us right back to where we started!  At least the
IO::WrapTie mixin lets us say:

    $IO = FooHandle->new_tie(&FOO_RDWR, 2);
    print $IO "Hello!\n";

and so is not I<too> bad.  C<:-)>


=head1 WARNINGS

Remember: this stuff is for doing FileHandle-like i/o on things
I<without underlying file descriptors>.  If you have an underlying
file descriptor, you're better off just inheriting from IO::Handle.

B<Be aware that new_tie() always returns an instance of a
kind of IO::WrapTie::Master...> it does B<not> return an instance 
of the i/o class you're tying to!  

Invoking some methods on the master object causes AUTOLOAD to delegate
them to the slave object... so it I<looks> like you're manipulating a 
"FooHandle" object directly, but you're not.

I have not explored all the ramifications of this use of tie().
I<Here there be dragons>.


=head1 VERSION

$Id: WrapTie.pm,v 1.2 2005/02/10 21:21:53 dfs Exp $


=head1 AUTHOR

=item Primary Maintainer

Dianne Skoll (F<dfs@roaringpenguin.com>).

=item Original Author

Eryq (F<eryq@zeegee.com>).
President, ZeeGee Software Inc (F<http://www.zeegee.com>).

=cut

