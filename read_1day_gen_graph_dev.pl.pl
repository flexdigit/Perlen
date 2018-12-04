#!/usr/bin/perl -w
 
use warnings;
use strict;
use GD::Graph::area;
use DBI;
use List::Util qw( min max );   # To find quick the max value of @gasArr
use Time::Piece;                # For the date in the graph

##################################################
# for productiv run on Pi #1
#
#my $path2GasDB= "/home/pi/GPIO/Gasmeter.db";

# open DB
my $dbh = DBI->connect(
                        "dbi:SQLite:dbname=$path2GasDB",
                        { RaiseError => 1 }
                      ) or die $DBI::errstr;

my $day_sql_query = "select tstamp, 
        case cast (strftime('%H', tstamp) as integer)
            when 00 then '0'
            when 01 then '1'
            when 02 then '2'
            when 03 then '3'
            when 04 then '4'
            when 05 then '5'
            when 06 then '6'
            when 07 then '7'
            when 08 then '8'
            when 09 then '9'
            when 10 then '10'
            when 11 then '11'
            when 12 then '12'
            when 13 then '13'
            when 14 then '14'
            when 15 then '15'
            when 16 then '16'
            when 17 then '17'
            when 18 then '18'
            when 19 then '19'
            when 20 then '20'
            when 21 then '21'
            when 22 then '22'
            when 23 then '23'
            when 24 then '24'
        else 'fehler' end,
        sum(tick) from gascounter where date(tstamp) = date('now', '-23 days')
        GROUP BY strftime('%H', tstamp)
        ORDER BY tstamp";

# request SQL query
my $res = $dbh->selectall_arrayref($day_sql_query) or die $dbh->errstr();

my @hourArr;
my @gasArr;

my %dayHash = ( 0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0,
                5 => 0, 6 => 0, 7 => 0, 8 => 0, 9 => 0,
               10 => 0,11 => 0,12 => 0,13 => 0,14 => 0,
               15 => 0,16 => 0,17 => 0,18 => 0,19 => 0,
               20 => 0,21 => 0,22 => 0,23 => 0,24 => 0,
              );

# fill day hour array for correct sequence during print with a hash
my @dayhourhArr = (0 .. 24);
# to get the content from hash for graph plot
my @GasValues;

# save what we got from SQL query
foreach my $row (@$res)
{
    my ($tstamp, $h_per_day, $gas_consume) = @$row;
    #push(@tstampArr, $tstamp);
    #push(@hourArr, $h_per_day);
    #push(@gasArr, $gas_consume * 0.01);
    $dayHash{$h_per_day} = $gas_consume * 0.01;
}

# print dayHash for tests and push into @GasValues for data for graph plot
for my $i(0..$#dayhourhArr)
{
    push (@GasValues, $dayHash{$dayhourhArr[$i]});
    #print "$dayhourhArr[$i]: $dayHash{$dayhourhArr[$i]}\n";
}

my $maxYAxisValue = max @gasArr;    # max value for the y axis
 
my $date = localtime->strftime('%a, %d.%m.%Y');

#my $graph = GD::Graph::area->new(1600, 600);
my $graph = GD::Graph::area->new(500, 250);
$graph->set(
    x_label           => '[h]',
    y_label           => 'gas consumption [m^3]',
    title             => 'Gas consumption on '.$date,
    y_max_value       => $maxYAxisValue,
    y_min_value       => 0.0,
    #y_tick_number     => 4,
    #y_label_skip      => 1,
    #x_label_skip      => 5,
    transparent       => 0,
    long_ticks        => 1,
) or die $graph->error;
 
#my @data = (\@hourArr,\@gasArr);
my @data = (\@dayhourhArr,\@GasValues);

$date = localtime->strftime('%Y');
$graph->set( dclrs => [ qw(green) ] );
$graph->set_legend_font('GD::gdMediumBoldFont');
$graph->set_legend('Gas consumption for one day - (C) '.$date.' flexdigit');

my $gd = $graph->plot(\@data) or die $graph->error;
 
open(IMG, '>gas_per_day.png') or die $!;
#open(IMG, '>/home/pi/temperature/gas_per_day.png') or die $!;
binmode IMG;
print IMG $gd->png;





