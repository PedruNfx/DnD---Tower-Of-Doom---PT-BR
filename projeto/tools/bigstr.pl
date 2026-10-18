# list strings in the big 16x16 scroll1 font (letter = code, code+1, code+0x10, code+0x11; bank 0x0400) ending in 0x4040
my $f = shift; open my $h, '<:raw', $f or die; local $/; my $d = <$h>; my @w = unpack('n*', $d);
my %ch; my @r = ('ABCDEFGH', 'IJKLMNOP', 'QRSTUVWX', 'YZ#.?!@_', '12345678', '90');
for my $i (0 .. $#r) { my @c = split //, $r[$i]; for my $j (0 .. $#c) { $ch{0x0400 + $i * 0x20 + 2 * $j} = $c[$j]; } } $ch{0x04AE} = ' ';
for (my $i = 0; $i < @w; $i++) { next unless exists $ch{$w[$i]}; my $j = $i; my $s = '';
  while ($j < @w && exists $ch{$w[$j]}) { $s .= $ch{$w[$j]}; $j++; }
  if ($j < @w && $w[$j] == 0x4040 && length($s) >= 3) { printf "%06X hdr=%04X %04X  '%s'\n", 2 * $i, $w[$i - 2], $w[$i - 1], $s; } $i = $j; }
