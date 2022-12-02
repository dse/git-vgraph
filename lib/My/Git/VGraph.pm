package My::Git::VGraph;
use warnings;
use strict;

use FindBin;
use lib "../..";

use My::Git::VGraph::PriorityFight;
use My::Git::VGraph::Draw::ASCII;

use List::Util qw(min max);
sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    $self->{strategy} //= $self->{options}->{strategy};
    $self->{colSep} //= ($self->{options}->{colSep} // 3);
    $self->{pri} = My::Git::VGraph::PriorityFight->new(%args) if $self->usingPriorityFight;
    $self->{draw} = My::Git::VGraph::Draw::ASCII->new(%args);
    return $self;
}
sub commit {
    my ($self, @commitids) = @_;
    my ($commit, @parents) = @commitids;
    my ($firstParent, @otherParents) = @parents;
    my $reserved = $self->{RC} //= {};
    my $columns  = $self->{C} //= {};
    my $state1   = { %$columns };
    my $state2;

    my @left;
    my @right;
    my $leftFill;

    if (!defined $columns->{$commit}) {
        $columns->{$commit} = $self->newColumn($columns);
        $state1->{$commit} = $columns->{$commit};
        if (defined $self->{orphaned}) {
            # if previous commit A had no parents and this commit B is
            # assigned same column, insert a "blank" line to render
            # properly, and not mislead people that A's parent is B.
            if ($columns->{$commit} == $self->{orphaned}) {
                push(@left, $self->{orphanLine});
                push(@right, '');
            }
            delete $self->{orphanLine};
            delete $self->{orphaned};
        }
    }
    if (!defined $firstParent) {
        if ($self->usingPriorityFight) {
            $self->{pri}->remove($commit);
        }
        $self->{orphaned} = $state1->{$commit};
        delete $state1->{$commit};
        my $maxCol = max grep { defined $_ } values %$columns;
        my $line1 = $self->{draw}->vertical($maxCol, $columns, $columns->{$commit});
        my $line2 = $self->{draw}->vertical($maxCol, $state1);
        $self->{orphanLine} = $line2; # may need later
        $leftFill = $line2;
        push(@left, $line1);
        %$columns = %$state1;
        return {
            left => \@left,
            right => \@right,
            leftFill => $leftFill,
        };
    }

    $state1->{$firstParent} //= $columns->{$commit};
    foreach my $otherParent (@otherParents) {
        $state1->{$otherParent} //= $self->newColumn($state1);
    }

    my $switchFromColumn;
    my $switchToColumn;
    if ($self->usingPriorityFight) {
        # normally if a commit and its first parent are assigned
        # to different columns, we move from current commit's
        # column $col1 to the first parent's column $col2.
        my $col1 = $state1->{$commit};
        my $col2 = $state1->{$firstParent};
        if ($col1 != $col2) {
            my ($winner, $loser) = $self->{pri}->winner($commit, $firstParent);
            if (defined $winner && $state1->{$winner} == $col1) {
                # we move first parent from $col2 to current
                # commit's column $col1
                $state2 = { %$state1 };
                $switchFromColumn = $col2;
                $switchToColumn   = $col1;
            }
        }
    }
    if ($self->usingLeftmostColumn) {
        my $col1 = $state1->{$commit};
        my $col2 = $state1->{$firstParent};
        if ($col1 != $col2) {
            my $newCol = min($col1, $col2);
            if ($newCol != $col2) {
                $state2 = { %$state1 };
                $switchFromColumn = $col2;
                $switchToColumn   = $col1;
            }
        }
    }

    my $maxCol = max grep { defined $_ } (values(%$columns), values(%$state1));
    my @diagLines1;
    my @diagLines2;
    if (defined $switchFromColumn && defined $switchToColumn) {
        my @verticalColumns = ($switchFromColumn, (map { $columns->{$_} }
                                                   grep { defined $state1->{$_} && $columns->{$_} == $state1->{$_} }
                                                   keys %$columns));
        my @diagonalsToColumns = map { $state1->{$_} } @otherParents;
        @diagLines1 = $self->{draw}->draw(
            mode => 'diagonals',
            maxCol => $maxCol,
            verticalColumns => [@verticalColumns],
            diagonalsFromColumn => $columns->{$commit},
            diagonalsToColumns => [@diagonalsToColumns],
        );
        @verticalColumns = ($switchToColumn, (grep { $_ != $switchFromColumn } values %$state1));
        @diagLines2 = $self->{draw}->draw(
            mode => 'diagonals',
            maxCol => $maxCol,
            verticalColumns => [@verticalColumns],
            diagonalsFromColumn => $switchFromColumn,
            diagonalsToColumns => [$switchToColumn],
        );
        $state2->{$firstParent} = $state2->{$commit};
        delete $state2->{$commit};
    } else {
        delete $state1->{$commit};
        my @verticalColumns = (map { $columns->{$_} }
                               grep { defined $state1->{$_} && $columns->{$_} == $state1->{$_} }
                               keys %$columns);
        my @diagonalsToColumns = map { $state1->{$_} } ($firstParent, @otherParents);
        @diagLines1 = $self->{draw}->draw(
            mode => 'diagonals',
            maxCol => $maxCol,
            verticalColumns => [@verticalColumns],
            diagonalsFromColumn => $columns->{$commit},
            diagonalsToColumns => [@diagonalsToColumns],
        );
    }
    $leftFill = $self->{draw}->vertical($maxCol, $state2 // $state1);
    my $line0 = $self->{draw}->vertical($maxCol, $columns, $columns->{$commit});
    push(@left, $line0);
    foreach my $diagLine (@diagLines1, @diagLines2) {
        push(@left, $diagLine);
    }
    if ($self->usingPriorityFight) {
        $self->{pri}->add($commit, $firstParent, @otherParents);
        $self->{pri}->replace($commit, $firstParent, @otherParents);
    }
    if (defined $state2) {
        %$columns = %$state2;
    } else {
        %$columns = %$state1;
    }

    return {
        left => \@left,
        right => \@right,
        leftFill => $leftFill,
    };
}
sub newColumn {
    my ($self, @states) = @_;
    my @columns = grep { defined $_ } map { (values(%$_)) } @states;
    my %columns = map { ($_ => 1) } @columns;
    for (my $i = 0; ; $i += 1) {
        if (!$columns{$i}) {
            return $i;
        }
    }
}
sub usingPriorityFight {
    my ($self) = @_;
    return defined $self->{strategy} && $self->{strategy} eq 'priority-fight';
}
sub usingLeftmostColumn {
    my ($self) = @_;
    return defined $self->{strategy} && $self->{strategy} eq 'leftmost-column';
}

1;
