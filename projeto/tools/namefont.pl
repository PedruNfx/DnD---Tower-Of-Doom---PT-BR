package NameFont;
# Class names (LUTADOR, CLÉRIGO, ELFA, ANÃO) redrawn in three pre-drawn styles:
#   sel   - player-select labels: 16x16 sprite tiles, serif caps with gradient pens and an underline
#   hud   - HUD name strips / class initials: scroll1 8x8 tiles on the HUD texture, 5-row letters
#   rank  - ranking bars: scroll1 8x8 tiles, 7-row letters on a solid bar
# Glyph masks: '#' = ink. Letters were transcribed from the original art (F I G H T E R C L A D); U O N and accents drawn to match.
use strict; use warnings;
our $G;   # aliased to $Font::G by the caller

# ---- pixel access ----
sub s1set { my ($c, $y, $x, $p) = @_; my $o = (0x20000 + $c) * 64 + $y * 8; my @b = unpack('C8', substr($G, $o, 8)); my $bit = 7 - $x;
  for my $pl (0 .. 3) { for my $hf (0, 1) { my $i = $pl + 4 * $hf; $b[$i] = ($b[$i] & ~(1 << $bit)) | ((($p >> $pl) & 1) << $bit); } }
  substr($G, $o, 8) = pack('C8', @b); }
sub sset { my ($t, $x, $y, $p) = @_; my $o = $t * 128 + $y * 8 + ($x < 8 ? 0 : 4); my @b = unpack('C4', substr($G, $o, 4)); my $bit = 7 - ($x % 8);
  for my $pl (0 .. 3) { $b[$pl] = ($b[$pl] & ~(1 << $bit)) | ((($p >> $pl) & 1) << $bit); } substr($G, $o, 4) = pack('C4', @b); }

