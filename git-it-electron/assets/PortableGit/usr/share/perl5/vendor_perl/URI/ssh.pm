package URI::ssh;

use strict;
use warnings;

use parent 'URI::_login';

# ssh://[USER@]HOST[:PORT]/SRC

sub default_port { 22 }

sub secure { 1 }

1;
