#!/usr/bin/env perl
use warnings;
use strict;
use open qw(:locale);

my @lines;

while (<>) {
    s{\R\z}{};
    my @x = split();
    if (scalar @x == 2) {
        my ($replaceThis, $withThis) = @x;
        foreach my $line (@lines) {
            @$line = map { $_ eq $replaceThis ? $withThis : $_ } @$line;
        }
    }
    if (scalar @x > 2) {
        push(@lines, [@x]);
    }
}

foreach my $line (@lines) {
    print(join(" ", @$line), "\n");
}
