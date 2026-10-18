# Find an ASCII phrase encoded in the 16-bit dialogue font format
require "$ENV{T}/tbl.pl"; my %enc = reverse %Tbl::dec;
my ($file, @phr) = @ARGV; open my $h, '<:raw', $file or die; local $/; my $d = <$h>;
for my $p (@phr) { my $pat = join '', map { pack('n', 0x1400 | ($enc{$_} // die "no enc for $_")) } split //, $p;
  my $pos = 0; while (($pos = index($d, $pat, $pos)) >= 0) { printf "%-30s %06X\n", $p, $pos if $pos % 2 == 0; $pos++; } }
