select 
    sum(unitsres) as total_registered_units,
    sum(unitsres) filter (where corpowners > 0) as corp_owned_units,
    sum(unitsres) filter (where corpowners > 0) / sum(unitsres)::numeric as percent_corp
from pluto_21v3
inner join (
    select
        bbl,
        count(*) filter (where type = 'CorporateOwner' and corporationname is not null) as corpowners
    from hpd_registrations
    left join hpd_contacts using (registrationid)
    group by bbl
) h using(bbl);
