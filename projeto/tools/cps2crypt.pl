# Per-word CPS2 opcode encryption/decryption (port of MAME capcom/cps2crypt.cpp; S-boxes parsed from it).
# Crypt::init($cppfile, $key0, $key1); Crypt::dec($addr, $word); Crypt::enc($addr, $word)   ($addr = byte address)
package Crypt;
use strict; use warnings;
my (%ob, $g1A, $g1B, $g2A, $g2B, @e2, @es, @key1, @master, @sb1, @sb2, %k2cache);
sub BIT { ($_[0] >> $_[1]) & 1 }
sub nums { return [ map { int } grep { /\S/ } split /[,\s]+/, $_[0] ] }
sub init {
  my ($src, $k0, $k1) = @_; open my $sh, '<', $src or die; local $/; my $cpp = <$sh>; close $sh;
  while ($cpp =~ /const sbox (fn[12]_r[1-4]_boxes)\[4\] =\s*\{(.*?)\n\};/sg) { my ($name, $body) = ($1, $2); my @b;
    while ($body =~ /\{\s*\/\/[^\n]*\n\s*\{([^}]*)\},\s*\{([^}]*)\},\s*\{([^}]*)\}\s*\}/sg) { push @b, [nums($1), nums($2), nums($3)]; }
    $ob{$name} = [ map { my ($t, $in, $o) = @$_; my (@lk, @out);
      for my $v (0 .. 255) { my $r = 0; for my $i (0 .. 5) { $r |= BIT($v, $in->[$i]) << $i if $in->[$i] >= 0; } $lk[$v] = $r; }
      for my $i (0 .. 63) { my $x = $t->[$i]; my $m = 0; $m |= 1 << $o->[0] if $x & 1; $m |= 1 << $o->[1] if $x & 2; $out[$i] = $m; } [\@lk, \@out] } @b ]; }
  my $grab = sub { $cpp =~ /\Q$_[0]\E\[8\]\s*=\s*\{([^}]*)\}/s or die; nums($1) };
  ($g1A, $g1B, $g2A, $g2B) = map { $grab->($_) } qw(fn1_groupA fn1_groupB fn2_groupA fn2_groupB);
  my ($e1) = $cpp =~ /void expand_1st_key.*?bits\[96\]\s*=\s*\{([^}]*)\}/s; my @e1 = @{ nums($e1) };
  my ($e2) = $cpp =~ /void expand_2nd_key.*?bits\[96\]\s*=\s*\{([^}]*)\}/s; @e2 = @{ nums($e2) };
  my ($es) = $cpp =~ /void expand_subkey.*?bits\[64\]\s*=\s*\{([^}]*)\}/s; @es = @{ nums($es) };
  @master = ($k0, $k1); @key1 = expand(\@e1, \@master);
  $key1[0] ^= BIT($key1[0], 1) << 4; $key1[0] ^= BIT($key1[0], 2) << 5; $key1[0] ^= BIT($key1[0], 8) << 11;
  $key1[1] ^= BIT($key1[1], 0) << 5; $key1[1] ^= BIT($key1[1], 8) << 11; $key1[2] ^= BIT($key1[2], 1) << 5; $key1[2] ^= BIT($key1[2], 8) << 11;
  @sb1 = map { $ob{"fn1_r${_}_boxes"} } 1 .. 4; @sb2 = map { $ob{"fn2_r${_}_boxes"} } 1 .. 4;
}
sub expand { my ($bits, $src) = @_; my @d = (0, 0, 0, 0); for my $i (0 .. 95) { $d[int($i / 24)] |= BIT($src->[int($bits->[$i] / 32)], $bits->[$i] % 32) << ($i % 24); } return @d; }
sub fn { my ($in, $sb, $key) = @_; my $r = 0; for my $k (0 .. 3) { my ($lk, $o) = @{ $sb->[$k] }; $r |= $o->[ $lk->[$in] ^ (($key >> (6 * $k)) & 0x3f) ]; } return $r; }
sub split2 { my ($v, $A, $B) = @_; my ($l, $r) = (0, 0); for my $i (0 .. 7) { $l |= BIT($v, $B->[$i]) << $i; $r |= BIT($v, $A->[$i]) << $i; } return ($l, $r); }
sub join2 { my ($l, $r, $A, $B) = @_; my $v = 0; for my $i (0 .. 7) { $v |= BIT($l, $i) << $A->[$i]; $v |= BIT($r, $i) << $B->[$i]; } return $v; }
sub key2 { my $i = shift; return @{ $k2cache{$i} } if $k2cache{$i};
  my ($l, $r) = split2($i, $g1A, $g1B); $l ^= fn($r, $sb1[0], $key1[0]); $r ^= fn($l, $sb1[1], $key1[1]); $l ^= fn($r, $sb1[2], $key1[2]); $r ^= fn($l, $sb1[3], $key1[3]);
  my $seed = join2($l, $r, $g1A, $g1B);
  my @sub = (0, 0); for my $j (0 .. 63) { $sub[int($j / 32)] |= BIT($seed, $es[$j]) << ($j % 32); } $sub[0] ^= $master[0]; $sub[1] ^= $master[1];
  my @k = expand(\@e2, \@sub);
  $k[0] ^= BIT($k[0], 0) << 5; $k[0] ^= BIT($k[0], 6) << 11; $k[1] ^= BIT($k[1], 0) << 5; $k[1] ^= BIT($k[1], 1) << 4;
  $k[2] ^= BIT($k[2], 2) << 5; $k[2] ^= BIT($k[2], 3) << 4; $k[2] ^= BIT($k[2], 7) << 11; $k[3] ^= BIT($k[3], 1) << 5;
  $k2cache{$i} = \@k; return @k; }
sub dec { my ($addr, $v) = @_; my @k = key2(($addr >> 1) & 0xFFFF); my ($l, $r) = split2($v, $g2A, $g2B);
  $l ^= fn($r, $sb2[0], $k[0]); $r ^= fn($l, $sb2[1], $k[1]); $l ^= fn($r, $sb2[2], $k[2]); $r ^= fn($l, $sb2[3], $k[3]); return join2($l, $r, $g2A, $g2B); }
sub enc { my ($addr, $v) = @_; my @k = key2(($addr >> 1) & 0xFFFF);
  my ($l, $r) = (0, 0); for my $i (0 .. 7) { $l |= BIT($v, $g2A->[$i]) << $i; $r |= BIT($v, $g2B->[$i]) << $i; }   # inverse of the output join
  $r ^= fn($l, $sb2[3], $k[3]); $l ^= fn($r, $sb2[2], $k[2]); $r ^= fn($l, $sb2[1], $k[1]); $l ^= fn($r, $sb2[0], $k[0]);
  my $out = 0; for my $i (0 .. 7) { $out |= BIT($l, $i) << $g2B->[$i]; $out |= BIT($r, $i) << $g2A->[$i]; } return $out; }
1;
