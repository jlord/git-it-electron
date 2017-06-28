# Error/Simple.pm
#
# Copyright (c) 2006 Shlomi Fish <shlomif@shlomifish.org>.
# This file is free software; you can redistribute it and/or
# modify it under the terms of the MIT/X11 license (whereas the licence
# of the Error distribution as a whole is the GPLv1+ and the Artistic
# licence).

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = "0.17024";

use Error;

1;
__END__

=head1 NAME

Error::Simple - the simple error sub-class of Error

=head1 SYNOPSIS

    use base 'Error::Simple';

=head1 DESCRIPTION

The only purpose of this module is to allow one to say:

    use base 'Error::Simple';

and the only thing it does is "use" Error.pm. Refer to the documentation
of L<Error> for more information about Error::Simple.

=head1 METHODS

=head2 Error::Simple->new($text [, $value])

Constructs an Error::Simple with the text C<$text> and the optional value
C<$value>.

=head2 $err->stringify()

Error::Simple overloads this method.

=head1 KNOWN BUGS

None.

=head1 AUTHORS

Shlomi Fish ( L<http://www.shlomifish.org/> )

=head1 SEE ALSO

L<Error>

