package Font;
# 8x16 dialogue font: glyph = tile c (top 8 rows) + tile c+0x10 (bottom 8 rows), gfx unit = 0x20000 + c
our $G;
sub load { my $f = shift; open my $h, '<:raw', $f or die; local $/; $G = <$h>; }
sub px { my ($b, $y, $x) = @_; my @by = unpack('C4', substr($G, $b * 64 + $y * 8, 4)); my $bit = 7 - $x;
  return ((($by[3] >> $bit) & 1) << 3) | ((($by[2] >> $bit) & 1) << 2) | ((($by[1] >> $bit) & 1) << 1) | (($by[0] >> $bit) & 1); }
sub get { my $c = shift; my @g; for my $y (0 .. 15) { my $b = 0x20000 + $c + ($y >= 8 ? 0x10 : 0); $g[$y] = [ map { px($b, $y % 8, $_) } 0 .. 7 ]; } return \@g; }
sub put { my ($c, $g) = @_;  # write glyph into both halves of tiles c and c+0x10
  for my $y (0 .. 15) { my $b = 0x20000 + $c + ($y >= 8 ? 0x10 : 0); my $off = $b * 64 + ($y % 8) * 8;
    my @by = (0) x 4; for my $x (0 .. 7) { my $p = $g->[$y][$x]; my $bit = 7 - $x; for my $pl (0 .. 3) { $by[$pl] |= (($p >> $pl) & 1) << $bit; } }
    substr($G, $off, 8) = pack('C8', @by, @by); } }
sub shade { my $y = shift; return $y <= 7 ? 0 : $y <= 9 ? 1 : $y == 10 ? 2 : 3; }
# compose: base glyph + accent ink [[y,x],...]; clears rows 0-5 first when $clear
sub compose { my ($base, $ink, $clear) = @_; my $g = [ map { [ @$_ ] } @{ get($base) } ];
  if ($clear) { for my $y (0 .. 5) { $g->[$y] = [ (15) x 8 ]; } }
  for my $p (@$ink) { my ($y, $x) = @$p; $g->[$y][$x] = shade($y); }
  for my $p (@$ink) { my ($y, $x) = @$p;
    for my $s ([$y, $x + 1], [$y + 1, $x]) { my ($sy, $sx) = @$s; next if $sy > 15 || $sx > 7; $g->[$sy][$sx] = 14 if $g->[$sy][$sx] == 15; } }
  return $g; }
our %ACC = (
  tilde => [[3,1],[3,2],[3,5],[4,0],[4,3],[4,4]],
  acute => [[3,4],[4,3]],
  grave => [[3,2],[4,3]],
  circ  => [[3,3],[4,2],[4,4]],
  ced   => [[12,3],[13,4],[14,2],[14,3]],
);
# new glyphs: char => [slot code, base code, accent, clear]
our %NEW = (
  "\x{e3}" => [0x2CE0, 0x146A, 'tilde', 1],  # ã
  "\x{f5}" => [0x2CE1, 0x1488, 'tilde', 1],  # õ
  "\x{e7}" => [0x2CE7, 0x146C, 'ced',   0],  # ç  (replaces ü)
  "\x{e2}" => [0x2CC0, 0x146A, 'circ',  1],  # â  (replaces ¡)
  "\x{ea}" => [0x2CC1, 0x146E, 'circ',  1],  # ê  (replaces ¿)
  "\x{f4}" => [0x2CC7, 0x1488, 'circ',  1],  # ô  (replaces Ü)
  "\x{e0}" => [0x14E1, 0x146A, 'grave', 1],  # à  (replaces ñ)
);
sub install_new {
  # compute every glyph from the original tiles first (some slots are also sources), then write
  my %g = map { my ($slot, $base, $acc, $clr) = @{ $NEW{$_} }; ($slot => compose($base, $ACC{$acc}, $clr)) } keys %NEW;
  for my $ch (keys %NEWU) { my ($slot, $base, $acc) = @{ $NEWU{$ch} }; $g{$slot} = compose_upper($base, $acc); }
  my %g8 = map { my ($slot, $base, $acc) = @$_; ($slot => compose8($base, $acc)) } values %NEW8, values %NEW0;
  put($_, $g{$_}) for keys %g; put8($_, $g8{$_}) for keys %g8; }

# uppercase 8x16 accents: accent ink in rows 0-2 (letters use rows 3-12); cedilla below
our %ACCU = (tilde => [[0,2],[0,3],[0,6],[1,1],[1,4],[1,5]], ced => [[13,3],[14,4],[15,2],[15,3]]);
our %NEWU = ("\x{c7}" => [0x14E0, 0x1442, 'ced'],   # Ç (replaces Ñ)
             "\x{c3}" => [0x2CA0, 0x1440, 'tilde'], # Ã (replaces Ñ in bank 2C)
             "\x{d5}" => [0x2CA1, 0x144E, 'tilde']); # Õ (replaces ñ in bank 2C)
sub compose_upper { my ($base, $acc) = @_; my $g = [ map { [ @$_ ] } @{ get($base) } ]; my $ink = $ACCU{$acc};
  for my $p (@$ink) { my ($y, $x) = @$p; $g->[$y][$x] = $y <= 7 ? 0 : 3; }
  for my $p (@$ink) { my ($y, $x) = @$p; for my $s ([$y, $x + 1], [$y + 1, $x]) { my ($sy, $sx) = @$s; next if $sy > 15 || $sx > 7; $g->[$sy][$sx] = 14 if $g->[$sy][$sx] == 15; } }
  return $g; }

