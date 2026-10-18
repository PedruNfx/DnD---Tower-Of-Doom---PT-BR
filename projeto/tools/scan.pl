# Scan for 16-bit encoded strings: hi byte = attribute, lo byte = char code
require "$ENV{T}/tbl.pl";
my ($file) = @ARGV;
open my $h, '<:raw', $file or die; local $/; my $d = <$h>;
my @w = unpack('n*', $d);
my %attr;
my ($start, $run, $txt) = (-1, 0, '');
for my $i (0 .. $#w) {
  my ($hi, $lo) = ($w[$i] >> 8, $w[$i] & 0xFF);
  if ($w[$i] == 0x2F2F) { $txt .= '/'; next if $start >= 0; }
  if ($start >= 0 || 1) {
    if ($lo >= 0x40 && $lo <= 0xAF && $hi != 0 && $hi < 0x40) {
      $start = $i if $start < 0; $attr{$hi}++;
      $txt .= exists $Tbl::dec{$lo} ? $Tbl::dec{$lo} : sprintf('{%02X}', $lo); $run++;
      next;
    }
  }
  if ($run >= 6) { printf "%06X: %s%s\n", $start*2, $txt, ($w[$i] == 0x4040 ? '@' : sprintf('<%04X>', $w[$i])); }
  ($start, $run, $txt) = (-1, 0, '');
}
print STDERR join(' ', map { sprintf '%02X:%d', $_, $attr{$_} } sort { $attr{$b} <=> $attr{$a} } keys %attr), "\n";
