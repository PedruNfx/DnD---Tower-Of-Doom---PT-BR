# 3 coins, start, press START again during the ranking, coin during ranking; screenshots
use strict; use warnings; use FindBin; require "$FindBin::Bin/pad.pl";
Pad::idle(6.0); for (1 .. 3) { Pad::hold(0.15, 'SELECT'); Pad::idle(0.4); } Pad::idle(1.0); Pad::hold(0.2, 'START');
for my $i (1 .. 30) { Pad::idle(1.0); Pad::cmd('SCREENSHOT'); if ($i == 4) { Pad::hold(0.2, 'START'); } if ($i == 7) { Pad::hold(0.15, 'SELECT'); } }
Pad::hold(0.2, 'B'); Pad::idle(3.0); Pad::cmd('SCREENSHOT'); Pad::idle(5.0); Pad::cmd('SCREENSHOT');
