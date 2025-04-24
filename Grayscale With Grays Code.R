# Install necessary packages if not installed
if (!requireNamespace("threejs", quietly = TRUE)) install.packages("threejs")
if (!requireNamespace("magick", quietly = TRUE)) install.packages("magick")
if (!requireNamespace("leaflet", quietly = TRUE)) install.packages("leaflet")
if (!requireNamespace("htmltools", quietly = TRUE)) install.packages("htmltools")
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")

# Load libraries
library(threejs)
library(magick)
library(leaflet)
library(htmltools)
library(dplyr)

# Read the CSV file (adjust this path if needed)
tracking_df <- read.csv("C:/Users/amjar/Downloads/HornbilltelemetryinnortheastIndia.csv")

# Compute bounding box for inset map
bbox <- c(
  min(tracking_df$location.long),
  max(tracking_df$location.long),
  min(tracking_df$location.lat),
  max(tracking_df$location.lat)
)

bbox_lat <- c(bbox[3], bbox[4], bbox[4], bbox[3], bbox[3])
bbox_lon <- c(bbox[1], bbox[1], bbox[2], bbox[2], bbox[1])

# Filter points inside bounding box
within_bbox <- tracking_df %>%
  filter(
    location.long >= bbox[1], location.long <= bbox[2],
    location.lat  >= bbox[3], location.lat  <= bbox[4]
  )

# Leaflet inset mini-map
leaflet_plot <- leaflet(options = leafletOptions(zoomControl = FALSE, dragging = FALSE)) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  fitBounds(bbox[1], bbox[3], bbox[2], bbox[4]) %>%
  addPolygons(lng = bbox_lon, lat = bbox_lat, color = "red", fill = FALSE) %>%
  addCircleMarkers(
    lng = within_bbox$location.long,
    lat = within_bbox$location.lat,
    radius = 1, color = "blue"
  )

# Compute center of the data
center_lat <- mean(tracking_df$location.lat, na.rm = TRUE)
center_lon <- mean(tracking_df$location.long, na.rm = TRUE)

# --- Texture Loading and Adjusting ---

# Define file paths
original_texture_path <- "world_map_outline.jpg"
adjusted_texture_path <- "adjusted_world_map_outline.jpg"

# URL of the grayscale world map outline
image_url <- "https://images.fineartamerica.com/images/artworkimages/mediumlarge/2/world-map-outline-in-gray-color-chokkicx.jpg"

# Download the image if it doesn’t exist
if (!file.exists(original_texture_path)) {
  download.file(image_url, destfile = original_texture_path, mode = "wb")
}

# Load and process image with a cooler blue-brown tint using RGB
earth_image <- image_read(original_texture_path) %>%
  image_convert(colorspace = "Gray") %>%
  image_colorize(opacity = 30, color = rgb(140, 90, 60, maxColorValue = 255)) %>%  # RGB format
  image_modulate(brightness = 73, saturation = 115) %>%  # Intermediate darkness
  image_resize("4096x2048!")

# Save adjusted image
image_write(earth_image, adjusted_texture_path, format = "jpeg")

# Preview in R
print(earth_image)

# --- Create the Globe with the Custom Texture ---

# Create globe using the custom adjusted texture
globe_plot <- globejs(
  img = adjusted_texture_path,  # Use the processed texture image
  lat = tracking_df$location.lat,
  long = tracking_df$location.long,
  value = rep(1.5, nrow(tracking_df)),
  color = rep("red", nrow(tracking_df)),
  atmosphere = TRUE,   # Enable glow effect
  bg = "black",        # Dark background for better contrast
  zoom = 2,
  lat0 = center_lat,
  long0 = center_lon,
  camera = list(
    lat = center_lat,
    long = center_lon,
    altitude = 2.5  # Adjust altitude as needed to zoom in or out
  )
)

# JS for lines between inset and globe center (gray color and shorter lines)
script <- HTML("
  window.addEventListener('load', () => {
    const box = document.getElementById('leaflet-inset');
    const rect = box.getBoundingClientRect();
    const boxCorners = [
      [rect.left, rect.top],
      [rect.right, rect.top],
      [rect.right, rect.bottom],
      [rect.left, rect.bottom]
    ];
    // Define the center of the screen (not the right side of the screen)
    const globeCenterX = window.innerWidth / 2;
    const globeCenterY = window.innerHeight / 2;
    const svg = document.createElementNS('http://www.w3.org/2000/svg','svg');
    svg.setAttribute('style', 'position:absolute; top:0; left:0; width:100%; height:100%; z-index:2; pointer-events: none;');
    svg.setAttribute('xmlns','http://www.w3.org/2000/svg');
    svg.setAttribute('viewBox', `0 0 ${window.innerWidth} ${window.innerHeight}`);
    
    // Function to create a line
    const createLine = (x1, y1, x2, y2) => {
      const line = document.createElementNS('http://www.w3.org/2000/svg','line');
      line.setAttribute('x1', x1);
      line.setAttribute('y1', y1);
      line.setAttribute('x2', x2);
      line.setAttribute('y2', y2);
      line.setAttribute('stroke', 'gray');  // Set line color to gray
      line.setAttribute('stroke-width', '2');
      svg.appendChild(line);
    };

    // Loop through box corners and create lines pointing to the globe center
    for (let i = 0; i < 4; i++) {
      // Modify this part to make the lines shorter
      createLine(boxCorners[i][0], boxCorners[i][1], globeCenterX * 0.8, globeCenterY * 0.8); // Shorten line length by scaling the target
    }

    // Append SVG to the body
    document.body.appendChild(svg);
  });
")

# Combined layout
combined_plot <- tagList(
  tags$div(
    style = "position: relative; width: 100vw; height: 100vh; overflow: hidden;",
    
    tags$div(
      id = "globe-container",
      style = "position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0;",
      globe_plot
    ),
    
    tags$div(
      id = "leaflet-inset",
      style = "position: absolute; 
               top: 50%; left: 10px; 
               transform: translateY(-135%);
               width: 200px; height: 200px;
               z-index: 3; 
               background: white; 
               border: 5px solid black;
               overflow: hidden;",
      tags$div(
        style = "width: 100%; height: 100%; position: relative; top: -100px;",
        leaflet_plot
      )
    ),
    
    tags$script(script)
  )
)

# Save to temporary HTML file
html_file <- tempfile(fileext = ".html")
htmltools::save_html(combined_plot, file = html_file)

# Open in default web browser
browseURL(html_file)
