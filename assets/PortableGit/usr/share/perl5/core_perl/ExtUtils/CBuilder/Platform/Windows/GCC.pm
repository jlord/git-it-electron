package ExtUtils::CBuilder::Platform::Windows::GCC;
$ExtUtils::CBuilder::Platform::Windows::GCC::VERSION = '0.280220';
sub format_compiler_cmd {
  my ($self, %spec) = @_;

  foreach my $path ( @{ $spec{includes} || [] },
                     @{ $spec{perlinc}  || [] } ) {
    $path = '-I' . $path;
  }

  # split off any -arguments included in cc
  my @cc = split / (?=-)/, $spec{cc};

  return [ grep {defined && length} (
    @cc, '-c'               ,
    @{$spec{includes}}      ,
    @{$spec{cflags}}        ,
    @{$spec{optimize}}      ,
    @{$spec{defines}}       ,
    @{$spec{perlinc}}       ,
    '-o', $spec{output}     ,
    $spec{source}           ,
  ) ];
}

sub format_linker_cmd {
  my ($self, %spec) = @_;
  my $cf = $self->{config};

  # The Config.pm variable 'libperl' is hardcoded to the full name
  # of the perl import library (i.e. 'libperl56.a'). GCC will not
  # find it unless the 'lib' prefix & the extension are stripped.
  $spec{libperl} =~ s/^(?:lib)?([^.]+).*$/-l$1/;

  unshift( @{$spec{other_ldflags}}, '-nostartfiles' )
    if ( $spec{startup} && @{$spec{startup}} );

  # From ExtUtils::MM_Win32:
  #
  ## one thing for GCC/Mingw32:
  ## we try to overcome non-relocateable-DLL problems by generating
  ##    a (hopefully unique) image-base from the dll's name
  ## -- BKS, 10-19-1999
  File::Basename::basename( $spec{output} ) =~ /(....)(.{0,4})/;
  $spec{image_base} = sprintf( "0x%x0000", unpack('n', $1 ^ $2) );

  %spec = $self->write_linker_script(%spec)
    if $spec{use_scripts};

  foreach my $path ( @{$spec{libpath}} ) {
    $path = "-L$path";
  }

  my @cmds; # Stores the series of commands needed to build the module.

  my $DLLTOOL = $cf->{dlltool} || 'dlltool';

  push @cmds, [
    $DLLTOOL, '--def'        , $spec{def_file},
              '--output-exp' , $spec{explib}
  ];

  # split off any -arguments included in ld
  my @ld = split / (?=-)/, $spec{ld};

  push @cmds, [ grep {defined && length} (
    @ld                       ,
    '-o', $spec{output}       ,
    "-Wl,--base-file,$spec{base_file}"   ,
    "-Wl,--image-base,$spec{image_base}" ,
    @{$spec{lddlflags}}       ,
    @{$spec{libpath}}         ,
    @{$spec{startup}}         ,
    @{$spec{objects}}         ,
    @{$spec{other_ldflags}}   ,
    $spec{libperl}            ,
    @{$spec{perllibs}}        ,
    $spec{explib}             ,
    $spec{map_file} ? ('-Map', $spec{map_file}) : ''
  ) ];

  push @cmds, [
    $DLLTOOL, '--def'        , $spec{def_file},
              '--output-exp' , $spec{explib},
              '--base-file'  , $spec{base_file}
  ];

  push @cmds, [ grep {defined && length} (
    @ld                       ,
    '-o', $spec{output}       ,
    "-Wl,--image-base,$spec{image_base}" ,
    @{$spec{lddlflags}}       ,
    @{$spec{libpath}}         ,
    @{$spec{startup}}         ,
    @{$spec{objects}}         ,
    @{$spec{other_ldflags}}   ,
    $spec{libperl}            ,
    @{$spec{perllibs}}        ,
    $spec{explib}             ,
    $spec{map_file} ? ('-Map', $spec{map_file}) : ''
  ) ];

  return @cmds;
}

sub write_linker_script {
  my ($self, %spec) = @_;

  my $script = File::Spec->catfile( $spec{srcdir},
                                    $spec{basename} . '.lds' );

  $self->add_to_cleanup($script);

  print "Generating script '$script'\n" if !$self->{quiet};

  my $SCRIPT = IO::File->new( ">$script" )
    or die( "Could not create script '$script': $!" );

  print $SCRIPT ( 'SEARCH_DIR(' . $_ . ")\n" )
    for @{delete $spec{libpath} || []};

  # gcc takes only one startup file, so the first object in startup is
  # specified as the startup file and any others are shifted into the
  # beginning of the list of objects.
  if ( $spec{startup} && @{$spec{startup}} ) {
    print $SCRIPT 'STARTUP(' . shift( @{$spec{startup}} ) . ")\n";
    unshift @{$spec{objects}},
      @{delete $spec{startup} || []};
  }

  print $SCRIPT 'INPUT(' . join( ',',
    @{delete $spec{objects}  || []}
  ) . ")\n";

  print $SCRIPT 'INPUT(' . join( ' ',
     (delete $spec{libperl}  || ''),
    @{delete $spec{perllibs} || []},
  ) . ")\n";

  #it is important to keep the order 1.linker_script - 2.other_ldflags
  unshift @{$spec{other_ldflags}}, '"' . $script . '"';

  return %spec;
}

1;


