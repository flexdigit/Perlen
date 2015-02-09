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
    FROM gascounter WHERE tstamp BETWEEN DATE('now', '-7 days') AND DATE('now')
    GROUP BY strftime('%w', tstamp)
    ORDER BY tstamp";

#my ($name, $age) = "";
my $res = $dbh->selectall_arrayref($sql_query) or die $dbh->errstr();

foreach my $row (@$res) {
    my ($tstamp, $day, $ticks) = @$row;
    #print("$tstamp : $day : $ticks\n");
    print("$day : $ticks\n");
}

# SQL-query for last entry in table gascounter
$sql_query = "SELECT max(tstamp) FROM gascounter";
$res = $dbh->selectall_arrayref($sql_query) or die $dbh->errstr();

foreach my $row (@$res) {
    my ($last_entry) = @$row;
    print("Last entry in DB: $last_entry\n");
}


#if ($dbh->err()) { die "$DBI::errstr\n"; }
$dbh->disconnect();

