#!/usr/bin/perl -w
 
use warnings;
use strict;
use GD::Graph::bars;
use DBI;
use List::Util qw( min max );
use Time::Piece;                # For the date in the graph

##################################################
# for development on Desktop
#
#my $path2GasDB= "/home/georg/Rasp-Pis/No1/GPIO/Gasmeter.db";

##################################################
# for productiv run on Pi #1
#
my $path2GasDB= "/home/pi/GPIO/Gasmeter.db";

# open DB
my $dbh = DBI->connect(
                        "dbi:SQLite:dbname=$path2GasDB",
                        { RaiseError => 1 }
                      ) or die $DBI::errstr;

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
my $res = $dbh->selectall_arrayref($year_sql_query) or die $dbh->errstr();

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

my @GasValues;      # to get the content from hash for graph plot

# save what we got from SQL query
foreach my $row (@$res)
{
    my ($tstamp, $month, $gas_consume) = @$row;
    $yearHash{$month} = $gas_consume * 0.01;
}

# print yearHash for tests and push into @GasValues for data for graph plot
for my $i(0..$#monthArr)
{
    #print "$monthArr[$i]: $yearHash{$monthArr[$i]}\n";
    push (@GasValues, $yearHash{$monthArr[$i]});
}

#my $maxYAxisValue = max @gasArr;    # max value for the y axis
my $maxYAxisValue = max values (%yearHash);     # max value for the y axis from a hash

#exit;
 
my $date = localtime->strftime('%Y');

#my $graph = GD::Graph::bars->new(1600, 600);
my $graph = GD::Graph::bars->new(500, 250);
$graph->set(
    x_label         => '[month]',
    y_label         => 'gas consumption [m^3]',
    title           => 'Gas consumption for year '.$date,
    
    # shadows
    bar_spacing     => 10,
    shadow_depth    => 4,
    shadowclr       => 'dgreen',
    
    y_max_value     => $maxYAxisValue,
    #y_tick_number     => 4,
    #y_label_skip      => 2,
    #x_label_skip      => 5,
    long_ticks      => 1,
    
    accent_treshold => 200,
    transparent     => 0,

) or die $graph->error;
 
my @data = (\@monthArr,\@GasValues);

$graph->set( dclrs => [ qw(green) ] );
$graph->set_legend_font('GD::gdMediumBoldFont');
$graph->set_legend('Gas consumption for one week - (C) '.$date.' flexdigit');

my $gd = $graph->plot(\@data) or die $graph->error;
 
#open(IMG, '>year_bars.png') or die $!;
open(IMG, '>/home/pi/temperature/year_bars.png') or die $!;
binmode IMG;
print IMG $gd->png;

