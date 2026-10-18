# Solve unknown decoded-word bits of a CPS2 key via CRC32 linearity (GF(2)), confirm with SHA1
use Compress::Zlib qw(crc32); use Digest::SHA qw(sha1_hex);
my $CRC = 0x7c03ec9e; my $SHA = '4fbcb1484dd5b8d569e54a96c81b3aa0faf37789';
sub enc { my @d = @_; my @kd = (0) x 20;
  for my $b (0 .. 159) { my $bit = (317 - $b) % 160; if (($d[int($b / 16)] >> (15 - $b % 16)) & 1) { $kd[int($bit / 8)] |= 1 << (($bit ^ 7) % 8); } }
  return pack('C20', @kd); }
my @base = (0xeca1, 0x9c3d, 0x2473, 0x6bf0, 0x4000, 0x1019, 0x0C78, 0x4000, 0x0900, 0x03a0);
for my $set (['d9+d8', [8, 9]], ['d9+d7', [7, 9]], ['d9+d4', [4, 9]], ['d9+d5', [5, 9]], ['d9+d6', [6, 9]], ['d7+d8', [7, 8]]) {
  my ($name, $words) = @$set; my @unk = map { my $w = $_; map { [$w, $_] } 0 .. 15 } @$words;
  my @b0 = @base; $b0[$_] = 0 for @$words; my $c0 = crc32(enc(@b0));
  my @vec; for my $u (@unk) { my @t = @b0; $t[$u->[0]] ^= 1 << $u->[1]; push @vec, crc32(enc(@t)) ^ $c0; }
  # gaussian elimination: find x with XOR of selected vec = target
  my $target = $c0 ^ $CRC; my @rows = map { [$vec[$_], 1 << $_] } 0 .. $#vec;  # [value, combo mask] (32 unknowns -> fits)
  my @piv; my %used;
  for my $bitpos (reverse 0 .. 31) { my ($r) = grep { !$used{$_} && (($rows[$_][0] >> $bitpos) & 1) } 0 .. $#rows; next unless defined $r; $used{$r} = 1; push @piv, [$bitpos, $r];
    for my $j (0 .. $#rows) { next if $j == $r; if (($rows[$j][0] >> $bitpos) & 1) { $rows[$j][0] ^= $rows[$r][0]; $rows[$j][1] ^= $rows[$r][1]; } } }
  my ($val, $mask) = ($target, 0);
  for my $p (@piv) { my ($bitpos, $r) = @$p; if (($val >> $bitpos) & 1) { $val ^= $rows[$r][0]; $mask ^= $rows[$r][1]; } }
  if ($val) { print "$name: no solution\n"; next; }
  my @null = map { $rows[$_][1] } grep { !$used{$_} } 0 .. $#rows;  # null space (combos with zero CRC effect)
  my $found = 0;
  for my $n (0 .. (1 << @null) - 1) { my $m = $mask; for my $i (0 .. $#null) { $m ^= $null[$i] if ($n >> $i) & 1; }
    my @t = @b0; for my $i (0 .. $#unk) { $t[$unk[$i][0]] ^= 1 << $unk[$i][1] if ($m >> $i) & 1; }
    my $data = enc(@t); if (sha1_hex($data) eq $SHA) { printf "%s: MATCH words=%s\n", $name, join(' ', map { sprintf '%04X', $_ } @t); open my $o, '>:raw', "$ARGV[0]" or die; print $o $data; close $o; $found = 1; last; } }
  print "$name: crc-solvable, sha1 mismatch (nullspace ", scalar(@null), ")\n" unless $found; last if $found;
}
