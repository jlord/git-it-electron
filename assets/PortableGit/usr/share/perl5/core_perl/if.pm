package if;

$VERSION = '0.0604';

sub work {
  my $method = shift() ? 'import' : 'unimport';
  die "Too few arguments to 'use if' (some code returning an empty list in list context?)"
    unless @_ >= 2;
  return unless shift;		# CONDITION

  my $p = $_[0];		# PACKAGE
  (my $file = "$p.pm") =~ s!::!/!g;
  require $file;		# Works even if $_[0] is a keyword (like open)
  my $m = $p->can($method);
  goto &$m if $m;
}

sub import   { shift; unshift @_, 1; goto &work }
sub unimport { shift; unshift @_, 0; goto &work }

1;
__END__

=head1 NAME

if - C<use> a Perl module if a condition holds (also can C<no> a module)

=head1 SYNOPSIS

  use if CONDITION, MODULE => ARGUMENTS;
  no if CONDITION, MODULE => ARGUMENTS;

=head1 DESCRIPTION

The C<if> module is used to conditionally load or unload another module.
The construct

  use if CONDITION, MODULE => ARGUMENTS;

will load MODULE only if CONDITION evaluates to true.
The above statement has no effect unless C<CONDITION> is true.
If the CONDITION does evaluate to true, then the above line has
the same effect as:

  use MODULE ARGUMENTS;

The use of C<< => >> above provides necessary quoting of C<MODULE>.
If you don't use the fat comma (eg you don't have any ARGUMENTS),
then you'll need to quote the MODULE.

=head2 EXAMPLES

The following line is taken from the testsuite for L<File::Map>:

  use if $^O ne 'MSWin32', POSIX => qw/setlocale LC_ALL/;

If run on any operating system other than Windows,
this will import the functions C<setlocale> and C<LC_ALL> from L<POSIX>.
On Windows it does nothing.

The following is used to L<deprecate> core modules beyond a certain version of Perl:

  use if $] > 5.016, 'deprecate';

This line is taken from L<Text::Soundex> 3.04,
and marks it as deprecated beyond Perl 5.16.
If you C<use Text::Soundex> in Perl 5.18, for example,
and you have used L<warnings>,
then you'll get a warning message
(the deprecate module looks to see whether the
calling module was C<use>'d from a core library directory,
and if so, generates a warning),
unless you've installed a more recent version of L<Text::Soundex> from CPAN.

You can also specify to NOT use something:

 no if $] ge 5.021_006, warnings => "locale";

This warning category was added in the specified Perl version (a development
release).  Without the C<'if'>, trying to use it in an earlier release would
generate an unknown warning category error.

=head1 BUGS

The current implementation does not allow specification of the
required version of the module.

=head1 SEE ALSO

L<Module::Requires> can be used to conditionally load one or modules,
with constraints based on the version of the module.
Unlike C<if> though, L<Module::Requires> is not a core module.

L<Module::Load::Conditional> provides a number of functions you can use to
query what modules are available, and then load one or more of them at runtime.

L<provide> can be used to select one of several possible modules to load,
based on what version of Perl is running.

=head1 AUTHOR

Ilya Zakharevich L<mailto:ilyaz@cpan.org>.

=cut

