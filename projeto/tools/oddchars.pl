# For words embedded between text characters, count unknown codes with context
require "$ENV{T}/tbl.pl";
my ($file) = @ARGV;
open my $h, '<:raw', $file or die; local $/; my $d = <$h>;
my @w = unpack('n*', $d);
sub ch { my $x = shift; return '/' if $x == 0x2F2F; return $Tbl::dec{$x & 0xFF} if ($x >> 8) == 0x14 && exists $Tbl::dec{$x & 0xFF}; return undef }
my (%cnt, %ctx);
for my $i (3 .. $#w - 3) {
  next if defined ch($w[$i]) || $w[$i] == 0x4040;
  my $l = join '', map { ch($w[$_]) // '' } $i-3 .. $i-1;
  my $r = join '', map { ch($w[$_]) // '' } $i+1 .. $i+3;
  next unless length($l) == 3 && length($r) >= 2 && "$l$r" =~ /[a-z]/;
  my $k = sprintf '%04X', $w[$i]; $cnt{$k}++; push @{$ctx{$k}}, "$l*$r" if @{$ctx{$k} || []} < 6;
}
for my $k (sort keys %cnt) { printf "%s x%-4d %s\n", $k, $cnt{$k}, join(' | ', @{$ctx{$k}}); }
