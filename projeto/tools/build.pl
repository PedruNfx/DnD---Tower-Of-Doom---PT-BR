# Build the PT-BR patched ddtodur1 ROM files.
# usage: T=<tooldir> perl build.pl <romdir> <transdir> <outdir>
use strict; use warnings;
binmode STDOUT, ':utf8'; binmode STDERR, ':utf8';
my $T = $ENV{T}; require "$T/font.pl";
my ($romdir, $tdir, $outdir) = @ARGV;
sub slurp { my $f = shift; open my $h, '<:raw', $f or die "$f: $!"; local $/; return scalar <$h>; }
sub spew { my ($f, $d) = @_; open my $h, '>:raw', $f or die "$f: $!"; print $h $d; close $h; }

# ---------- program image ----------
my @PF = qw(dadu.03a dadu.04a dadu.05a dad.06 dad.07);
my $P = pack('v*', unpack('n*', join '', map { slurp("$romdir/$_") } @PF));
my $P0 = $P;
sub rw { unpack('n', substr($P, $_[0], 2)) }
sub rl { unpack('N', substr($P, $_[0], 4)) }
sub wl { substr($P, $_[0], 4) = pack('N', $_[1]) }

# ---------- font / encoding ----------
$Font::G = build_gfx(); Font::install_new(); Font::build_enc();
# half-shifted words, so a 6-letter line and a 5-letter line can both be centred in the two-line slot texts
# (INSIRA over FICHA, APERTE over START): glyphs 0x1400-0x1406 = INSIRA, 0x1407-0x140C = START, 0x1420-0x1425 = FICHA
# (kanji cells unused by the US text)
for my $hs (['INSIRA', 0x1400], ['START', 0x1407], ['FICHA', 0x1420]) { my ($w, $code) = @$hs;
  { my @g = map { Font::get($Font::ENC{$_}) } split //, $w;
    for my $k (0 .. @g) { Font::put($code++, [ map { my $y = $_; [ (map { $k > 0 ? $g[$k - 1][$y][$_ + 4] : 15 } 0 .. 3), (map { $k < @g ? $g[$k][$y][$_] : 15 } 0 .. 3) ] } 0 .. 15 ]); } } }

