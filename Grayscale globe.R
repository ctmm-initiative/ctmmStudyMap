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

# Load and process image to simulate a sepia tone
earth_image <- image_read(original_texture_path) %>%
  image_convert(colorspace = "Gray") %>%                     # Ensure grayscale base
  image_colorize(opacity = 30, color = "saddlebrown") %>%    # Apply warm brown tint
  image_modulate(brightness = 80, saturation = 120) %>%      # Slight color and brightness boost
  image_resize("4096x2048!")                                 # Resize to match globe texture

# Save adjusted image
image_write(earth_image, adjusted_texture_path, format = "jpeg")

# Preview in R
print(earth_image)

# Render globe with colored texture and no atmosphere
globejs(
  img = adjusted_texture_path,
  atmosphere = FALSE,  # Disable blue glow
  bg = "black"
)


