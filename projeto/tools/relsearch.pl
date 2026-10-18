# Relative search: find a word encoded with unknown constant offset, at byte stride 1 or 2 (also 16-bit word stride)
my ($file, @words) = @ARGV;
open my $h, '<:raw', $file or die; local $/; my $d = <$h>; my $n = length $d;
my @b = unpack('C*', $d);
for my $w (@words) {
  my @c = map { ord } split //, uc $w; my $L = @c;
  for my $stride (1, 2) {
    for my $i (0 .. $n - $L*$stride - 1) {
      my $off = ($b[$i] - $c[0]) & 0xFF; my $ok = 1;
      for my $k (1 .. $L-1) { if ((($b[$i+$k*$stride] - $c[$k]) & 0xFF) != $off) { $ok = 0; last } }
      next unless $ok;
      next if $off == 0 && $stride == 1;  # plain ascii already seen
      my $ctx = join ' ', map { sprintf '%02X', $b[$_] } $i .. $i + $L*$stride + 7;
      printf "%-10s stride%d off=%02X at %06X: %s\n", $w, $stride, $off, $i, $ctx;
    }
  }
}
