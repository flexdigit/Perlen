#!/usr/bin/perl -w
#####################################################################
# 
# Script adds some values and a weektable to the index.htm
# 
#####################################################################
use strict;
use warnings;
use DBI;
use File::Copy;

##################################################
# for development on Desktop
#
#my $path2GasDB= "/home/georg/Rasp-Pis/No1/GPIO/Gasmeter.db";
#my $index     = "/home/georg/Rasp-Pis/No1/temperature/index.htm";
#my $index_OLD = "/home/georg/Rasp-Pis/No1/temperature/index_OLD.htm";

##################################################
# for productiv run on Pi #1
#
my $path2GasDB= "/home/pi/GPIO/Gasmeter.db";
my $index     = "/home/pi/temperature/index.htm";
my $index_OLD = "/home/pi/temperature/index_OLD.htm";

my @indexHtmArr;        # Array which contains the file index.htm
my @tstampArr;          # Array which contains the tstamp values from the DB
my @dayArr;             # Array which contains the days from DB
my @ticksArr;           # Array which contains the sum of ticks from DB
my $HlpString;          # Temporary scalar to save condent of index.htm
my $HlpTable;           # Temporary scalar for additional Gasmeter-table
my $LastEntry  = 0;     # Temporary scalar for last line in DB
my $StartValue = 9025.709;         # Start value for calculating the actual Gas meter value
my $TotalValue;         # Total Gasmeter value

######################################
#
# read index.htm into a array
#
# check if index.htm is already there, if so copy it
# to index_OLD.htm and generate next a new index.htm
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

# open DB
my $dbh = DBI->connect(
                    "dbi:SQLite:dbname=$path2GasDB",
                    { RaiseError => 1 }
                ) or die $DBI::errstr;

######################################
#
# fetch info for weekoverview                
#
my $week_sql_query = "SELECT tstamp,
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

# request SQL query
my $res = $dbh->selectall_arrayref($week_sql_query) or die $dbh->errstr();

# save what we got from SQL query
foreach my $row (@$res)
{
    my ($tstamp, $day, $ticks) = @$row;
    push(@tstampArr, $tstamp);
    push(@dayArr, $day);
    push(@ticksArr, $ticks * 0.01);
    #my @tmp = split (/ /, $tstamp);
    #printf("%-1s %-10s %-10s\n",$tmp[0], $day, $ticks);
}

######################################
#
# fetch info for year overview
#
my $year_sql_query = "select tstamp, 
                    case cast (strftime('%m', tstamp) as integer)
                        when 01 then 'Jan'
                        when 02 then 'Feb'
                        when 03 then 'Mar'
                        when 04 then 'Apr'
                        when 05 then 'May'
                        when 06 then 'Jun'
                        when 07 then 'Jul'
                        when 08 then 'Aug'
                        when 09 then 'Sep'
                        when 10 then 'Oct'
                        when 11 then 'Nov'
                        when 12 then 'Dez'
                        else 'fehler' end,
                    sum(tick) FROM gascounter
                    WHERE tstamp BETWEEN DATE('now', '-365 days') AND DATE('now')
                    GROUP BY strftime('%m', tstamp)
                    ORDER BY tstamp";

# request SQL query
$res = $dbh->selectall_arrayref($year_sql_query) or die $dbh->errstr();

# fill hash per default
my %yearHash = (
    Jan  => 0,
    Feb  => 0,
    Mar  => 0,
    Apr  => 0,
    May  => 0,
    Jun  => 0,
    Jul  => 0,
    Aug  => 0,
    Sep  => 0,
    Oct  => 0,
    Nov  => 0,
    Dez  => 0,
);

# fill month array for correct sequence during print with a hash
my @monthArr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dez);

# save what we got from SQL query
foreach my $row (@$res)
{
    my ($tstamp, $month, $gas_consume) = @$row;
    $yearHash{$month} = $gas_consume * 0.01;
}

