# Render a mock dialogue box with the game's font (approximate palette)
use utf8; binmode STDOUT, ':utf8';
require "$ENV{T}/png.pl"; require "$ENV{T}/font.pl";
my ($gfx, $out, @lines) = @ARGV; @lines = map { utf8::decode($_); $_ } @lines;
Font::load($gfx); Font::install_new(); Font::build_enc();
my %pal = (0 => [255,255,255], 1 => [255,240,170], 2 => [255,214,90], 3 => [240,170,40], 14 => [10,10,30]);
my $bg = [24,32,96];
my $cols = 30; my ($W, $H) = (($cols + 2) * 8, (@lines + 1) * 16 + 8);
my @img = map { [ ($bg) x $W ] } 1 .. $H;
for my $li (0 .. $#lines) { my @ch = split //, $lines[$li];
  for my $ci (0 .. $#ch) { my $c = $Font::ENC{$ch[$ci]}; die "no glyph for '$ch[$ci]'\n" unless defined $c; my $g = Font::get($c);
    for my $y (0 .. 15) { for my $x (0 .. 7) { my $p = $g->[$y][$x]; next if $p == 15; my $col = $pal{$p} || [255,0,255];
      $img[12 + $li * 16 + $y][8 + $ci * 8 + $x] = $col; } } } }
my $sc = 3; my @rows;
for my $r (@img) { my $line = join '', map { pack('C3', @$_) x $sc } @$r; push @rows, ($line) x $sc; }
Png::write_rgb($out, $W * $sc, $H * $sc, \@rows);
