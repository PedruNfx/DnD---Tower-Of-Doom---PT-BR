# preview a two-line slot text from the built gfx: slotprev.pl outdir out.png line1codes line2codes (comma-separated hex)
require "$ENV{T}/font.pl"; require "$ENV{T}/png.pl";
my ($dir, $out, @lines) = @ARGV;
sub sl { open my $h, '<:raw', shift or die; local $/; <$h> }
my @sets = ([0x000000, 0x200000, qw(dad.13m dad.15m dad.17m dad.19m)], [0x800000, 0x100000, qw(dad.14m dad.16m dad.18m dad.20m)]);
my $reg = "\0" x 0xC00000;
for my $s (@sets) { my ($base, $size, @f) = @$s; my @d = map { sl("$dir/$_") } @f; my $n = $size / 2;
  substr($reg, $base, $n * 8) = join '', map { my $j = $_; join '', map { substr($d[$_], 2 * $j, 2) } 0 .. 3 } 0 .. $n - 1; }
my $res = ''; for (my $b = 0; $b < length $reg; $b += 0x200000) { my @q = unpack('(a8)*', substr($reg, $b, 0x200000));
  $res .= join('', @q[grep { !($_ & 1) } 0 .. $#q]) . join('', @q[grep { $_ & 1 } 0 .. $#q]); }
$Font::G = $res; my $sc = 4; my $W = 8 * 8; my $H = 32;
my @img = map { [ (pack('C3', 40, 90, 110)) x $W ] } 1 .. $H;
my @pal = map { my $v = 255 - $_ * 30; pack('C3', $v, $v, $v * 0.85) } 0 .. 15; $pal[14] = pack('C3', 0, 0, 0);
for my $l (0, 1) { my @c = map { hex } split /,/, $lines[$l];
  for my $i (0 .. $#c) { next unless $c[$i]; my $g = Font::get($c[$i]); for my $y (0 .. 15) { for my $x (0 .. 7) { my $p = $g->[$y][$x]; next if $p == 15; $img[$l * 16 + $y][$i * 8 + $x] = $pal[$p]; } } } }
my @rows; for my $r (@img) { my $line = join '', map { $_ x $sc } @$r; push @rows, ($line) x $sc; }
Png::write_rgb($out, $W * $sc, $H * $sc, \@rows);
