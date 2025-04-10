# Load libraries
library(threejs)
library(magick)  # For image processing

# Define file paths
original_texture_path <- "envisat_earth_texture.jpg"
adjusted_texture_path <- "adjusted_envisat_earth_texture.jpg"

# URL of the new high-res Earth image from ESA
image_url <- "https://www.esa.int/var/esa/storage/images/esa_multimedia/images/2005/05/envisat_mosaic_may_-_november_2004/9695811-3-eng-GB/Envisat_mosaic_May_-_November_2004_pillars.jpg"

# Download the image if it doesn’t exist
if (!file.exists(original_texture_path)) {
  download.file(image_url, destfile = original_texture_path, mode = "wb")
}

# Load the image
earth_image <- image_read(original_texture_path)

# Adjust brightness, contrast, and color balance
earth_image <- earth_image %>%
  image_modulate(brightness = 90, saturation = 130, hue = 100) %>%  # Adjust values as needed
  image_resize("8192x4096!")  # Increase resolution for better texture quality

# Crop out any unnecessary borders (if applicable)
earth_image <- image_crop(earth_image, "8192x4096+0+0")  # Ensure perfect 2:1 aspect ratio

# Save the final adjusted image
image_write(earth_image, adjusted_texture_path, format = "jpeg")

# Preview the image in R (to confirm the colors are correct)
print(earth_image)

# Create the interactive globe using the adjusted image
globejs(
  img = adjusted_texture_path,  # Use the properly formatted texture
  atmosphere = TRUE,   # Enable glow effect
  bg = "black"         # Dark background for better contrast
)


