package Test::Simple;

use 5.006;

use strict;

our $VERSION = '1.001014';
$VERSION = eval $VERSION;    ## no critic (BuiltinFunctions::ProhibitStringyEval)

use Test::Builder::Module 0.99;
our @ISA    = qw(Test::Builder::Module);
our @EXPORT = qw(ok);

my $CLASS = __PACKAGE__;

=head1 NAME

Test::Simple - Basic utilities for writing tests.

=head1 SYNOPSIS

  use Test::Simple tests => 1;

  ok( $foo eq $bar, 'foo is bar' );


=head1 DESCRIPTION

** If you are unfamiliar with testing B<read L<Test::Tutorial> first!> **

This is an extremely simple, extremely basic module for writing tests
suitable for CPAN modules and other pursuits.  If you wish to do more
complicated testing, use the Test::More module (a drop-in replacement
for this one).

The basic unit of Perl testing is the ok.  For each thing you want to
test your program will print out an "ok" or "not ok" to indicate pass
or fail.  You do this with the C<ok()> function (see below).

The only other constraint is you must pre-declare how many tests you
plan to run.  This is in case something goes horribly wrong during the
test and your test program aborts, or skips a test or whatever.  You
do this like so:

    use Test::Simple tests => 23;

You must have a plan.


=over 4

=item B<ok>

  ok( $foo eq $bar, $name );
  ok( $foo eq $bar );

C<ok()> is given an expression (in this case C<$foo eq $bar>).  If it's
true, the test passed.  If it's false, it didn't.  That's about it.

C<ok()> prints out either "ok" or "not ok" along with a test number (it
keeps track of that for you).

  # This produces "ok 1 - Hell not yet frozen over" (or not ok)
  ok( get_temperature($hell) > 0, 'Hell not yet frozen over' );

If you provide a $name, that will be printed along with the "ok/not
ok" to make it easier to find your test when if fails (just search for
the name).  It also makes it easier for the next guy to understand
what your test is for.  It's highly recommended you use test names.

All tests are run in scalar context.  So this:

    ok( @stuff, 'I have some stuff' );

will do what you mean (fail if stuff is empty)

=cut

sub ok ($;$) {    ## no critic (Subroutines::ProhibitSubroutinePrototypes)
    return $CLASS->builder->ok(@_);
}

=back

Test::Simple will start by printing number of tests run in the form
"1..M" (so "1..5" means you're going to run 5 tests).  This strange
format lets L<Test::Harness> know how many tests you plan on running in
case something goes horribly wrong.

If all your tests passed, Test::Simple will exit with zero (which is
normal).  If anything failed it will exit with how many failed.  If
you run less (or more) tests than you planned, the missing (or extras)
will be considered failures.  If no tests were ever run Test::Simple
will throw a warning and exit with 255.  If the test died, even after
having successfully completed all its tests, it will still be
considered a failure and will exit with 255.

So the exit codes are...

    0                   all tests successful
    255                 test died or all passed but wrong # of tests run
    any other number    how many failed (including missing or extras)

If you fail more than 254 tests, it will be reported as 254.

This module is by no means trying to be a complete testing system.
It's just to get you started.  Once you're off the ground its
recommended you look at L<Test::More>.


=head1 EXAMPLE

Here's an example of a simple .t file for the fictional Film module.

    use Test::Simple tests => 5;

    use Film;  # What you're testing.

    my $btaste = Film->new({ Title    => 'Bad Taste',
                             Director => 'Peter Jackson',
                             Rating   => 'R',
                             NumExplodingSheep => 1
                           });
    ok( defined($btaste) && ref $btaste eq 'Film',     'new() works' );

    ok( $btaste->Title      eq 'Bad Taste',     'Title() get'    );
    ok( $btaste->Director   eq 'Peter Jackson', 'Director() get' );
    ok( $btaste->Rating     eq 'R',             'Rating() get'   );
    ok( $btaste->NumExplodingSheep == 1,        'NumExplodingSheep() get' );

It will produce output like this:

    1..5
    ok 1 - new() works
    ok 2 - Title() get
    ok 3 - Director() get
    not ok 4 - Rating() get
    #   Failed test 'Rating() get'
    #   in t/film.t at line 14.
    ok 5 - NumExplodingSheep() get
    # Looks like you failed 1 tests of 5

Indicating the Film::Rating() method is broken.


=head1 CAVEATS

Test::Simple will only report a maximum of 254 failures in its exit
code.  If this is a problem, you probably have a huge test script.
Split it into multiple files.  (Otherwise blame the Unix folks for
using an unsigned short integer as the exit status).

Because VMS's exit codes are much, much different than the rest of the
universe, and perl does horrible mangling to them that gets in my way,
it works like this on VMS.

    0     SS$_NORMAL        all tests successful
    4     SS$_ABORT         something went wrong

Unfortunately, I can't differentiate any further.


=head1 NOTES

Test::Simple is B<explicitly> tested all the way back to perl 5.6.0.

Test::Simple is thread-safe in perl 5.8.1 and up.

=head1 HISTORY

This module was conceived while talking with Tony Bowden in his
kitchen one night about the problems I was having writing some really
complicated feature into the new Testing module.  He observed that the
main problem is not dealing with these edge cases but that people hate
to write tests B<at all>.  What was needed was a dead simple module
that took all the hard work out of testing and was really, really easy
to learn.  Paul Johnson simultaneously had this idea (unfortunately,
he wasn't in Tony's kitchen).  This is it.


=head1 SEE ALSO

=over 4

=item L<Test::More>

More testing functions!  Once you outgrow Test::Simple, look at
L<Test::More>.  Test::Simple is 100% forward compatible with L<Test::More>
(i.e. you can just use L<Test::More> instead of Test::Simple in your
programs and things will still work).

=back

Look in L<Test::More>'s SEE ALSO for more testing modules.


=head1 AUTHORS

Idea by Tony Bowden and Paul Johnson, code by Michael G Schwern
E<lt>schwern@pobox.comE<gt>, wardrobe by Calvin Klein.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2001-2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
