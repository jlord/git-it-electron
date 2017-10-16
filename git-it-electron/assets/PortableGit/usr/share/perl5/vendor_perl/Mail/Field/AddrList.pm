# Copyrights 1995-2014 by [Mark Overmeer <perl@overmeer.net>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use strict;

package Mail::Field::AddrList;
use vars '$VERSION';
$VERSION = '2.14';

use base 'Mail::Field';

use Carp;
use Mail::Address;


my $x = bless [];
$x->register('To');
$x->register('From');
$x->register('Cc');
$x->register('Reply-To');
$x->register('Sender');

sub create(@)
{   my ($self, %arg)  = @_;
    $self->{AddrList} = {};

    while(my ($e, $n) = each %arg)
    {   $self->{AddrList}{$e} = Mail::Address->new($n, $e);
    }

    $self;
}

sub parse($)
{   my ($self, $string) = @_;
    foreach my $a (Mail::Address->parse($string))
    {   my $e = $a->address;
	$self->{AddrList}{$e} = $a;
    }
    $self;
}

sub stringify()
{   my $self = shift;
    join(", ", map { $_->format } values %{$self->{AddrList}});
}


sub addresses { keys %{shift->{AddrList}} }


# someone forgot to implement a method to return the Mail::Address
# objects.  Added in 2.00; a pity that the name addresses() is already
# given :(  That one should have been named emails()
sub addr_list { values %{shift->{AddrList}} }


sub names { map { $_->name } values %{shift->{AddrList}} }


sub set_address($$)
{   my ($self, $email, $name) = @_;
    $self->{AddrList}{$email} = Mail::Address->new($name, $email);
    $self;
}

1;
