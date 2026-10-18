# Find 8x8 half-tiles in gfx whose pixel pattern equals a reference glyph (up to pen renaming)
my ($gfx, @codes) = @ARGV; open my $h, '<:raw', $gfx or die; local $/; my $g = <$h>; my $n = length($g) / 64;
sub half { my ($u, $hf) = @_; my @p; for my $y (0..7) { my @b = unpack('C4', substr($g, $u*64 + $y*8 + 4*$hf, 4)); for my $x (0..7) { my $bit = 7-$x; push @p, ((($b[3]>>$bit)&1)<<3)|((($b[2]>>$bit)&1)<<2)|((($b[1]>>$bit)&1)<<1)|(($b[0]>>$bit)&1); } } return @p; }
sub canon { my %m; my $k = 0; return join ',', map { $_ == 15 ? 'T' : ($m{$_} //= $k++) } @_; }
for my $c (@codes) { my $ref = canon(half(0x20000 + hex($c), 0)); my @hits;
  for my $u (0 .. $n - 1) { for my $hf (0, 1) { next unless (my $s = canon(half($u, $hf))) eq $ref; push @hits, sprintf('%05X%s', $u, $hf ? 'R' : 'L'); } last if @hits > 40; }
  print "$c: ", join(' ', @hits), "\n"; }
