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

# Authenticate with Google Sheets
# gs4_auth()  # Uncomment if you need to authenticate

# Read the Google Sheet
read_sheet(surveyresponsesurl) %>% 
  # as.data.frame() %>% 
  janitor::clean_names() %>% 
  mutate(response_id = row_number())->responsesall

# saveRDS(geocoded_responses %>% head(2), 'responses.RDS')
read_rds('responses.RDS') %>% 
  select(response_id, everything())->responsesold


# find which are new to geocode -------------------------------------------



responsesall %>% 
  filter(!(response_id %in% responsesold$response_id))->newresponsestogeocode
# responsesall ->newresponsestogeocode

if(nrow(newresponsestogeocode)==0){
  responsesold->responses; 
  print("no new businesses to add")
  } else if (nrow(newresponsestogeocode)>0){
newresponsestogeocode %>%
  head() %>%
  mutate(
    postal_code = as.numeric(postal_code),
    inputgeocodeaddress = case_when(
      is.na(complete_physical_address_of_business_project)  ~ 
        glue("{city_location_of_business_project}, {state_region_location_of_business_project}, {country_of_business_project}, {postal_code}"),
      nchar(complete_physical_address_of_business_project) < 10  ~ 
        glue("{city_location_of_business_project}, {state_region_location_of_business_project}, {country_of_business_project}"),
      TRUE ~ complete_physical_address_of_business_project
    )
  ) %>% 
  geocode(address = inputgeocodeaddress, method = 'osm', lat = latitude, long = longitude, return_addresses = TRUE
          ) ->geocoded_responses


geocoded_responses %>% 
  rbind(responsesold) %>%
  distinct(response_id, .keep_all = T)-> responses


saveRDS(responses, 'responses.RDS')
# saveRDS(responsesall, 'responses.RDS')
glue::glue("added {newresponsestogeocode %>% nrow} new businesses")
  }
