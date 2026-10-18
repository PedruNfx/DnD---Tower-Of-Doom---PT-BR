# Dump strings referenced by a list of 32-bit pointers: ptrlist.pl prog.bin table_hex count hdrwords
require "$ENV{T}/tbl.pl"; my %pun=(0xA4=>" ",0xA5=>";",0xA6=>":",0xA7=>",",0xA8=>".",0xA9=>"'",0xAA=>"-",0xAB=>'"',0xAC=>'"',0xAD=>"&",0xAE=>"!",0xAF=>"?");
my ($f,$t,$n,$nh)=@ARGV; $t=hex $t; open H,"<:raw",$f; local $/; my $d=<H>;
for my $i (0..$n-1) { my $a=unpack("N",substr($d,$t+4*$i,4)); my @h=unpack("n$nh",substr($d,$a,2*$nh)); my $p=$a+2*$nh; my $s="";
  while(1){ my $w=unpack("n",substr($d,$p,2)); $p+=2; last if $w==0x4040 || $p>length $d; if($w==0x2F2F){$s.="/";next} my ($hi,$lo)=($w>>8,$w&255);
    $s.= ($hi==0x14 && exists $Tbl::dec{$lo}) ? $Tbl::dec{$lo} : ($hi==0x14 && exists $pun{$lo}) ? $pun{$lo} : sprintf("{%04X}",$w); }
  printf "%2d %06X [%s] %s\n",$i,$a,join(" ",map{sprintf"%04X",$_}@h),$s; }
