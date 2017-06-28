package ExtUtils::CBuilder::Platform::darwin;
$ExtUtils::CBuilder::Platform::darwin::VERSION = '0.280221';
use strict;
use ExtUtils::CBuilder::Platform::Unix;

use vars qw(@ISA);
@ISA = qw(ExtUtils::CBuilder::Platform::Unix);

sub compile {
  my $self = shift;
  my $cf = $self->{config};

  # -flat_namespace isn't a compile flag, it's a linker flag.  But
  # it's mistakenly in Config.pm as both.  Make the correction here.
  local $cf->{ccflags} = $cf->{ccflags};
  $cf->{ccflags} =~ s/-flat_namespace//;
  $self->SUPER::compile(@_);
}


1;
