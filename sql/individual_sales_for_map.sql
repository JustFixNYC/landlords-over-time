select 
    case 
        when p.name ~ any('{LLC,CORP,INC,BANK,ASSOC,TRUST}') then 'corp'
    else 'person' end as ptype,
    docdate::timestamp,
    unitsres,
    latitude,
    longitude
from real_property_parties p
inner join real_property_master m using(documentid)
inner join real_property_legals l using(documentid)
left join pluto_21v3 pl using(bbl)
where doctype = 'DEED' 
and partytype = 2
and docdate >= '2003-01-01'
and docamount > 100
and p.name !~ any('{TRUSTEE,REFEREE,WILL AND TESTAMENT}')
and pl.unitsres > 0
and pl.latitude is not null and pl.longitude is not null;