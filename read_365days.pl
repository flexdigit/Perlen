#!/usr/bin/perl -w
 
use warnings;
use strict;
use DBI;

#####################################################################
# 
# reads from Gasmeter.db monthly gas consumption and generated into
# index.htm a table.
# 
#####################################################################

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

my $sql_query = "select tstamp, 
                    case cast (strftime('%m', tstamp) as integer)
                        when 01 then 'Jan'
                        when 02 then 'Feb'
                        when 03 then 'Mar'
                        when 04 then 'Apr'
                        when 05 then 'May'
                        when 06 then 'June'
                        when 07 then 'July'
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
my $res = $dbh->selectall_arrayref($sql_query) or die $dbh->errstr();

#my @tstampArr;
my @hourArr;
my @gasArr;
# save what we got from SQL query
foreach my $row (@$res)
{
    my ($tstamp, $month, $gas_consume) = @$row;
    #push(@tstampArr, $tstamp);
    push(@hourArr, $month);
    push(@gasArr, $gas_consume * 0.01);
    #my @tmp = split (/ /, $tstamp);
    printf("%-1s %-10s %-10s\n",$tstamp, $month, $gas_consume);
}



