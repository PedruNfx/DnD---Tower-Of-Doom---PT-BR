# Render 16x16 sprite tiles (tile t = units 2t (rows 0-7) and 2t+1 (rows 8-15); L half = left 8 px, R = right 8 px)
# usage: render16.pl gfx first_tile_hex count_hex out.png scale [cols]
require "$ENV{T}/png.pl";
my ($gfx, $start, $count, $out, $scale, $cols) = @ARGV; $start = hex $start; $count = hex $count; $scale ||= 2; $cols ||= 16;
open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>;
my @pal = (map { my $v = int($_ * 255 / 15); [$v, $v, $v] } 0 .. 15); $pal[15] = [40, 0, 60];
my $rows = int(($count + $cols - 1) / $cols); my ($W, $H) = ($cols * 17, $rows * 17);
my @img = map { [ ([255, 0, 0]) x $W ] } 1 .. $H;
for my $k (0 .. $count - 1) { my $t = $start + $k; my ($cx, $cy) = (($k % $cols) * 17, int($k / $cols) * 17);
  for my $y (0 .. 15) { my $o = $t * 128 + $y * 8; my @b = unpack('C8', substr($g, $o, 8));
    for my $x (0 .. 15) { my $q = $x < 8 ? 0 : 4; my $bit = 7 - ($x % 8);
      my $p = ((($b[$q + 3] >> $bit) & 1) << 3) | ((($b[$q + 2] >> $bit) & 1) << 2) | ((($b[$q + 1] >> $bit) & 1) << 1) | (($b[$q] >> $bit) & 1);
      $img[$cy + $y][$cx + $x] = $pal[$p]; } } }
my @ro; for my $r (@img) { my $line = join '', map { pack('C3', @$_) x $scale } @$r; push @ro, ($line) x $scale; }
Png::write_rgb($out, $W * $scale, $H * $scale, \@ro);
