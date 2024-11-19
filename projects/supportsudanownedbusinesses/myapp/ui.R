library(shiny)
library(leaflet)
library(dplyr)
library(gt)

# Load the dataset
readRDS("responses.RDS") -> responses

# Define UI
ui <- fluidPage(
  # Custom CSS to style the select inputs, tab links, and other components
  tags$head(
    tags$style(HTML("
      /* Style for select inputs */
      .selectize-input {
        background-color: #f1f1f1;
        border-color: #0d807a;
        color: #0d807a;
      }
      .selectize-input:hover {
        border-color: #0d807a;
        box-shadow: 0 0 3px 1px rgba(13, 128, 122, 0.5);
      }
      .selectize-dropdown {
        background-color: #f1f1f1;
        border-color: #0d807a;
      }
      .selectize-dropdown .option {
        color: #0d807a;
      }
      .selectize-dropdown .active {
        background-color: #0d807a;
        color: white;
      }

      /* Style for tab links */
      .nav-tabs > li > a {
        color: #0d807a;
        font-weight: bold;
      }
      .nav-tabs > li > a:hover {
        color: #0d807a;
        background-color: #f1f1f1;
      }
      .nav-tabs > li.active > a {
        color: white;
        background-color: #0d807a;
      }

      /* Style for the floating submission form */
      .submission-info {
        position: fixed;
        bottom: 0;
        left: 0;
        width: 100%;
        background-color: #f1f1f1;
        padding: 15px;
        box-shadow: 0 -2px 5px rgba(0, 0, 0, 0.1);
        z-index: 100;
      }

      .submission-info a {
        color: #0d807a;
        text-decoration: underline;
      }

      .submission-info h4 {
        color: #0d807a;
      }

    "))
  ),
  
  # Application title
  # titlePanel("Sudanese & Diaspora Owned Businesses and Projects"),
  
  # Tab navigation
  sidebarLayout(
    sidebarPanel(
      selectInput("country", "Select Country", choices = c("All", unique(responses$country_of_business_project))),
      selectInput("category", "Select Category", choices = c("All", unique(responses$category_of_business_or_project))),
      selectInput("project", "Select Business/Project", choices = c("All", unique(responses$business_or_project)))
    ),
    
    mainPanel(
      tabsetPanel(
        # Map tab
        tabPanel("Map", leafletOutput("businessMap")),
        
        # Table tab
        tabPanel("Table", gt_output("businessTable")),
        
        # About tab
        tabPanel("About",
                 fluidRow(
                   column(12, 
                          HTML("<h3>About the Dashboard</h3>
                                <p>The war in Sudan has affected millions of people. Over <b>25 million</b> Sudanese have been forced to leave their homes because of the fighting, and many have lost their jobs and businesses. In fact, about <b>50%</b> of people living in Sudan have lost their jobs due to the conflict, making it even harder for families to survive and rebuild.</p>
                                <p>This dashboard is in place to help Sudanese-owned businesses and projects, both in Sudan and around the world (the diaspora). By supporting these businesses and projects, you’re helping people recover from the war in Sudan, get back to work, and rebuild their communities. Some businesses and projects' strategic aim is to help people on the ground or pledge to support others affected by war - in essence, your effort to support is compounded!</p>
                                <p>We update submissions to this dashboard within a day or two. For questions or edits, reach us at: <a href='mailto:admin@geotruth.org' style='color: #0d807a;'>admin@geotruth.org</a></p>
                                <h3>About Us</h3>
                                <p>First, geo:truth does not take any compensation, commission or reward from any purchases or support provided to businesses displayed on this dashboard. We're <b>geo:truth</b>, a nonprofit research organization using the power of geography and data to uncover and address critical global challenges. We are committed to tackling health disparities, economic inequities, and the impacts of crises like the war in Sudan through geospatial analysis and innovative research methods.</p>
                                <p>If you'd like to support us, check out our <a href='https://geotruth.github.io/support/' style='color: #0d807a;'>Support Us ➡️</a> page for deets!</p>
                                <p>Our goal is to create a world where everyone—no matter their location—has equal access to health, well-being, and opportunity. We collaborate with local organizations, healthcare providers, and community leaders to provide the data and tools they need to make informed decisions and create lasting change.</p>
                                <h3>How You Can Help</h3>
                                <ul>
                                  <li><b>Find Businesses</b>: Explore the list of Sudanese and diaspora-owned businesses and projects, and see if there’s something you’d like to support or purchase.</li>
                                  <li><b>Spread the Word</b>: Share this website with your friends and family to help these businesses grow and reach more people.</li>
                                  <li><b>Add a Business</b>: Know of a Sudanese or diaspora-owned business? <a href='https://docs.google.com/forms/d/e/1FAIpQLSd29RONu1wQb2m9U6ZKbQRK37P3I1JfwzNB8DRcjMmsixpy_g/viewform?usp=sharing' target='_blank'>Add it here</a>, and we’ll update the website soon!</li>
                                </ul>
                                <p>By supporting these businesses and/or projects, you’re helping people who’ve lost their homes and jobs because of the war. Together, we can help Sudanese families and businesses rebuild during these difficult times.</p>
                                "))
                 )
        )),
      # New Submission Info Tab
      tabPanel(
        "Submission Info",
        div(
          class = "submission-info",
          h4("Add a Missing Business or Project"),
          p("Did you notice a missing Sudanese-owned business or project? Use the link below to submit it."),
          tags$a(
            href = "https://docs.google.com/forms/d/e/1FAIpQLSd29RONu1wQb2m9U6ZKbQRK37P3I1JfwzNB8DRcjMmsixpy_g/viewform?usp=sharing",
            "Submit a Business or Project",
            target = "_blank"
          ),
          br(),
          p(
            "We update submissions to this dashboard within a day or two. For questions or edits, reach us at: ",
            tags$a(
              href = "mailto:admin@geotruth.org",
              "admin@geotruth.org"
            )
          )
        )
      )
    )
  )
)