select 
	count(distinct(bbl)) filter (where p.name ~ any('{LLC,CORP,INC,BANK,ASSOC,TRUST}')) as corp_sales,
	count(distinct(bbl)) as total_sales,
	extract(year from docdate) as year,
	pl.zipcode
from real_property_parties p
inner join real_property_master m using(documentid)
inner join real_property_legals l using(documentid)
left join pluto_21v3 pl using(bbl)
left join (
	select ucbbl from rentstab full join rentstab_v2 using(ucbbl)
) rs on bbl = ucbbl
where doctype = 'DEED' 
and partytype = 2
and docdate >= '2003-01-01'
and docamount > 100
and p.name !~ any('{TRUSTEE,REFEREE,WILL AND TESTAMENT}')
and pl.unitsres > 2
and trim(pl.zipcode) is not null
group by year, zipcode