#!/usr/bin/perl
#
#
$unit_num=$ARGV[0];
$state_num=$ARGV[1];
$outfile=$ARGV[2];

$total_num=$unit_num*$state_num;

open(MAP,">$outfile") || die "Can't write to file $outfile";

print MAP "sil 0\n";

$index=1;
for ($i=1;$i<=$unit_num;++$i)
{
	for ($j=1;$j<=$state_num;++$j)
	{
	    print MAP "a${i}_${j} $index\n";
            $index++;
        }
}

close MAP;
