my ($file, $min) = @ARGV; $min ||= 6;
open my $h, '<:raw', $file or die; local $/; my $d = <$h>;
while ($d =~ /([\x20-\x7e]{$min,})/g) { printf "%06X: %s\n", pos($d) - length($1), $1; }
