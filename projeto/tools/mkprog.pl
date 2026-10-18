# Build 68k program image from word-swapped CPS2 program ROMs
my ($romdir, $out) = @ARGV;
my @f = qw(dadu.03a dadu.04a dadu.05a dad.06 dad.07);
my $img = '';
for my $f (@f) { open my $h, '<:raw', "$romdir/$f" or die "$f: $!"; local $/; my $d = <$h>; $img .= $d; }
$img = pack('v*', unpack('n*', $img));  # swap bytes in each word
open my $o, '>:raw', $out or die; print $o $img; close $o;
print length($img), "\n";
