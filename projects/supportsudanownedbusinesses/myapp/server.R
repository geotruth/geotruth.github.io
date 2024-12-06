library(shiny)
library(leaflet)
library(dplyr)
library(gt)
library(wordcloud2)

# Load the dataset
readRDS("responses.RDS") -> responses
# Data cleaning and preprocessing
responses <- responses %>%
  select(
    response_id,
    timestamp,
    email = email_address,
    type = business_or_project,
    name = name_of_business_project,
    website = business_project_website,
    short_description = short_business_project_description,
    long_description = long_business_project_and_or_mission,
    category = category_of_business_or_project,
    languages = language_spoken,
    full_address = complete_physical_address_of_business_project,
    city = city_location_of_business_project,
    state = state_region_location_of_business_project,
    country = country_of_business_project,
    business_email = email_of_business_project,
    facebook_link = facebook_link_of_business_project,
    instagram_handle = instagram_handle_of_business_project,
    twitter_handle = twitter_x_handle,
    funding_link = link_to_funding_donate_page,
    support_needed = type_of_support_needed,
    additional_support = additional_support_needs,
    status = current_business_project_status,
    challenges = key_challenges_facing_your_business_project,
    emergency_assistance = as_a_business_project_owner_are_you_in_urgent_need_of_emergency_assistance,
    urgency_type = type_of_urgency,
    last_update = business_project_information_entered_is_up_to_date_as_of,
    comments = notes_or_comments,
    feedback,
    postal_code,
    consent_use_info = consent_for_use_of_unidentifiable_information,
    consent_highlight_owners = consent_to_highlight_business_owners,
    address = inputgeocodeaddress,
    latitude,
    longitude
  ) %>%
  # Clean postal code
  mutate(postal_code = as.character(as.integer(postal_code))) %>%
  # Replace missing URLs or social media handles with "N/A"
  mutate(across(c(website, facebook_link, instagram_handle, twitter_handle, funding_link), ~ ifelse(is.na(.), "N/A", .)))

