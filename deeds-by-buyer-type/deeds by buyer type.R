library(tidyverse) # general data manipulation
library(ggthemes) # chart themes
library(dotenv) # get env variables
library(glue) # glue_sql()
library(DBI) # DB connection
library(janitor) # clean datasets
library(sf) # spatial data analysis

### SETUP DB CONNECTION: 

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

### VISUALIZE SALES BY BUYER TYPE OVER TIME:  

# Run custom SQL query in nydcb
data_nyc <- dbGetQuery(con, statement = read_file("sql/sales_by_buyer_type_and_housing_type.sql") , .con = con)

# Map out Individual Chart
ggplot(data_nyc, aes(
    fill=ptype,
    # Configure the housing type here:
    y=bldg_sales_rent_stab, 
    x=year)
  ) + 
  geom_bar(position="dodge", stat="identity") +
  ggtitle(c("Who's been buying properties in NYC?")) +
  xlab("Year") +
  ylab("Annual Property Purchases") +
  scale_fill_discrete(name="Buyer Type",
                      breaks=c("corp", "person"),
                      labels=c("Corporation", "Person")) +
  theme_fivethirtyeight()

data_long <- data_nyc %>% 
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


### MAP SALES BY ZIPCODE OVER TIME:  

# Run custom SQL query in nycdb
data_by_zip <- dbGetQuery(con, statement = read_file("sql/sales_by_zip.sql") , .con = con)

# Load in spatial layer from shapefile
nyc_zips_shapefile <- read_sf("nyc_zips/nyc_zips.shp") %>% 
  janitor::clean_names() %>% 
  st_transform(2263) %>%
  select(zipcode)

# Join spatial layer with sql data
data_by_zip_shapefile = nyc_zips_shapefile %>% 
  inner_join(data_by_zip, by = 'zipcode') %>%
  mutate(predom = ifelse(corp_sales > total_sales/2, "corp", "person"))

# Plot nyc map small multiples
ggplot(data_by_zip_shapefile, aes(fill = predom)) +
  geom_sf(color = "white", size = 0.05) +
  facet_wrap(~ year, nrow = 2) + 
  ggtitle(c("Who's has been buying property in your neighborhood?"), 
          subtitle = "Trends in yearly property purchases, 4+ unit buildings"
  ) +
  scale_fill_discrete(name="Predominant type of buyer:",
                      breaks=c("corp", "person"),
                      labels=c("Corporation", "Person")) +
  theme_fivethirtyeight() +
  theme(axis.text.x = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks = element_blank(),
        panel.grid.major = element_blank(), 
        panel.grid.minor = element_blank()
  )

