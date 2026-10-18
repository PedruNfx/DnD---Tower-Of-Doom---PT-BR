# Render 8x8 tiles seamlessly (left halves only), 16 codes per row, row stride = 16 codes; with code labels.
# usage: render2.pl gfx start_hex count_hex out.png scale
require "$ENV{T}/png.pl";
my ($gfx, $start, $count, $out, $scale) = @ARGV; $start = hex $start; $count = hex $count; $scale ||= 4;
open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>;
my @pal = (map { my $v = int($_ * 255 / 15); [$v, $v, $v] } 0 .. 15); $pal[15] = [40, 0, 60]; $pal[0] = [255, 255, 255];
my $cols = 16; my $rows = int(($count + 15) / 16); my ($W, $H) = ($cols * 8 + 24, $rows * 8);
my @img = map { [ ([0, 0, 0]) x $W ] } 1 .. $H;
for my $k (0 .. $count - 1) { my $code = $start + $k; my ($cx, $cy) = (24 + ($k % $cols) * 8, int($k / $cols) * 8);
  for my $y (0 .. 7) { my @b = unpack('C4', substr($g, $code * 64 + $y * 8, 4));
    for my $x (0 .. 7) { my $bit = 7 - $x; my $p = ((($b[3] >> $bit) & 1) << 3) | ((($b[2] >> $bit) & 1) << 2) | ((($b[1] >> $bit) & 1) << 1) | (($b[0] >> $bit) & 1);
      $img[$cy + $y][$cx + $x] = $pal[$p]; } } }
# tick marks every row start (code labels in hex would need a font; mark rows with alternating bars)
for my $r (0 .. $rows - 1) { for my $y (0 .. 7) { for my $x (0 .. 20) { $img[$r * 8 + $y][$x] = ($r % 2) ? [200, 60, 60] : [60, 60, 200] if $x < 4 || ($r % 4 == 0 && $x < 12); } } }
my @rowsout; for my $r (@img) { my $line = join '', map { pack('C3', @$_) x $scale } @$r; push @rowsout, ($line) x $scale; }
Png::write_rgb($out, $W * $scale, $H * $scale, \@rowsout);
