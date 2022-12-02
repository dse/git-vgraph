package My::Git::VGraph::PriorityFight;
use warnings;
use strict;

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    $self->{pri} = {};
    return $self;
}
sub winner {
    my ($self, $a, $b) = @_;
    my $pri = $self->{pri};
    if ($pri->{$a}->{$b}) {
        return ($a, $b) if wantarray;
        return  $a;
    }
    if ($pri->{$b}->{$a}) {
        return ($b, $a) if wantarray;
        return  $b;
    }
    return;
}
sub as_string {
    my ($self) = @_;
    my $pri = $self->{pri};
    my @rules;
    foreach my $a (keys %$pri) {
        foreach my $b (keys %{$pri->{$a}}) {
            push(@rules, sprintf("%s > %s [%d]", $a, $b, $pri->{$a}->{$b}));
        }
    }
    return join(' ', @rules);
}
sub add {
    my ($self, $commit, $a, @b) = @_;
    my $pri = $self->{pri};
    foreach my $b (@b) {
        if ($pri->{$a}->{$b}) {
            next;
        }
        if ($pri->{$b}->{$a}) {
            next;
        }
        if ($a eq $b) {
            next;
        }
        $pri->{$a}->{$b} = 1;
    }
}
sub replace {
    my ($self, $a, $b, @p) = @_;
    my $pri = $self->{pri};
    return $self->priorityUnmention($a) if !defined $b;
    foreach my $x (keys %{$pri->{$a}}) {
        delete $pri->{$a}->{$x};
        if ($pri->{$b}->{$x}) {
            next;
        }
        if ($pri->{$x}->{$b}) {
            next;
        }
        if ($b eq $x) {
            next;
        }
        $pri->{$b}->{$x} = 1;
    }
    delete $pri->{$a} if !scalar keys %{$pri->{$a}};
    foreach my $x (keys %$pri) {
        if ($pri->{$x}->{$a}) {
            delete $pri->{$x}->{$a};
            if ($pri->{$b}->{$x}) {
                next;
            }
            if ($pri->{$x}->{$b}) {
                next;
            }
            if ($x eq $b) {
                next;
            }
            $pri->{$x}->{$b} = 1;
        }
    }
}
sub remove {
    my ($self, $a) = @_;
    my $pri = $self->{pri};
    delete $pri->{$a};
    foreach my $b (keys %$pri) {
        delete $pri->{$b}->{$a};
        delete $pri->{$b} if !scalar keys %{$pri->{$b}};
    }
}

1;
