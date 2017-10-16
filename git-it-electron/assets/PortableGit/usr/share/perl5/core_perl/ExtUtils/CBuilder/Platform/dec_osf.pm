package ExtUtils::CBuilder::Platform::dec_osf;
$ExtUtils::CBuilder::Platform::dec_osf::VERSION = '0.280221';
use strict;
use ExtUtils::CBuilder::Platform::Unix;
use File::Spec;

use vars qw(@ISA);
@ISA = qw(ExtUtils::CBuilder::Platform::Unix);

sub link_executable {
  my $self = shift;
  # $Config{ld} is 'ld' but that won't work: use the cc instead.
  local $self->{config}{ld} = $self->{config}{cc};
  return $self->SUPER::link_executable(@_);
}

1;
