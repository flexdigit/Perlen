select tstamp, 
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
sum(tick) * 0.01 FROM gascounter WHERE tstamp BETWEEN DATE('now', '-365 days') AND DATE('now')
GROUP BY strftime('%m', tstamp)
ORDER BY tstamp
