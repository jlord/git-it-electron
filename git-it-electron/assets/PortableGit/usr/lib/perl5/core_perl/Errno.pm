# -*- buffer-read-only: t -*-
#
# This file is auto-generated. ***ANY*** changes here will be lost
#

package Errno;
require Exporter;
use Config;
use strict;

"$Config{'archname'}-$Config{'osvers'}" eq
"i686-msys-thread-multi-64int-2.1.4(0.28753)" or
	die "Errno architecture (i686-msys-thread-multi-64int-2.1.4(0.28753)) does not match executable architecture ($Config{'archname'}-$Config{'osvers'})";

our $VERSION = "1.23";
$VERSION = eval $VERSION;
our @ISA = 'Exporter';

my %err;

BEGIN {
    %err = (
	EPERM => 1,
	ENOENT => 2,
	ESRCH => 3,
	EINTR => 4,
	EIO => 5,
	ENXIO => 6,
	E2BIG => 7,
	ENOEXEC => 8,
	EBADF => 9,
	ECHILD => 10,
	EAGAIN => 11,
	EWOULDBLOCK => 11,
	ENOMEM => 12,
	EACCES => 13,
	EFAULT => 14,
	ENOTBLK => 15,
	EBUSY => 16,
	EEXIST => 17,
	EXDEV => 18,
	ENODEV => 19,
	ENOTDIR => 20,
	EISDIR => 21,
	EINVAL => 22,
	ENFILE => 23,
	EMFILE => 24,
	ENOTTY => 25,
	ETXTBSY => 26,
	EFBIG => 27,
	ENOSPC => 28,
	ESPIPE => 29,
	EROFS => 30,
	EMLINK => 31,
	EPIPE => 32,
	EDOM => 33,
	ERANGE => 34,
	ENOMSG => 35,
	EIDRM => 36,
	ECHRNG => 37,
	EL2NSYNC => 38,
	EL3HLT => 39,
	EL3RST => 40,
	ELNRNG => 41,
	EUNATCH => 42,
	ENOCSI => 43,
	EL2HLT => 44,
	EDEADLK => 45,
	ENOLCK => 46,
	EBADE => 50,
	EBADR => 51,
	EXFULL => 52,
	ENOANO => 53,
	EBADRQC => 54,
	EBADSLT => 55,
	EDEADLOCK => 56,
	EBFONT => 57,
	ENOSTR => 60,
	ENODATA => 61,
	ETIME => 62,
	ENOSR => 63,
	ENONET => 64,
	ENOPKG => 65,
	EREMOTE => 66,
	ENOLINK => 67,
	EADV => 68,
	ESRMNT => 69,
	ECOMM => 70,
	EPROTO => 71,
	EMULTIHOP => 74,
	ELBIN => 75,
	EDOTDOT => 76,
	EBADMSG => 77,
	EFTYPE => 79,
	ENOTUNIQ => 80,
	EBADFD => 81,
	EREMCHG => 82,
	ELIBACC => 83,
	ELIBBAD => 84,
	ELIBSCN => 85,
	ELIBMAX => 86,
	ELIBEXEC => 87,
	ENOSYS => 88,
	ENMFILE => 89,
	ENOTEMPTY => 90,
	ENAMETOOLONG => 91,
	ELOOP => 92,
	EOPNOTSUPP => 95,
	EPFNOSUPPORT => 96,
	ECONNRESET => 104,
	ENOBUFS => 105,
	EAFNOSUPPORT => 106,
	EPROTOTYPE => 107,
	ENOTSOCK => 108,
	ENOPROTOOPT => 109,
	ESHUTDOWN => 110,
	ECONNREFUSED => 111,
	EADDRINUSE => 112,
	ECONNABORTED => 113,
	ENETUNREACH => 114,
	ENETDOWN => 115,
	ETIMEDOUT => 116,
	EHOSTDOWN => 117,
	EHOSTUNREACH => 118,
	EINPROGRESS => 119,
	EALREADY => 120,
	EDESTADDRREQ => 121,
	EMSGSIZE => 122,
	EPROTONOSUPPORT => 123,
	ESOCKTNOSUPPORT => 124,
	EADDRNOTAVAIL => 125,
	ENETRESET => 126,
	EISCONN => 127,
	ENOTCONN => 128,
	ETOOMANYREFS => 129,
	EPROCLIM => 130,
	EUSERS => 131,
	EDQUOT => 132,
	ESTALE => 133,
	ENOTSUP => 134,
	ENOMEDIUM => 135,
	ENOSHARE => 136,
	ECASECLASH => 137,
	EILSEQ => 138,
	EOVERFLOW => 139,
	ECANCELED => 140,
	ENOTRECOVERABLE => 141,
	EOWNERDEAD => 142,
	ESTRPIPE => 143,
    );
    # Generate proxy constant subroutines for all the values.
    # Well, almost all the values. Unfortunately we can't assume that at this
    # point that our symbol table is empty, as code such as if the parser has
    # seen code such as C<exists &Errno::EINVAL>, it will have created the
    # typeglob.
    # Doing this before defining @EXPORT_OK etc means that even if a platform is
    # crazy enough to define EXPORT_OK as an error constant, everything will
    # still work, because the parser will upgrade the PCS to a real typeglob.
    # We rely on the subroutine definitions below to update the internal caches.
    # Don't use %each, as we don't want a copy of the value.
    foreach my $name (keys %err) {
        if ($Errno::{$name}) {
            # We expect this to be reached fairly rarely, so take an approach
            # which uses the least compile time effort in the common case:
            eval "sub $name() { $err{$name} }; 1" or die $@;
        } else {
            $Errno::{$name} = \$err{$name};
        }
    }
}

