# Find exact duplicates (same pens, either half) of given units' left halves across the whole gfx region
my ($gfx, @units) = @ARGV; open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>; my $n = length($g) / 64;
my %want; for my $u (@units) { my $L = join '', map { substr($g, hex($u) * 64 + $_ * 8, 4) } 0 .. 7; $want{$L} = $u; }
for my $v (0 .. $n - 1) { for my $hf (0, 1) { my $s = join '', map { substr($g, $v * 64 + $_ * 8 + 4 * $hf, 4) } 0 .. 7; if (exists $want{$s}) { printf "%s == %05X%s\n", $want{$s}, $v, $hf ? 'R' : 'L'; } } }
