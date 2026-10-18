my ($file, @addrs) = @ARGV;
open my $h, '<:raw', $file or die; local $/; my $d = <$h>;
for my $a (@addrs) {
  my $v = hex $a;
  for my $pat ([pack('N', $v), 'L'], [pack('n', $v & 0xFFFF), 'W']) {
    my ($p, $t) = @$pat; my $pos = 0; my @hits;
    while (($pos = index($d, $p, $pos)) >= 0) { push @hits, sprintf('%06X', $pos) if $pos % 2 == 0; $pos++; }
    @hits = @hits[0..19] if @hits > 20;
    printf "%s %s: %s\n", $a, $t, join(' ', @hits) if $t eq 'L' || @hits < 20;
  }
}
