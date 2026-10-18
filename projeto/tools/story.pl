# Parse a story block: records (10 bytes: off16, time, win, f1, f2) + strings (header word + text until 0x4040)
require "$ENV{T}/tbl.pl";
my ($file, $base) = @ARGV; $base = hex $base;
open my $h, '<:raw', $file or die; local $/; my $d = <$h>;
my $first = unpack('n', substr($d, $base, 2)); my $n = $first / 10;
my %lines;
for my $i (0 .. $n - 1) {
  my ($off, $t, $win, $f1, $f2) = unpack('n5', substr($d, $base + $i * 10, 10));
  my $p = $base + $off; my $hdr = unpack('n', substr($d, $p, 2)); $p += 2; my $txt = ''; my $nl = 1;
  while (1) { my $w = unpack('n', substr($d, $p, 2)); $p += 2; last if $w == 0x4040;
    if ($w == 0x2F2F) { $txt .= '/'; $nl++; next; }
    my ($hi, $lo) = ($w >> 8, $w & 0xFF);
    $txt .= ($hi == 0x14 && exists $Tbl::dec{$lo}) ? $Tbl::dec{$lo} : sprintf('{%04X}', $w); }
  my $L = $win >> 9; $lines{($L == $nl) ? 'ok' : "mismatch"}++;
  printf "%3d %06X t=%04X win=%04X f=%04X,%04X hdr=%04X L=%d/%d %s\n", $i, $base + $off, $t, $win, $f1, $f2, $hdr, $nl, $L, $txt;
  printf "END %06X\n", $p if $i == $n - 1;
}
print STDERR join(' ', %lines), "\n";
