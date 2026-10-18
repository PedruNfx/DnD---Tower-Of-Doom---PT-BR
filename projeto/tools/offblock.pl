# Dump an "offset block": u16 offsets (relative to base, signed) followed by records ending in 0x4040.
# usage: offblock.pl prog.bin base_hex nentries_or_0 hdrwords
require "$ENV{T}/tbl.pl";
my ($file, $base, $n, $nh) = @ARGV; $base = hex $base; $nh //= 5;
open my $h, '<:raw', $file or die; local $/; my $d = <$h>;
if (!$n) { my $first = 0xFFFF; for (my $i = 0; ; $i++) { my $o = unpack('n', substr($d, $base + 2 * $i, 2)); last if 2 * $i >= $first; $first = $o if $o < $first && $o < 0x8000; $n = $i + 1; } }
my %pun = (0xA4 => ' ', 0xA5 => ';', 0xA6 => ':', 0xA7 => ',', 0xA8 => '.', 0xA9 => "'", 0xAA => '-', 0xAB => '"', 0xAC => '"', 0xAD => '&', 0xAE => '!', 0xAF => '?');
my $maxend = 0;
for my $i (0 .. $n - 1) {
  my $o = unpack('n', substr($d, $base + 2 * $i, 2)); my $so = $o >= 0x8000 ? $o - 0x10000 : $o; my $p = $base + $so;
  my @hw = unpack("n$nh", substr($d, $p, 2 * $nh)); my $q = $p + 2 * $nh; my $txt = '';
  while (1) { my $w = unpack('n', substr($d, $q, 2)); $q += 2; last if $w == 0x4040 || $q > length $d;
    if ($w == 0x2F2F) { $txt .= '/'; next; } my ($hi, $lo) = ($w >> 8, $w & 0xFF);
    if ($hi == 0x14 && exists $Tbl::dec{$lo}) { $txt .= $Tbl::dec{$lo} } elsif ($hi == 0x14 && exists $pun{$lo}) { $txt .= $pun{$lo} } else { $txt .= sprintf('{%04X}', $w) } }
  $maxend = $q if $q > $maxend && $so > 0;
  printf "%3d %06X [%s] %s\n", $i, $p, join(' ', map { sprintf '%04X', $_ } @hw), $txt;
}
printf "N=%d END %06X\n", $n, $maxend;
