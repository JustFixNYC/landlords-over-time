library(tidyverse) # general data manipulation
library(ggthemes) # chart themes
library(dotenv) # get env variables
library(glue) # glue_sql()
library(DBI) # DB connection
library(janitor) # clean datasets
library(sf) # spatial data analysis
library(rmapshaper) # simplifying spatial geometries

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

# Set variables for universal colors
jf_pink = '#FFA0C7'
jf_green = '#1AA551'
jf_orange = '#FF813A'
jf_black = '#242323'
jf_white = '#FAF8F4'
jf_grey = '#C4C3C0'

# Set default theme for charts
jf_theme = theme(
  rect = element_rect(fill = jf_white),
  panel.grid.major.y = element_line(color = jf_grey, size = 0.2),
  panel.grid.major.x = element_blank(),
  legend.position="none",
  axis.title.x = element_blank(),
  axis.title.y = element_blank(),
  axis.ticks = element_blank(),
  axis.text = element_text(color = jf_black),
  panel.background = element_blank(),
  panel.border = element_blank(),
  panel.grid.minor = element_blank(),
  strip.background = element_blank(),
  strip.text = element_blank()
)

# Set default theme for maps
jf_map_theme = jf_theme + 
  theme(
    axis.text = element_blank(),
    panel.grid.major = element_blank()
  )

# Run custom SQL query in nydcb
data_nyc <- dbGetQuery(con, statement = read_file("sql/sales_by_buyer_type_and_housing_type.sql") , .con = con)

# Chart trends in building sales citywide 
ggplot(data_nyc, aes(
    fill=ptype,
    # Configure the housing type here:
    y=bldg_sales_3_plus_unit, 
    x=year)
  ) + 
  geom_bar(position=position_dodge(0.8), width=0.6, stat="identity") +
  scale_fill_discrete(name="Buyer Type",
                      breaks=c("corp", "person"),
                      labels=c("Corporation", "Person"),
                      type = c(jf_pink, jf_green)
                      ) +
  jf_theme

# Export graphic to SVG by running:
# ggsave("Graphics/all_nyc_trend.svg", device = "svg")
  
# Run custom SQL query in nydcb
change_of_owner_type <- dbGetQuery(con, statement = read_file("sql/sales_between_different_owner_types.sql") , .con = con)

# Chart trends in building sales where change of owner type occurred 
ggplot(change_of_owner_type, aes(
  color=buyertype,
  # Configure the housing type here:
  y=count, 
  x=year)
) + 
  geom_line() +
  expand_limits(y = 0) +
  scale_color_discrete(name="Buyer Type",
                      breaks=c("corp", "person"),
                      labels=c("Corporation", "Person"),
                      type = c(jf_pink, jf_green)
  ) +
  jf_theme

# Export graphic to SVG by running:
# ggsave("Graphics/all_nyc_change_of_owner_type.svg", device = "svg")

# Convert table to long format to look at specific building types
data_long <- data_nyc %>% 
  pivot_longer(
    starts_with("bldg"), 
    names_to = "bldg_type", 
    values_to = "sales"
  ) %>% 
  mutate(bldg_type = str_replace(bldg_type,"bldg_sales_","")) %>%
  filter(bldg_type %in% c("2_or_less_unit", "all_residential", "6_plus_unit"))

# Chart trends in building sales citywide for specific building types
ggplot(data_long, aes(fill=ptype, y=sales, x=year)) +
  # Grouped bar chart: 
  geom_bar(position=position_dodge(0.8), width=0.6, stat="identity") +
  facet_wrap(~ bldg_type, nrow = 3, scales = "free_y") +
  xlab("Year") +
  ylab("Annual Property Purchases") +
  scale_fill_discrete(name="Buyer Type",
                      breaks=c("corp", "person"),
                      labels=c("Corporation", "Person"),
                      type = c(jf_pink, jf_green)) +
  jf_theme

# Export graphic to SVG by running:
# ggsave("Graphics/trends_by_housing_type.svg", device = "svg", width=5, height=10)

### VISUALIZE SALES BY NEIGHBORHOOD OVER TIME: 

# Run custom SQL query in nycdb
data_neighborhood <- dbGetQuery(con, statement = read_file("sql/sales_by_neighborhood.sql") , .con = con)

# Convert table to long format to look at specific building types
data_neighborhood_long <- data_neighborhood %>% 
  pivot_longer(
    starts_with("bldg"), 
    names_to = "bldg_type", 
    values_to = "sales"
  ) %>% 
  mutate(bldg_type = str_replace(bldg_type,"bldg_sales_","")) %>%
  filter(bldg_type %in% c("2_or_less_unit", "all_residential", "6_plus_unit"))


