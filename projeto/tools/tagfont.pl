package TagFont;
# Player-select tagline font: extracted from the original boxes (pen 7 ink, pen E shadow, 15 transparent).
use strict; use warnings;
our $G;
our %BOX = (   # 11x3 tile blocks (rows of codes) and their tagline lines
  fighter => ['1E0C,1E0D,1E0E,1E0F,1E80,1E81,1E82,1E83,1E84,1E85,1E86', '1E1C,1E1D,1E1E,1E1F,1E90,1E91,1E92,1E93,1E94,1E95,1E96', '1E2C,1E2D,1E2E,1E2F,1EA0,1EA1,1EA2,1EA3,1EA4,1EA5,1EA6'],
  cleric  => ['1F06,1F07,1F08,1F09,1F0A,1F0B,1F0C,1F0D,1F0E,1F0F,1F10', '1F16,1F17,1F18,1F19,1F1A,1F1B,1F1C,1F1D,1F1E,1F1F,1F20', '1F26,1F27,1F28,1F29,1F2A,1F2B,1F2C,1F2D,1F2E,1F2F,1F30'],
  elf     => ['1E88,1E89,1E8A,1E8B,1E8C,1E8D,1E8E,1E8F,1F00,1F01,1F02', '1E98,1E99,1E9A,1E9B,1E9C,1E9D,1E9E,1E9F,1F10,1F11,1F12', '1EA8,1EA9,1EAA,1EAB,1EAC,1EAD,1EAE,1EAF,1F20,1F21,1F22'],
  dwarf   => ['1F82,1F83,1F84,1F85,1F86,1F87,1F88,1F89,1F8A,1F8B,1F8C', '1F92,1F93,1F94,1F95,1F96,1F97,1F98,1F99,1F9A,1F9B,1F9C', '1FA2,1FA3,1FA4,1FA5,1FA6,1FA7,1FA8,1FA9,1FAA,1FAB,1FAC'],
);
our %TEXT = (fighter => ['Strength&', 'endurance'], cleric => ['Manofwar&', 'healing'], elf => ['Magic-using', 'warrior'], dwarf => ['Power&', 'resistance']);
sub grid { my $b = shift; return [ map { [ map { hex } split /,/ ] } @{ $BOX{$b} } ]; }
sub px { my ($u, $y, $x) = @_; my @b = unpack('C4', substr($G, $u * 64 + $y * 8, 4)); my $bit = 7 - $x;
  return ((($b[3] >> $bit) & 1) << 3) | ((($b[2] >> $bit) & 1) << 2) | ((($b[1] >> $bit) & 1) << 1) | (($b[0] >> $bit) & 1); }
sub setpx { my ($u, $y, $x, $p) = @_; my $o = $u * 64 + $y * 8; my @b = unpack('C8', substr($G, $o, 8)); my $bit = 7 - $x;
  for my $pl (0 .. 3) { for my $hf (0, 1) { my $i = $pl + 4 * $hf; $b[$i] = ($b[$i] & ~(1 << $bit)) | ((($p >> $pl) & 1) << $bit); } } substr($G, $o, 8) = pack('C8', @b); }
