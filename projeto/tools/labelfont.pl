package LabelFont;
# Pre-drawn HUD labels (tile bank 0x0A00): redraw them with Portuguese text in the same pixel font.
# Glyphs were transcribed from the original labels (A C E F I J L N O P R S T Y ! 2); D G H U V Á drawn to match.
use strict; use warnings;
our $G;   # aliased to $Font::G by the caller
sub px { my ($u, $y, $x) = @_; my @b = unpack('C4', substr($G, $u * 64 + $y * 8, 4)); my $bit = 7 - $x;
  return ((($b[3] >> $bit) & 1) << 3) | ((($b[2] >> $bit) & 1) << 2) | ((($b[1] >> $bit) & 1) << 1) | (($b[0] >> $bit) & 1); }
sub setpx { my ($u, $y, $x, $p) = @_; my $o = $u * 64 + $y * 8; my @b = unpack('C8', substr($G, $o, 8)); my $bit = 7 - $x;
  for my $pl (0 .. 3) { for my $hf (0, 1) { my $i = $pl + 4 * $hf; $b[$i] = ($b[$i] & ~(1 << $bit)) | ((($p >> $pl) & 1) << $bit); } }
  substr($G, $o, 8) = pack('C8', @b); }

# label font: 6 ink rows (glyph rows 1-6); an accent may use row 0
my %F6 = (
  A => ['..##..','..##..','.#..#.','.####.','#....#','##..##'],
  C => ['.####.','#....#','#.....','#.....','#....#','.####.'],
  D => ['#####.','.#...#','.#...#','.#...#','.#...#','#####.'],
  E => ['######','.#...#','.###..','.#....','.#...#','######'],
  F => ['######','.#...#','.###..','.#....','.#....','###...'],
  G => ['.####.','#....#','#.....','#..###','#....#','.####.'],
  H => ['###.###','.#...#.','.#####.','.#...#.','.#...#.','###.###'],
  I => ['###','.#.','.#.','.#.','.#.','###'],
  J => ['...###','....#.','....#.','##..#.','#...#.','.###..'],
  L => ['###...','.#....','.#....','.#....','.#...#','######'],
  N => ['##...###','.##...#.','.#.#..#.','.#..#.#.','.#...##.','###...#.'],
  O => ['.####.','#....#','#....#','#....#','#....#','.####.'],
  P => ['#####.','.#...#','.####.','.#....','.#....','###...'],
  R => ['#####..','.#...#.','.####..','.#.#...','.#..#..','###..##'],
  S => ['.####.','#....#','.###..','....#.','#....#','.####.'],
  T => ['#######','#..#..#','...#...','...#...','...#...','..###..'],
  U => ['###.###','.#...#.','.#...#.','.#...#.','.#...#.','..###..'],
  V => ['###.###','.#...#.','.#...#.','..#.#..','..#.#..','...#...'],
  Y => ['###...###','..#...#..','...#.#...','....#....','....#....','...###...'],
  '!' => ['#','#','#','#','.','#'],
  '2' => ['.####.','#....#','..###.','.#....','#....#','######'],
);
my %ACC6 = ("\x{c1}" => ['A', '....#.']);   # Á: A with an acute on row 0
# small 5-row font of the "NOTHING" box
my %F5 = (
  A => ['.###.','#...#','#####','#...#','#...#'],
  D => ['####.','#...#','#...#','#...#','####.'],
  N => ['#...#','##..#','#.#.#','#..##','#...#'],
);
# item-bar font: 5 ink rows; glyph rows = [accent row a, accent row b, ink x5, cedilla] (drawn with y0 = bar row 3)
my %FB = (
  A => ['.##.','#..#','####','#..#','#..#'], B => ['###.','#..#','###.','#..#','###.'], C => ['.###','#...','#...','#...','.###'],
  D => ['###.','#..#','#..#','#..#','###.'], E => ['####','#...','####','#...','####'], F => ['####','#...','####','#...','#...'],
  G => ['.###','#...','#.##','#..#','.##.'], I => ['#','#','#','#','#'], K => ['#..#','#.#.','##..','#.#.','#..#'],
  L => ['#...','#...','#...','#...','####'], M => ['####.','#.#.#','#.#.#','#.#.#','#.#.#'], N => ['###.','#..#','#..#','#..#','#..#'],
  O => ['.###.','#...#','#...#','#...#','.###.'], P => ['###.','#..#','###.','#...','#...'], R => ['###.','#..#','###.','#..#','#..#'],
  S => ['.###','#...','.##.','...#','###.'], T => ['###','.#.','.#.','.#.','.#.'], U => ['#..#','#..#','#..#','#..#','.##.'],
  V => ['#...#','.#.#.','.#.#.','..#..','..#..'], X => ['#...#','.#.#.','..#..','.#.#.','#...#'], Z => ['####','..#.','.#..','#...','####'], '-' => ['...','...','###','...','...'],
);
my %ACCB = ("\x{c1}" => ['A', '..#.', '....'], "\x{c9}" => ['E', '..#.', '....'], "\x{cd}" => ['I', '#', '.'],
            "\x{d3}" => ['O', '..#..', '.....'], "\x{c2}" => ['A', '.##.', '#..#']);
