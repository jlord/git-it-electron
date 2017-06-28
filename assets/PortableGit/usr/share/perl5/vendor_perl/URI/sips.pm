package URI::sips;

use strict;
use warnings;

use parent 'URI::sip';

sub default_port { 5061 }

sub secure { 1 }

1;
