library(tidyverse)
library(readxl)
library(googlesheets4)
library(janitor)
library(glue)
library(tidygeocoder)
library(leaflet)
# Set working directory
"/Users/rashaelnimeiry/Library/Mobile Documents/com~apple~CloudDocs/geotruth"-> working 

# Read the link to survey from the Excel file
read_xlsx(glue('{working}/keys/tokens.xlsx')) %>% 
  filter(Program == 'supportsudanform') %>%
  pull(key) -> surveyform 

# Read the link to survey responses from the Excel file
read_xlsx(glue('{working}/keys/tokens.xlsx')) %>% 
  filter(Program == 'supportsudanresponses') %>%
  pull(key)-> surveyresponsesurl 

# Google API
read_xlsx(glue('{working}/keys/tokens.xlsx')) %>% 
  filter(Program == 'googlegeocode') %>%
  pull(key)-> googleapi 

# Authenticate with Google Sheets
# gs4_auth()  # Uncomment if you need to authenticate

# Read the Google Sheet
read_sheet(surveyresponsesurl) %>% 
  # as.data.frame() %>% 
  janitor::clean_names() %>% 
  mutate(response_id = row_number())->responsesall
2
# saveRDS(geocoded_responses %>% head(2), 'responses.RDS')
# read_rds("~/Library/Mobile Documents/com~apple~CloudDocs/geotruth/geotruthwebsite/geotruth.github.io/projects/supportsudanownedbusinesses/myapp/responses.RDS") %>% 
read_rds("responses.RDS") %>% 
  select(response_id, everything())->responsesold


# find which are new to geocode -------------------------------------------



responsesall %>%
  filter(timestamp >"2024-11-19") %>% 
  filter(!(response_id %in% responsesold$response_id))->newresponsestogeocode
# newresponsestogeocode %>% 
#   ->responsesall

if(nrow(newresponsestogeocode)==0){
  responsesold->responsesall; 
  print("no new businesses to add")
  } else if (nrow(newresponsestogeocode)>0){
newresponsestogeocode %>%
      mutate(
        postal_code = as.character(postal_code),  # Ensure it's a character vector
        postal_code = case_when(
          postal_code == "NULL" ~ "",    # Replace "NULL" string with "0"
          TRUE ~ postal_code              # Keep existing values for others
        ),
        inputgeocodeaddress = case_when(
      is.na(complete_physical_address_of_business_project)  ~ 
        glue("{city_location_of_business_project}, {state_region_location_of_business_project}, {country_of_business_project}, {postal_code}"),
      nchar(complete_physical_address_of_business_project) < 10  ~ 
        glue("{city_location_of_business_project}, {state_region_location_of_business_project}, {country_of_business_project}"),
      TRUE ~ complete_physical_address_of_business_project
    )
  ) %>% 
      # filter(!(geocoded %in% "yes")) %>% 

  tidygeocoder::geocode(
    address = inputgeocodeaddress,
    method = 'arcgis', lat = latitude, 
    long = longitude,
    return_addresses = TRUE,
    # address = complete_physical_address_of_business_project,
    # city = city_location_of_business_project, 
    # state = state_region_location_of_business_project,
    # country = country_of_business_project,postalcode = postal_code
    # api_key =googleapi 
    ) %>% 
      mutate(geocoded= "yes")->geocoded_responses



    geocoded_responses %>%
      rbind(responsesold) %>%
      distinct(response_id, .keep_all = T) %>%  # Remove duplicates based on response_id
      group_by(latitude, longitude) %>%        # Group by latitude and longitude
      rowwise() %>%                            # Apply operations row-by-row
      mutate(
        # Apply jitter to lat/lon only if there are duplicate lat/lon
        # Apply jitter to lat/lon only if there are duplicate lat/lon
        jittered_lat = if_else(n() >= 1, latitude + runif(1, -0.2899, 0.2899), latitude),  # Add jitter in latitude (for 20 miles)
        jittered_lon = if_else(n() >= 1, longitude + runif(1, -0.2899 / cos(latitude * pi / 180), 0.2899 / cos(latitude * pi / 180)), longitude)  # Add jitter in longitude (for 20 miles)
      ) %>%
      mutate(latitude=jittered_lat,
             longitude = jittered_lon ) %>% 
      ungroup() -> responses

# saveRDS(responses, file = '~/Library/Mobile Documents/com~apple~CloudDocs/geotruth/geotruthwebsite/geotruth.github.io/projects/supportsudanownedbusinesses/myapp/responses.RDS')
saveRDS(responses, file = 'responses.RDS')
# saveRDS(responsesall, 'responses.RDS')
glue::glue("added {newresponsestogeocode %>% nrow} new businesses:")
glue::glue("{geocoded_responses$name_of_business_project %>% unlist}")
glue::glue("Date added: {Sys.time()}")
  }
