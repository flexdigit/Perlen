#!/usr/bin/perl -w

use strict;
use warnings;
use DBI;

my $dbh = DBI->connect(
            "dbi:SQLite:dbname=Gasmeter.db",
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
    FROM gascounter WHERE tstamp BETWEEN DATE('now', '-20 days') AND DATE('now')
    GROUP BY strftime('%w', tstamp)
    ORDER BY tstamp";

#my ($name, $age) = "";
my $res = $dbh->selectall_arrayref($sql_query) or die $dbh->errstr();

foreach my $row (@$res) {
    my ($tstamp, $day, $ticks) = @$row;
    my @tmp = split (/ /, $tstamp);
    #print("$tmp[0] : $day : $ticks\n");
    printf("%-1s %-10s %-10s\n",$tmp[0], $day, $ticks);
}



#if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->disconnect();
