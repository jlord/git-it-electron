# For internal Module::CoreList use only.
package Module::CoreList::TieHashDelta;
use strict;
use vars qw($VERSION);

$VERSION = '5.20150520';

sub TIEHASH {
    my ($class, $changed, $removed, $parent) = @_;

    return bless {
        changed => $changed,
        removed => $removed,
        parent => $parent,
        keys_inflated => 0,
    }, $class;
}

sub FETCH {
    my ($self, $key) = @_;

    if (exists $self->{changed}{$key}) {
        return $self->{changed}{$key};
    } elsif (exists $self->{removed}{$key}) {
        return undef;
    } elsif (defined $self->{parent}) {
        return $self->{parent}{$key};
    }
    return undef;
}

sub EXISTS {
    my ($self, $key) = @_;

    restart:
    if (exists $self->{changed}{$key}) {
        return 1;
    } elsif (exists $self->{removed}{$key}) {
        return '';
    } elsif (defined $self->{parent}) {
        $self = tied %{$self->{parent}}; #avoid extreme magic/tie recursion
        goto restart;
    }
    return '';
}

sub FIRSTKEY {
    my ($self) = @_;

    if (not $self->{keys_inflated}) {
        # This inflates the whole set of hashes... Somewhat expensive, but saves
        # many tied hash calls later.
        my @parent_keys;
        if (defined $self->{parent}) {
            @parent_keys = keys %{$self->{parent}};
        }

        @parent_keys = grep !exists $self->{removed}{$_}, @parent_keys;
        for my $key (@parent_keys) {
            next if exists $self->{changed}->{$key};
            $self->{changed}{$key} = $self->{parent}{$key};
        }

        $self->{keys_inflated} = 1;
    }

    keys %{$self->{changed}}; # reset each
    $self->NEXTKEY;
}

sub NEXTKEY {
    my ($self) = @_;
    each %{$self->{changed}};
}

1;