sub cget { my ($gr, $x, $y) = @_; return px(0x20000 + $gr->[int($y / 8)][int($x / 8)], $y % 8, $x % 8); }
sub cset { my ($gr, $x, $y, $p) = @_; setpx(0x20000 + $gr->[int($y / 8)][int($x / 8)], $y % 8, $x % 8, $p); }
# line l (0/1) occupies canvas rows 4..13 / 12..21 (cell rows 0..9); text area columns 3..84
sub cell { my ($l, $r) = @_; return ($l ? 12 : 4) + $r; }
our %GL;   # char -> [ columns ], column = [ pens for cell rows 0..9 ] (15 = empty)
sub learn {
  for my $b (sort keys %TEXT) { my $gr = grid($b);
    for my $l (0, 1) { my @chars = split //, $TEXT{$b}[$l]; my @seg; my $st;
      for my $x (3 .. 84) { my $ink = grep { my $p = cget($gr, $x, cell($l, $_)); $p == 7 || $p == 14 } 0 .. ($l ? 8 : 7);
        if ($ink && !defined $st) { $st = $x } elsif (!$ink && defined $st) { push @seg, [$st, $x - 1]; undef $st } }
      push @seg, [$st, 84] if defined $st;
      if (@seg != @chars) { warn "tagfont: $b line $l: " . scalar(@seg) . " segments for '" . join('', @chars) . "'\n"; next; }
      for my $i (0 .. $#chars) { next if $GL{ $chars[$i] }; my ($a, $z) = @{ $seg[$i] };
        $GL{ $chars[$i] } = [ map { my $x = $_; [ map { my $r = $_; my $p = cget($gr, $x, cell($l, $r)); ($l == 0 && $r == 9) ? 15 : ($p == 7 || $p == 14 ? $p : 15) } 0 .. 9 ] } $a .. $z ]; } } } }