# Chart trends in building sales citywide for specific neighborhoods
ggplot(data_neighborhood_long, aes(color=ptype, y=sales, x=year)) +
  geom_line(size = 1.5) +
  facet_wrap(neighborhood ~ bldg_type) +
  xlab("Year") +
  ylab("Annual Property Purchases") +
  scale_color_discrete(name="Buyer Type",
                      breaks=c("corp", "person"),
                      labels=c("Corporation", "Person"),
                      type = c(jf_pink, jf_green)) +
  jf_theme

# Export graphic to SVG by running:
# ggsave("Graphics/sales_by_neighborhood.svg", device = "svg")

### MAP SALES BY ZIPCODE OVER TIME:  

# Run custom SQL query in nycdb
data_by_zip <- dbGetQuery(con, statement = read_file("sql/sales_by_zip.sql") , .con = con)

# Load in spatial layer from shapefile
nyc_zips_shapefile <- read_sf("nyc_zips/nyc_zips.shp") %>% 
  rmapshaper::ms_simplify() %>%
  janitor::clean_names() %>% 
  st_transform(2263) %>%
  select(zipcode)

# Join spatial layer with sql data
data_by_zip_shapefile = nyc_zips_shapefile %>% 
  inner_join(data_by_zip, by = 'zipcode') %>%
  mutate(predom = ifelse(corp_sales > total_sales/2, "corp", "person"))

# Plot nyc map small multiples showing predominant type of buyer per zip code
ggplot(data_by_zip_shapefile, aes(fill = predom)) +
  geom_sf(color = jf_white, size = 0.05) +
  facet_wrap(~ year, nrow = 2) + 
  scale_fill_discrete(name="Predominant type of buyer:",
                      breaks=c("corp", "person"),
                      labels=c("Corporation", "Person"),
                      type = c(jf_pink, jf_green)) +
  jf_map_theme
  
# Export graphic to SVG by running:
# ggsave("Graphics/nyc_map_over_time.svg", device = "svg", width=10, height=5)

### COMPARE SALES BY ZIPCODE TO COVID EVICTION FILINGS:  

# Run custom SQL query in nycdb
evictions_by_zip <- dbGetQuery(con, statement = read_file("https://raw.githubusercontent.com/housing-data-coalition/rtc-eviction-viz/main/sql/filings-by-zip-since-0323.sql") , .con = con)

# Join spatial layer with sql data
evictions_by_zip_shapefile = nyc_zips_shapefile %>% 
  inner_join(evictions_by_zip, by = 'zipcode')

# Plot map of nyc eviction filings during COVID
ggplot(evictions_by_zip_shapefile, aes(fill = filingsrate_2plus)) +
  geom_sf(color = jf_grey, size = 0.05) +
  scale_fill_gradientn(
    colours = c(jf_white,jf_orange,jf_orange), 
    breaks = c(0,0.5,1),
    na.value = jf_grey
  ) +
  jf_map_theme

# Export graphic to SVG by running:
# ggsave("Graphics/nyc_eviction_filings_map.svg", device = "svg", width=8, height=8)

# Summarize sales data to look only at specific year range
data_by_zip_summarised <- data_by_zip %>%
  filter(year >= 2016 & year <= 2018) %>%
  group_by(zipcode) %>%
  summarise(corp_sales = sum(corp_sales), total_sales = sum(total_sales)) %>%
  mutate(pct_corp = corp_sales/total_sales)

# Join spatial layer with sql data
data_by_zip_summarised_shapefile = nyc_zips_shapefile %>% 
  inner_join(data_by_zip_summarised, by = 'zipcode')

# Plot map of percent corporate sales by zip 
ggplot(data_by_zip_summarised_shapefile, aes(fill = pct_corp)) +
  geom_sf(color = jf_grey, size = 0.05) +
  scale_fill_gradientn(
    colours = c(jf_white,jf_white,jf_pink), 
    breaks = c(0,0.7, 1), 
    na.value = jf_grey
  ) +
  jf_map_theme

# Export graphic to SVG by running:
# ggsave("Graphics/nyc_corporate_sales_map.svg", device = "svg", width=8, height=8)

### EXTRACT DATA TO VISUALIZE TIME LAPSE OF INDIVIDUAL SALES: 

# Run custom SQL query in nycdb
individual_sales_with_buyer_type <- dbGetQuery(con, statement = read_file("sql/individual_sales_for_map.sql") , .con = con)

# Export dataframe to CSV by running:
# write_csv(individual_sales_with_buyer_type, file = "individual_sales_with_buyer_type.csv", na = "")

