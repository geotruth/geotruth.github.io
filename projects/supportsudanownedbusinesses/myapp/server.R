library(shiny)
library(leaflet)
library(dplyr)
library(gt)

# Load the dataset
readRDS("responses.RDS") -> responses

# Define Server Logic
server <- function(input, output, session) {
  
  # Reactive dataset filtering based on user inputs (excluding category and project filters)
  filteredData <- reactive({
    data <- responses
    # Apply filters based on the selected country and project
    if (input$country != "All") {
      data <- data %>% filter(country_of_business_project == input$country)
    }
    data  # This returns the filtered data excluding the category and business/project filters
  })
  
  # Apply category filtering independently for map and table
  filteredByCategory <- reactive({
    data <- filteredData()  # Start with filtered data from other dropdowns
    # Apply category filter only when a specific category is selected
    if (input$category != "All") {
      data <- data %>% filter(category_of_business_or_project == input$category)
    }
    data
  })
  
  # Apply business/project type filtering independently for map and table
  filteredByBusinessProject <- reactive({
    data <- filteredByCategory()  # Start with the category-filtered data
    # Apply business/project type filter only when a specific type is selected
    if (input$project != "All") {
      data <- data %>% filter(business_or_project == input$project)
    }
    data
  })
  
  # Update the 'category' and 'business/project type' options dynamically when filters change
  observe({
    updateSelectInput(
      session,
      "category",
      choices = c("All", sort(unique(filteredData()$category_of_business_or_project)))
    )
    updateSelectInput(
      session,
      "project",
      choices = c("All", sort(unique(filteredData()$business_or_project)))
    )
  })
  
  # Render the Leaflet Map
  output$businessMap <- renderLeaflet({
    data <- filteredByBusinessProject()  # Use the business/project-filtered data
    leaflet(data) %>%
      addTiles() %>%
      addCircleMarkers(
        ~longitude, ~latitude,
        radius = 6,
        color = "#0d807a",  # Choose color for markers
        stroke = TRUE,
        fillOpacity = 0.8,
        label = ~name_of_business_project,
        popup = ~paste0(
          "<b>", name_of_business_project, "</b><br>",
          "Category: ", category_of_business_or_project, "<br>",
          "Business/Project Type: ", business_or_project, "<br>",
          "Location: ", city_location_of_business_project, ", ", country_of_business_project, "<br>",
          ifelse(!is.na(business_project_website),
                 paste0("<a href='", business_project_website, "' target='_blank'>Website</a>"), "")
        )
      ) %>%
      setView(lng = mean(data$longitude, na.rm = TRUE), lat = mean(data$latitude, na.rm = TRUE), zoom = 2)
  })
  
  # Render the GT Table
  output$businessTable <- render_gt({
    data <- filteredByBusinessProject()  # Use the business/project-filtered data
    data %>%
      select(
        "Business Name" = name_of_business_project,
        "Website" = business_project_website,
        "Category" = category_of_business_or_project,
        "Business/Project Type" = business_or_project,
        "City" = city_location_of_business_project,
        "Country" = country_of_business_project
      ) %>%
      gt() %>%
      tab_header(
        title = md("**Sudanese & Diaspora Owned Businesses**"),
        subtitle = md("Filtered results based on your selections.")
      ) %>%
      fmt_missing(columns = everything(), missing_text = "Not Available") %>%
      cols_width(
        `Business Name` ~ px(250),
        `Website` ~ px(250),
        everything() ~ px(150)
      ) %>%
      opt_table_outline() %>%
      tab_spanner(
        label = "Business Details", columns = c("Business Name", "Website", "Business/Project Type")
      )
  })
}

