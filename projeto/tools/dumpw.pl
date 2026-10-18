# Dump a region as 16-bit words, decoding (attr,char) words inline
require "$ENV{T}/tbl.pl";
my ($file, $from, $len) = @ARGV; $from = hex $from; $len = hex $len;
open my $h, '<:raw', $file or die; local $/; my $d = <$h>;
my @w = unpack('n*', substr($d, $from, $len));
my $out = sprintf("%06X: ", $from); my $col = 0;
for my $i (0 .. $#w) {
  my ($hi, $lo) = ($w[$i] >> 8, $w[$i] & 0xFF);
  if ($w[$i] == 0x2F2F) { $out .= '/'; }
  elsif ($w[$i] == 0x4040) { $out .= sprintf("@\n%06X: ", $from + ($i+1)*2); }
  elsif ($hi > 0 && $hi < 0x40 && $hi != 0x2F && exists $Tbl::dec{$lo}) { $out .= ($hi == 0x14 ? '' : sprintf('<a%02X>', $hi)) . $Tbl::dec{$lo}; }
  elsif ($hi > 0 && $hi < 0x40 && $hi != 0x2F) { $out .= sprintf('{%02X%s}', $lo, $hi == 0x14 ? '' : sprintf(':a%02X', $hi)); }
  else { $out .= sprintf('[%04X]', $w[$i]); }
}
print "$out\n";
