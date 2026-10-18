# find a word encoded with an unknown linear font (code = base + k*(ch-'A')), any stride; prints offset, base, k, stride
my ($file, $word) = @ARGV; open my $h, '<:raw', $file or die; local $/; my $d = <$h>; my @c = map { ord($_) - 65 } split //, $word;
my $n = length($d) / 2; my @w = unpack('n*', $d);
for my $st (1, 2, 3, 4) { for my $k (1, 2, 4) { for my $i (0 .. $n - 1 - $st * $#c) { my $b = $w[$i] - $k * $c[0]; my $ok = 1;
  for my $j (1 .. $#c) { if ($w[$i + $j * $st] != $b + $k * $c[$j]) { $ok = 0; last } } printf "%06X base=%04X k=%d stride=%d\n", 2 * $i, $b, $k, $st if $ok; } } }