sub colsb { my $ch = shift; my ($base, $a1, $a2) = exists $ACCB{$ch} ? @{ $ACCB{$ch} } : ($ch);
  my $g = $FB{$base} or die "bar font: no glyph '$ch'\n"; my $w = length $g->[0];
  return map { my $x = $_; [ (defined $a1 && substr($a1, $x, 1) eq '#') ? 1 : 0, (defined $a2 && substr($a2, $x, 1) eq '#') ? 1 : 0,
    (map { substr($g->[$_], $x, 1) eq '#' ? 1 : 0 } 0 .. 4), 0 ] } 0 .. $w - 1; }
# glyph -> list of columns, each column = arrayref of ink flags for rows 0..7 (6-row font: rows 1-6)
sub cols6 { my $ch = shift; my ($base, $acc) = exists $ACC6{$ch} ? @{ $ACC6{$ch} } : ($ch, undef);
  my $g = $F6{$base} or die "label font: no glyph '$ch'\n"; my $w = length $g->[0];
  return map { my $x = $_; [ (defined $acc && substr($acc, $x, 1) eq '#') ? 1 : 0, (map { substr($g->[$_], $x, 1) eq '#' ? 1 : 0 } 0 .. 5), 0 ] } 0 .. $w - 1; }
sub cols5 { my $ch = shift; my $g = $F5{$ch} or die "small font: no glyph '$ch'\n"; my $w = length $g->[0];
  return map { my $x = $_; [ map { substr($g->[$_], $x, 1) eq '#' ? 1 : 0 } 0 .. 4 ] } 0 .. $w - 1; }
# lay out a text: returns (columns, per-column glyph index) with gap 1 (shrinks to 0 where needed to fit $maxw)
sub layout { my ($text, $font, $maxw, $space) = @_; $space //= 3; my @glyphs = map { $_ eq ' ' ? undef : [ $font eq q{5} ? cols5($_) : $font eq q{b} ? colsb($_) : cols6($_) ] } split //, $text;
  my @gaps = map { 1 } 1 .. $#glyphs; my $w = sub { my $t = 0; $t += defined $_ ? scalar @$_ : $space for @glyphs; $t += $_ for @gaps; $t };
  for my $i (0 .. $#gaps) { last if $w->() <= $maxw; $gaps[$i] = 0 if defined $glyphs[$i] && defined $glyphs[$i + 1]; }
  die "label '$text' too wide (" . $w->() . " > $maxw)\n" if $w->() > $maxw;
  my (@cols, @gi); for my $i (0 .. $#glyphs) { my $g = $glyphs[$i];
    if (!defined $g) { push @cols, ([]) x $space; push @gi, ($i) x $space; } else { push @cols, @$g; push @gi, ($i) x @$g; }
    if ($i < $#glyphs) { push @cols, ([]) x $gaps[$i]; push @gi, ($i) x $gaps[$i]; } }
  return (\@cols, \@gi); }
# draw into a grid of tiles. %o: grid => [[codes]], clear => [x0,y0,x1,y1] (inclusive), bg => pen,
#   lines => [ { text, y0 (canvas y of glyph row 0), cx (centre x), font => '6'|'5', pens => [by glyph row], pens_for => {glyph index => [pens]} } ]
sub draw { my %o = @_; my $grid = $o{grid}; my $W = 8 * @{ $grid->[0] };
  my $cell = sub { my ($x, $y) = @_; my $code = $grid->[int($y / 8)][int($x / 8)]; return (0x20000 + $code, $y % 8, $x % 8); };
  my ($x0, $y0, $x1, $y1) = @{ $o{clear} }; for my $y ($y0 .. $y1) { for my $x ($x0 .. $x1) { setpx($cell->($x, $y), ref $o{bg} ? $o{bg}[$y] : $o{bg}); } }
  for my $l (@{ $o{lines} }) { my ($cols, $gi) = layout($l->{text}, $l->{font} // '6', $x1 - $x0 + 1);
    my $sx = int($l->{cx} - @$cols / 2 + 0.5); $sx = $x0 if $sx < $x0; $sx = $x1 + 1 - @$cols if $sx + @$cols > $x1 + 1;
    for my $c (0 .. $#$cols) { my $col = $cols->[$c]; my $pens = ($l->{pens_for} && $l->{pens_for}{ $gi->[$c] }) || $l->{pens};
      for my $r (0 .. $#$col) { next unless $col->[$r]; setpx($cell->($sx + $c, $l->{y0} + $r), $pens->[$r]); } } } }
1;