# Define Server Logic
server <- function(input, output, session) {
  
  # Reactive dataset filtering based on user inputs
  filteredData <- reactive({
    data <- responses
    
    # Filter by country if selected
    if (!is.null(input$country) && input$country != "All") {
      data <- data %>% filter(country == input$country)
    }
    
    # Filter by status if selected
    if (!is.null(input$status) && input$status != "All") {
      data <- data %>% filter(status == input$status)
    }
    
    data
  })
  
  # Apply additional filters for category and project type
  filteredByCategoryAndType <- reactive({
    data <- filteredData()
    
    if (input$category != "All") {
      data <- data %>% filter(category == input$category)
    }
    
    if (input$project != "All") {
      data <- data %>% filter(type == input$project)
    }
    
    data
  })
  
  # Handle Apply Filters button
  observeEvent(input$apply_filters, {
    filteredByCategoryAndType()
  })
  
  # Handle Reset Filters button
  observeEvent(input$reset_filters, {
    updateSelectInput(session, "country", selected = "All")
    updateSelectInput(session, "category", selected = "All")
    updateSelectInput(session, "project", selected = "All")
    updateSelectInput(session, "status", selected = "All")
  })
  
  # Dynamically update filter options based on filtered data
  observe({
    updateSelectInput(
      session,
      "category",
      choices = c("All", sort(unique(filteredData()$category)))
    )
    updateSelectInput(
      session,
      "project",
      choices = c("All", sort(unique(filteredData()$type)))
    )
    updateSelectInput(
      session,
      "status",
      choices = c("All", sort(unique(filteredData()$status))),
      selected = input$status
    )
  })
  
  # Render the Leaflet Map with all social media links and project status
  output$businessMap <- renderLeaflet({
    data <- filteredByCategoryAndType()
    leaflet(data) %>%
      addTiles() %>%
      addCircleMarkers(
        ~longitude, ~latitude,
        radius = 6,
        color = "#0d807a",
        stroke = TRUE,
        fillOpacity = 0.8,
        label = ~name,
        popup = ~paste0(
          "<b>", name, "</b><br>",
          "Category: ", category, "<br>",
          "Type: ", type, "<br>",
          "Status: ", status, "<br>",
          "Country: ", country, "<br>",
          "City: ", city, "<br>",
          ifelse(website != "N/A", paste0("<a href='", website, "' target='_blank'>Website</a><br>"), ""),
          ifelse(instagram_handle != "N/A", paste0("<a href='", instagram_handle, "' target='_blank'>Instagram</a><br>"), ""),
          ifelse(twitter_handle != "N/A", paste0("<a href='", twitter_handle, "' target='_blank'>Twitter</a><br>"), ""),
          ifelse(facebook_link != "N/A", paste0("<a href='", facebook_link, "' target='_blank'>Facebook</a><br>"), ""),
          ifelse(funding_link != "N/A", paste0("<a href='", funding_link, "' target='_blank'>Funding</a>"), "")
        )
      ) %>%
      setView(lng = mean(data$longitude, na.rm = TRUE), lat = mean(data$latitude, na.rm = TRUE), zoom = 2.01)
  })
  
  # Render the GT Table with all social media links and project status
  output$businessTable <- render_gt({
    data <- filteredByCategoryAndType()
    
    data %>% 
      select(
        `Business Name` = name,
        `Website` = website,
        `Instagram` = instagram_handle,
        `Twitter` = twitter_handle,
        `Facebook` = facebook_link,
        `Funding Link` = funding_link,
        `Category` = category,
        `Type` = type,
        `City` = city,
        `Country` = country,
        `Project Status` = status
      ) %>%
      gt() %>%
      tab_header(
        title = md("**Sudanese & Diaspora Owned Businesses**"), 
        subtitle = md("Filtered results based on your selections.")
      ) %>%
      fmt_missing(columns = everything(), missing_text = "Not Available") %>%
      cols_width(
        `Business Name` ~ px(200), 
        `Website` ~ px(150),
        `Instagram` ~ px(120),
        `Twitter` ~ px(120),
        `Facebook` ~ px(120),
        `Funding Link` ~ px(120),
        everything() ~ px(100)
      ) %>%
      opt_table_outline() %>%
      tab_spanner(
        label = "Social Media Links", 
        columns = c("Website", "Instagram", "Twitter", "Facebook", "Funding Link")
      ) %>%
      tab_spanner(
        label = "Business Details", 
        columns = c("Business Name", "Category", "Type", "City", "Country", "Project Status")
      )
  })
  # Render Word Cloud for Key Challenges
  output$wordCloud <- renderWordcloud2({
    data <- filteredByCategoryAndType()  # Get filtered data
    
    # Debug: Check the column names of the filtered data
    print(colnames(data))  # This will print the column names to the console
    
    # Check if 'challenges' column exists
    if ("challenges" %in% colnames(data)) {
      
      # Check the first few values of the 'challenges' column
      print(head(data$challenges))  # This will print the first few values of the challenges column
      
      # Clean and process the challenges text data
      challenges_text <- data$challenges %>%
        na.omit() %>%  # Remove NA values
        tolower() %>%  # Convert to lowercase
        gsub("[[:punct:]]", "", .) %>%  # Remove punctuation
        gsub("\\s+", " ", .)  # Remove extra spaces
      
      # Check if the processed data still has content
      if (length(challenges_text) > 0) {
        challenges_text <- paste(challenges_text, collapse = " ")
        # Define a list of stopwords (you can add more words to this list as needed)
        stopwords <- c("for", "eg", "and", "the", "to", "a", "of", "in", "on", "with", "by", "is", "that", "this", "at", "as", "an", "be", "it", "was", "from", "are", "has", "have", "not", "or", "but")
        
        # Debug: Check if the word cloud text is processed correctly
        print(head(challenges_text))  # Print the first few words to check formatting
        
        wordcloud2(
          data = data$challenges %>%
            na.omit() %>%                    # Remove NA values
            tolower() %>%                    # Convert to lowercase
            gsub("[^[:alnum:] ]", "", .) %>% # Remove non-alphanumeric characters (except spaces)
            strsplit(" ") %>%                # Split the text into individual words
            unlist() %>%                     # Flatten the list into a vector of words
            .[!. %in% stopwords] %>%         # Remove stopwords
            table() %>%                      # Create a frequency table of words
            as.data.frame(),                     # Create a frequency table of words
          size = .5,
          fontWeight = "bold",
          color = '#0d807a',
          maxRotation = 0,
          rotateRatio = 1,
          backgroundColor = 'transparent'
        )
      } else {
        # If no data available for word cloud
        print("No challenges text available after cleaning!")
        return(NULL)
      }
    } else {
      # If 'challenges' column is missing
      print("Challenges column is missing!")
      return(NULL)
    }
  })
  
  
  
}
