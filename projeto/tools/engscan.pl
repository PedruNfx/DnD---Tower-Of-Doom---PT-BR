# list 0x14xx/0x2Cxx dialogue strings in a program image that look English
require "$ENV{T}/tbl.pl"; my %d = %Tbl::dec;
my $f = shift; open my $h, '<:raw', $f or die; local $/; my $p = <$h>; my @w = unpack('n*', $p);
my $re = qr/\b(the|you|your|and|of|is|are|have|has|this|that|with|will|for|to|it|not|can|from|was|we|my|me|be|what|there|here|please|go|get)\b/i;
my ($s, $st) = ('', undef);
for my $i (0 .. $#w) { my $x = $w[$i];
  if ($x == 0x4040) { if (defined $st && length $s >= 6) { my $n = () = $s =~ /$re/g; printf "%06X %s\n", 2 * $st, $s if $n >= 2 || ($n >= 1 && length $s < 30); } $s = ''; undef $st; next; }
  my $c = $x == 0x2F2F ? '/' : (($x >> 8) == 0x14 && exists $d{$x & 0xFF}) ? $d{$x & 0xFF} : undef;
  if (defined $c) { $st //= $i; $s .= $c; } else { $s = '' unless defined $st; $s .= '~' if defined $st; } }