# print yearHash for tests
for my $i(0..$#monthArr)
{
    #print "$monthArr[$i]: $yearHash{$monthArr[$i]}\n";
}
######################################
#
# find out the last line/entry in the Gascounter-DB
my $sql_query_last_line = "SELECT max(tstamp) FROM gascounter";

# request SQL query
$res = $dbh->selectall_arrayref($sql_query_last_line) or die $dbh->errstr();

# save what we got from SQL query
foreach my $row (@$res)
{
    ($LastEntry) = @$row;
    #print $LastEntry."\n";
}

######################################
#
# Start to build "master" table with one row and two columns
#
$HlpTable  = "\n<table>\n";             # start master table
$HlpTable .= "<tr valign=\"top\">\n";   # start the only row
$HlpTable .= "<td>\n";                  # start first column

######################################
#
# Build together new Gasmeter table (week overview)
#
$HlpTable .= "\n<table border=2 frame=hsides rules=all>\n";
$HlpTable .= "<caption><bold>Gasmeter/week</bold></caption>\n";
$HlpTable .= "<tr>\n";
$HlpTable .= "<th bgcolor=#d2b48c>Date</th>\n";
$HlpTable .= "<th bgcolor=#d2b48c>Day</th>\n";
$HlpTable .= "<th bgcolor=#d2b48c>m&sup3;</th>\n";
$HlpTable .= "</tr>\n";

for my $i(0..$#tstampArr)   # @tstampArr, @dayArr and @ticksArr has the same number of indexs
{
    $HlpTable .= "<tr>\n";
    $HlpTable .= "<td>$tstampArr[$i]</td><td>$dayArr[$i]</td><td>$ticksArr[$i]</td>\n";
    $HlpTable .= "</tr>\n";
}
$HlpTable .= "</table>\n";  # end week overview table
$HlpTable .= "</td>\n";     # end first column

#$HlpTable .= "\n";
$HlpTable .= "<td>\n";      # start secound column

######################################
#
# Build together new year overview
#
$HlpTable .= "\n<table border=2 frame=hsides rules=all>\n";
$HlpTable .= "<caption><bold>Gasmeter/year</bold></caption>\n";
$HlpTable .= "<tr>\n";
$HlpTable .= "<th bgcolor=#d2b48c>Month</th>\n";
$HlpTable .= "<th bgcolor=#d2b48c>m&sup3;</th>\n";
$HlpTable .= "</tr>\n";

for my $i(0..$#monthArr)
{
    $HlpTable .= "<tr>\n";
    $HlpTable .= "<td>$monthArr[$i]</td><td>$yearHash{$monthArr[$i]}</td>\n";
    $HlpTable .= "</tr>\n";
}

$HlpTable .= "</table>\n";  # end year overview table

$HlpTable .= "</td>\n";     # end secound column

$HlpTable .= "</tr>\n";     # end the only row
$HlpTable .= "</table>\n";  # end master table

######################################
# week overview:
# Add new Gasmeter table (week overview) to content
# of index.htm
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
# Add total value of Gasmeter into index.htm
#
my $sql_query_all_ticks = "SELECT sum(tick) FROM gascounter";

# request SQL query
$res = $dbh->selectall_arrayref($sql_query_all_ticks) or die $dbh->errstr();

# save what we got from SQL query
my $hlpval = 0;
foreach my $row (@$res)
{
    ($hlpval) = @$row;
    #print $hlpval."\n";
}
#print $hlpval."\n";

# round on 3 decimal places
$TotalValue = sprintf("%.3f", ($StartValue + $hlpval * 0.01) );

$HlpString .= "\nTotal value:\t\t$TotalValue m&sup3;\n\n";

######################################
#
# Add last entry, made into DB, into index.htm and add the end
# of an html page.
#
$HlpString .= "Last entry into DB:\t".$LastEntry;

######################################
#
# Add daily graph
#
$HlpString .= "\n\n    <img src=\"day_graph.png\">\n\n";

######################################
#
# Add end of html page
#
$HlpString .= "</body>\n";
$HlpString .= "</html>\n";

######################################
#
# Print new index.htm
#
open (_IN_, ">", $index) or die "\n Can not generate $index: $!\n";
print _IN_ $HlpString;
close (_IN_);

# close DB connection
#if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->disconnect();


