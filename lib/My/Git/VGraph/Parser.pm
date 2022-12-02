package My::Git::VGraph::Parser;
use warnings;
use strict;

use FindBin;
use lib "../../..";

use My::Git::VGraph;
use My::Git::VGraph::Printer;
use Text::Tabs qw(expand);

our $RX_ESCAPE;
BEGIN {
    $RX_ESCAPE = qr{\e\[[0-9;]*m};
}
sub new {
    my ($class, %args) = @_;
    my $self = bless(\%args, $class);
    $self->{vgraph} = My::Git::VGraph->new(%args);
    $self->{printer} = My::Git::VGraph::Printer->new(%args);
    $self->{printer}->{color} = 0 if !-t 1 && !$self->{options}->{isPaging};
    $self->{abbrev} //= ($self->{options}->{abbrev} // 8);
    return $self;
}
sub parseLine {
    my ($self, $line) = @_;
    $line =~ s{\R\z}{};        # safer than chomp regarding \r\n vs \n
    local $_ = $line;
    $_ = expand($_);
    my $RX_COMMIT_ID = qr{[[:xdigit:]]{$self->{abbrev},}}x;
    if (m{^(?<esc1>${RX_ESCAPE})?
          (commit[ ])?
          (?<commitids>(?:${RX_COMMIT_ID})(?:[ ](?:${RX_COMMIT_ID}))*\b)
          (?<esc2>\s*${RX_ESCAPE})?
          (?<remainder>.*)$}x) {
        my $esc1      = $+{esc1};
        my $commitids = $+{commitids};
        my $esc2      = $+{esc2};
        my $remainder = $+{remainder};
        my @commitids = grep { m{\S} } split(qr{\s+}, $commitids);
        $self->startCommit(@commitids);
        if (!$self->{options}->{parents}) {
            $line = ($esc1 // '') . $commitids[0] . ($esc2 // '') . $remainder;
        }
        $self->commitLogLine($line);
    } else {
        $self->commitLogLine($line);
    }
}
sub startCommit {
    my ($self, $commit, $firstParent, @otherParents) = @_;
    $self->{printer}->flush();
    my $data = $self->{vgraph}->commit($commit, $firstParent, @otherParents);
    my @left = @{$data->{left}};
    my @right = @{$data->{right}};
    my $leftFill = $data->{leftFill};
    $self->{printer}->setLeftFill($leftFill);
    foreach my $line (@left) {
        $self->{printer}->printLeft($line);
    }
    foreach my $line (@right) {
        $self->{printer}->printRight($line);
    }
}
sub commitLogLine {
    my ($self, $line) = @_;
    $self->{printer}->printRight($line);
}
sub eof {
    my ($self) = @_;
    $self->{printer}->flush();
}

1;
