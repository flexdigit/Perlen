#!/usr/bin/perl -w

use strict;
use warnings;
use DBI;
use File::Copy;

# for development on Desktop
my $path2GasDB="/home/georg/Rasp-Pis/No1/GPIO/Gasmeter.db";

# for productiv run on Pi #1
#my $path2GasDB="/home/pi/GPIO/Gasmeter.db";

my @indexHtmArr;        # Array which contains the file index.htm
my @tstampArr;          # Array which contains the tstamp values from the DB
my @dayArr;             # Array which contains the days from DB
my @ticksArr;           # Array which contains the sum of ticks from DB
my $HlpString;          # Temporary scalar to save condent of index.htm
my $HlpTable;           # Temporary scalar for additional Gasmeter-table
my $LastEntry;          # Temporary scalar for last line in DB

my $dbh = DBI->connect(
                    "dbi:SQLite:dbname=$path2GasDB",
                    { RaiseError => 1 }
                ) or die $DBI::errstr;

# SQL-Query
my $sql_query = "SELECT tstamp,
    CASE CAST (strftime('%w', tstamp) as integer)
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
        WHEN 0 THEN 'Sunday'
        ELSE 'fehler' END,
    SUM(tick)
    FROM gascounter WHERE tstamp BETWEEN DATE('now', '-7 days') AND DATE('now')
    GROUP BY strftime('%w', tstamp)
    ORDER BY tstamp";

my $res = $dbh->selectall_arrayref($sql_query) or die $dbh->errstr();

foreach my $row (@$res)
{
    my ($tstamp, $day, $ticks) = @$row;
    push(@tstampArr, $tstamp);
    push(@dayArr, $day);
    push(@ticksArr, $ticks);
    #my @tmp = split (/ /, $tstamp);
    #printf("%-1s %-10s %-10s\n",$tmp[0], $day, $ticks);
}

# find out the last line/entry in the Gascounter-DB
my $sql_query_last_line = "SELECT max(tstamp) FROM gascounter";
$res = $dbh->selectall_arrayref($sql_query_last_line) or die $dbh->errstr();

foreach my $row (@$res)
{
    ($LastEntry) = @$row;
    #print $LastEntry."\n";
}


if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->disconnect();

######################################
#
# read index.htm into a array
#
# check if index.htm is already there, if so copy it to index_OLD.htm
# and generate next a new index.htm
my $index     = "/home/georg/Rasp-Pis/No1/temperature/index.htm";
my $index_OLD = "/home/georg/Rasp-Pis/No1/temperature/index_OLD.htm";
if(-e $index)
{
    print $index,"\nexist already, will be renamed to\n". $index_OLD."\n";
    copy($index, $index_OLD);
    # read file into array
    open (_IN_, "<", $index) or die "\n Can not open $index: $!\n";
    @indexHtmArr = <_IN_>;
    close (_IN_);
}
else
{
    print "\nindex.htm not available...\n\n";
}
######################################
#
# Put together new Gasmeter-table
#
$HlpTable  = "\nGasmeter\n<table border=2 frame=hsides rules=all>\n";
$HlpTable .= "<tr>\n";
$HlpTable .= "<th bgcolor=#0080FF>Date</th>
              <th bgcolor=#0080FF>Day</th>
              <th bgcolor=#0080FF>m&sup3;</th>";
$HlpTable .= "<\/tr>";
for my $i(0..$#tstampArr)   # @tstampArr, @dayArr and @ticksArr has the same number of indexs
{
    $HlpTable .= "<tr>\n";
    $HlpTable .= "<td>$tstampArr[$i]</td><td>$dayArr[$i]</td><td>$ticksArr[$i]</td>\n";
    $HlpTable .= "</tr>\n";
}
$HlpTable .= "</table>\n";

######################################
#
# Add new Gasmeter-table to already content of index.htm
#
for my $i(0..$#indexHtmArr)
{
    $HlpString .= $indexHtmArr[$i];
    
    if($indexHtmArr[$i] =~ /<\/table>/)
    {
        
        #print "FOUND: $indexHtmArr[$i]";
        $HlpString .= $HlpTable;
        last;
    }
}

######################################
#
# Add last entry, made into DB, into index.htm and add the end
# of an html page.
#
$HlpString .= "Last entry into DB:\n".$LastEntry;
$HlpString  .= "</body>\n";
$HlpString  .= "</html>\n";


######################################
#
# Print new index.htm
#
open (_IN_, ">", $index) or die "\n Can not generate $index: $!\n";
print _IN_ $HlpString;
close (_IN_);