our @EXPORT_OK = keys %err;

our %EXPORT_TAGS = (
    POSIX => [qw(
	E2BIG EACCES EADDRINUSE EADDRNOTAVAIL EAFNOSUPPORT EAGAIN EALREADY
	EBADF EBUSY ECHILD ECONNABORTED ECONNREFUSED ECONNRESET EDEADLK
	EDESTADDRREQ EDOM EDQUOT EEXIST EFAULT EFBIG EHOSTDOWN EHOSTUNREACH
	EINPROGRESS EINTR EINVAL EIO EISCONN EISDIR ELOOP EMFILE EMLINK
	EMSGSIZE ENAMETOOLONG ENETDOWN ENETRESET ENETUNREACH ENFILE ENOBUFS
	ENODEV ENOENT ENOEXEC ENOLCK ENOMEM ENOPROTOOPT ENOSPC ENOSYS ENOTBLK
	ENOTCONN ENOTDIR ENOTEMPTY ENOTSOCK ENOTTY ENXIO EOPNOTSUPP EPERM
	EPFNOSUPPORT EPIPE EPROCLIM EPROTONOSUPPORT EPROTOTYPE ERANGE EREMOTE
	EROFS ESHUTDOWN ESOCKTNOSUPPORT ESPIPE ESRCH ESTALE ETIMEDOUT
	ETOOMANYREFS ETXTBSY EUSERS EWOULDBLOCK EXDEV
    )]
);

sub TIEHASH { bless \%err }

sub FETCH {
    my (undef, $errname) = @_;
    return "" unless exists $err{$errname};
    my $errno = $err{$errname};
    return $errno == $! ? $errno : 0;
}

sub STORE {
    require Carp;
    Carp::confess("ERRNO hash is read only!");
}

*CLEAR = *DELETE = \*STORE; # Typeglob aliasing uses less space

sub NEXTKEY {
    each %err;
}

sub FIRSTKEY {
    my $s = scalar keys %err;	# initialize iterator
    each %err;
}

sub EXISTS {
    my (undef, $errname) = @_;
    exists $err{$errname};
}

tie %!, __PACKAGE__; # Returns an object, objects are true.

__END__

=head1 NAME

Errno - System errno constants

=head1 SYNOPSIS

    use Errno qw(EINTR EIO :POSIX);

=head1 DESCRIPTION

C<Errno> defines and conditionally exports all the error constants
defined in your system C<errno.h> include file. It has a single export
tag, C<:POSIX>, which will export all POSIX defined error numbers.

C<Errno> also makes C<%!> magic such that each element of C<%!> has a
non-zero value only if C<$!> is set to that value. For example:

    use Errno;

    unless (open(FH, "/fangorn/spouse")) {
        if ($!{ENOENT}) {
            warn "Get a wife!\n";
        } else {
            warn "This path is barred: $!";
        } 
    } 

If a specified constant C<EFOO> does not exist on the system, C<$!{EFOO}>
returns C<"">.  You may use C<exists $!{EFOO}> to check whether the
constant is available on the system.

=head1 CAVEATS

Importing a particular constant may not be very portable, because the
import will fail on platforms that do not have that constant.  A more
portable way to set C<$!> to a valid value is to use:

    if (exists &Errno::EFOO) {
        $! = &Errno::EFOO;
    }

=head1 AUTHOR

Graham Barr <gbarr@pobox.com>

=head1 COPYRIGHT

Copyright (c) 1997-8 Graham Barr. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# ex: set ro:
