# Build CPS2 gfx region (ROM_LOAD64_WORD interleave + per-2MB-bank unshuffle)
my ($romdir, $out) = @ARGV;
my @sets = ([0x000000, 0x200000, qw(dad.13m dad.15m dad.17m dad.19m)], [0x800000, 0x100000, qw(dad.14m dad.16m dad.18m dad.20m)]);
my $reg = "\0" x 0xC00000;
for my $s (@sets) {
  my ($base, $size, @f) = @$s;
  my @d = map { open my $h, '<:raw', "$romdir/$_" or die "$_: $!"; local $/; scalar <$h> } @f;
  my $n = $size / 2;
  my $chunk = '';
  for my $j (0 .. $n - 1) { $chunk .= substr($d[0], 2*$j, 2) . substr($d[1], 2*$j, 2) . substr($d[2], 2*$j, 2) . substr($d[3], 2*$j, 2); }
  substr($reg, $base, length $chunk) = $chunk;
}
# unshuffle: within each 2MB bank, even qwords then odd qwords
my $res = '';
for (my $b = 0; $b < length $reg; $b += 0x200000) {
  my @q = unpack('(a8)*', substr($reg, $b, 0x200000));
  $res .= join('', @q[grep { !($_ & 1) } 0 .. $#q]) . join('', @q[grep { $_ & 1 } 0 .. $#q]);
}
open my $o, '>:raw', $out or die; print $o $res; close $o; print length($res), "\n";
