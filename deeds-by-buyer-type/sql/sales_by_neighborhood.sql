select 
	case 
		when p.name ~ any('{LLC,CORP,INC,BANK,ASSOC,TRUST}') then 'corp'
	else 'person' end as ptype,
	case
		when pl.zipcode = any('{10468,10458}') then 'fordham'
	else 'prospect' end as neighborhood,
	extract(year from docdate) as year,
	count(distinct(bbl)) as bldg_sales_all_residential,
	count(distinct(bbl)) filter(where pl.unitsres > 5) as bldg_sales_6_plus_unit,
	count(distinct(bbl)) filter(where pl.unitsres < 3) as bldg_sales_2_or_less_unit
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
and pl.zipcode = any('{11238,11205,10468,10458}')
and pl.unitsres > 0
group by ptype, year, neighborhood;