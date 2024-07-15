library(shiny)
library(leaflet)
library(dplyr)
library(readr)
library(lubridate)
library(DT)
library(RColorBrewer)

#Authors Hannah Pefley and Kristine Lee

# Define UI
ui <- fluidPage(
  
  tags$head(
    tags$style(HTML("
      #balloon_table {
        max-height: auto;
        overflow-y: auto;
        width: 100%;
      }
      #balloon_table tbody tr td:nth-child(1) {
        padding-left: 10px;
        background-color: #ffffff; /* default background color */
      }
    "))
  ),
  
  titlePanel("Balloons and Moon Path"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("time", "Select Time:", 
                  min = 0, max = 5000, value = 0, step = 1, 
                  animate = animationOptions(interval = 50, loop = TRUE)),
      selectInput("variable", "Select Variable to Display:", 
                  choices = c("External Temperature (F)", "Light (lux)", "Acceleration (g)", "Altitude (ft)", "Internal Temperature (F)", "UVA (W/m^2)", "IR (scale)")),
      dataTableOutput("balloon_table"),
      checkboxInput("show_moon", "Show Shadow", value = TRUE)  # Toggle switch for showing moon
    ),
    mainPanel(
      leafletOutput("map", height='80vh'),
    )
  )
)

# Load and prepare data
balloon_data <- read_csv("AllNullsFilled.csv", show_col_types = FALSE)
moon_data <- read_csv("expanded_testingcleaningofmoon.csv", show_col_types = FALSE)  

