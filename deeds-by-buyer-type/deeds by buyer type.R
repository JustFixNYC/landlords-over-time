library(tidyverse) # general data manipulation
library(ggthemes) # chart themes
library(dotenv) # get env variables
library(glue) # glue_sql()
library(DBI) # DB connection

# Edit "Renviron.sample" to set variables and save as ".Renviron"
load_dot_env(".Renviron")

# Connection to NYCDB SQL database.
con <- dbConnect(
  drv = RPostgres::Postgres(),
  bigint="numeric",
  host = Sys.getenv("HDC_NYCDB_HOST"),
  user = Sys.getenv("HDC_NYCDB_USER"),
  password = Sys.getenv("HDC_NYCDB_PASSWORD"),
  port = Sys.getenv("HDC_NYCDB_PORT"),
  dbname = Sys.getenv("HDC_NYCDB_DBNAME")
)

# Use glue_sql() to insert our list of tracts into the WHERE statement: 
# "where geoid in ({rtu_tracts*})"

# Reformat tract geoid column in pluto, create a crosswalk between NYC
# boro-block and census tract because most other datasets don't have a tract
# column.

# Then for each data set aggregate by tract to get various indicators relevant
# to displacement risk, and finally join them all together by tract
data_nyc <- dbGetQuery(con, "
select 
	case 
		when p.name ~ any('{LLC,CORP,INC,BANK,ASSOC,TRUST}') then 'corp'
	else 'person' end as ptype,
	extract(year from docdate) as year,
	count(distinct(bbl)) filter(where pl.unitsres > 0) as bldg_sales_all_residential,
	count(distinct(bbl)) filter(where pl.unitsres > 1) as bldg_sales_2_plus_unit,
	count(distinct(bbl)) filter(where pl.unitsres > 2) as bldg_sales_3_plus_unit,
	count(distinct(bbl)) filter(where pl.unitsres > 3) as bldg_sales_4_plus_unit,
	count(distinct(bbl)) filter(where pl.unitsres > 5) as bldg_sales_6_plus_unit,
	count(distinct(bbl)) filter(where pl.unitsres <= 5) as bldg_sales_5_or_less_unit,
	count(distinct(bbl)) filter(where pl.unitsres < 3) as bldg_sales_2_or_less_unit,
	count(distinct(bbl)) filter(where pl.unitsres = 1) as bldg_sales_1_unit,
	count(distinct(bbl)) filter(where rs.ucbbl is not null) as bldg_sales_rent_stab
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
-- and pl.zipcode = any('{11238,11205}')
group by ptype, year;
", .con = con)


# Individual Chart
ggplot(data_nyc, aes(fill=ptype, y=bldg_sales_rent_stab, x=year)) + 
  geom_bar(position="dodge", stat="identity") +
  ggtitle(c("Who's been buying properties in NYC?")) +
  xlab("Year") +
  ylab("Annual Property Purchases") +
  scale_fill_discrete(name="Buyer Type",
                      breaks=c("corp", "person"),
                      labels=c("Corporation", "Person")) +
  theme_fivethirtyeight()

data_long <- data_ft_greene %>% 
  pivot_longer(
    starts_with("bldg"), 
    names_to = "bldg_type", 
    values_to = "sales"
  ) %>% 
  mutate(bldg_type = str_replace(bldg_type,"bldg_sales_",""))


# Facet Chart
ggplot(data_long, aes(fill=ptype, y=sales, x=year)) +
  # Grouped bar chart: 
  geom_bar(position="dodge", stat="identity") +
  # Proportional stacked bar chart: 
  # geom_bar(position="fill", stat="identity") +
  facet_wrap(~ bldg_type) +
  ggtitle(c("Who's been buying properties in NYC?")) +
  xlab("Year") +
  ylab("Annual Property Purchases") +
  scale_fill_discrete(name="Buyer Type",
                      breaks=c("corp", "person"),
                      labels=c("Corporation", "Person")) +
  theme_fivethirtyeight()


