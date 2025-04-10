# Install necessary packages if not installed
if (!requireNamespace("threejs", quietly = TRUE)) install.packages("threejs")
if (!requireNamespace("magick", quietly = TRUE)) install.packages("magick")

# Load libraries
library(threejs)
library(magick)

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
  image_modulate(brightness = 75, saturation = 115) %>%  # Intermediate darkness
  image_resize("4096x2048!")

# Save adjusted image
image_write(earth_image, adjusted_texture_path, format = "jpeg")

# Preview in R
print(earth_image)

# Render globe with the cooler blue-brown tone
globejs(
  img = adjusted_texture_path,
  atmosphere = FALSE,
  bg = "black"
)


