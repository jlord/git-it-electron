package autodie::ScopeUtil;

use strict;
use warnings;

# Docs say that perl 5.8.3 has Exporter 5.57 and autodie requires
# 5.8.4, so this should "just work".
use Exporter 5.57 qw(import);

use autodie::Scope::GuardStack;

our @EXPORT_OK = qw(on_end_of_compile_scope);

# ABSTRACT: Utilities for managing %^H scopes
our $VERSION = '2.26'; # VERSION

# docs says we should pick __PACKAGE__ /<whatever>
my $H_STACK_KEY = __PACKAGE__ . '/stack';

sub on_end_of_compile_scope {
    my ($hook) = @_;

    # Dark magic to have autodie work under 5.8
    # Copied from namespace::clean, that copied it from
    # autobox, that found it on an ancient scroll written
    # in blood.

    # This magic bit causes %^H to be lexically scoped.
    $^H |= 0x020000;

    my $stack = $^H{$H_STACK_KEY};
    if (not defined($stack)) {
        $stack = autodie::Scope::GuardStack->new;
        $^H{$H_STACK_KEY} = $stack;
    }

    $stack->push_hook($hook);
    return;
}

1;

=head1 NAME

autodie::ScopeUtil - Utilities for managing %^H scopes

=head1 SYNOPSIS

    use autodie::ScopeUtil qw(on_end_of_compile_scope);
    on_end_of_compile_scope(sub { print "Hallo world\n"; });

=head1 DESCRIPTION

Utilities for abstracting away the underlying magic of (ab)using
C<%^H> to call subs at the end of a (compile-time) scopes.

Due to how C<%^H> works, these utilities are only useful during the
compilation phase of a perl module and relies on the internals of how
perl handles references in C<%^H>.  This module is not a part of
autodie's public API.

=head2 Methods

=head3 on_end_of_compile_scope

  on_end_of_compile_scope(sub { print "Hallo world\n"; });

Will invoke a sub at the end of a (compile-time) scope.  The sub is
called once with no arguments.  Can be called multiple times (even in
the same "compile-time" scope) to install multiple subs.  Subs are
called in a "first-in-last-out"-order (FILO or "stack"-order).

=head1 AUTHOR

Copyright 2013, Niels Thykier E<lt>niels@thykier.netE<gt>

=head1 LICENSE

This module is free software.  You may distribute it under the
same terms as Perl itself.
