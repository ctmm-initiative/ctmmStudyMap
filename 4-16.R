library(leaflet)
library(threejs)
library(htmltools)
library(htmlwidgets)
library(dplyr)

# Simulating tracking data
set.seed(1)
tracking_data <- data.frame(
  location.long = runif(300, -80, -70),
  location.lat = runif(300, 30, 40)
)

# Bounding box for inset map (optional, will show region on Leaflet)
bbox <- c(
  min(tracking_data$location.long),
  max(tracking_data$location.long),
  min(tracking_data$location.lat),
  max(tracking_data$location.lat)
)

bbox_lat <- c(bbox[3], bbox[4], bbox[4], bbox[3], bbox[3])
bbox_lon <- c(bbox[1], bbox[1], bbox[2], bbox[2], bbox[1])

# Filter points inside bounding box
within_bbox <- tracking_data %>%
  filter(
    location.long >= bbox[1], location.long <= bbox[2],
    location.lat  >= bbox[3], location.lat  <= bbox[4]
  )

# Apply shifts for inset (if needed)
shift_lat <- -9.45
shift_lon <- -0.3

shifted_bbox_lat <- c(bbox[3] + shift_lat, bbox[4] + shift_lat)
shifted_bbox_lon <- c(bbox[1] + shift_lon, bbox[2] + shift_lon)

# Leaflet inset mini-map
leaflet_plot <- leaflet(options = leafletOptions(zoomControl = FALSE, dragging = FALSE)) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  fitBounds(shifted_bbox_lon[1], shifted_bbox_lat[1], shifted_bbox_lon[2], shifted_bbox_lat[2]) %>%
  addPolygons(lng = bbox_lon, lat = bbox_lat, color = "red", fill = FALSE) %>%
  addCircleMarkers(
    lng = within_bbox$location.long,
    lat = within_bbox$location.lat,
    radius = 1, color = "blue"
  )

# Center for 3D globe
center_lat <- mean(tracking_data$location.lat)
center_lon <- mean(tracking_data$location.long)

# Globe setup, locked and centered
globe_plot <- globejs(
  lat = tracking_data$location.lat,
  long = tracking_data$location.long,
  value = rep(1.5, nrow(tracking_data)),
  color = rep("red", nrow(tracking_data)),
  atmosphere = TRUE,
  bg = "black",
  zoom = 1.5,
  lat0 = center_lat,    # Centered on data mean
  long0 = center_lon,   # Centered on data mean
  rotationSpeed = 0     # Disabling interaction (locked globe)
)

# JavaScript for creating white lines (connecting to the center of the globe)
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

    // Screen center
    const globeCenterX = window.innerWidth / 2;
    const globeCenterY = window.innerHeight / 2;

    const svg = document.createElementNS('http://www.w3.org/2000/svg','svg');
    svg.setAttribute('style', 'position:absolute; top:0; left:0; width:100%; height:100%; z-index:2; pointer-events: none;');
    svg.setAttribute('xmlns','http://www.w3.org/2000/svg');
    svg.setAttribute('viewBox', `0 0 ${window.innerWidth} ${window.innerHeight}`);

    const createLine = (x1, y1, x2, y2) => {
      const line = document.createElementNS('http://www.w3.org/2000/svg','line');
      line.setAttribute('x1', x1);
      line.setAttribute('y1', y1);
      line.setAttribute('x2', x2);
      line.setAttribute('y2', y2);
      line.setAttribute('stroke', 'white');
      line.setAttribute('stroke-width', '2');
      svg.appendChild(line);
    };

    // Connect the bounding box corners to the center of the globe
    for (let i = 0; i < 4; i++) {
      createLine(boxCorners[i][0], boxCorners[i][1], globeCenterX, globeCenterY);
    }

    document.body.appendChild(svg);
  });
")

# Final layout combining the globe and the inset map
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
           width: 200px; height: 150px;
           z-index: 3; 
           background: white; 
           border: 5px solid black;
           overflow: hidden;",
      tags$div(
        style = "width: 100%; height: 100%;",
        leaflet_plot
      )
    ),
    
    tags$script(script)
  )
)

# Display the result in the viewer or browser
browsable(combined_plot)


