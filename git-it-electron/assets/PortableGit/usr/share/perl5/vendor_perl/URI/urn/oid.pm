package URI::urn::oid;  # RFC 2061

use strict;
use warnings;

use parent 'URI::urn';

sub oid {
    my $self = shift;
    my $old = $self->nss;
    if (@_) {
	$self->nss(join(".", @_));
    }
    return split(/\./, $old) if wantarray;
    return $old;
}

1;
