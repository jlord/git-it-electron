# Copyrights 1995-2014 by [Mark Overmeer <perl@overmeer.net>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use strict;
package Mail::Filter;
use vars '$VERSION';
$VERSION = '2.14';


use Carp;

sub new(@)
{   my $class = shift;
    bless { filters => [ @_ ] }, $class;
}


sub add(@)
{   my $self = shift;
    push @{$self->{filters}}, @_;
}


sub _filter($)
{   my ($self, $mail) = @_;

    foreach my $sub ( @{$self->{filters}} )
    {   my $mail
          = ref $sub eq 'CODE' ? $sub->($self,$mail)
	  : !ref $sub          ? $self->$sub($mail)
	  : carp "Cannot call filter '$sub', ignored";

	ref $mail or last;
    }

    $mail;
}

sub filter
{   my ($self, $obj) = @_;
    if($obj->isa('Mail::Folder'))
    {   $self->{folder} = $obj;
	foreach my $m ($obj->message_list)
	{   my $mail = $obj->get_message($m) or next;
	    $self->{msgnum} = $m;
	    $self->_filter($mail);
	}
	delete $self->{folder};
	delete $self->{msgnum};
    }
    elsif($obj->isa('Mail::Internet'))
    {   return $self->filter($obj);
    }
    else
    {   carp "Cannot process '$obj'";
	return undef;
    }
}


sub folder() {shift->{folder}}


sub msgnum() {shift->{msgnum}}

1;
