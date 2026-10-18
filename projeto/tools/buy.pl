# load the shop state, move the cursor to the last item and buy it; screenshots along the way
use strict; use warnings; use FindBin; require "$FindBin::Bin/pad.pl";
Pad::idle(2.0); Pad::cmd('LOAD_STATE'); Pad::idle(1.5);
for (1 .. 4) { Pad::hold(0.12, 'RIGHT'); Pad::idle(0.4); }
Pad::cmd('SCREENSHOT'); Pad::idle(0.5);
Pad::hold(0.12, 'B'); Pad::idle(1.5); Pad::cmd('SCREENSHOT'); Pad::idle(0.5);
Pad::hold(0.12, 'B'); Pad::idle(1.5); Pad::cmd('SCREENSHOT'); Pad::idle(0.5);
Pad::hold(0.12, 'B'); Pad::idle(1.5); Pad::cmd('SCREENSHOT'); Pad::idle(0.5);