# ---- layout: text -> ink canvas {w, rows => [[0/1...]...]} with $gap px between glyph boxes ----
sub canvas { my ($font, $text, $h, $gap, $tight) = @_; my @cols; $tight ||= {};
  my @ch = split //, $text;
  for my $i (0 .. $#ch) { my $m = $font->{ $ch[$i] } or die "name font: no glyph '$ch[$i]'\n"; my $w = 0; $w = length > $w ? length : $w for @$m;
    for my $x (0 .. $w - 1) { push @cols, [ map { my $r = $m->[$_] // ''; $x < length $r && substr($r, $x, 1) eq '#' ? 1 : 0 } 0 .. $h - 1 ]; }
    push @cols, ([ (0) x $h ]) x ($tight->{ $ch[$i] } ? 0 : $gap) if $i < $#ch; }
  return \@cols; }

# ============ player-select labels (rows 0-2 accents, 3-11 caps, 12 shadow, 14 underline, 15 its shadow) ============
my %SEL = (
  F => ['#########', '.###....#', '.###', '.######', '.#####', '.###', '.###', '.###', '..###'],
  I => ['###', '.###', '.###', '.###', '.###', '.###', '.###', '.#####', '..###'],
  G => ['..#####', '.###...#', '###', '###', '###', '###...##', '####...#', '.#######', '..#####'],
  T => ['##########', '##.###..##', '#..###..#', '...###', '...###', '...###', '...###', '...###', '....###'],
  E => ['########', '.###', '.###', '.######', '.#####', '.###', '.###', '.###...#', '..######'],
  R => ['####.###', '.####..##', '.###...##', '.###...#', '.######', '.###.###', '.###..###', '.###..##', '..###.###'],
  C => ['..#####', '.###...#', '###', '###', '###', '###', '####...#', '.#######', '..####'],
  L => ['###', '.###', '.###', '.###', '.###', '.###', '.###...#', '.###...##', '########'],
  A => ['....######', '.....####', '....#.###', '...#..###', '..##..###', '.##.#####', '###...###', '####..####', '.##....##'],
  D => ['#######', '.###..##', '.###...##', '.###...##', '.###...##', '.###...##', '.###...##', '.###..###', '..######'],
  O => ['..#####', '.###.###', '###...###', '###...###', '###...###', '###...###', '###...###', '.###.###', '..#####'],
  U => ['###...###', '.###...##', '.###...##', '.###...##', '.###...##', '.###...##', '.###...##', '..###.##', '...####'],
  N => ['###....###', '.###....#', '.####...#', '.#.###..#', '.#..###.#', '.#...####', '.#....###', '.#.....##', '###.....#'],
);
my %SELACC = ("\x{c9}" => ['E', ['.....##', '....##', '']], "\x{c3}" => ['A', ['.....##..#', '....#..##', '']]);
my %SELF = map { $_ => [ '', '', '', @{ $SEL{$_} } ] } keys %SEL;
for my $k (keys %SELACC) { my ($b, $a) = @{ $SELACC{$k} }; $SELF{$k} = [ @$a, @{ $SEL{$b} } ]; }
my @SELPEN = (1, 0, 0, 1, 0, 0, 8, 8, 8, 9, 0xA, 0xB);
# %o: tiles => [16x16 tile codes, left to right], text, x0 (left) or cx (centre)
sub sel { my %o = @_; my @t = @{ $o{tiles} }; my $W = 16 * @t;
  my $px = sub { my ($x, $y, $p) = @_; return if $x < 0 || $x >= $W; sset($t[int($x / 16)], $x % 16, $y, $p); };
  for my $y (0 .. 15) { $px->($_, $y, 15) for 0 .. $W - 1; }
  my $cv = canvas(\%SELF, $o{text}, 12, 1, { I => 1 }); my $w = @$cv + 1;   # +1: shadow column of the last glyph
  my $x0 = defined $o{x0} ? $o{x0} : int($o{cx} - $w / 2 + 0.5); die "label '$o{text}' too wide ($w px from $x0 > $W)\n" if $x0 < 0 || $x0 + $w + 1 > $W;
  my %ink; for my $x (0 .. $#$cv) { for my $y (0 .. 11) { $ink{"$x,$y"} = 1 if $cv->[$x][$y]; } }
  for my $k (keys %ink) { my ($x, $y) = split /,/, $k; for my $s ([$x + 1, $y], [$x + 1, $y + 1]) { my ($sx, $sy) = @$s; $px->($x0 + $sx, $sy, 0xE) unless $ink{"$sx,$sy"}; } }
  for my $k (keys %ink) { my ($x, $y) = split /,/, $k; $px->($x0 + $x, $y, $SELPEN[$y]); }
  my ($u0, $u1) = ($x0, $x0 + $w - 1);   # underline: B at the ends, 8 in the middle; shadow below-right
  for my $x ($u0 .. $u1) { my $d = abs(($x - $u0) / (($u1 - $u0) || 1) - 0.5) * 2; $px->($x, 14, $d < 0.2 ? 8 : $d < 0.4 ? 9 : $d < 0.75 ? 0xA : 0xB); $px->($x + 1, 15, 0xE); }
  $px->($u1 + 1, 14, 0xE); }

# ============ HUD (scroll1, 8x8 both halves): rows 0 = frame line, 1-6 text area on a texture, 7 texture ============
my @TEX = ('77777777', '46664666', '44664464', '44664664', '46664464', '46446666', '66446646', '66446446');
my %HUD = (   # 6 rows: [accent row 1, letter rows 2-6]
  L => ['', '###..', '.#...', '.#...', '.#..#', '#####'],
  U => ['', '##..##', '.#..#.', '.#..#.', '.#..#.', '..##..'],
  T => ['', '#####', '#.#.#', '..#..', '..#..', '.###.'],
  A => ['', '..##..', '.#..#.', '######', '#....#', '##..##'],
  D => ['', '#####.', '.#...#', '.#...#', '.#...#', '#####.'],
  O => ['', '.####.', '#....#', '#....#', '#....#', '.####.'],
  R => ['', '#####.', '.#...#', '.####.', '.#..#.', '###.##'],
  C => ['', '.####.', '#....#', '#.....', '#....#', '.####.'],
  E => ['', '######', '.#...#', '.###..', '.#...#', '######'],
  I => ['', '###', '.#.', '.#.', '.#.', '###'],
  G => ['', '.####', '#....', '#.###', '#...#', '.####'],
  F => ['', '######', '.#...#', '.###..', '.#....', '###...'],
  N => ['', '##..###', '.##..#.', '.#.#.#.', '.#..##.', '###..#.'],
  "\x{c9}" => ['....#.', '######', '.#...#', '.###..', '.#...#', '######'],
  "\x{c3}" => ['.##.#.', '#.##..', '.#..#.', '######', '#....#', '##..##'],
  n => ['', '#...#', '##..#', '#.#.#', '#..##', '#...#'],   # level "N" (nivel), replaces the HUD "L"
);
my %HUDF = map { my $m = $HUD{$_}; $_ => [ '', @$m ] } keys %HUD;   # canvas rows 0-6 (row 0 unused)
# draw text at canvas x0 onto a grid of codes; area = [x0..x1] x rows 1-6 is rebuilt from the texture first
sub hud_draw { my ($codes, $ax0, $ax1, $text, $pen, $tx0) = @_;
  my $px = sub { my ($x, $y, $p) = @_; s1set($codes->[int($x / 8)], $y, $x % 8, $p); };
  for my $y (1 .. 6) { for my $x ($ax0 .. $ax1) { $px->($x, $y, hex substr($TEX[$y], $x % 8, 1)); } }
  my $cv = canvas(\%HUDF, $text, 7, 1); die "hud name '$text' too wide\n" if $tx0 + @$cv - 1 > $ax1;
  my %ink; for my $x (0 .. $#$cv) { for my $y (1 .. 6) { $ink{"$x,$y"} = 1 if $cv->[$x][$y]; } }
  for my $k (keys %ink) { my ($x, $y) = split /,/, $k;
    for my $s ([$x - 1, $y], [$x, $y - 1], [$x - 1, $y - 1]) { my ($sx, $sy) = @$s; next if $sy < 1 || $tx0 + $sx < $ax0; $px->($tx0 + $sx, $sy, 5) unless $ink{"$sx,$sy"}; } }
  for my $k (keys %ink) { my ($x, $y) = split /,/, $k; $px->($tx0 + $x, $y, $pen); } }
sub hud_strip { my %o = @_; my $c = $o{codes}; hud_draw($c, 1, 8 * @$c - 1, $o{text}, $o{pen}, $o{x0} // 2); }
sub hud_tile { my ($code, $ch, $pen, $x0) = @_; hud_draw([$code], 1, 7, $ch, $pen, $x0); }

# ============ ranking bars (scroll1, 7 tiles = 56 px): rows 0-6 letters, 7 shadow; bar pen A, corners transparent ============
my %RANK = (
  L => ['####..', '.##...', '.##...', '.##...', '.##...', '.##..#', '######'],
  U => ['##...##', '##...##', '##...##', '##...##', '##...##', '##...##', '.#####.'],
  T => ['######', '#.##.#', '..##..', '..##..', '..##..', '..##..', '.####.'],
  A => ['..###..', '.##.##.', '##...##', '##...##', '#######', '##...##', '##...##'],
  D => ['######.', '.##..##', '.##..##', '.##..##', '.##..##', '.##..##', '######.'],
  O => ['.#####.', '##...##', '##...##', '##...##', '##...##', '##...##', '.#####.'],
  R => ['######..', '.##..##.', '.##..##.', '.#####..', '.##..##.', '.##..##.', '####.###'],
  C => ['.#####.', '##...##', '##...##', '##.....', '##...##', '##...##', '.#####.'],
  E => ['######.', '.##...#', '.##....', '.####..', '.##....', '.##...#', '######.'],
  F => ['######.', '.##...#', '.##....', '.####..', '.##....', '.##....', '####...'],
  I => ['####', '.##.', '.##.', '.##.', '.##.', '.##.', '####'],
  G => ['.#####.', '##...##', '##...##', '##.....', '##..###', '##...##', '.######'],
  N => ['##...##', '###..##', '####.##', '##.####', '##..###', '##...##', '##...##'],
  "\x{c9}" => ['....##', '...##.', '######', '.##..#', '.####.', '.##..#', '######'],
  "\x{c3}" => ['..##..#', '.#..##.', '..###..', '.##.##.', '##...##', '#######', '##...##'],
);
my @RANKPEN = (0, 0, 0, 0, 1, 2, 3);
sub rank_bar { my %o = @_; my @c = @{ $o{codes} }; my $W = 8 * @c;
  my $px = sub { my ($x, $y, $p) = @_; return if ($x <= 0 || $x >= $W - 1) && ($y == 0 || $y == 7); s1set($c[int($x / 8)], $y, $x % 8, $p); };
  for my $y (0 .. 7) { $px->($_, $y, 0xA) for 0 .. $W - 1; }
  my $cv = canvas(\%RANK, $o{text}, 7, 1); my $w = @$cv; my $x0 = int(($W - $w) / 2); die "rank name '$o{text}' too wide\n" if $x0 < 1;
  my %ink; for my $x (0 .. $#$cv) { for my $y (0 .. 6) { $ink{"$x,$y"} = 1 if $cv->[$x][$y]; } }
  for my $k (keys %ink) { my ($x, $y) = split /,/, $k; for my $s ([$x + 1, $y], [$x, $y + 1], [$x + 1, $y + 1]) { my ($sx, $sy) = @$s; $px->($x0 + $sx, $sy, 0xE) unless $ink{"$sx,$sy"}; } }
  for my $k (keys %ink) { my ($x, $y) = split /,/, $k; $px->($x0 + $x, $y, $RANKPEN[$y]); } }
1;
