# Minimal-but-broad 68000 disassembler.
# usage: m68kdis.pl <dec.bin> <start_hex> <count_or_end_hex> [data.bin]
#   instruction words come from dec.bin (decrypted opcodes); PC-relative data annotations use data.bin.
use strict; use warnings;
my ($file, $start, $cnt, $dfile) = @ARGV;
open my $h, '<:raw', $file or die; local $/; my $D = <$h>; close $h;
my $DATA = $D; if ($dfile) { open my $g, '<:raw', $dfile or die; $DATA = <$g>; }
my $pc;
sub w16 { my $v = unpack('n', substr($D, $pc, 2)); $pc += 2; return $v; }
sub s16 { my $v = w16(); return $v >= 0x8000 ? $v - 0x10000 : $v; }
sub w32 { my $a = w16(); my $b = w16(); return ($a << 16) | $b; }
sub s8 { my $v = shift; return $v >= 0x80 ? $v - 0x100 : $v; }
my @SZ = ('.b', '.w', '.l');
my @CC = qw(t f hi ls cc cs ne eq vc vs pl mi ge lt gt le);
sub hx { my $v = shift; return $v < 0 ? sprintf('-$%X', -$v) : sprintf('$%X', $v); }
sub ea { my ($mode, $reg, $size) = @_;   # size: 0 b,1 w,2 l (for immediates)
  return "d$reg" if $mode == 0; return "a$reg" if $mode == 1; return "(a$reg)" if $mode == 2;
  return "(a$reg)+" if $mode == 3; return "-(a$reg)" if $mode == 4;
  if ($mode == 5) { my $d = s16(); return hx($d) . "(a$reg)"; }
  if ($mode == 6) { my $e = w16(); my $xr = (($e >> 15) ? 'a' : 'd') . (($e >> 12) & 7) . (($e >> 11) & 1 ? '.l' : '.w'); return hx(s8($e & 0xFF)) . "(a$reg,$xr)"; }
  if ($reg == 0) { my $v = w16(); $v |= 0xFFFF0000 if $v >= 0x8000; return sprintf('($%X).w', $v); }
  if ($reg == 1) { return sprintf('($%X).l', w32()); }
  if ($reg == 2) { my $base = $pc; my $d = s16(); my $t = $base + $d; return sprintf('$%X(pc)', $t) . anno($t); }
  if ($reg == 3) { my $base = $pc; my $e = w16(); my $xr = (($e >> 15) ? 'a' : 'd') . (($e >> 12) & 7) . (($e >> 11) & 1 ? '.l' : '.w'); my $t = $base + s8($e & 0xFF); return sprintf('$%X(pc,%s)', $t, $xr); }
  if ($reg == 4) { return '#' . ($size == 0 ? sprintf('$%X', w16() & 0xFF) : $size == 1 ? sprintf('$%X', w16()) : sprintf('$%X', w32())); }
  return '???'; }
