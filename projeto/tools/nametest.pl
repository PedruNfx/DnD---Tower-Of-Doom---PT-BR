# coin, start, pick fighter, wait for the name entry, screenshot
use strict; use warnings; use FindBin; require "$FindBin::Bin/pad.pl";
Pad::idle(6.0); Pad::hold(0.3, 'SELECT'); Pad::idle(1.5); Pad::hold(0.2, 'START'); Pad::idle(2.5);
Pad::hold(0.2, 'B'); Pad::idle(9.0);
for (1 .. 3) { Pad::cmd('SCREENSHOT'); Pad::idle(2.0); }
