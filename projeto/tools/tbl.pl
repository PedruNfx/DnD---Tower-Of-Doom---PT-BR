package Tbl;
our %dec;
my @rows = ([0x40, 'ABCDEFGHIJKLMNOP'], [0x60, 'QRSTUVWXYZabcdef'], [0x80, 'ghijklmnopqrstuv'], [0xA0, 'wxyz ']);
for my $r (@rows) { my ($b, $s) = @$r; my $i = 0; $dec{$b + $i++} = $_ for split //, $s; }
1;
