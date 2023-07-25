package My::Git::VGraph::Draw::ASCII;
use warnings;
use strict;

use List::Util qw(min max);
sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    $self->{bullet} //= $self->{options}->{bullet} // "#";
    $self->{stubby} //= $self->{options}->{stubby} // 0;
    $self->{unicode} //= $self->{options}->{unicode} // 0;
    return $self;
}
sub vertical {
    my ($self, $maxCol, $A, $mark, @revLists) = @_;
    my @vcol = grep { defined $_ } values(%$A);
    return $self->draw(
        maxCol => $maxCol,
        mode => 'verticals',
        verticalColumns => \@vcol,
        markColumn => $mark,
        revLists => [@revLists],
    );
}
sub draw {
    my ($self, %args) = @_;

    # conceptually specifies what kind of drawing you're doing; in
    # reality only determines type of return value.
    my $mode = $args{mode};

    my $stubby = $self->{stubby};

    my @revLists = @{$args{revLists} // []};
    my $code = scalar @revLists ? $revLists[0]{code} : undef;

    my $maxCol              = $args{maxCol};
    my @verticalColumns     = eval { @{$args{verticalColumns}} };
    my $diagonalsFromColumn = $args{diagonalsFromColumn};
    my @diagonalsToColumns  = eval { @{$args{diagonalsToColumns}} };
    my $markColumn          = $args{markColumn};

    if ($mode eq 'verticals') {
        return if !scalar @verticalColumns && !defined $markColumn;
    }

    my $colSep = $self->{colSep};
    my $useLine1;
    my $useLine2;
    my $line1 = ' ' x ($maxCol * $colSep + 1);
    my $line2 = ' ' x ($maxCol * $colSep + 1);
    my @leftColumns  = grep { $_ < $diagonalsFromColumn } @diagonalsToColumns;
    my @rightColumns = grep { $_ > $diagonalsFromColumn } @diagonalsToColumns;

    my $leftLow = $self->{unicode} ? "\N{LEFT LOW PARAPHRASE BRACKET}" : ".";
    my $rightLow = $self->{unicode} ? "\N{RIGHT LOW PARAPHRASE BRACKET}" : ".";
    my $leftRaised = $self->{unicode} ? "\N{LEFT RAISED OMISSION BRACKET}" : "'";
    my $rightRaised = $self->{unicode} ? "\N{RIGHT RAISED OMISSION BRACKET}" : "'";

    if (defined $diagonalsFromColumn) {
        if (scalar @leftColumns) {
            $useLine1 = 1;
            if ($stubby) {
                substr($line1, $diagonalsFromColumn * $colSep - 1, 1) = $rightRaised;
            } else {
                substr($line1, $diagonalsFromColumn * $colSep - 1, 1) = '/';
            }
            my $leftmostColumn = min @leftColumns;
            foreach my $column (@leftColumns) {
                if ($stubby) {
                    if ($column == $diagonalsFromColumn - 1 && $colSep < 3) {
                        substr($line1, $column * $colSep + 1, 1) = "/";
                    } else {
                        substr($line1, $column * $colSep + 1, 1) = $rightLow;
                    }
                } else {
                    next if $column == $diagonalsFromColumn - 1 && $colSep < 3;
                    $useLine2 = 1;
                    substr($line2, $column * $colSep + 1, 1) = '/';
                }
            }
            my $pos1 = $leftmostColumn * $colSep + 2;
            my $pos2 = $diagonalsFromColumn * $colSep - 2;
            if ($pos1 <= $pos2) {
                if ($stubby) {
                    substr($line1, $pos1, $pos2 - $pos1 + 1) = '-' x ($pos2 - $pos1 + 1);
                } else {
                    substr($line1, $pos1, $pos2 - $pos1 + 1) = '_' x ($pos2 - $pos1 + 1);
                }
            }
        }
        if (scalar @rightColumns) {
            $useLine1 = 1;
            if ($stubby) {
                substr($line1, $diagonalsFromColumn * $colSep + 1, 1) = $leftRaised;
            } else {
                substr($line1, $diagonalsFromColumn * $colSep + 1, 1) = '\\';
            }
            my $rightmostColumn = max @rightColumns;
            foreach my $column (@rightColumns) {
                if ($stubby) {
                    if ($column == $diagonalsFromColumn + 1 && $colSep < 3) {
                        substr($line1, $column * $colSep - 1, 1) = "\\";
                    } else {
                        substr($line1, $column * $colSep - 1, 1) = $leftLow;
                    }
                } else {
                    next if $column == $diagonalsFromColumn + 1 && $colSep < 3;
                    $useLine2 = 1;
                    substr($line2, $column * $colSep - 1, 1) = '\\';
                }
            }
            my $pos1 = $diagonalsFromColumn * $colSep + 2;
            my $pos2 = $rightmostColumn * $colSep - 2;
            if ($pos1 <= $pos2) {
                if ($stubby) {
                    substr($line1, $pos1, $pos2 - $pos1 + 1) = '-' x ($pos2 - $pos1 + 1);
                } else {
                    substr($line1, $pos1, $pos2 - $pos1 + 1) = '_' x ($pos2 - $pos1 + 1);
                }
            }
        }
        if (grep { $diagonalsFromColumn == $_ } @diagonalsToColumns) {
            substr($line1, $diagonalsFromColumn * $colSep, 1) = '|';
            if ($useLine2) {
                substr($line2, $diagonalsFromColumn * $colSep, 1) = '|';
            }
        }
    }
    foreach my $column (@verticalColumns) {
        substr($line1, $column * $colSep, 1) = '|';
        if ($useLine2) {
            substr($line2, $column * $colSep, 1) = '|';
        }
    }
    if ($self->{colSep} < 3) {
        foreach my $column (@diagonalsToColumns) {
            if ($column == $diagonalsFromColumn - 1 || $column == $diagonalsFromColumn + 1) {
                # there is a diagonal from column n to column n-1 or
                # n+1 if there are also diagonals to columns 2+
                # columns away
                if ($useLine2) {
                    substr($line2, $column * $colSep, 1) = '|';
                }
            }
        }
    }
    if (defined $markColumn) {
        my $bullet = $self->{bullet};
        substr($line1, $markColumn * $colSep, 1) = $bullet;
        if (defined $code) {
            $line1 =~ s{\Q$bullet\E}{\e[103;30;1m$code\e[m}g;
        } else {
            $line1 =~ s{\Q$bullet\E}{\e[1;33m$&\e[m}g;
        }
    }
    if ($mode eq 'diagonals') {
        return ($line1, $line2) if $useLine2;
        return ($line1) if $useLine1;
        return ();
    }
    if ($mode eq 'verticals') {
        return $line1;
    }
}

1;
