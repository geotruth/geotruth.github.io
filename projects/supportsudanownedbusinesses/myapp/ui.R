library(shiny)
library(leaflet)
library(dplyr)
library(gt)
library(wordcloud2)  # Import wordcloud2 for rendering word clouds

# Load the dataset
readRDS("responses.RDS") -> responses
# Define UI
ui <- fluidPage(
  # Custom CSS for clean, public-friendly UI
  tags$head(
    tags$style(HTML("
      /* General Page Styling */
      body {
        font-family: 'Arial', sans-serif;
        background-color: #f1f1f1;
        color: #333333;
        padding-top: 20px;
      }

      /* Title and Header Styling */
      .titlePanel {
        text-align: center;
        margin-bottom: 20px;
        color: #0d807a; /* geo:truth brand color */
        font-size: 20px;
      }
      .side-panel {
        width: 140px; /* Adjust this value to make the panel narrower */
        background-color: #0d807a; /* Optional: keep the background color consistent */
        height: 10px; /* Ensure it spans the full height of the screen */
        position: fixed; /* Keeps the panel fixed in place */
        left: 0;
        top: 0;
        overflow-x: fixed; /* Add a scrollbar if the content overflows */
        overflow-y: auto; /* Add a scrollbar if the content overflows */
        box-shadow: 2px 0 5px rgba(0, 0, 0, 0.1); /* Optional: add a subtle shadow */
      }
      
      /* Main Content Area Styling */
      .content-container {
        padding: 15px;
        background-color: white;
        box-shadow: 0px 4px 6px rgba(0, 0, 0, 0.1);
        border-radius: 8px;
        margin-bottom: 30px;
      }

      /* Simple Styling for Form Inputs */
      .form-control {
        font-size: 12px;
        padding: 12px;
        border-radius: 5px;
        border: 1px solid #ccc;
        width: 10%;
        margin-bottom: 15px;
      }

      .form-control:hover {
        border-color: #0d807a; /* geo:truth brand color */
      }

      /* Larger Buttons */
      .btn-primary {
        background-color: #0d807a; /* geo:truth brand color */
        color: white;
        border-radius: 5px;
        padding: 12px 15px;
        width: 100%;
        border: none;
        font-size: 14px;
      }
      .btn-primary:hover {
        background-color: #085d53; /* darker shade of geo:truth color */
      }

      .btn-secondary {
        background-color: #e5e5e5;
        color: #333333;
        border-radius: 5px;
        padding: 12px 15px;
        font-size: 14px;
      }
      .btn-secondary:hover {
        background-color: #ccc;
      }

      /* Tab Styling */
      .nav-tabs > li > a {
        color: #0d807a; /* geo:truth brand color */
        font-weight: bold;
        font-size: 16px;
      }

      .nav-tabs > li > a:hover {
        background-color: #ffffff;
        color: #0d807a; /* geo:truth brand color */
      }

      .nav-tabs > li.active > a {
        color: white;
        background-color: #0d807a; /* geo:truth brand color */
      }

      /* Map Container */
      .leaflet-container {
        height: 100%;
        border-radius: 8px;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
      }

      /* Floating Submission Info at the bottom */
      .submission-info {
        position: fixed;
        bottom: -15px; /* Adjust this value to move the bar further down */
        left: 0;
        width: 100%;
        background-color: #0d807a; /* geo:truth brand color */
        color: white;
        padding: 15px;
        box-shadow: 0 -2px 5px rgba(0, 0, 0, 0.1);
        z-index: 100;
        text-align: left; font-size: 10px;
      }
      .submission-info a {
        color: white;
        text-decoration: underline;
      }

      .submission-info a:hover {
        color: #f1f1f1;
      }
    "))
  ),
  
  # Page Header
  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = "country",
        label = "Select Country",
        choices = c("All", unique(responses$country_of_business_project)),
        selected = "All"
      ),
      selectInput(
        inputId = "category",
        label = "Select Category",
        choices = c("All", unique(responses$category_of_business_or_project)),
        selected = "All"
      ),
      selectInput(
        inputId = "project",
        label = "Select Project Type",
        choices = c("All", unique(responses$business_or_project)),
        selected = "All"
      ),
      selectInput(
        inputId = "status",
        label = "Select Business Status",
        choices = c("All", unique(responses$current_business_project_status)),
        selected = "All"
      ),
      actionButton(
        inputId = "apply_filters",
        label = "Apply Filters",
        class = "btn-primary"
      ),
      actionButton(
        inputId = "reset_filters",
        label = "Reset Filters",
        class = "btn-secondary"
      )
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Map", leafletOutput("businessMap")),
        tabPanel("Table", gt_output("businessTable")),
        tabPanel("Challenges", 
                 fluidRow(
                   column(12, 
                          h3("Key Challenges Word Cloud"),
                          wordcloud2Output("wordCloud", height = "400px")
                   )
                 )),  # New Word Cloud Tab
        tabPanel("About",
                 fluidRow(
                   column(12, 
                          div(
                            class = "about-section",
                            HTML("<h3>About the Dashboard</h3>
                      <p>The war in Sudan has affected millions of people. Over <b>11 million</b> Sudanese have been forced to leave their homes because of the fighting, and many have lost their jobs and businesses. In fact, about <b>50%</b> of people living in Sudan have lost their jobs due to the conflict.</p>
                      <p>This dashboard is in place to help Sudanese-owned businesses and projects, both in Sudan and around the world (the diaspora). By supporting these businesses and projects, you’re helping people recover from the war in Sudan, get back to work, and rebuild their communities.</p>
                      <p>We update submissions to this dashboard within a day or two. For questions or edits, reach us at: <a href='mailto:admin@geotruth.org' style='color: #0d807a;'>admin@geotruth.org</a></p>
                      <h3>About Us</h3>
                      <p>Our goal is to create a world where everyone—no matter their location—has equal access to health, well-being, and opportunity.</p>
                      <p>geo:truth does not take any compensation, commission or reward from any purchases or support provided to businesses displayed on this dashboard.</p>
                      <h3>How You Can Help</h3>
                      <ul>
                        <li><b>Find Businesses</b>: Explore the list of Sudanese and diaspora-owned businesses and projects.</li>
                        <li><b>Spread the Word</b>: Share this website with your friends and family.</li>
                        <li><b>Add a Business</b>: Know of a Sudanese or diaspora-owned business? <a href='https://docs.google.com/forms/d/e/1FAIpQLSd29RONu1wQb2m9U6ZKbQRK37P3I1JfwzNB8DRcjMmsixpy_g/viewform?usp=sharing' style='color: #0d807a;'>Add it here</a></li>
                      </ul>
                      <p>By supporting these businesses and/or projects, you’re helping people who’ve lost their homes and jobs because of the war.</p>
                      <h4><br>Sources: </h4>
                      <p>- NDP https://www.undp.org/sudan/stories/year-war-much-remains-be-done-sudan
                      </br>- OCHA https://www.unocha.org/publications/report/sudan/sudan-one-year-conflict-key-facts-and-figures-15-april-2024</p>
                                 <br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>"
                            )
                          )
                   )
                 )
        ),
        tabPanel("How to Use",
                 fluidRow(
                   column(12, 
                          div(
                            class = "how-to-use-section",
                            HTML("<h3>How to Use the Dashboard</h3>
                                <p><b>Step 1:</b> Select your filters (Country, Category, Project, Status) to refine your search.</p>
                                <p><b>Step 2:</b> Explore the interactive map or view the data in a table format.</p>
                                <p><b>Step 3:</b> Hover over and click on businesses or projects on the map for more details or submit your own business <a href='https://docs.google.com/forms/d/e/1FAIpQLSd29RONu1wQb2m9U6ZKbQRK37P3I1JfwzNB8DRcjMmsixpy_g/viewform?usp=sharing'>here</a>.</p>
                                <p><b>Step 4:</b> View the key challenges faced by businesses, displayed in a word cloud format on the 'Challenges' tab. </p>
                            ")
                          )
                   )
                 )
        )
      )
    )
  ),
  
  # Floating Submission Info Tab
  div(
    class = "submission-info",
    h4("Add a Missing Business or Project"),
    p("Help us by submitting any missing Sudanese-owned businesses or projects."),
    tags$a(
      href = "https://docs.google.com/forms/d/e/1FAIpQLSd29RONu1wQb2m9U6ZKbQRK37P3I1JfwzNB8DRcjMmsixpy_g/viewform?usp=sharing",
      "Submit a Business or Project",
      target = "_blank"
    ),
    br(),
    p(
      "We update submissions to this dashboard within a day or two."),
    tags$a(
      href = "mailto:admin@geotruth.org",
      "Questions or Edits",
      target = "_blank"
    )
  )
)