# ---------- pre-drawn HUD labels (tile bank 0x0A00) redrawn in Portuguese ----------
require "$T/labelfont.pl"; *LabelFont::G = \$Font::G;
{
  my @blue = (6, 6, 6, 7, 7, 8, 9, 0); my @white = (2, 2, 2, 3, 3, 4, 5, 0);
  my $row = sub { my ($c0, $text, $pens) = @_; LabelFont::draw(grid => [[ map { $c0 + $_ } 0 .. 9 ]], clear => [0, 0, 79, 7], bg => 0,
    lines => [{ text => $text, y0 => 0, cx => 40, pens => $pens }]); };
  $row->(0x0A10, 'APERTE START', \@blue);
  $row->(0x0A20, 'ENTRAR!', \@blue);
  $row->(0x0A30, "JOGO GR\x{c1}TIS", \@blue);
  $row->(0x0A40, 'AGUARDE', \@white);
  $row->(0x0A60, 'INSIRA FICHA', \@blue);
  # two-line "INSERT / 2 COINS" (7x3 tiles, text straddles tile rows)
  LabelFont::draw(grid => [[0x0A0C, 0x0A0D, 0x0A0E, 0x0A0F, 0x0A3A, 0x0A3B, 0x0A3C], [0x0A1C, 0x0A1D, 0x0A1E, 0x0A1F, 0x0A4A, 0x0A4B, 0x0A4C],
                           [0x0A2C, 0x0A2D, 0x0A2E, 0x0A2F, 0x0A5A, 0x0A5B, 0x0A5C]], clear => [0, 4, 55, 19], bg => 0,
    lines => [{ text => 'INSIRA', y0 => 4, cx => 30, pens => \@blue }, { text => '2 FICHAS', y0 => 12, cx => 24, pens => \@blue, pens_for => { 0 => \@white } }]);
  # "NOTHING" (empty item box, small 5-row font)
  LabelFont::draw(grid => [[ map { 0x0AE4 + $_ } 0 .. 11 ], [ map { 0x0AF4 + $_ } 0 .. 11 ]], clear => [30, 5, 85, 9], bg => 0,
    lines => [{ text => 'NADA', y0 => 5, cx => 55, font => '5', pens => [9, 9, 9, 9, 9] }]);
  # item bars in the HUD item box: 64x16 px each, two per 16-tile row pair; same layout in banks 0x0D00 and 0x2000
  my @bars = (['MARTELO', "M\x{cd}SSIL M\x{c1}GICO"], ['ARCO', 'INVISIBILIDADE'], ['ADAGA', 'BOLA DE FOGO'], ["\x{d3}LEO", "REL\x{c2}MPAGO"],
              ['NEVASCA', 'IMOBILIZAR'], ['METAMORFOSE', 'ARMA FORTE'], ["N\x{c9}VOA MORTAL", 'CURAR FERIDAS'], ["LUZ CONT\x{cd}NUA", 'VARAS-COBRA']);
  my @bg = (0, 0, 0, 0xE, 0xD, 0xC, 0xB, 0xA, 0xA, 0xB, 0xC, 0xD, 0xE, 0, 0, 0);
  for my $bank (0x0D00, 0x2000) { for my $i (0 .. 7) { for my $side (0, 1) { my $c0 = $bank + 0x20 * $i + 8 * $side;
    LabelFont::draw(grid => [[ map { $c0 + $_ } 0 .. 7 ], [ map { $c0 + 0x10 + $_ } 0 .. 7 ]], clear => [0, 3, 63, 11], bg => \@bg,
      lines => [{ text => $bars[$i][$side], y0 => 3, cx => 33, font => 'b', pens => [(9) x 8] }]); } } }
  # TURNING UNDEAD and the magic ring bars ("RING" + spell code; only the word is replaced)
  my $bar = sub { my ($c0, $clear, $text, $cx) = @_; LabelFont::draw(grid => [[ map { $c0 + $_ } 0 .. 7 ], [ map { $c0 + 0x10 + $_ } 0 .. 7 ]],
    clear => $clear, bg => \@bg, lines => [{ text => $text, y0 => 3, cx => $cx, font => 'b', pens => [(9) x 8] }]); };
  for my $bank (0x0E00, 0x2100) {
    $bar->($bank, [0, 3, 63, 11], 'EXPULSAR', 33);
    for my $c0 ($bank + 8, $bank + 0x20, $bank + 0x28, $bank + 0x40, $bank + 0x48, $bank + 0x60) { $bar->($c0, [12, 3, 35, 11], 'ANEL', 23); } }
  $bar->(0x2168, [12, 3, 35, 11], 'ANEL', 23);   # RING CSW (only in the 0x2100 copy)
  print "hud labels: redrawn\n";
  # player-select taglines: the boxes on screen are 6x2 blocks of 16x16 sprite tiles (bank 0x9480-0x957F).
  # (A scroll-layer copy of the same art exists at tiles 0x1E00-0x1FFF but is not what this screen shows.)
  require "$T/tagfont.pl"; *TagFont::G = \$Font::G;
  TagFont::draw_spr(box => 'fighter', lines => ["For\x{e7}a e", 'vigor']);
  TagFont::draw_spr(box => 'cleric',  lines => ['Guerreiro e', 'curandeiro']);
  TagFont::draw_spr(box => 'elf',     lines => ['Guerreira', 'e maga']);
  TagFont::draw_spr(box => 'dwarf',   lines => ['Poder e', "resist\x{ea}ncia"]);
  print "player select taglines: redrawn\n";
  # class names: select-screen labels (sprites 0x95B2-0x960D), HUD initials + level letter and 2-player HUD names, ranking bars
  require "$T/namefont.pl"; *NameFont::G = \$Font::G;
  NameFont::sel(tiles => [0x95B2, 0x95B3, 0x95B4, 0x95B5, 0x95BB], text => 'LUTADOR', x0 => 2);
  NameFont::sel(tiles => [0x95BC .. 0x95BF], text => "CL\x{c9}RIGO", x0 => 0);
  NameFont::sel(tiles => [0x95C0 .. 0x95C3], text => 'ELFA', cx => 31);
  NameFont::sel(tiles => [0x960A .. 0x960D], text => "AN\x{c3}O", cx => 33);
  NameFont::hud_strip(codes => [0x0A80 .. 0x0A85], text => 'LUTADOR', pen => 0xD);
  NameFont::hud_strip(codes => [0x0A96 .. 0x0A9B], text => "CL\x{c9}RIGO", pen => 0x9);
  NameFont::hud_strip(codes => [0x0A90 .. 0x0A95], text => 'ELFA', pen => 0xA);
  NameFont::hud_strip(codes => [0x0A86 .. 0x0A8B], text => "AN\x{c3}O", pen => 0xB);
  NameFont::hud_tile(0x0921, 'L', 0xD, 2); NameFont::hud_tile(0x0978, 'C', 0x9, 2); NameFont::hud_tile(0x0976, 'E', 0xA, 2); NameFont::hud_tile(0x097A, 'A', 0xB, 2);
  NameFont::hud_tile($_, 'n', 0xE, 3) for 0x0922, 0x0977, 0x0979, 0x097B;   # "L7" (level) -> "N7" (nivel)
  NameFont::rank_bar(codes => [0x0840 .. 0x0846], text => 'LUTADOR');
  NameFont::rank_bar(codes => [0x0860 .. 0x0866], text => "CL\x{c9}RIGO");
  NameFont::rank_bar(codes => [0x0850 .. 0x0856], text => 'ELFA');
  NameFont::rank_bar(codes => [0x0870 .. 0x0876], text => "AN\x{c3}O");
  print "class names: redrawn\n";
}
my %ENC = %Font::ENC;
sub enc { my $s = shift; my $orig = $s; my @w;
  while (length $s) {
    if ($s =~ s/^\{([0-9A-Fa-f]{4})\}//) { push @w, hex $1; next; }
    my $c = substr($s, 0, 1, '');
    if ($c eq '/') { push @w, 0x2F2F; next; }
    die "no glyph for '$c' in: $orig\n" unless defined $ENC{$c}; push @w, $ENC{$c}; }
  return @w; }
sub nlines { my $s = shift; return 1 + ($s =~ tr{/}{}); }
sub textlen { my $s = shift; $s =~ s/\{[0-9A-Fa-f]{4}\}/x/g; return length $s; }

# ---------- translation files: "key|text" lines, '#' comments ----------
sub load_tr { my $f = shift; my %t; return \%t unless -e $f; open my $h, '<:encoding(UTF-8)', $f or die;
  while (<$h>) { s/\r?\n$//; s/^\x{feff}//; next if /^\s*(#|$)/; my ($k, $v) = split /\|/, $_, 2; die "bad line $f: $_\n" unless defined $v; $t{$k} = $v; } return \%t; }
my @warn;
sub checkw { my ($tag, $s, $max) = @_; for my $l (split m{/}, $s, -1) { push @warn, "$tag: line too long (" . textlen($l) . "): $l" if textlen($l) > $max; } }

# ---------- story block ----------
{
  my $tr = load_tr("$tdir/story.txt");
  my $base = 0x0FE06C; my $limit = 0x112508; my $n = rw($base) / 10;
  my (@rec, %str, @order, %byoff);
  for my $i (0 .. $n - 1) { my @r = unpack('n5', substr($P0, $base + $i * 10, 10)); push @rec, \@r; my $off = $r[0];
    push @{ $byoff{$off} }, $i;
    next if $off == 0 || exists $str{$off}; my $p = $base + $off; my @w; while (1) { my $x = unpack('n', substr($P0, $p, 2)); $p += 2; last if $x == 0x4040; push @w, $x; }
    $str{$off} = \@w; push @order, $off; }
  my (%newoff, %pt); my $out = ''; my $pos = $n * 10;
  for my $off (@order) {
    my @w = @{ $str{$off} }; my $hdr = shift @w; my ($id) = @{ $byoff{$off} };
    if (exists $tr->{$id}) { my $s = $tr->{$id}; checkw("story $id", $s, 29); @w = enc($s); $pt{$off} = $s; }
    die "story offset overflow\n" if $pos > 0xFFFF;
    $newoff{$off} = $pos; my $blob = pack('n*', $hdr, @w, 0x4040); $out .= $blob; $pos += length $blob; }
  my $tab = '';
  for my $i (0 .. $n - 1) { my ($off, $t, $win, $f1, $f2) = @{ $rec[$i] };
    if ($off && exists $pt{$off}) {
      my @ow = @{ $str{$off} }; my $oldl = 1 + grep { $_ == 0x2F2F } @ow[1 .. $#ow];
      my $s = $pt{$off}; my $nl = nlines($s);
      if (($win >> 9) == $oldl && $nl != $oldl) { $win = (($nl * 2) << 8) | ($win & 0xFF); }
      if ($t != 0xFFFF && $t) { my $oldc = grep { $_ != 0x2F2F } @ow[1 .. $#ow]; my $r = textlen($s) / ($oldc || 1); $t = int($t * $r) if $r > 1.05; $t = 0x0400 if $t > 0x0400; } }
    $tab .= pack('n5', $off ? $newoff{$off} : 0, $t, $win, $f1, $f2); }
  my $blk = $tab . $out; die sprintf("story block too big: %X\n", length $blk) if $base + length($blk) > $limit;
  substr($P, $base, length $blk) = $blk;
  for (my $a = 0x0FC162; $a < 0x0FC1A2; $a += 4) { wl($a, $base) if rl($a) != 0x0FC1A2; }
  printf "story: %d records, %d translated, block %X bytes (free %X)\n", $n, scalar(keys %pt), length $blk, $limit - $base - length $blk;
  # the old ES/FR/DE/IT story blocks are no longer referenced: use them as a free-space pool
  our @POOL = (($base + length($blk) + 15) & ~15, $limit);
}
sub alloc { my $len = shift; our @POOL; my $a = $POOL[0]; die "free pool exhausted\n" if $a + $len > $POOL[1]; $POOL[0] = ($a + $len + 1) & ~1; return $a; }

# ---------- intro ----------
{
  my $tr = load_tr("$tdir/intro.txt");
  # The game reaches these texts through fixed addresses, so every record / paragraph keeps
  # its exact original start and size; shorter text is padded with trailing spaces.
  # title block (EN slot): record 1 = title, record 2 = closing text
  if (exists $tr->{title}) {
    for my $r ([0x327AC, 4, 'title'], [0x327E4, 2, 'after']) { my ($at, $nh, $k) = @$r;
      my $p = $at + $nh * 2; my $n = 0; $n++, $p += 2 while unpack('n', substr($P0, $p, 2)) != 0x4040;
      my $s = $tr->{$k} // die "intro: missing $k\n"; checkw("intro $k", $s, 28); my @w = enc($s);
      die "intro $k too long (" . scalar(@w) . " > $n words)\n" if @w > $n; push @w, (0x14A4) x ($n - @w);
      substr($P, $at + $nh * 2, $n * 2) = pack('n*', @w); }
    print "intro titles: ok\n";
  }
  # scroll script: keep the EN command words, replace each text line, keep paragraph starts fixed
  my @keys = grep { exists $tr->{"line$_"} } 1 .. 60;
  if (@keys) {
    my $start = 0x32D78; my $p = $start; my @par;   # paragraphs: [start, end, [lines]]
    while (1) { my $x = unpack('n', substr($P0, $p, 2)); last if $x == 0x001C;
      my $ls = $p; my @c; while ($x < 0x40) { push @c, $x; $p += 2; $x = unpack('n', substr($P0, $p, 2)); }
      my @t; while ($x != 0xFFFF) { push @t, $x; $p += 2; $x = unpack('n', substr($P0, $p, 2)); } $p += 2;
      if (!@par || $c[0] == 0x0018) { $par[-1][1] = $ls if @par; push @par, [$ls, 0, []]; }
      push @{ $par[-1][2] }, [\@c, \@t]; }
    $par[-1][1] = $p;
    my $li = 0; my @prev;
    for my $pa (@par) { my ($ps, $pe, $lines) = @$pa; my @enc;
      for my $s (@$lines) { my ($c, $t) = @$s; my @tw;
        my $bottom = @$t && !grep { ($_ & 0x10) == 0 && $_ != 0x14A4 } @$t;
        if ($bottom) { @tw = map { $_ == 0x14A4 ? $_ : $_ + 0x10 } @prev; }
        else { $li++; my $k = "line$li"; die "intro: missing $k\n" unless exists $tr->{$k}; checkw("intro $k", $tr->{$k}, 28); @tw = enc($tr->{$k}); @prev = @tw; }
        push @enc, [$c, \@tw]; }
      my $size = 0; $size += 2 * (@{ $_->[0] } + @{ $_->[1] } + 1) for @enc;
      my $room = ($pe - $ps - $size) / 2; die sprintf("intro paragraph at %06X too long by %d chars\n", $ps, -$room) if $room < 0;
      for my $i (reverse 0 .. $#enc) { my $t = $enc[$i][1]; next if grep { $_ & 0x10 && $_ != 0x14A4 } @$t; push @$t, (0x14A4) x $room; last; }
      my $blob = join '', map { pack('n*', @{ $_->[0] }, @{ $_->[1] }, 0xFFFF) } @enc;
      die "intro size mismatch\n" if length($blob) != $pe - $ps; substr($P, $ps, length $blob) = $blob; }
    die "intro script has $li lines, translation has " . scalar(@keys) . "\n" if $li != @keys;
    printf "intro script: %d lines in %d paragraphs\n", $li, scalar @par;
  }
}

# ---------- offset blocks: per-language block = u16 offset table + records [hdr words][text][4040] ----------
# The language pointer table (16 x 32-bit) is repointed so every Latin language uses the rebuilt EN block.
# Header word 0 high byte = window height (lines*2); it is updated when the line count changes.
sub offblock {
  my (%o) = @_; my $tr = load_tr("$tdir/$o{file}"); return unless %$tr;
  my $lt = $o{langtab}; my @lp = map { unpack('N', substr($P0, $lt + 4 * $_, 4)) } 0 .. 15;
  my $base = $lp[1]; my $jp = $lp[0];
  my $n = 0; my $first = 0xFFFF; while (2 * $n < $first) { my $x = unpack('n', substr($P0, $base + 2 * $n, 2)); $first = $x if $x < 0x8000 && $x < $first; $n++; }
  my (@abs, %rec, @order, %ids);
  for my $i (0 .. $n - 1) { my $x = unpack('n', substr($P0, $base + 2 * $i, 2)); my $a = $base + ($x >= 0x8000 ? $x - 0x10000 : $x); push @abs, $a; push @{ $ids{$a} }, $i;
    next if exists $rec{$a} || $a < $base;   # records before the block (dummies) stay where they are
    my $p = $a; my @w; push @w, unpack('n', substr($P0, $p + 2 * $_, 2)) for 0 .. $o{hdr} - 1; $p += 2 * $o{hdr};
    while (1) { my $x2 = unpack('n', substr($P0, $p, 2)); $p += 2; last if $x2 == 0x4040; push @w, $x2; }
    $rec{$a} = \@w; push @order, $a; }
  my $out = ''; my $pos = 2 * $n; my (%new, $cnt);
  for my $a (@order) { my @w = @{ $rec{$a} }; my @h = splice @w, 0, $o{hdr}; my ($id) = @{ $ids{$a} };
    if (exists $tr->{$id}) { my $s = $tr->{$id}; checkw("$o{file} $id", $s, $o{width}); my $ol = 1 + grep { $_ == 0x2F2F } @w; my $nl = nlines($s);
      die "$o{file} $id: $nl lines > max $o{maxlines}\n" if $nl > $o{maxlines};
      if (defined $o{win} && ($h[$o{win}] >> 9) == $ol && $nl != $ol) { $h[$o{win}] = (($nl * 2) << 8) | ($h[$o{win}] & 0xFF); }
      @w = enc($s); $cnt++; }
    $new{$a} = $pos; my $blob = pack('n*', @h, @w, 0x4040); $out .= $blob; $pos += length $blob; }
  my $tab = join '', map { pack('n', exists $new{$_} ? $new{$_} : ($_ - $base) & 0xFFFF) } @abs;
  my $blk = $tab . $out; die sprintf("%s: block too big (%X > %X)\n", $o{file}, length $blk, $o{limit} - $base) if $base + length($blk) > $o{limit};
  substr($P, $base, length $blk) = $blk;
  for my $i (0 .. 15) { wl($lt + 4 * $i, $base) if $lp[$i] != $jp; }
  printf "%s: %d records, %d translated, block %X (free %X)\n", $o{file}, $n, $cnt // 0, length $blk, $o{limit} - $base - length $blk;
}
offblock(file => 'shop.txt', langtab => 0x0C42CC, hdr => 5, win => 0, width => 21, maxlines => 5, limit => 0x0CC3D0);

# ---------- path choices: lang table of u16 offsets (0xBE644) -> [6 u16 set offsets][19 x 32-bit ptrs] ----------
{
  my $tr = load_tr("$tdir/choices.txt");
  if (%$tr) {
    my $lt = 0xBE644; my @lo = map { unpack('n', substr($P0, $lt + 2 * $_, 2)) } 0 .. 15;
    my $base = $lt + $lo[1]; my $limit = 0xBFF34; my $np = 19; my $ptab = $base + 12;
    my $pos = $ptab + 4 * $np; my %done;
    for my $i (0 .. $np - 1) { my $a = unpack('N', substr($P0, $ptab + 4 * $i, 4));
      my $hdr = unpack('n', substr($P0, $a, 2)); my $p = $a + 2; my @w; while ((my $x = unpack('n', substr($P0, $p, 2))) != 0x4040) { push @w, $x; $p += 2; }
      if (exists $tr->{$i}) { checkw("choice $i", $tr->{$i}, 28); @w = enc($tr->{$i}); }
      my $blob = pack('n*', $hdr, @w, 0x4040); die "choices overflow\n" if $pos + length $blob > $limit;
      substr($P, $pos, length $blob) = $blob; wl($ptab + 4 * $i, $pos); $pos += length $blob; }
    for my $i (0 .. 15) { substr($P, $lt + 2 * $i, 2) = pack('n', $lo[1]) if $lo[$i] != $lo[0]; }
    printf "choices: %d strings (free %X)\n", $np, $limit - $pos;
  }
}

# ---------- hints / signs: 34 x 32-bit ptrs at 0x4823A, record = [col row][attr][text] (EN only) ----------
{
  my $tr = load_tr("$tdir/hints.txt");
  if (%$tr) {
    my $tab = 0x4823A; my $n = 34; my ($area, $aend) = (0x482C2, 0x48B78); my $pos = $area; my %seen;
    for my $i (0 .. $n - 1) { my $a = unpack('N', substr($P0, $tab + 4 * $i, 4));
      my ($cr, $attr) = unpack('n2', substr($P0, $a, 4)); my $p = $a + 4; my @w; while ((my $x = unpack('n', substr($P0, $p, 2))) != 0x4040) { push @w, $x; $p += 2; }
      if (exists $tr->{$i}) { my $s = $tr->{$i}; checkw("hint $i", $s, 30);
        my @ol = (''); for (@w) { if ($_ == 0x2F2F) { push @ol, '' } else { $ol[-1] .= 'x' } }
        my $omax = 0; $omax = length > $omax ? length : $omax for @ol; my $nmax = 0; for (split m{/}, $s) { my $l = textlen($_); $nmax = $l if $l > $nmax; }
        my ($col, $row) = ($cr >> 8, $cr & 0xFF); my $center = $col + $omax / 2; $col = int($center - $nmax / 2 + 0.5); $col = 1 if $col < 1;
        my $onl = scalar @ol; my $nnl = nlines($s); $row += ($onl - $nnl) if $onl != $nnl && $row >= 1;   # keep the block vertically placed
        $cr = ($col << 8) | $row; @w = enc($s); }
      my $blob = pack('n*', $cr, $attr, @w, 0x4040); my $at;
      if ($pos + length $blob <= $aend) { $at = $pos; $pos += length $blob; } else { $at = alloc(length $blob); }
      substr($P, $at, length $blob) = $blob; wl($tab + 4 * $i, $at); }
    printf "hints: %d strings\n", $n;
  }
}

# ---------- records reached through pointer tables (EN tables only), keyed by original address ----------
# file lines "ADDR|text". Translated records go to the free pool; every pointer to ADDR in the tables is updated.
# $o{colw}: header word index holding [col<<8 | row] (text is re-centred); undef = keep position.
sub ptrrecs {
  my (%o) = @_; my $tr = load_tr("$tdir/$o{file}"); return unless %$tr; my $cnt = 0;
  my %tr = map { hex($_) => $tr->{$_} } keys %$tr;
  my %slots; for my $t (@{ $o{tables} }) { my ($ta, $n) = @$t; for my $i (0 .. $n - 1) { my $pa = unpack('N', substr($P0, $ta + 4 * $i, 4)); push @{ $slots{$pa} }, $ta + 4 * $i; } }
  for my $ra (sort keys %tr) { die sprintf("%s: %06X not referenced by the tables\n", $o{file}, $ra) unless $slots{$ra};
    my @h = unpack("n$o{hdr}", substr($P0, $ra, 2 * $o{hdr})); my $p = $ra + 2 * $o{hdr}; my @w; while ((my $x = unpack('n', substr($P0, $p, 2))) != 0x4040) { push @w, $x; $p += 2; }
    my $s = $tr{$ra}; checkw(sprintf(q{%s %06X}, $o{file}, $ra), $s, $o{width});
    if ($o{spell}) {   # first line = title, centred with 0x2323 (skip-column) codes; row depends on line count
      my ($t, @rest) = split m{/}, $s, -1; $t = " $t "; my $sk = int(($o{spell} - textlen($t)) / 2); $sk = 0 if $sk < 0;
      $s = ('{2323}' x $sk) . $t . (@rest ? '/' . join('/', @rest) : ''); my $L = 1 + @rest; $L = 2 if $L < 2;
      $h[0] = ($h[0] & 0xFF00) | (0x12 - 2 * ($L - 2)); }
    if (defined $o{colw}) { my @ol = (0); for (@w) { if ($_ == 0x2F2F) { push @ol, 0 } else { $ol[-1]++ } } my $omax = (sort { $b <=> $a } @ol)[0];
      my $nmax = (sort { $b <=> $a } map { textlen($_) } split m{/}, $s)[0]; my ($col, $row) = ($h[$o{colw}] >> 8, $h[$o{colw}] & 0xFF);
      $col = int($col + $omax / 2 - $nmax / 2 + 0.5); $col = 1 if $col < 1; $h[$o{colw}] = ($col << 8) | $row; }
    my $blob = pack('n*', @h, enc($s), 0x4040); my $na = alloc(length $blob); substr($P, $na, length $blob) = $blob;
    wl($_, $na) for @{ $slots{$ra} }; $cnt++; }
  printf "%s: %d records relocated\n", $o{file}, $cnt;
}
ptrrecs(file => 'bosses.txt', tables => [[0xD74C4, 11], [0xD75CC, 11]], hdr => 6, colw => 4, width => 31);
ptrrecs(file => 'bosses2.txt', tables => [[0xFAB04, 2]], hdr => 7, colw => 5, width => 31);
ptrrecs(file => 'request.txt', tables => [[0xF4E90, 5]], hdr => 1, width => 36);
ptrrecs(file => 'spells.txt', tables => [[0xFB1FA, 24]], hdr => 2, spell => 30, width => 30);

# ---------- item / spell / treasure names (8x8 font, table of 59 ptrs at 0x47960, EN only) ----------
{
  my $tr = load_tr("$tdir/items.txt");
  if (%$tr) { Font::build_enc8(); my %E8 = %Font::ENC8; my $cnt = 0; my %done;
    for my $i (0 .. 58) { next unless exists $tr->{$i}; my $a = unpack('N', substr($P0, 0x47960 + 4 * $i, 4));
      my @pre; my $p = $a; while (1) { my $x = unpack('n', substr($P0, $p, 2)); last if ($x >> 8) == 0x2A; push @pre, $x; $p += 2; }
      my @w = map { $E8{$_} // die "items $i: no 8x8 glyph for '$_'\n" } split //, $tr->{$i};
      push @warn, "items $i: long name (" . scalar(@w) . ")" if @w > 19;
      my $blob = pack('n*', @pre, @w, 0x4040); my $na = alloc(length $blob); substr($P, $na, length $blob) = $blob; wl(0x47960 + 4 * $i, $na); $cnt++; }
    print "items: $cnt names\n"; }
}

# ---------- enemy names (shown at the top when hitting an enemy): 25 ptrs at 0x47732 to raw-byte slots ----------
# Each slot holds a right-aligned 15-char name + '@' (bytes are bank-0 tile codes). Ã Í Ó map to 0x5D-0x5F.
{
  my $tr = load_tr("$tdir/enemies.txt");
  if (%$tr) { my %map = ("\x{c3}" => "\x5D", "\x{cd}" => "\x5E", "\x{d3}" => "\x5F"); my $cnt = 0;
    for my $i (sort { $a <=> $b } keys %$tr) { my $pa = unpack('N', substr($P0, 0x47732 + 4 * $i, 4));
      my $len = index(substr($P0, $pa, 32), '@'); die "enemy $i: no terminator\n" if $len < 0;
      my $s = join '', map { exists $map{$_} ? $map{$_} : $_ } split //, $tr->{$i};
      die "enemy $i: bad char in '$tr->{$i}'\n" if $s =~ /[^\x20-\x5F]/; die "enemy $i: '$tr->{$i}' longer than $len\n" if length $s > $len;
      substr($P, $pa, $len) = (' ' x ($len - length $s)) . $s; $cnt++; }
    print "enemies: $cnt names\n"; }
}

# ---------- 9-entry language tables [JP, EN, ES, EN, EN, ES, FR, DE, IT] ----------
# groups.txt lines: "<table hex>:<header words>|text". The PT record is written at the EN string's
# address (may overflow into the following ES/IT/FR/DE strings) and every Latin entry points to it.
{
  my $tr = load_tr("$tdir/groups.txt"); my $n = 0;
  for my $k (sort keys %$tr) {
    my ($tab, $nh, $rc) = $k =~ /^([0-9A-Fa-f]+):(\d+)(:c)?$/ or die "groups: bad key $k\n"; $tab = hex $tab;
    my @e = map { unpack('N', substr($P0, $tab + 4 * $_, 4)) } 0 .. 8;
    my $en = $e[1]; my %lat = map { $_ => 1 } @e[1 .. 8];
    my $send = sub { my $p = shift; $p += 2 while unpack('n', substr($P0, $p, 2)) != 0x4040; return $p + 2; };
    my $end = $en; my @t = sort { $a <=> $b } keys %lat;   # contiguous run of Latin strings starting at EN
    for my $t (@t) { next if $t < $en; last if $t != $end && $t != $en; $end = $send->($t); }
    my $s = $tr->{$k}; checkw(sprintf('group %06X', $tab), $s, 29);
    my $hdr = substr($P0, $en, $nh * 2);
    if ($rc) { my $cr = unpack('n', $hdr); my $p = $en + 2 * $nh; my @ol = (0);
      while ((my $x = unpack('n', substr($P0, $p, 2))) != 0x4040) { if ($x == 0x2F2F) { push @ol, 0 } else { $ol[-1]++ } $p += 2; }
      my ($omax) = sort { $b <=> $a } @ol; my ($nmax) = sort { $b <=> $a } map { textlen($_) } split m{/}, $s;
      my $col = int(($cr >> 8) + $omax / 2 - $nmax / 2 + 0.5); $col = 1 if $col < 1; substr($hdr, 0, 2) = pack('n', ($col << 8) | ($cr & 0xFF)); }
    my $blob = $hdr . pack('n*', enc($s), 0x4040);
    my $at = length($blob) <= $end - $en ? $en : alloc(length $blob);   # in place, or in the free pool
    substr($P, $at, length $blob) = $blob;
    for my $i (0 .. 8) { wl($tab + 4 * $i, $at) if $lat{$e[$i]} || $e[$i] == $en; }
    $n++; }
  print "groups: $n translated\n" if $n;
}

# ---------- fixed records: text replaced in place, same start and size (padded with spaces) ----------
# fixed.txt lines "ADDR:hdrwords|text" (ADDR = record start). Used where the game reaches the text by a fixed address.
{
  my $tr = load_tr("$tdir/fixed.txt"); my $cnt = 0;
  for my $k (sort keys %$tr) { my ($a, $nh) = $k =~ /^([0-9A-Fa-f]+):(\d+)$/ or die "fixed: bad key $k\n"; $a = hex $a;
    my $p = $a + 2 * $nh; my $n = 0; $n++, $p += 2 while unpack('n', substr($P0, $p, 2)) != 0x4040;
    my $s = $tr->{$k}; checkw(sprintf('fixed %06X', $a), $s, 32); my @w = enc($s);
    die sprintf("fixed %06X: too long (%d > %d)\n", $a, scalar @w, $n) if @w > $n; push @w, (0x14A4) x ($n - @w);
    substr($P, $a + 2 * $nh, 2 * $n) = pack('n*', @w); $cnt++; }
  print "fixed: $cnt records\n" if $cnt;
}

# ---------- text map: every '@'-terminated string in the given regions whose text equals an EN key is ----------
# ---------- replaced in place (same size, padded). textmap.txt lines "EN text|PT text"                ----------
{
  my $tr = load_tr("$tdir/textmap.txt");
  if (%$tr) { my %dec; for my $c (keys %ENC) { my $v = $ENC{$c}; $dec{$v} = $c if ($v >> 8) == 0x14 && !exists $dec{$v}; } $dec{0x2F2F} = '/';
    my %hits; my @regions = ([0x31380, 0x31700], [0x12FE00, 0x1308C0], [0x03FBCA, 0x040200]);
    for my $r (@regions) { my ($lo, $hi) = @$r; my $start; my $s = '';
      for (my $p = $lo; $p < $hi; $p += 2) { my $w = unpack('n', substr($P0, $p, 2));
        if ($w == 0x4040) { if (defined $start && length $s && exists $tr->{$s}) {
            my $n = ($p - $start) / 2; my @nw = enc($tr->{$s}); die sprintf("textmap %06X '%s': too long (%d > %d)\n", $start, $s, scalar @nw, $n) if @nw > $n;
            push @nw, (0x14A4) x ($n - @nw); substr($P, $start, 2 * $n) = pack('n*', @nw); $hits{$s}++; }
          undef $start; $s = ''; next; }
        if (exists $dec{$w}) { $start //= $p; $s .= $dec{$w}; } else { undef $start; $s = ''; } } }
    my @miss = grep { !$hits{$_} } keys %$tr; push @warn, "textmap: not found: $_" for @miss;
    my $t = 0; $t += $_ for values %hits; print "textmap: $t replacements (" . scalar(keys %hits) . " texts)\n"; }
}

# ---------- legal / boot texts (title trademark, copyright, WARNING, QSound): raw bytes in the bank-0 ASCII font ----------
# Lines are fixed-width runs between '/' and '@'; a translation keeps the run width (padded, or centred if the original was).
# New lowercase accents go into unused bank-0 codes: 0x7B á, 0x7C ã, 0x7D ç, 0x7E é, 0x60 í.
{ my %acc = ("\x{e1}" => [0x7B, 0x61, 'acute'], "\x{e3}" => [0x7C, 0x61, 'tilde'], "\x{e7}" => [0x7D, 0x63, 'ced'], "\x{e9}" => [0x7E, 0x65, 'acute'], "\x{ed}" => [0x60, 0x69, 'acute']);
  my %ink = (acute => [[0,4],[1,3]], tilde => [[0,2],[0,3],[0,5],[1,1],[1,4]]);
  for my $ch (keys %acc) { my ($code, $base, $a) = @{ $acc{$ch} }; my $src = Font::get8($base); my $g = [ map { [ (15) x 8 ] } 0 .. 7 ];
    if ($a eq 'ced') {   # c raised one row, cedilla in rows 6-7
      $g->[$_ - 1] = [ @{ $src->[$_] } ] for 2 .. 7;
      for my $p ([6,3],[7,2],[7,3]) { my ($y, $x) = @$p; $g->[$y][$x] = 3; }
      for my $p ([6,3],[7,2],[7,3]) { my ($y, $x) = @$p; $g->[$y][$x + 1] = 14 if $g->[$y][$x + 1] == 15; } }
    else {
      if ($base == 0x61) { $g->[2] = [ @{ $src->[1] } ]; $g->[$_] = [ @{ $src->[$_] } ] for 3 .. 7; }   # a: top bar down one row
      elsif ($base == 0x69) { $g->[$_] = [ @{ $src->[$_] } ] for 3 .. 7; }                               # i: dot replaced
      else { $g->[$_] = [ @{ $src->[$_] } ] for 2 .. 7; }
      for my $p (@{ $ink{$a} }) { my ($y, $x) = @$p; $g->[$y][$x] = 0; }
      for my $p (@{ $ink{$a} }) { my ($y, $x) = @$p; $g->[$y][$x + 1] = 14 if $x < 7 && $g->[$y][$x + 1] == 15; } }
    Font::put8($code, $g); }
  my $tr = load_tr("$tdir/legal.txt"); my $n = 0;
  for my $en (sort keys %$tr) { my $pt = $tr->{$en}; my $raw = join '', map { exists $acc{$_} ? chr $acc{$_}[0] : $_ } split //, $pt;
    die "legal: unsupported character in '$pt'\n" if $raw =~ /[^\x20-\x7E]|[\@\/]/ && $raw !~ /^[\x20-\x7E]*$/;
    my $hits = 0;
    for my $r ([0x2B80, 0x2D80], [0x2F600, 0x2F900], [0x31900, 0x31C40], [0x31D00, 0x31F00]) { my ($lo, $hi) = @$r; my $p = $lo;
      while (($p = index($P0, $en, $p)) >= 0 && $p < $hi) { my ($a, $b) = ($p, $p + length $en);
        $a-- while substr($P0, $a - 1, 1) eq ' '; $b++ while substr($P0, $b, 1) eq ' ';
        if (substr($P0, $a - 1, 1) =~ /[\x20-\x7E]/ && substr($P0, $a - 1, 1) !~ m{[/#]}) { $p = $b; next; }   # must start a line
        if (substr($P0, $b, 1) !~ m{[/\@]}) { $p = $b; next; }                                                     # and end it
        my $w = $b - $a; die "legal: '$pt' too wide (" . length($raw) . " > $w)\n" if length $raw > $w;
        my $lead = $p - $a > 8 ? int(($w - length $raw) / 2) : 0;
        substr($P, $a, $w) = (' ' x $lead) . $raw . (' ' x ($w - $lead - length $raw)); $hits++; $p = $b; } }
    push @warn, "legal: not found: $en" unless $hits; $n += $hits; }
  print "legal texts: $n lines\n"; }

# ---------- "TIME" label (scroll1 8x8 tiles; the font also holds the Spanish "TIEMPO") -> "TEMPO" ----------
# TEMPO = TIEMPO (row 0x3690, strip columns 36-75) without the I; it replaces every copy of the TIME block.
{ my $pxs = sub { my ($row, $x, $y) = @_; my @b = unpack('C4', substr($Font::G, (0x20000 + $row + int($x / 8)) * 64 + $y * 8, 4)); my $bit = 7 - ($x % 8);
    return ((($b[3] >> $bit) & 1) << 3) | ((($b[2] >> $bit) & 1) << 2) | ((($b[1] >> $bit) & 1) << 1) | (($b[0] >> $bit) & 1); };
  my $set = sub { my ($row, $x, $y, $p) = @_; my $o = (0x20000 + $row + int($x / 8)) * 64 + $y * 8; my @b = unpack('C8', substr($Font::G, $o, 8)); my $bit = 7 - ($x % 8);
    for my $pl (0 .. 3) { for my $hf (0, 1) { my $i = $pl + 4 * $hf; $b[$i] = ($b[$i] & ~(1 << $bit)) | ((($p >> $pl) & 1) << $bit); } } substr($Font::G, $o, 8) = pack('C8', @b); };
  my @tempo = map { my $x = $_; [ map { $pxs->(0x3690, $x, $_) } 0 .. 7 ] } 36 .. 42, 48 .. 75;
  my @time = map { my $x = $_; [ map { $pxs->(0x3690, $x, $_) } 0 .. 7 ] } 85 .. 121;
  my $n = 0;
  for my $row (0x3680, 0x3690, 0x36A0) { for my $off (0 .. 128 - @time) {
      next if grep { my $c = $_; grep { $pxs->($row, $off + $c, $_) != $time[$c][$_] } 0 .. 7 } 0 .. $#time;
      for my $x ($off .. $off + $#time) { $set->($row, $x, $_, 15) for 0 .. 7; }
      my $x0 = $off + int((@time - @tempo) / 2); for my $c (0 .. $#tempo) { $set->($row, $x0 + $c, $_, $tempo[$c][$_]) for 0 .. 7; } $n++; } }
  die "TIME label not found\n" unless $n; print "TIME -> TEMPO: $n copies\n"; }

# ---------- "PLAYER SELECT" wooden sign (28x4 scroll1 tiles: 0x160A+, 0x1680+, 0x1700+) -> "SELEÇÃO" ----------
# Letters are pens B/C/D on a wood texture. S E L E C come from SELECT; Ç = C + cedilla, Ã = A (from PLAYER) + tilde,
# O = C closed with its own mirrored left half. The old letters are painted over with wood from the same row.
{ my $code = sub { my ($c, $r) = @_; return ($c < 6 ? 0x160A + $c : $c < 22 ? 0x1680 + $c - 6 : 0x1700 + $c - 22) + 0x10 * $r; };
  my $get = sub { my ($x, $y) = @_; my @b = unpack('C4', substr($Font::G, (0x20000 + $code->(int($x / 8), int($y / 8))) * 64 + ($y % 8) * 8, 4)); my $bit = 7 - $x % 8;
    return ((($b[3] >> $bit) & 1) << 3) | ((($b[2] >> $bit) & 1) << 2) | ((($b[1] >> $bit) & 1) << 1) | (($b[0] >> $bit) & 1); };
  my $put = sub { my ($x, $y, $p) = @_; my $o = (0x20000 + $code->(int($x / 8), int($y / 8))) * 64 + ($y % 8) * 8; my @b = unpack('C8', substr($Font::G, $o, 8)); my $bit = 7 - $x % 8;
    for my $pl (0 .. 3) { for my $hf (0, 1) { my $i = $pl + 4 * $hf; $b[$i] = ($b[$i] & ~(1 << $bit)) | ((($p >> $pl) & 1) << $bit); } } substr($Font::G, $o, 8) = pack('C8', @b); };
  my @cv = map { my $y = $_; [ map { $get->($_, $y) } 0 .. 223 ] } 0 .. 31;
  my $ink = sub { $_[0] >= 0xB && $_[0] <= 0xD };
  my $near = sub { my ($x, $y) = @_; for my $dy (-1 .. 1) { for my $dx (-1 .. 1) { my ($a, $b) = ($x + $dx, $y + $dy); return 1 if $b >= 0 && $b < 32 && $a >= 0 && $a < 224 && $ink->($cv[$b][$a]); } } return 0; };
  # glyph columns of 32 pens: the letter pens plus the dark carved halo touching them (pens <= 7)
  my $glyph = sub { my ($x0, $x1) = @_; [ map { my $x = $_; [ map { my $p = $cv[$_][$x]; $ink->($p) || ($p <= 7 && $_ >= 5 && $_ <= 26 && $near->($x, $_)) ? $p : 15 } 0 .. 31 ] } $x0 - 1 .. $x1 + 1 ] };
  my %G = (S => $glyph->(118, 129), E => $glyph->(132, 146), L => $glyph->(148, 162), C => $glyph->(180, 193), A => $glyph->(44, 56));
  my $mark = sub { my ($g, $pts) = @_; my @n = map { [ @$_ ] } @$g;
    for my $p (@$pts) { my ($x, $y) = @$p; $n[$x][$y] = 0xC; } for my $p (@$pts) { my ($x, $y) = @$p; $n[$x - 1][$y + 1] = 0xD if $x > 0 && $n[$x - 1][$y + 1] == 15; } return \@n; };
  my $cw = @{ $G{C} }; my $mid = int($cw / 2);
  $G{O} = [ (map { [ @{ $G{C}[$_] } ] } 0 .. $mid - 1), (map { [ @{ $G{C}[$mid - 1 - $_] } ] } 0 .. $mid - 1) ];
  $G{"\x{c7}"} = $mark->($G{C}, [ map { [$mid + $_->[0], $_->[1]] } [0,24], [1,24], [1,25], [2,25], [-1,26], [0,26], [1,26] ]);
  $G{"\x{c3}"} = $mark->($G{A}, [ map { [3 + $_->[0], $_->[1]] } [1,5], [2,5], [3,5], [7,5], [0,6], [4,6], [5,6], [6,6] ]);
  # paint the old letters and their dark halo over with clean wood from the same row (runs map to runs, keeping the grain)
  my %dirty; for my $y (5 .. 26) { for my $x (0 .. 223) { next unless $ink->($cv[$y][$x]);
    for my $dy (-2 .. 2) { for my $dx (-3 .. 3) { $dirty{ ($y + $dy) . ',' . ($x + $dx) } = 1; } } } }
  for my $y (5 .. 26) { my @clean = grep { !$dirty{"$y,$_"} } 8 .. 215; next unless @clean; my $k = ($y * 37) % @clean;
    for my $x (8 .. 215) { next unless $dirty{"$y,$x"}; $put->($x, $y, $cv[$y][ $clean[ ($k + $x) % @clean ] ]); } }
  my @word = ('S', 'E', 'L', 'E', "\x{c7}", "\x{c3}", 'O'); my $gap = 0; my $w = -$gap; $w += @{ $G{$_} } + $gap for @word;
  my $x = 112 - int($w / 2);
  for my $ch (@word) { my $g = $G{$ch}; for my $c (0 .. $#$g) { for my $y (0 .. 31) { $put->($x + $c, $y, $g->[$c][$y]) if $g->[$c][$y] != 15; } } $x += @$g + $gap; }
  print "PLAYER SELECT -> SELE\x{c7}\x{c3}O ($w px)\n"; }

# ---------- shop: "EXIT" sign (16x16 tiles 0x9F07-0x9F0A over 0x9F17-0x9F1A) -> "SAÍDA", "OIL" label (0x9F8C-0x9F8D) -> "ÓLEO" ----------
{ my $sget = sub { my ($t, $x, $y) = @_; my @b = unpack('C4', substr($Font::G, $t * 128 + $y * 8 + ($x < 8 ? 0 : 4), 4)); my $bit = 7 - $x % 8;
    return ((($b[3] >> $bit) & 1) << 3) | ((($b[2] >> $bit) & 1) << 2) | ((($b[1] >> $bit) & 1) << 1) | (($b[0] >> $bit) & 1); };
  my $sput = sub { my ($t, $x, $y, $p) = @_; my $o = $t * 128 + $y * 8 + ($x < 8 ? 0 : 4); my @b = unpack('C4', substr($Font::G, $o, 4)); my $bit = 7 - $x % 8;
    for my $pl (0 .. 3) { $b[$pl] = ($b[$pl] & ~(1 << $bit)) | ((($p >> $pl) & 1) << $bit); } substr($Font::G, $o, 4) = pack('C4', @b); };
  my $canvas = sub { my @rows = @_; my $W = 16 * @{ $rows[0] };   # rows of tile codes -> (get, put) over the block
    (sub { my ($x, $y) = @_; $sget->($rows[int($y / 16)][int($x / 16)], $x % 16, $y % 16) }, sub { my ($x, $y, $p) = @_; $sput->($rows[int($y / 16)][int($x / 16)], $x % 16, $y % 16, $p) }) };
  my $draw = sub { my ($put, $font, $text, $x, $y0, $gap) = @_; my @pts;
    for my $ch (split //, $text) { my $m = $font->{$ch} or die "shop font: no '$ch'\n"; my $w = 0; $w = length > $w ? length : $w for @$m;
      for my $r (0 .. $#$m) { for my $c (0 .. length($m->[$r]) - 1) { push @pts, [$x + $c, $y0 + $r] if substr($m->[$r], $c, 1) eq '#'; } } $x += $w + $gap; }
    return @pts; };
  # EXIT sign: letters pen B rows 6-16 inside the wooden board (text area x 21-72 of the 64x32 block, x counted from tile 0x9F06)
  { my ($get, $put) = $canvas->([0x9F06 .. 0x9F0B], [0x9F16 .. 0x9F1B]);
    my %ink; for my $y (5 .. 17) { for my $x (21 .. 73) { my $p = $get->($x, $y); $ink{"$y,$x"} = 1 if $p == 0xB || ($p == 0xA && $y >= 6 && $y <= 16); } }
    my %dirty; for my $k (keys %ink) { my ($y, $x) = split /,/, $k; for my $dy (-1 .. 1) { for my $dx (-1 .. 1) { $dirty{ ($y + $dy) . ',' . ($x + $dx) } = 1; } } }
    my %orig; for my $y (5 .. 17) { $orig{"$y,$_"} = $get->($_, $y) for 20 .. 74; }
    for my $y (6 .. 16) { my @clean = grep { !$dirty{"$y,$_"} } 21 .. 72; next unless @clean; my $k = ($y * 11) % @clean;
      for my $x (21 .. 72) { $put->($x, $y, $orig{"$y,$clean[($k + $x) % @clean]"}) if $dirty{"$y,$x"}; } }
    my %F = (S => ['.#######', '###...##', '###.....', '###.....', '.#####..', '..######', '.....###', '.....###', '##...###', '########', '.######.'],
             A => ['...####...', '..######..', '.###..###.', '.###..###.', '###....###', '###....###', '##########', '###....###', '###....###', '###....###', '###....###'],
             "\x{cd}" => [ ('###') x 11 ],
             D => ['######..', '###.###.', '###..###', '###..###', '###..###', '###..###', '###..###', '###..###', '###..###', '###.###.', '######..']);
    my $txt = "SA\x{cd}DA"; my $w = -2; for (split //, $txt) { my $m = $F{$_}; my $l = 0; $l = length > $l ? length : $l for @$m; $w += $l + 2; }
    my $x0 = 47 - int($w / 2); my @pts = $draw->($put, \%F, $txt, $x0, 6, 2);
    my $ix = $x0 + 9 + 2 + 9 + 2; push @pts, [$ix + 2, 4], [$ix + 1, 5];   # acute over the I (rows 4-5)
    my %on = map {; "$_->[0],$_->[1]" => 1 } @pts;
    for my $p (@pts) { my ($x, $y) = @$p; $put->($x - 1, $y, 4) unless $on{ ($x - 1) . ",$y" }; }   # dark carved edge on the left
    $put->($_->[0], $_->[1], 0xB) for @pts; }
  # OIL label: grey box pen B, letters pen D rows 8-12 (x counted from tile 0x9F8B)
  { my ($get, $put) = $canvas->([0x9F8B .. 0x9F8E]);
    for my $y (7 .. 13) { for my $x (20 .. 45) { $put->($x, $y, 0xB) if $get->($x, $y) == 0xD; } }
    my %F = (O => ['.###.', '##.##', '##.##', '##.##', '.###.'], L => ['##..', '##..', '##..', '##..', '####'], E => ['####', '##..', '###.', '##..', '####']);
    $F{"\x{d3}"} = $F{O}; my @pts = $draw->($put, \%F, "\x{d3}LEO", 22, 8, 1); push @pts, [25, 7], [26, 7];
    $put->($_->[0], $_->[1], 0xD) for @pts; }
  # class medallions on the pointing hands (shop cursor / select screen): F -> L (tiles 0x9524-25), D -> A (0x952A-2B)
  { my ($get, $put) = $canvas->([0x9524, 0x9525]);   # letter pens 9 (stroke) with an A highlight on the stem
    for my $y (4 .. 12) { for my $x (11 .. 21) { $put->($x, $y, 0) if $get->($x, $y) >= 9 && $get->($x, $y) <= 0xC; } }
    my @L = ('#####...', '.##.....', '.##.....', '.##.....', '.##.....', '.##.....', '.##.....', '.##....#', '########');
    for my $r (0 .. 8) { for my $c (0 .. 7) { next unless substr($L[$r], $c, 1) eq '#'; $put->(11 + $c, 4 + $r, ($c == 1 && $r >= 1 && $r <= 7) ? 0xA : 9); } } }
  { my ($get, $put) = $canvas->([0x952A, 0x952B]);   # letter pens 3-7: 3 on top rows, 4 below, 5 on the left edge of each run
    for my $y (3 .. 11) { for my $x (8 .. 26) { my $p = $get->($x, $y); $put->($x, $y, 0) if $p >= 3 && $p <= 7; } }
    my @A = ('....###....', '...#####...', '...##.###..', '..###..###.', '..###..###.', '.#########.', '.###...###.', '###....####', '####..#####');
    for my $r (0 .. 8) { for my $c (0 .. 10) { next unless substr($A[$r], $c, 1) eq '#'; my $left = $c == 0 || substr($A[$r], $c - 1, 1) ne '#';
      $put->(11 + $c, 3 + $r, $left ? 5 : $r <= 3 ? 3 : 4); } } }
  # the bigger hand of the shop cursor: F -> L (0x97F8-F9, pens 9-C), D -> A (0x97FE-FF, pens 4-8)
  { my ($get, $put) = $canvas->([0x97F8, 0x97F9]);
    for my $y (7 .. 13) { for my $x (10 .. 22) { $put->($x, $y, 0) if $get->($x, $y) >= 9 && $get->($x, $y) <= 0xC; } }
    my @L = ('#####...', '.##.....', '.##.....', '.##.....', '.##.....', '.##....#', '########');
    for my $r (0 .. 6) { for my $c (0 .. 7) { next unless substr($L[$r], $c, 1) eq '#'; $put->(12 + $c, 7 + $r, ($c == 1 && $r >= 1 && $r <= 5) ? 0xB : 9); } } }
  { my ($get, $put) = $canvas->([0x97FE, 0x97FF]);
    for my $y (6 .. 13) { for my $x (6 .. 25) { my $p = $get->($x, $y); $put->($x, $y, 0) if $p >= 4 && $p <= 8; } }
    my @A = ('....###....', '...#####...', '..###.###..', '..##...##..', '.#########.', '.###...###.', '###.....###', '####...####');
    for my $r (0 .. 7) { for my $c (0 .. 10) { next unless substr($A[$r], $c, 1) eq '#'; my $left = $c == 0 || substr($A[$r], $c - 1, 1) ne '#';
      $put->(10 + $c, 6 + $r, $left ? 6 : $r <= 3 ? 4 : 5); } } }
  # "SOLD OUT" plaque: sprite pieces 0x9803, 0x9826, 0x9829, 0x9960, 0x99E7 side by side; red letters pen D on grey pen 3
  { my ($get, $put) = $canvas->([0x9803, 0x9826, 0x9829, 0x9960, 0x99E7]);
    for my $y (3 .. 10) { for my $x (3 .. 63) { my $p = $get->($x, $y); $put->($x, $y, 3) if $p == 0xD || $p == 4; } }
    my %F = (E => ['######', '##....', '##....', '#####.', '##....', '##....', '##....', '######'],
             S => ['.#####', '##....', '##....', '.####.', '....##', '....##', '....##', '#####.'],
             G => ['.#####', '##....', '##....', '##.###', '##..##', '##..##', '##..##', '.#####'],
             O => ['.####.', '##..##', '##..##', '##..##', '##..##', '##..##', '##..##', '.####.'],
             T => ['######', '..##..', '..##..', '..##..', '..##..', '..##..', '..##..', '..##..'],
             A => ['.####.', '##..##', '##..##', '##..##', '######', '##..##', '##..##', '##..##'],
             D => ['#####.', '##..##', '##..##', '##..##', '##..##', '##..##', '##..##', '#####.']);
    $put->($_->[0], $_->[1], 0xD) for $draw->($put, \%F, 'ESGOTADO', 6, 3, 1); }
  print "shop signs: SA\x{cd}DA, \x{d3}LEO, ESGOTADO; hand medallions L, A\n"; }

# ---------- short two-line "INSERT/ COIN" slot records (two tables of 4 slots: [pos, 0004, text, 4040]) ----------
# "INSIRA/FICHA" centred needs one word more than the original, so the records move to the free pool
# with the same position: INSIRA on columns c..c+5 and the half-shifted FICHA (0x1420-0x1425) under it.
{ my $n = 0;
  for my $tab (0x03154C, 0x1306EC) { for my $e (0 .. 3) { my $old = rl($tab + 4 * $e);
    die sprintf("slot record %06X: unexpected header\n", $old) unless rw($old + 2) == 0x0004;
    my $rec = pack('n*', rw($old), 0x0004, enc('INSIRA'), 0x2F2F, 0x1420 .. 0x1425, 0x4040);
    my $a = alloc(length $rec); substr($P, $a, length $rec) = $rec; wl($tab + 4 * $e, $a); $n++; } }
  print "slot records: $n relocated\n"; }

# ---------- raw byte strings (plain ASCII-coded texts): exact same-length replacement in given regions ----------
{
  my $tr = load_tr("$tdir/bytemap.txt");
  if (%$tr) { my $cnt = 0; my @regions = ([0x12FE00, 0x12FF40], [0x040080, 0x040100]);
    for my $en (keys %$tr) { my $pt = $tr->{$en}; die "bytemap: '$pt' must have the same length as '$en'\n" if length $pt != length $en;
      for my $r (@regions) { my ($lo, $hi) = @$r; my $p = $lo; while (($p = index($P0, $en, $p)) >= 0 && $p < $hi) { substr($P, $p, length $pt) = $pt; $cnt++; $p++; } } }
    print "bytemap: $cnt replacements\n"; }
}

# ---------- pieces reached by "lea d16(pc),An" in encrypted code: relocate and patch the displacement ----------
# pieces.txt lines "LEA_ADDR:TARGET:hdrwords|text"; pieces are packed into the region given per group.
require "$T/cps2crypt.pl"; Crypt::init("$T/cps2crypt.cpp", 0xECA19C3D, 0x24736BF0);
sub patch_lea { my ($at, $target) = @_;
  my $op = Crypt::dec($at, unpack('n', substr($P0, $at, 2)));
  die sprintf("patch_lea %06X: not a lea d16(pc) (%04X)\n", $at, $op) unless ($op & 0xF1FF) == 0x41FA;
  my $d = $target - ($at + 2); die sprintf("patch_lea %06X: out of range\n", $at) if $d < -0x8000 || $d > 0x7FFF;
  substr($P, $at + 2, 2) = pack('n', Crypt::enc($at + 2, $d & 0xFFFF)); }
{
  my $tr = load_tr("$tdir/pieces.txt");
  if (%$tr) { my %region = (levelup => [0x3F8F8, 0x3FBCA]); my %pos; my $cnt = 0;
    for my $k (sort keys %$tr) { my ($grp, $lea, $tgt, $nh) = $k =~ /^(\w+):([0-9A-Fa-f]+):([0-9A-Fa-f]+):(\d+)$/ or die "pieces: bad key $k\n";
      ($lea, $tgt) = (hex $lea, hex $tgt); $pos{$grp} //= $region{$grp}[0];
      my $blob = substr($P0, $tgt, 2 * $nh) . pack('n*', enc($tr->{$k}), 0x4040);
      die "pieces $grp: region full\n" if $pos{$grp} + length $blob > $region{$grp}[1];
      substr($P, $pos{$grp}, length $blob) = $blob; patch_lea($lea, $pos{$grp}); $pos{$grp} += length $blob; $cnt++; }
    print "pieces: $cnt relocated\n"; }
}

# ---------- demo banner and level-up word: big 16x16 scroll1 font (letter = code, +1, +0x10, +0x11) ----------
{ my %B; my @r = ('ABCDEFGH', 'IJKLMNOP', 'QRSTUVWX', 'YZ');
  for my $i (0 .. $#r) { my @c = split //, $r[$i]; $B{ $c[$_] } = 0x0400 + 0x20 * $i + 2 * $_ for 0 .. $#c; }
  $B{' '} = 0x04AE; @B{"\x{d1}", "\x{c1}", "\x{c9}", "\x{cd}", "\x{d3}", "\x{da}"} = (0x04E0, 0x04E2, 0x04E4, 0x04E6, 0x04E8, 0x04EA);
  my $big = sub { map { $B{$_} // die "big font: no glyph '$_'\n" } split //, shift };
  # "PLEASE INSERT COIN" / "FREE PLAY": records [column << 8 | row, 0x0001, codes, 0x4040], centred (column = 24 - letters)
  my $rec = sub { my @c = $big->(shift); return pack('n*', ((24 - @c) << 8) | 0x0C, 0x0001, @c, 0x4040); };
  my ($r1, $r2) = ($rec->('INSIRA FICHA'), $rec->("JOGO GR\x{c1}TIS"));
  die "banner records too long\n" if length($r1 . $r2) > 0x033B7C - 0x033B3A;
  substr($P, 0x033B3A, length($r1 . $r2)) = $r1 . $r2; patch_lea(0x030742, 0x033B3A + length $r1);
  substr($P, 0x03F8BA, 10) = pack('n*', $big->("N\x{cd}VEL")); substr($P, 0x03F8DC, 6) = pack('n*', $big->("M\x{c1}X"));   # level-up
  print "banner: replaced\n"; }
# "There!" shout over the HUD before the wounded soldier (record [pos, 0010, text, 4040]; 4 letters -> one column right)
{ my $r = pack('n*', 0x1715, 0x0010, enc('Ali!'), 0x4040); die "There! record too long\n" if length $r > 18; substr($P, 0x0F3EB2, length $r) = $r; }

# ---------- write program ROMs ----------
mkdir $outdir; my @changed;
{ my $img = pack('v*', unpack('n*', $P));
  for my $i (0 .. $#PF) { my $d = substr($img, $i * 0x80000, 0x80000); spew("$outdir/$PF[$i]", $d); push @changed, $PF[$i] if $d ne slurp("$romdir/$PF[$i]"); } }
# ---------- write gfx ROMs ----------
{ my $G = $Font::G; if ($ENV{FILL}) { for my $rg (split /,/, $ENV{FILL}) { my ($lo, $hi) = map { hex } split /-/, $rg; substr($G, $_ * 64, 64) = pack(q{C8}, 0x55, 0x33, 0x0F, 0x00, 0x55, 0x33, 0x0F, 0x00) x 8 for $lo .. $hi - 1; } print "DEBUG fill $ENV{FILL}
"; } my @sets = ([0x000000, 0x200000, qw(dad.13m dad.15m dad.17m dad.19m)], [0x800000, 0x100000, qw(dad.14m dad.16m dad.18m dad.20m)]);
  my $reg = '';
  for (my $b = 0; $b < length $G; $b += 0x200000) { my @q = unpack('(a8)*', substr($G, $b, 0x200000)); my $h = @q / 2; my @o;
    for my $k (0 .. $h - 1) { $o[2 * $k] = $q[$k]; $o[2 * $k + 1] = $q[$h + $k]; } $reg .= join '', @o; }
  for my $s (@sets) { my ($base, $size, @f) = @$s; my $n = $size / 2; my $chunk = substr($reg, $base, $n * 8);
    for my $fi (0 .. 3) { my $part = join '', map { substr($chunk, $_ * 8 + $fi * 2, 2) } 0 .. $n - 1;
      spew("$outdir/$f[$fi]", $part); push @changed, $f[$fi] if $part ne slurp("$romdir/$f[$fi]"); } } }
print "changed: @changed\n"; print "WARN $_\n" for @warn;

sub build_gfx {
  my @sets = ([0x000000, 0x200000, qw(dad.13m dad.15m dad.17m dad.19m)], [0x800000, 0x100000, qw(dad.14m dad.16m dad.18m dad.20m)]);
  my $reg = "\0" x 0xC00000;
  for my $s (@sets) { my ($base, $size, @f) = @$s; my @d = map { slurp("$romdir/$_") } @f; my $n = $size / 2;
    my $chunk = join '', map { my $j = $_; substr($d[0], 2*$j, 2) . substr($d[1], 2*$j, 2) . substr($d[2], 2*$j, 2) . substr($d[3], 2*$j, 2) } 0 .. $n - 1;
    substr($reg, $base, length $chunk) = $chunk; }
  my $res = '';
  for (my $b = 0; $b < length $reg; $b += 0x200000) { my @q = unpack('(a8)*', substr($reg, $b, 0x200000));
    $res .= join('', @q[grep { !($_ & 1) } 0 .. $#q]) . join('', @q[grep { $_ & 1 } 0 .. $#q]); }
  return $res; }
