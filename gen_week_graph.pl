#!/usr/bin/perl -w
 
use warnings;
use strict;
use GD::Graph::bars;
use DBI;
use List::Util qw( min max sum );
use Time::Piece;                # For the date in the graph

##################################################
# for development on Desktop
#
#my $path2GasDB= "...";

##################################################
# for productiv run on Pi #1
#
my $path2GasDB= "/home/pi/GPIO/Gasmeter.db";

# open DB
my $dbh = DBI->connect(
                        "dbi:SQLite:dbname=$path2GasDB",
                        { RaiseError => 1 }
                      ) or die $DBI::errstr;

my $week_sql_query = "SELECT tstamp,
    CASE CAST (strftime('%w', tstamp) as integer)
        WHEN 1 THEN 'Mon'
        WHEN 2 THEN 'Tue'
        WHEN 3 THEN 'Wed'
        WHEN 4 THEN 'Thu'
        WHEN 5 THEN 'Fri'
        WHEN 6 THEN 'Sat'
        WHEN 0 THEN 'Sun'
        ELSE 'fehler' END,
    SUM(tick)
    FROM gascounter WHERE tstamp BETWEEN DATE('now', '-7 days') AND DATE('now')
    GROUP BY strftime('%w', tstamp)
    ORDER BY tstamp";

# request SQL query
my $res = $dbh->selectall_arrayref($week_sql_query) or die $dbh->errstr();

# Disconnect the DB
$dbh->disconnect();

my @dayArr;             # Array which contains the days from DB
my @ticksArr;           # Array which contains the sum of ticks from DB

# save what we got from SQL query
foreach my $row (@$res)
{
    my ($tstamp, $day, $ticks) = @$row;
    push(@dayArr, $day);
    push(@ticksArr, $ticks * 0.01);
    #printf("%-10s %-10s\n", $day, $ticks * 0.01);
}

my $WeeklySum = sum(@ticksArr);         # To get the weekly sum

my $maxYAxisValue = max @ticksArr;      # max value for the y axis

my $date = localtime->strftime('%V');

#my $graph = GD::Graph::area->new(1600, 600);
my $graph = GD::Graph::bars->new(500, 250);
$graph->set(
    x_label           => '[day]',
    y_label           => 'gas consumption [m^3]',
    #title             => 'Total gas consumption for CW '.$date.': '.$WeeklySum.' m^3',
    title             => 'Total gas consumption for last 7 days :'.$WeeklySum.' m^3',
    
    # shadows
    bar_spacing     => 10,
    shadow_depth    => 4,
    shadowclr       => 'dgreen',
    
    y_max_value       => $maxYAxisValue,
    #y_tick_number     => 4,
    #y_label_skip      => 2,
    #x_label_skip      => 5,
    long_ticks        => 1,
    
    accent_treshold => 200,
    transparent       => 0,
    
) or die $graph->error;
 
my @data = (\@dayArr,\@ticksArr);
$date = localtime->strftime('%Y');
$graph->set( dclrs => [ qw(green) ] );
$graph->set_legend_font('GD::gdMediumBoldFont');
$graph->set_legend('Gas consumption for one week - (C) '.$date.' flexdigit');

my $gd = $graph->plot(\@data) or die $graph->error;
 
#open(IMG, '>week_bars.png') or die $!;
open(IMG, '>/home/pi/temperature/week_bars.png') or die $!;
binmode IMG;
print IMG $gd->png;
