package My::Git::VGraph::Printer;
use warnings;
use strict;

sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    $self->{minSpace} //= 6;
    $self->{minCol} //= 24;
    $self->{color} //= 1;
    $self->{leftLines} = [];
    $self->{rightLines} = [];
    return $self;
}
sub setLeftFill {
    my ($self, $text) = @_;
    $self->{leftFill} = $text;
}
sub printLeft {
    my ($self, $text) = @_;
    push(@{$self->{leftLines}}, $text);
    $self->printOut();
}
sub printRight {
    my ($self, $text) = @_;
    push(@{$self->{rightLines}}, $text);
    $self->printOut();
}
sub printOut {
    my ($self) = @_;
    my $L = $self->{leftLines};
    my $R = $self->{rightLines};
    while (scalar @$L && scalar @$R) {
        my $left = shift(@$L);
        my $right = shift(@$R);
        $self->printLine($left, $right);
    }
}
sub flush {
    my ($self) = @_;
    my $L = $self->{leftLines};
    my $R = $self->{rightLines};
    $self->printOut();
    while (scalar @$L || scalar @$R) {
        my $left = shift(@$L);
        my $right = shift(@$R);
        $self->printLine($left // $self->{leftFill} // '', $right);
    }
}
sub printLine {
    my ($self, $left, $right) = @_;
    return if !defined $left && !defined $right;
    $left //= '';
    $right //= '';
    $left .= ' ' x $self->{minSpace};
    my $len = printedLength($left);
    if ($len < $self->{minCol}) {
        $left .= ' ' x ($self->{minCol} - $len);
    }
    if (!$self->{color}) {
        $left  =~ s{\e\[[0-9;]*m}{}g;
        $right =~ s{\e\[[0-9;]*m}{}g;
    }
    print($left, $right, "\n");
}
sub printedLength {
    my ($string) = @_;
    $string =~ s{\e\[[0-9;]*m}{}g;
    return length $string;
}

1;
