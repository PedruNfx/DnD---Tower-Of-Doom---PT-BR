# coin, start, then screenshots every second; pick a character near the end
use strict; use warnings; use FindBin; require "$FindBin::Bin/pad.pl";
my $n = shift // 26;
Pad::idle(6.0); Pad::hold(0.3, 'SELECT'); Pad::idle(1.5); Pad::hold(0.2, 'START');
for my $i (1 .. $n) { Pad::idle(1.0); Pad::cmd('SCREENSHOT'); }
Pad::hold(0.2, 'B'); Pad::idle(3.0); Pad::cmd('SCREENSHOT'); Pad::idle(4.0); Pad::cmd('SCREENSHOT');
