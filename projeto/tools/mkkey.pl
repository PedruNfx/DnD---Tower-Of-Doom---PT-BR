# Build a CPS2 .key file (inverse of MAME cps2_state::init_cps2crypt) and verify against known CRC32/SHA1
use Compress::Zlib qw(crc32); use Digest::SHA qw(sha1_hex);
my ($out, $k0, $k1, $upper, $w1, $w2, $w3, $crc, $sha) = @ARGV;
$_ = hex $_ for ($k0, $k1, $upper, $w1, $w2, $w3, $crc);
my $lo10 = (~((($upper - 1) & ~0x3fff) >> 14)) & 0x3ff;
for my $hi6 (0 .. 63) {
  my @d = ($k0 >> 16, $k0 & 0xffff, $k1 >> 16, $k1 & 0xffff, $w3, $w2, $w1, 0x4000, 0x0900, ($hi6 << 10) | $lo10);
  my @kd = (0) x 20;
  for my $b (0 .. 159) { my $bit = (317 - $b) % 160; if (($d[int($b / 16)] >> (15 - $b % 16)) & 1) { $kd[int($bit / 8)] |= 1 << (($bit ^ 7) % 8); } }
  my $data = pack('C20', @kd);
  if (crc32($data) == $crc && sha1_hex($data) eq lc $sha) { open my $o, '>:raw', $out or die; print $o $data; close $o; printf "match: d9=%04X crc=%08X sha1=%s\n", $d[9], crc32($data), sha1_hex($data); exit 0; }
}
die "no match\n";
