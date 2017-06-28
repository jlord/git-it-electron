# Copyrights 1995-2014 by [Mark Overmeer <perl@overmeer.net>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.

use strict;
package Mail::Send;
use vars '$VERSION';
$VERSION = '2.14';


use Carp;
require Mail::Mailer;

sub Version { our $VERSION }


sub new(@)
{   my ($class, %attr) = @_;
    my $self = bless {}, $class;

    while(my($key, $value) = each %attr)
    {	$key = lc $key;
        $self->$key($value);
    }

    $self;
}


sub set($@)
{   my ($self, $hdr, @values) = @_;
    $self->{$hdr} = [ @values ] if @values;
    @{$self->{$hdr} || []};	# return new (or original) values
}


sub add($@)
{   my ($self, $hdr, @values) = @_;
    push @{$self->{$hdr}}, @values;
}


sub delete($)
{   my($self, $hdr) = @_;
    delete $self->{$hdr};
}


sub to		{ my $self=shift; $self->set('To', @_); }
sub cc		{ my $self=shift; $self->set('Cc', @_); }
sub bcc		{ my $self=shift; $self->set('Bcc', @_); }
sub subject	{ my $self=shift; $self->set('Subject', join (' ', @_)); }


sub open(@)
{   my $self = shift;
    Mail::Mailer->new(@_)->open($self);
}

1;
