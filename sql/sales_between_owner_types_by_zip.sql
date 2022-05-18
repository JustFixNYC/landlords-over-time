with combined_deeds as (
	select 
		documentid,
		array_agg(l.bbl) as bbls,
		string_agg(p.name,', ') filter (where partytype = '1') as seller,
		string_agg(p.name,', ') filter (where partytype = '2') as buyer,
		max(docdate) as date 
	from real_property_parties p
	inner join real_property_master m using(documentid)
	inner join real_property_legals l using(documentid)
	left join pluto_21v3 pl using(bbl)
	where doctype = 'DEED'
	and docdate >= '2003-01-01'
	and docamount > 100
	and p.name !~ any('{TRUSTEE,REFEREE,WILL AND TESTAMENT}')
	and pl.unitsres >= 3
	group by documentid
),

res_buildings_by_zip as (
    select 
        zipcode,
        count(*) as res_bldgs
    from pluto_21v3
    where unitsres >= 3
    group by zipcode
)

select 
    extract(year from date) as year,
	pl.zipcode,
    count(distinct(bbl)) filter (
        where seller !~ any('{LLC,CORP,INC,BANK,ASSOC,TRUST}')
        and buyer ~ any('{LLC,CORP,INC,BANK,ASSOC,TRUST}')) 
    as person_to_corp_sales,
    first(res_bldgs) as res_bldgs
from (select *, unnest(bbls) as bbl from combined_deeds) t
left join pluto_21v3 pl using(bbl)
left join res_buildings_by_zip using (zipcode)
group by year, zipcode;