sub anno { my $t = shift; return '' if $t < 0 || $t + 4 > length $DATA; return sprintf(' {%08X}', unpack('N', substr($DATA, $t, 4))); }
sub reglist { my ($m, $rev) = @_; my @n; for my $i (0 .. 15) { my $bit = $rev ? 15 - $i : $i; push @n, ($i < 8 ? "d$i" : 'a' . ($i - 8)) if ($m >> $bit) & 1; } return join '/', @n; }
sub dis1 {
  my $op = w16(); my $hi = $op >> 12; my ($rx, $ox, $my, $ry) = (($op >> 9) & 7, ($op >> 6) & 7, ($op >> 3) & 7, $op & 7);
  my $sz = ($op >> 6) & 3;
  if ($hi == 0) {
    if (($op & 0xF138) == 0x0108) { my $d = s16(); my $s = ($op & 0x40) ? '.l' : '.w'; return ($op & 0x80) ? "movep$s d$rx," . hx($d) . "(a$ry)" : "movep$s " . hx($d) . "(a$ry),d$rx"; }
    if ($op & 0x100) { my @b = qw(btst bchg bclr bset); return $b[$sz] . " d$rx," . ea($my, $ry, 0); }
    if (($op & 0x0F00) == 0x0800) { my @b = qw(btst bchg bclr bset); my $n = w16() & 0xFF; return $b[$sz] . " #$n," . ea($my, $ry, 0); }
    my @im = ('ori', 'andi', 'subi', 'addi', '?', 'eori', 'cmpi', '?'); my $nm = $im[$rx];
    if (($op & 0x3F) == 0x3C && $sz < 2) { my $v = w16(); return "$nm" . ($sz ? sprintf(' #$%X,sr', $v) : sprintf(' #$%X,ccr', $v & 0xFF)); }
    return "dc.w " . sprintf('$%04X', $op) if $sz == 3;
    my $imm = ea(7, 4, $sz); return "$nm$SZ[$sz] $imm," . ea($my, $ry, $sz); }
  if ($hi >= 1 && $hi <= 3) { my $s = $hi == 1 ? 0 : $hi == 3 ? 1 : 2; my $src = ea($my, $ry, $s); my $dst = ea($ox, $rx, $s);
    return ($ox == 1 ? 'movea' : 'move') . $SZ[$s] . " $src,$dst"; }
  if ($hi == 4) {
    return 'illegal' if $op == 0x4AFC; return 'reset' if $op == 0x4E70; return 'nop' if $op == 0x4E71; return sprintf('stop #$%X', w16()) if $op == 0x4E72;
    return 'rte' if $op == 0x4E73; return 'rts' if $op == 0x4E75; return 'trapv' if $op == 0x4E76; return 'rtr' if $op == 0x4E77;
    return 'trap #' . ($op & 15) if ($op & 0xFFF0) == 0x4E40;
    return "link a$ry," . hx(s16()) if ($op & 0xFFF8) == 0x4E50; return "unlk a$ry" if ($op & 0xFFF8) == 0x4E58;
    return "move a$ry,usp" if ($op & 0xFFF8) == 0x4E60; return "move usp,a$ry" if ($op & 0xFFF8) == 0x4E68;
    return 'jsr ' . ea($my, $ry, 2) if ($op & 0xFFC0) == 0x4E80; return 'jmp ' . ea($my, $ry, 2) if ($op & 0xFFC0) == 0x4EC0;
    return "lea " . ea($my, $ry, 2) . ",a$rx" if ($op & 0x1C0) == 0x1C0; return "chk.w " . ea($my, $ry, 1) . ",d$rx" if ($op & 0x1C0) == 0x180;
    return "swap d$ry" if ($op & 0xFFF8) == 0x4840; return 'pea ' . ea($my, $ry, 2) if ($op & 0xFFC0) == 0x4840;
    return "ext.w d$ry" if ($op & 0xFFF8) == 0x4880; return "ext.l d$ry" if ($op & 0xFFF8) == 0x48C0;
    if (($op & 0xFB80) == 0x4880) { my $m = w16(); my $s = ($op & 0x40) ? '.l' : '.w'; my $tomem = !($op & 0x400);
      my $e = ea($my, $ry, 1); return $tomem ? "movem$s " . reglist($m, $my == 4) . ",$e" : "movem$s $e," . reglist($m, 0); }
    return 'move sr,' . ea($my, $ry, 1) if ($op & 0xFFC0) == 0x40C0; return 'move ' . ea($my, $ry, 1) . ',ccr' if ($op & 0xFFC0) == 0x44C0;
    return 'move ' . ea($my, $ry, 1) . ',sr' if ($op & 0xFFC0) == 0x46C0; return 'nbcd ' . ea($my, $ry, 0) if ($op & 0xFFC0) == 0x4800;
    return 'tas ' . ea($my, $ry, 0) if ($op & 0xFFC0) == 0x4AC0;
    my %m = (0x4000 => 'negx', 0x4200 => 'clr', 0x4400 => 'neg', 0x4600 => 'not', 0x4A00 => 'tst');
    if (exists $m{$op & 0xFF00} && $sz < 3) { return $m{$op & 0xFF00} . $SZ[$sz] . ' ' . ea($my, $ry, $sz); }
    return sprintf('dc.w $%04X', $op); }
  if ($hi == 5) {
    if ($sz == 3) { my $c = $CC[($op >> 8) & 15]; if ($my == 1) { my $b = $pc; my $d = s16(); return sprintf("db$c d$ry,\$%X", $b + $d); } return "s$c " . ea($my, $ry, 0); }
    my $q = $rx || 8; return (($op & 0x100) ? 'subq' : 'addq') . $SZ[$sz] . " #$q," . ea($my, $ry, $sz); }
  if ($hi == 6) { my $c = ($op >> 8) & 15; my $b = $pc; my $d = s8($op & 0xFF); my $s = '.s'; if ($d == 0) { $d = s16(); $s = '.w'; }
    my $n = $c == 0 ? 'bra' : $c == 1 ? 'bsr' : "b$CC[$c]"; return sprintf("$n$s \$%X", $b + $d); }
  if ($hi == 7) { return sprintf('moveq #%s,d%d', hx(s8($op & 0xFF)), $rx); }
  if ($hi == 8 || $hi == 0xC) {
    my $nm = $hi == 8 ? 'or' : 'and';
    if ($ox == 3) { return ($hi == 8 ? 'divu' : 'mulu') . '.w ' . ea($my, $ry, 1) . ",d$rx"; }
    if ($ox == 7) { return ($hi == 8 ? 'divs' : 'muls') . '.w ' . ea($my, $ry, 1) . ",d$rx"; }
    if (($op & 0x1F0) == 0x100) { my $n = $hi == 8 ? 'sbcd' : 'abcd'; return $my & 1 ? "$n -(a$ry),-(a$rx)" : "$n d$ry,d$rx"; }
    if ($hi == 0xC && ($op & 0x1F8) == 0x140) { return "exg d$rx,d$ry"; } if ($hi == 0xC && ($op & 0x1F8) == 0x148) { return "exg a$rx,a$ry"; }
    if ($hi == 0xC && ($op & 0x1F8) == 0x188) { return "exg d$rx,a$ry"; }
    my $s = $ox & 3; return ($ox & 4) ? "$nm$SZ[$s] d$rx," . ea($my, $ry, $s) : "$nm$SZ[$s] " . ea($my, $ry, $s) . ",d$rx"; }
  if ($hi == 9 || $hi == 0xD) { my $nm = $hi == 9 ? 'sub' : 'add';
    if (($ox & 3) == 3) { my $s = ($ox & 4) ? 2 : 1; return "${nm}a$SZ[$s] " . ea($my, $ry, $s) . ",a$rx"; }
    my $s = $ox & 3; if (($op & 0x130) == 0x100) { return $my & 1 ? "${nm}x$SZ[$s] -(a$ry),-(a$rx)" : "${nm}x$SZ[$s] d$ry,d$rx"; }
    return ($ox & 4) ? "$nm$SZ[$s] d$rx," . ea($my, $ry, $s) : "$nm$SZ[$s] " . ea($my, $ry, $s) . ",d$rx"; }
  if ($hi == 0xB) {
    if (($ox & 3) == 3) { my $s = ($ox & 4) ? 2 : 1; return "cmpa$SZ[$s] " . ea($my, $ry, $s) . ",a$rx"; }
    my $s = $ox & 3; if ($ox & 4) { return "cmpm$SZ[$s] (a$ry)+,(a$rx)+" if $my == 1; return "eor$SZ[$s] d$rx," . ea($my, $ry, $s); }
    return "cmp$SZ[$s] " . ea($my, $ry, $s) . ",d$rx"; }
  if ($hi == 0xE) { my @t = qw(as ls rox ro);
    if ($sz == 3) { my $k = ($op >> 9) & 3; return $t[$k] . (($op & 0x100) ? 'l' : 'r') . '.w ' . ea($my, $ry, 1); }
    my $k = ($op >> 3) & 3; my $dir = ($op & 0x100) ? 'l' : 'r'; my $cnt = ($op & 0x20) ? "d$rx" : '#' . ($rx || 8);
    return $t[$k] . $dir . $SZ[$sz] . " $cnt,d$ry"; }
  return sprintf('dc.w $%04X', $op);
}
$pc = hex $start; my $end = $cnt =~ /^\d+$/ && length($cnt) < 5 ? undef : hex $cnt; my $n = defined $end ? 1e9 : $cnt;
while ($n-- > 0) { last if defined $end && $pc >= $end; my $a = $pc; my $txt = eval { dis1() } // '???';
  my $raw = join ' ', map { sprintf '%04X', unpack('n', substr($D, $_, 2)) } grep { $_ < $pc } map { $a + 2 * $_ } 0 .. 4;
  printf "%06X  %-24s %s\n", $a, $raw, $txt; }