# ---- 8x8 item font (bank 0x2A): glyph = single tile, drawn in both halves ----
sub get8 { my $c = shift; my $b = 0x20000 + $c; return [ map { my $y = $_; [ map { px($b, $y, $_) } 0 .. 7 ] } 0 .. 7 ]; }
sub put8 { my ($c, $g) = @_; my $b = 0x20000 + $c;
  for my $y (0 .. 7) { my @by = (0) x 4; for my $x (0 .. 7) { my $p = $g->[$y][$x]; my $bit = 7 - $x; for my $pl (0 .. 3) { $by[$pl] |= (($p >> $pl) & 1) << $bit; } }
    substr($G, $b * 64 + $y * 8, 8) = pack('C8', @by, @by); } }
# accented capital: accent (rows 0-1, shadow to the right) + base rows [1,2,4,5,6] at rows 2-6 (like the original Á)
our %ACC8 = (tilde => [[0,2],[0,3],[0,5],[1,1],[1,4]], circ => [[0,3],[1,2],[1,4]], acute => [[0,4],[1,3]]);
# bank-0 ASCII font (enemy names, raw bytes): new capitals in unused codes 0x5D-0x5F
our %NEW0 = ("\x{c3}0" => [0x005D, 0x0041, 'tilde'], "\x{cd}0" => [0x005E, 0x0049, 'acute'], "\x{d3}0" => [0x005F, 0x004F, 'acute']);
our %NEW8 = ("\x{c3}" => [0x2AE8, 0x2A41, 'tilde'], "\x{d5}" => [0x2AE9, 0x2A4F, 'tilde'],
             "\x{c2}" => [0x2AEA, 0x2A41, 'circ'],  "\x{d4}" => [0x2AEB, 0x2A4F, 'circ'],
             "\x{ca}" => [0x2AEC, 0x2A45, 'circ'],  "\x{c7}" => [0x2AE7, 0x2A43, 'ced']);
sub compose8 { my ($base, $acc) = @_; my $src = get8($base); my $g = [ map { [ (15) x 8 ] } 0 .. 7 ];
  if ($acc eq 'ced') {   # C rows 0,1,2,4,5 at rows 0-4, its shadow row at 5, cedilla at rows 5-7
    my @map = (0, 1, 2, 4, 5, 6); $g->[$_] = [ @{ $src->[$map[$_]] } ] for 0 .. 5;
    for my $p ([5,3],[6,4],[7,2],[7,3]) { my ($y, $x) = @$p; $g->[$y][$x] = 5; }
    for my $p ([5,3],[6,4],[7,2],[7,3]) { my ($y, $x) = @$p; $g->[$y][$x + 1] = 14 if $x < 7 && $g->[$y][$x + 1] == 15; }
    return $g; }
  my @map = (1, 2, 4, 5, 6); $g->[$_ + 2] = [ @{ $src->[$map[$_]] } ] for 0 .. 4;
  $g->[2] = [ @{ $src->[0] } ] if $base == 0x2A45;   # E keeps its top bar
  for my $p (@{ $ACC8{$acc} }) { my ($y, $x) = @$p; $g->[$y][$x] = 0; }
  for my $p (@{ $ACC8{$acc} }) { my ($y, $x) = @$p; $g->[$y][$x + 1] = 14 if $x < 7 && $g->[$y][$x + 1] == 15; }
  return $g; }
our %ENC8;
sub build_enc8 { %ENC8 = (); $ENC8{chr $_} = 0x2A00 | $_ for 0x21 .. 0x7E; $ENC8{' '} = 0x0020;
  my %a = ("\x{c1}" => 0x2AE0, "\x{c9}" => 0x2AE1, "\x{cd}" => 0x2AE2, "\x{d3}" => 0x2AE3, "\x{da}" => 0x2AE4, "\x{dc}" => 0x2AE5);
  %ENC8 = (%ENC8, %a); $ENC8{$_} = $NEW8{$_}[0] for keys %NEW8; }
# character -> code
our %ENC;
sub build_enc {
  my @rows = ([0x1440, 'ABCDEFGHIJKLMNOP'], [0x1460, 'QRSTUVWXYZabcdef'], [0x1480, 'ghijklmnopqrstuv'], [0x14A0, "wxyz ;:,.'-\x{201c}\x{201d}&!?"], [0x14C0, '()+0123456789']);
  for my $r (@rows) { my ($b, $s) = @$r; my $i = 0; $ENC{$_} = $b + $i++ for split //, $s; }
  my %acc = ("\x{e1}" => 0x2CE2, "\x{e9}" => 0x2CE3, "\x{ed}" => 0x2CE4, "\x{f3}" => 0x2CE5, "\x{fa}" => 0x2CE6,
             "\x{c1}" => 0x2CC2, "\x{c9}" => 0x2CC3, "\x{cd}" => 0x2CC4, "\x{d3}" => 0x2CC5, "\x{da}" => 0x2CC6);
  %ENC = (%ENC, %acc); $ENC{$_} = $NEW{$_}[0] for keys %NEW; $ENC{$_} = $NEWU{$_}[0] for keys %NEWU; $ENC{'"'} = 0x14AB; }
1;
