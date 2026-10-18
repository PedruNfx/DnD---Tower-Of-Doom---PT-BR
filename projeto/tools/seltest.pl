# coin -> title "press start" shots -> start -> select screen shots -> pick fighter -> inn/HUD shots
use strict; use warnings; use FindBin; require "$FindBin::Bin/pad.pl";
Pad::idle(6.0); Pad::hold(0.3, 'SELECT'); Pad::idle(1.5);
for (1 .. 2) { Pad::cmd('SCREENSHOT'); Pad::idle(1.1); }
Pad::hold(0.2, 'START'); Pad::idle(2.5);
for (1 .. 2) { Pad::cmd('SCREENSHOT'); Pad::idle(1.1); }
Pad::hold(0.2, 'B'); Pad::idle(3.0);
for (1 .. 2) { Pad::cmd('SCREENSHOT'); Pad::idle(1.1); }
