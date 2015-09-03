# -*- Mode: cperl; coding: utf-8; cperl-indent-level: 4 -*-
# vim: ts=4 sts=4 sw=4:
package CPAN::Exception::RecursiveDependency;
use strict;
use overload '""' => "as_string";

use vars qw(
            $VERSION
);
$VERSION = "5.5";

# a module sees its distribution (no version)
# a distribution sees its prereqs (which are module names) (usually with versions)
# a bundle sees its module names and/or its distributions (no version)

sub new {
    my($class) = shift;
    my($deps_arg) = shift;
    my (@deps,%seen,$loop_starts_with);
  DCHAIN: for my $dep (@$deps_arg) {
        push @deps, {name => $dep, display_as => $dep};
        if ($seen{$dep}++) {
            $loop_starts_with = $dep;
            last DCHAIN;
        }
    }
    my $in_loop = 0;
    for my $i (0..$#deps) {
        my $x = $deps[$i]{name};
        $in_loop ||= $loop_starts_with && $x eq $loop_starts_with;
        my $xo = CPAN::Shell->expandany($x) or next;
        if ($xo->isa("CPAN::Module")) {
            my $have = $xo->inst_version || "N/A";
            my($want,$d,$want_type);
            if ($i>0 and $d = $deps[$i-1]{name}) {
                my $do = CPAN::Shell->expandany($d);
                $want = $do->{prereq_pm}{requires}{$x};
                if (defined $want) {
                    $want_type = "requires: ";
                } else {
                    $want = $do->{prereq_pm}{build_requires}{$x};
                    if (defined $want) {
                        $want_type = "build_requires: ";
                    } else {
                        $want_type = "unknown status";
                        $want = "???";
                    }
                }
            } else {
                $want = $xo->cpan_version;
                $want_type = "want: ";
            }
            $deps[$i]{have} = $have;
            $deps[$i]{want_type} = $want_type;
            $deps[$i]{want} = $want;
            $deps[$i]{display_as} = "$x (have: $have; $want_type$want)";
        } elsif ($xo->isa("CPAN::Distribution")) {
            $deps[$i]{display_as} = $xo->pretty_id;
            if ($in_loop) {
                $xo->{make} = CPAN::Distrostatus->new("NO cannot resolve circular dependency");
            } else {
                $xo->{make} = CPAN::Distrostatus->new("NO one dependency ($loop_starts_with) is a circular dependency");
            }
            $xo->store_persistent_state; # otherwise I will not reach
                                         # all involved parties for
                                         # the next session
        }
    }
    bless { deps => \@deps, loop_starts_with => $loop_starts_with }, $class;
}

sub as_string {
    my($self) = shift;
    my $deps = $self->{deps};
    my $loop_starts_with = $self->{loop_starts_with};
    unless ($loop_starts_with) {
        return "--not a recursive/circular dependency--";
    }
    my $ret = "\nRecursive dependency detected:\n    ";
    $ret .= join("\n => ", map {$_->{display_as}} @$deps);
    $ret .= ".\nCannot resolve.\n";
    $ret;
}

1;