# Define Server
server <- function(input, output, session) {
  
  Sys.setenv(TZ = "UTC")
  
  # Prepare moon data
  moon_data <- moon_data %>%
    mutate(time = as.POSIXct(Timestamp, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")) %>%
    select(time, latitude = Central_Latitude_Decimal, longitude = Central_Longitude_Decimal, width = `Path Width (km)`)
  
  # Prepare balloon data
  balloon_data <- balloon_data %>%
    mutate(time = as.POSIXct(Timestamp, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")) %>%
    select(time, latitude = AdjLatFilled, longitude = AdjLonFilled, Balloon, 
           `Packet ID`, `External Temperature (F)` = TempImputed, 
           `Light (lux)` = LightImputed, `Acceleration (g)` = AccelImputed, `Altitude (ft)` = AltImputed, `Internal Temperature (F)` = IntTempImputed, `UVA (W/m^2)` = `UVA (W/m^2) predicted`, `IR (scale)` = `IR (scale) predicted`)
  
  balloon_data$`Altitude (ft)` <- round(balloon_data$`Altitude (ft)`, digits = 3)
  balloon_data$`Internal Temperature (F)` <- round(balloon_data$`Internal Temperature (F)`, digits = 3)
  balloon_data$`UVA (W/m^2)` <- round(balloon_data$`UVA (W/m^2)`, digits = 3)
  balloon_data$`IR (scale)` <- round(balloon_data$`IR (scale)`, digits = 3)
  
  tester_data <- balloon_data
  tester_data <- tester_data %>%
    mutate(time = time + 4*3600)
  
  updateSliderInput(session, "time", 
                    min = with_tz(min(tester_data$time, na.rm = TRUE), tzone = "UTC"),
                    max = with_tz(max(tester_data$time, na.rm = TRUE), tzone = "UTC"),
                    value = with_tz(min(tester_data$time, na.rm = TRUE), tzone = "UTC"),
                    step = 60)
  
  # Choose colors from a specific palette (e.g., Set3 from RColorBrewer)
  balloon_colors <- colorFactor(brewer.pal(12, "Paired"), unique(balloon_data$Balloon))
  
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$Stadia.AlidadeSmooth,
                       options = providerTileOptions(noWrap = TRUE)
      ) %>%
      setView(lng = -86.25, lat = 40, zoom = 6)  # Centered around Indiana and Ohio
  })
  
  # Reactive value to keep track of the previous time value
  previous_time <- reactiveVal(NULL)
  
  observe({
    req(input$time)
    current_time <- as.POSIXct(input$time, origin = "1970-01-01", tz = "EST")
    
    balloons_to_show <- balloon_data %>% 
      filter(time <= (current_time-4*3600))
    
    visible_balloons <- reactiveVal(balloons_to_show)
    
    table_data <- reactive({
      req(input$time)
      current_time <- as.POSIXct(input$time, origin = "1970-01-01", tz = "EST")
      
      table_info <- balloons_to_show %>%
        group_by(Balloon) %>%
        filter(time == max(time)) %>%
        summarise(
          `Packet ID` = first(`Packet ID`),
          Coordinates = paste0(round(first(latitude), 3), ",", round(first(longitude), 3)),
          Variable = first(!!sym(input$variable))
        ) %>%
        rename(!!input$variable := Variable)
      
      table_info
    })
    
    output$balloon_table <- renderDataTable({
      datatable(table_data(), options = list(
        dom = 't',
        paging = FALSE,
        ordering = FALSE,
        scrollX = TRUE,
        scrollY = '300px',
        scrollCollapse = TRUE
      ), rownames = FALSE) %>%
        formatStyle(
          'Balloon',
          backgroundColor = styleEqual(unique(balloon_data$Balloon), balloon_colors(unique(balloon_data$Balloon)))
        )
    })    
    
    current_moon_data <- moon_data %>%
      filter(abs(difftime(moon_data$time, (current_time-4*3600), units = "secs")) < 1)
    
    current_moon_data <- current_moon_data %>%
      filter(time == min(current_moon_data$time))
    
    # Clear markers and shapes based on time direction
    if (!is.null(previous_time()) && current_time < previous_time()) {
      leafletProxy("map") %>%
        clearMarkers() %>%
        clearShapes()
    } else {
      leafletProxy("map") %>%
        clearMarkers()
    }
    
    # Plot moon data if checkbox is checked
    if (input$show_moon) {
      leafletProxy("map") %>%
        addCircles(data = current_moon_data, 
                   lng = ~longitude, lat = ~latitude, 
                   color = "grey", 
                   radius = ~width * 500,
                   stroke = FALSE,
                   layerId = "foo",
                   fillOpacity = 0.55,
                   popup = ~paste("Shadow"), 
                   label = ~paste("Shadow"))
    } else {
      leafletProxy("map") %>%
        removeShape(layerId = "foo")
    }
    
    # Loop over unique balloon IDs and add paths and markers
    balloon_ids <- unique(balloons_to_show$Balloon)
    
    for (id in balloon_ids) {
      
      balloon_trail <- balloons_to_show %>% 
        filter(Balloon == id)
      
      head_row <- balloon_trail %>%
        filter(time == max(balloon_trail$time))
      
      popup = paste(
        "<B>Balloon</B>: ", head_row$Balloon, "<BR>",
        "<B>Coordinates</B>: ", head_row$latitude, ",", head_row$longitude, "<BR>",
        "<B>Packet ID</B>: ", head_row$`Packet ID`, "<BR>",
        "<B>External Temperature (F)</B>: ", head_row$`External Temperature (F)`, "<BR>",
        "<B>Acceleration (g)</B>: ", head_row$`Acceleration (g)`, "<BR>",
        "<B>Light (lux)</B>: ", head_row$`Light (lux)`, "<BR>",
        "<B>Internal Temperature</B>: ", head_row$`Internal Temperature (F)`, "<BR>",
        "<B>UVA (W/m^2)</B>: ", head_row$`UVA (W/m^2)`, "<BR>",
        "<B>IR (scale)</B>: ", head_row$`IR (scale)`,"<BR>",
        "<B>Altitude</B>: ", head_row$`Altitude (ft)`)
      
      leafletProxy("map") %>%
        addPolylines(data = balloon_trail, 
                     lng = ~longitude, lat = ~latitude, 
                     color = balloon_colors(id), 
                     weight = 2, 
                     opacity = 0.7) %>%
        addMarkers(data = filter(balloon_trail, time == max(balloon_trail$time)), 
                   lng = ~longitude, lat = ~latitude, 
                   popup = popup, 
                   label = ~as.character(Balloon))
    }
    
    # Update the previous time value
    previous_time(current_time)
    
  })
}

# Run the app
shinyApp(ui, server)
