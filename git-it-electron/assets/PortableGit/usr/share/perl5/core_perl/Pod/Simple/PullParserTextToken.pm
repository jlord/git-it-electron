
require 5;
package Pod::Simple::PullParserTextToken;
use Pod::Simple::PullParserToken ();
use strict;
use vars qw(@ISA $VERSION);
@ISA = ('Pod::Simple::PullParserToken');
$VERSION = '3.29';

sub new {  # Class->new(text);
  my $class = shift;
  return bless ['text', @_], ref($class) || $class;
}

# Purely accessors:

sub text { (@_ == 2) ? ($_[0][1] = $_[1]) : $_[0][1] }

sub text_r { \ $_[0][1] }

1;

__END__

=head1 NAME

Pod::Simple::PullParserTextToken -- text-tokens from Pod::Simple::PullParser

=head1 SYNOPSIS

(See L<Pod::Simple::PullParser>)

=head1 DESCRIPTION

When you do $parser->get_token on a L<Pod::Simple::PullParser>, you might
get an object of this class.

This is a subclass of L<Pod::Simple::PullParserToken> and inherits all its methods,
and adds these methods:

=over

=item $token->text

This returns the text that this token holds.  For example, parsing
CZ<><foo> will return a C start-token, a text-token, and a C end-token.  And
if you want to get the "foo" out of the text-token, call C<< $token->text >>

=item $token->text(I<somestring>)

This changes the string that this token holds.  You probably won't need
to do this.

=item $token->text_r()

This returns a scalar reference to the string that this token holds.
This can be useful if you don't want to memory-copy the potentially
large text value (well, as large as a paragraph or a verbatim block)
as calling $token->text would do.

Or, if you want to alter the value, you can even do things like this:

  for ( ${  $token->text_r  } ) {  # Aliases it with $_ !!

    s/ The / the /g; # just for example

    if( 'A' eq chr(65) ) {  # (if in an ASCII world)
      tr/\xA0/ /;
      tr/\xAD//d;
    }

    ...or however you want to alter the value...
  }

=back

You're unlikely to ever need to construct an object of this class for
yourself, but if you want to, call
C<<
Pod::Simple::PullParserTextToken->new( I<text> )
>>

=head1 SEE ALSO

L<Pod::Simple::PullParserToken>, L<Pod::Simple>, L<Pod::Simple::Subclassing>

=head1 SUPPORT

Questions or discussion about POD and Pod::Simple should be sent to the
pod-people@perl.org mail list. Send an empty email to
pod-people-subscribe@perl.org to subscribe.

This module is managed in an open GitHub repository,
L<https://github.com/theory/pod-simple/>. Feel free to fork and contribute, or
to clone L<git://github.com/theory/pod-simple.git> and send patches!

Patches against Pod::Simple are welcome. Please send bug reports to
<bug-pod-simple@rt.cpan.org>.

=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2002 Sean M. Burke.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Pod::Simple was created by Sean M. Burke <sburke@cpan.org>.
But don't bother him, he's retired.

Pod::Simple is maintained by:

=over

=item * Allison Randal C<allison@perl.org>

=item * Hans Dieter Pearcey C<hdp@cpan.org>

=item * David E. Wheeler C<dwheeler@cpan.org>

=back

=cut
