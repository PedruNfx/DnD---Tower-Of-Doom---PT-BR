# Render 8x8 scroll1 tiles: each code shown as 16x8 (left+right halves). 16 codes per row.
require "$ENV{T}/png.pl";
my ($gfx, $start, $count, $out, $scale) = @ARGV; $start = hex $start; $count = hex $count; $scale ||= 3;
open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>;
my @pal = map { my $v = int($_ * 255 / 15); pack('C3', $v, $v, $v) } 0 .. 15; $pal[0] = pack('C3', 0, 0, 80);
my $cols = 16; my $rowsN = int(($count + $cols - 1) / $cols);
my $W = $cols * 17; my $H = $rowsN * 9;
my @img = map { [ (pack('C3', 255, 0, 0)) x $W ] } 1 .. $H;
for my $k (0 .. $count - 1) {
  my $code = $start + $k; my ($cx, $cy) = (($k % $cols) * 17, int($k / $cols) * 9);
  for my $y (0 .. 7) { my @b = unpack('C8', substr($g, $code * 64 + $y * 8, 8));
    for my $half (0, 1) { my $o = $half * 4;
      for my $x (0 .. 7) { my $bit = 7 - $x;
        my $p = ((($b[$o+3] >> $bit) & 1) << 3) | ((($b[$o+2] >> $bit) & 1) << 2) | ((($b[$o+1] >> $bit) & 1) << 1) | (($b[$o] >> $bit) & 1);
        $img[$cy + $y][$cx + $half * 8 + $x] = $pal[$p]; } } } }
my @rows;
for my $r (@img) { my $line = join '', map { $_ x $scale } @$r; push @rows, ($line) x $scale; }
Png::write_rgb($out, $W * $scale, $H * $scale, \@rows);
