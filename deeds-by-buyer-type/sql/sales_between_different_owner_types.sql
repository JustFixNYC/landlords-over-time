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

seller_and_buyer as (
	select 
		case 
			when seller ~ any('{LLC,CORP,INC,BANK,ASSOC,TRUST}') then 'corp'
		else 'person' end as sellertype,
		case 
			when buyer ~ any('{LLC,CORP,INC,BANK,ASSOC,TRUST}') then 'corp'
		else 'person' end as buyertype,
		extract(year from date) as year,
		count(distinct bbl)
	from 
		(select *, unnest(bbls) as bbl from combined_deeds)
	group by sellertype, buyertype, year
)

select *
from seller_and_buyer 
where 
	(sellertype = 'corp' and buyertype = 'person') 
	OR (sellertype = 'person' and buyertype = 'corp');