# ---- drawing: ink masks (cell rows 0-8; caps from row 0, x-height from row 2, baseline row 6) + generated shadow ----
my %INK = (
  a => ['', '.7777', '.....7', '.77777', '77..77', '77..77', '.77777'],
  b => ['77', '77', '77', '77777', '77..77', '77..77', '77777'],
  c => ['', '', '.7777', '77..77', '77', '77..77', '.7777'],
  d => ['....77', '....77', '....77', '.77777', '77..77', '77..77', '.77777'],
  e => ['', '', '.7777', '77..77', '777777', '77', '.77777'],
  f => ['..777', '.77', '.77', '7777', '.77', '.77', '.77'],
  g => ['', '', '.7777', '77..77', '77..77', '.77777', '....77', '.7777'],
  i => ['', '77', '', '77', '77', '77', '77'],
  n => ['', '', '77777', '77..77', '77..77', '77..77', '77..77'],
  m => ['', '', '7777777', '77.77.77', '77.77.77', '77.77.77', '77.77.77'],
  o => ['', '', '.7777', '77..77', '77..77', '77..77', '.7777'],
  r => ['', '', '7.77', '777', '77', '77', '77'],
  s => ['', '', '.7777', '77', '.7777', '....77', '77777'],
  t => ['', '..77', '..77', '777777', '..77', '..77', '..77'],
  u => ['', '', '77..77', '77..77', '77..77', '77..77', '.77777'],
  v => ['', '', '77..77', '77..77', '77..77', '.7777', '..77'],
  C => ['.77777', '77...77', '77', '77', '77', '77...77', '.77777'],
  F => ['777777', '77', '77', '77777', '77', '77', '77'],
  G => ['.77777', '77...77', '77', '77..777', '77...77', '77...77', '.77777'],
  P => ['777777', '.77..77', '.77..77', '.77..77', '.77777', '.77', '7777'],
  "\x{e7}" => ['', '', '.7777', '77..77', '77', '77..77', '.7777', '...7', '..77'],      # ç
  "\x{ea}" => ['..77', '.7..7', '.7777', '77..77', '777777', '77', '.77777'],          # ê
);
sub glyph { my $ch = shift; my $m = $INK{$ch} or die "tagline font: no glyph '$ch'\n"; my $w = 0; $w = length > $w ? length : $w for @$m; $w++;
  my @g = map { [ (15) x 10 ] } 1 .. $w;   # columns x rows
  for my $r (0 .. $#$m) { for my $x (0 .. length($m->[$r]) - 1) { $g[$x][$r] = 7 if substr($m->[$r], $x, 1) eq '7'; } }
  for my $x (0 .. $w - 1) { for my $r (0 .. 9) { next unless $g[$x][$r] == 7;
    for my $s ([$x + 1, $r], [$x + 1, $r + 1]) { my ($sx, $sr) = @$s; next if $sx >= $w || $sr > 9; $g[$sx][$sr] = 14 if $g[$sx][$sr] == 15; } } }
  return @g; }
sub linecols { my $text = shift; my @cols;
  for my $ch (split //, $text) { if ($ch eq ' ') { push @cols, ([ (15) x 10 ]) x 3; next; } push @cols, glyph($ch); push @cols, [ (15) x 10 ]; }
  pop @cols while @cols && !grep { $_ != 15 } @{ $cols[-1] }; return @cols; }
# draw: clear the box interior (cells allowed by %o{skip}) and write the two lines starting at x0
sub draw { my (%o) = @_; my $gr = grid($o{box}); my %skip = map { $_ => 1 } @{ $o{skip} || [] };
  for my $y (3 .. 20) { for my $x (3 .. ($o{xmax} // 79)) { my $cid = int($y / 8) . ':' . int($x / 8); next if $skip{$cid}; cset($gr, $x, $y, 15); } }
  for my $l (0, 1) { my @cols = linecols($o{lines}[$l]); my $lim = $o{lim}[$l]; die "tagline '$o{lines}[$l]' too wide\n" if $o{x0} + @cols - 1 > $lim;
    for my $c (0 .. $#cols) { for my $r (0 .. 9) { my $p = $cols[$c][$r]; next if $p == 15; my $y = cell($l, $r); next if $y > 21; cset($gr, $o{x0} + $c, $y, $p); } } } }
# ---- the boxes actually shown on the select screen are 16x16 sprite tiles (6x2 per box) ----
# sprite pens: text 0, shadow C, box fill E. Tile t pixel (x,y): byte t*128 + y*8 + (x<8 ? 0 : 4), bit 7-(x%8).
our %SPR = (
  fighter => [[0x9510, 0x9511, 0x9512, 0x950D, 0x950E, 0x950F], [0x9520, 0x9521, 0x9522, 0x9502, 0x9503, 0x950C]],
  cleric  => [[0x94CA, 0x94CB, 0x94CC, 0x94CD, 0x94CE, 0x94CF], [0x94DA, 0x94DB, 0x94DC, 0x94DD, 0x94DE, 0x94DF]],
  elf     => [[0x94AE, 0x94AF, 0x94C8, 0x94C9, 0x94E8, 0x94E9], [0x94BE, 0x94BF, 0x94D8, 0x94D9, 0x94F8, 0x94F9]],
  dwarf   => [[0x94EA, 0x94EB, 0x94EC, 0x94ED, 0x94EE, 0x94EF], [0x94FA, 0x94FB, 0x94FC, 0x94FD, 0x94FE, 0x94FF]],
);
sub sset { my ($gr, $x, $y, $p) = @_; my $t = $gr->[int($y / 16)][int($x / 16)]; my ($xx, $yy) = ($x % 16, $y % 16);
  my $o = $t * 128 + $yy * 8 + ($xx < 8 ? 0 : 4); my @b = unpack('C4', substr($G, $o, 4)); my $bit = 7 - ($xx % 8);
  for my $pl (0 .. 3) { $b[$pl] = ($b[$pl] & ~(1 << $bit)) | ((($p >> $pl) & 1) << $bit); } substr($G, $o, 4) = pack('C4', @b); }
sub draw_spr { my (%o) = @_; my $gr = $SPR{ $o{box} } or die "no sprite box $o{box}\n"; my %pen = (7 => 0, 14 => 0xC);
  for my $y (6 .. 25) { for my $x (6 .. 89) { sset($gr, $x, $y, 0xE); } }
  for my $l (0, 1) { my @cols = linecols($o{lines}[$l]); die "tagline '$o{lines}[$l]' too wide\n" if 8 + @cols - 1 > 88;
    for my $c (0 .. $#cols) { for my $r (0 .. 9) { my $p = $cols[$c][$r]; next if $p == 15; my $y = ($l ? 16 : 8) + $r; next if $y > 25; sset($gr, 8 + $c, $y, $pen{$p}); } } } }
sub show { my $c = shift; my $g = $GL{$c} or return "($c missing)"; my $s = ''; for my $r (0 .. 9) { $s .= join('', map { $_->[$r] == 7 ? '7' : $_->[$r] == 14 ? 'E' : '.' } @$g) . "\n"; } return $s; }
1;
