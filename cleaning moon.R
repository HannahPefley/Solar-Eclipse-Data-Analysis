library(dplyr)
library(lubridate)
library(readr)
library(zoo)

# Set file paths (adjust these paths according to your actual file locations)
input_file <- "OriginalMoonData.csv"
#output_file <- "testingcleaningofmoon.csv"

# Read data from CSV
data <- read_csv(input_file)

# Function to convert degrees and minutes to decimal degrees
convert_to_decimal <- function(degrees, minutes, direction) {
  # Check if direction is NA
  if (is.na(direction)) {
    return(NA)
  }
  
  degrees <- as.numeric(degrees)
  minutes <- as.numeric(substring(minutes, 1, nchar(minutes) - 1))
  
  if (direction == "N") {
    return(degrees + minutes / 60)
  } else if (direction == "S") {
    return(-(degrees + minutes / 60))
  } else if (direction == "E") {
    return(degrees + minutes / 60)
  } else if (direction == "W") {
    return(-(degrees + minutes / 60))
  } else {
    return(NA)  # Handle any other cases as needed
  }
}

# Apply conversion function row-wise to create new columns for decimal degrees
data_with_decimals <- data %>%
  rowwise() %>%
  mutate(
    Northern_Latitude_Decimal = convert_to_decimal(NorthernLimLat1, NorthernLimLat2, substr(NorthernLimLat2, nchar(NorthernLimLat2), nchar(NorthernLimLat2))),
    Northern_Longitude_Decimal = convert_to_decimal(NorthernLimLong1, NorthernLimLong2, substr(NorthernLimLong2, nchar(NorthernLimLong2), nchar(NorthernLimLong2))),
    Southern_Latitude_Decimal = convert_to_decimal(SouthernLimLat1, SouthernLimLat2, substr(SouthernLimLat2, nchar(SouthernLimLat2), nchar(SouthernLimLat2))),
    Southern_Longitude_Decimal = convert_to_decimal(SouthernLimLong1, SouthernLimLong2, substr(SouthernLimLong2, nchar(SouthernLimLong2), nchar(SouthernLimLong2))),
    Central_Latitude_Decimal = convert_to_decimal(CentralLineLat1, CentralLineLat2, substr(CentralLineLat2, nchar(CentralLineLat2), nchar(CentralLineLat2))),
    Central_Longitude_Decimal = convert_to_decimal(CentralLineLong1, CentralLineLong2, substr(CentralLineLong2, nchar(CentralLineLong2), nchar(CentralLineLong2)))
    # Add more columns as needed
  ) %>%
  ungroup() 

# Remove columns that are all NA (null)
data_with_decimals <- data_with_decimals %>%
  select(where(~!all(is.na(.))))

# Write cleaned data to CSV, appending new columns
#write_csv(data_with_decimals, file = output_file)

#----------------------------------------------------------------
 #Originally a seperate file, we now take this data and add additional seconds to align with the seconds from our balloon dataset 

# Read the CSV file
#testingcleaningofmoon <- read_csv("testingcleaningofmoon.csv", 
#                                  col_types = cols(Timestamp = col_datetime(format = "%m/%d/%Y %H:%M:%S")))

testingcleaningofmoon <- data_with_decimals

# Adjust the UT column by subtracting 5 hours and rename it to Timestamp
# Create a fixed date string for April 8th, 2024
fixed_date <- "2024-04-08"

# Extract the time part from the UT column
time_part <- format(as.POSIXct(testingcleaningofmoon$UT, format = "%Y-%m-%d %H:%M:%S"), format = "%H:%M:%S")

# Combine the fixed date with the extracted time part
testingcleaningofmoon$Timestamp <- as.POSIXct(paste(fixed_date, time_part), format = "%Y-%m-%d %H:%M:%S") - hours(4)


# Filter out NA timestamps, if any
df <- testingcleaningofmoon[complete.cases(testingcleaningofmoon$Timestamp), ]

# Generate a sequence of timestamps with missing seconds filled in
if (nrow(df) > 1) {
  expanded_times <- data.frame(Timestamp = seq.POSIXt(from = min(df$Timestamp),
                                                      to = max(df$Timestamp),
                                                      by = "1 sec"))
} else {
  expanded_times <- data.frame(Timestamp = df$Timestamp)
}

# Merge expanded times with original data, filling in missing data
expanded_df <- merge(expanded_times, df, by = "Timestamp", all.x = TRUE)
expanded_df <- expanded_df[c("Timestamp", "Central_Latitude_Decimal", "Central_Longitude_Decimal", "Path Width (km)")]

# Interpolate missing values using spline
# Ensure to convert the Timestamp to numeric format for interpolation
timestamps_numeric <- as.numeric(expanded_df$Timestamp)

# Spline interpolation for Central_Latitude_Decimal
lat_spline <- with(expanded_df, spline(timestamps_numeric, Central_Latitude_Decimal, xout = timestamps_numeric))
expanded_df$Central_Latitude_Decimal <- lat_spline$y

# Spline interpolation for Central_Longitude_Decimal
long_spline <- with(expanded_df, spline(timestamps_numeric, Central_Longitude_Decimal, xout = timestamps_numeric))
expanded_df$Central_Longitude_Decimal <- long_spline$y

# Impute missing values in Path Width (km) with the last non-NA value
expanded_df$`Path Width (km)` <- na.locf(expanded_df$`Path Width (km)`)

# Sort by Timestamp (if needed)
expanded_df <- expanded_df[order(expanded_df$Timestamp), ]

# Write the expanded data frame back to CSV
write.csv(expanded_df, "expanded_testingcleaningofmoon.csv", row.names = FALSE)