# title (after coin) state, then select-screen state
use strict; use warnings; use FindBin; use File::Copy; use Time::HiRes qw(usleep); require "$FindBin::Bin/pad.pl";
my ($sf, $dir) = @ARGV; mkdir $dir;
Pad::idle(6.0); Pad::hold(0.3, 'SELECT'); Pad::idle(1.5);
Pad::cmd('SAVE_STATE'); Pad::idle(0.5); copy($sf, "$dir/title.state");
Pad::hold(0.2, 'START'); Pad::idle(0.4); Pad::cmd('SAVE_STATE'); Pad::idle(0.5); copy($sf, "$dir/start.state");
Pad::idle(2.0); Pad::cmd('SAVE_STATE'); Pad::idle(0.5); copy($sf, "$dir/select.state");
