# Copyrights 1995-2014 by [Mark Overmeer <perl@overmeer.net>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use strict;

package Mail::Field::Date;
use vars '$VERSION';
$VERSION = '2.14';

use base 'Mail::Field';

use Date::Format qw(time2str);
use Date::Parse  qw(str2time);

(bless [])->register('Date');


sub set()
{   my $self = shift;
    my $arg = @_ == 1 ? shift : { @_ };

    foreach my $s (qw(Time TimeStr))
    {   if(exists $arg->{$s})
             { $self->{$s} = $arg->{$s} }
        else { delete $self->{$s} }
    }

    $self;
}

sub parse($)
{   my $self = shift;
    delete $self->{Time};
    $self->{TimeStr} = shift;
    $self;
}


sub time(;$)
{   my $self = shift;

    if(@_)
    {   delete $self->{TimeStr};
        return $self->{Time} = shift;
    }

    $self->{Time} ||= str2time $self->{TimeStr};
}

sub stringify
{   my $self = shift;
    $self->{TimeStr} ||= time2str("%a, %e %b %Y %T %z", $self->time);
}

sub reformat
{   my $self = shift;
    $self->time($self->time);
    $self->stringify;
}

1;
