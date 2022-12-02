package My::Git::VGraph::Draw::BoxDrawing;
use warnings;
use strict;

use List::Util qw(min max);
sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    $self->{bullet} //= $self->{options}->{bullet} // "\N{BLACK CIRCLE}";
    $self->{arcs} = 1;
    return $self;
}
sub vertical {
    my ($self, $maxCol, $A, $mark) = @_;
    my @vcol = grep { defined $_ } values(%$A);
    return $self->draw(
        maxCol => $maxCol,
        mode => 'verticals',
        verticalColumns => \@vcol,
        markColumn => $mark,
    );
}
sub draw {
    my ($self, %args) = @_;

    # conceptually specifies what kind of drawing you're doing; in
    # reality only determines type of return value.
    my $mode = $args{mode};

    my $maxCol              = $args{maxCol};
    my @verticalColumns     = eval { @{$args{verticalColumns}} };
    my $diagonalsFromColumn = $args{diagonalsFromColumn};
    my @diagonalsToColumns  = eval { @{$args{diagonalsToColumns}} };
    my $markColumn          = $args{markColumn};

    if ($mode eq 'verticals') {
        return if !scalar @verticalColumns && !defined $markColumn;
    }

    my $useLine1;
    my @line1;
    my @leftColumns  = grep { $_ < $diagonalsFromColumn } @diagonalsToColumns;
    my @rightColumns = grep { $_ > $diagonalsFromColumn } @diagonalsToColumns;
    if (defined $diagonalsFromColumn) {
        if (scalar @leftColumns) {
            $useLine1 = 1;
            $line1[$diagonalsFromColumn]{t} = 1;
            $line1[$diagonalsFromColumn]{l} = 1;
            $line1[$diagonalsFromColumn]{tl} = 1;
            my $leftmostColumn = min @leftColumns;
            foreach my $column (@leftColumns) {
                $line1[$column]{r} = 1;
                $line1[$column]{b} = 1;
                $line1[$column]{rb} = 1;
            }
            my $pos1 = $leftmostColumn + 1;
            my $pos2 = $diagonalsFromColumn - 1;
            for (my $pos = $pos1; $pos <= $pos2; $pos += 1) {
                $line1[$pos]{l} = 1;
                $line1[$pos]{r} = 1;
            }
        }
        if (scalar @rightColumns) {
            $useLine1 = 1;
            $line1[$diagonalsFromColumn]{t} = 1;
            $line1[$diagonalsFromColumn]{r} = 1;
            $line1[$diagonalsFromColumn]{tr} = 1;
            my $rightmostColumn = max @rightColumns;
            foreach my $column (@rightColumns) {
                $line1[$column]{l} = 1;
                $line1[$column]{b} = 1;
                $line1[$column]{bl} = 1;
            }
            my $pos1 = $diagonalsFromColumn + 1;
            my $pos2 = $rightmostColumn - 1;
            for (my $pos = $pos1; $pos <= $pos2; $pos += 1) {
                $line1[$pos]{l} = 1;
                $line1[$pos]{r} = 1;
                $line1[$pos]{rl} = 1;
            }
        }
        if (grep { $diagonalsFromColumn == $_ } @diagonalsToColumns) {
            $line1[$diagonalsFromColumn]{t} = 1;
            $line1[$diagonalsFromColumn]{b} = 1;
        }
    }
    foreach my $column (@verticalColumns) {
        $line1[$column]{t} = 1;
        $line1[$column]{b} = 1;
    }
    if (defined $markColumn) {
        $line1[$markColumn]{bullet} = 1;
    }
    if ($mode eq 'diagonals') {
        return $self->boxDrawing(@line1) if $useLine1;
        return ();
    }
    if ($mode eq 'verticals') {
        return $self->boxDrawing(@line1);
    }
}
our %boxDrawing;
our %boxDrawingArcs;
INIT {
    %boxDrawing = (
        ''     => "\N{SPACE}",
        't'    => "\N{BOX DRAWINGS LIGHT UP}",
        'r'    => "\N{BOX DRAWINGS LIGHT RIGHT}",
        'b'    => "\N{BOX DRAWINGS LIGHT DOWN}",
        'l'    => "\N{BOX DRAWINGS LIGHT LEFT}",
        'tr'   => "\N{BOX DRAWINGS LIGHT UP AND RIGHT}",
        'tb'   => "\N{BOX DRAWINGS LIGHT VERTICAL}",
        'tl'   => "\N{BOX DRAWINGS LIGHT UP AND LEFT}",
        'rb'   => "\N{BOX DRAWINGS LIGHT DOWN AND RIGHT}",
        'rl'   => "\N{BOX DRAWINGS LIGHT HORIZONTAL}",
        'bl'   => "\N{BOX DRAWINGS LIGHT DOWN AND LEFT}",
        'trb'  => "\N{BOX DRAWINGS LIGHT VERTICAL AND RIGHT}",
        'trl'  => "\N{BOX DRAWINGS LIGHT UP AND HORIZONTAL}",
        'tbl'  => "\N{BOX DRAWINGS LIGHT VERTICAL AND LEFT}",
        'rbl'  => "\N{BOX DRAWINGS LIGHT DOWN AND HORIZONTAL}",
        'trbl' => "\N{BOX DRAWINGS LIGHT VERTICAL AND HORIZONTAL}",
    );
    %boxDrawingArcs = (
        'rb'   => "\N{BOX DRAWINGS LIGHT ARC DOWN AND RIGHT}",
        'bl'   => "\N{BOX DRAWINGS LIGHT ARC DOWN AND LEFT}",
        'tl'   => "\N{BOX DRAWINGS LIGHT ARC UP AND LEFT}",
        'tr'   => "\N{BOX DRAWINGS LIGHT ARC UP AND RIGHT}",
    );
}
sub boxDrawing {
    my ($self, @cells) = @_;
    my $line = '';
    for (my $i = 0; $i < scalar @cells; $i += 1) {
        if ($i) {
            $line .= $self->boxDrawingBetweenCells($cells[$i - 1], $cells[$i]) x ($self->{colSep} - 1);
        }
        $line .= $self->boxDrawingCell($cells[$i]);
    }
    return $line;
}
sub boxDrawingCell {
    my ($self, $cell) = @_;
    if ($cell->{bullet}) {
        return "\e[1;33m" . $self->{bullet} . "\e[m";
    }

    my $type = '';
    $type .= 't' if $cell->{t};
    $type .= 'r' if $cell->{r};
    $type .= 'b' if $cell->{b};
    $type .= 'l' if $cell->{l};

    if ($self->{arcs}) {
        return $boxDrawingArcs{tr} if $cell->{tr} && !$cell->{l};
        return $boxDrawingArcs{tl} if $cell->{tl} && !$cell->{r};
        return $boxDrawingArcs{rb} if $cell->{rb} && !$cell->{l};
        return $boxDrawingArcs{bl} if $cell->{bl} && !$cell->{r};
    }
    return $boxDrawing{$type};
}
sub boxDrawingBetweenCells {
    my ($self, $cell1, $cell2) = @_;
    if ($cell2->{l} && $cell1->{r}) {
        return $boxDrawing{rl};
    }
    return $boxDrawing{''};
}

1;
