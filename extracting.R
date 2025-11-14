library(httr)
library(dplyr)
library(lubridate)
library(ggplot2)
library(purrr)
library(tidyr)
library(jsonlite)
library(dplyr)



# Function to generate dates between start_date and end_date (inclusive)
generate_dates <- function(start_date, end_date) {
  start <- as.Date(start_date)
  end <- as.Date(end_date)
  dates <- seq(start, end, by = "day")
  return(format(dates, "%Y-%m-%d"))
}

# API configuration
base_uri <- "https://api.uhooinc.com/v1/"
generate_token_endpoint <- "generatetoken"
device_list_endpoint <- "devicelist"
device_data_endpoint <- "devicedata"

# Client ID
client_id <- "352720ef7053bc342bb7afdf518e1aa7470b3232da85daec"

# Get bearer token
token_response <- POST(
  url = paste0(base_uri, generate_token_endpoint),
  body = list(code = client_id),
  encode = "form"
)

data <- content(token_response, "parsed")
cat("Get bearer token response:\n")
print(content(token_response, "text"))

bearer_token <- data$access_token  # lasts 10 minutes

# Get device list
device_list_response <- GET(
  url = paste0(base_uri, device_list_endpoint),
  add_headers(Authorization = paste("Bearer", bearer_token))
)

device_list <- content(device_list_response, "parsed")

# Date range for data collection
start_date <- "2022-05-01"
end_date <- "2022-05-30"
dates_to_process <- generate_dates(start_date, end_date)

all_data <- list()
missing_data <- list()

# Process only first device (device_list[[1]])
for (i in 1:1) {
  device <- device_list[[i]]
  device_name <- device$deviceName
  mac_address <- device$macAddress
  mode <- "day"
  
  for (day in dates_to_process) {
    cat(sprintf("Gathering data for %s|%s\n", device_name, day))
    
    # Make request for device data
    response <- POST(
      url = paste0(base_uri, device_data_endpoint),
      add_headers(Authorization = paste("Bearer", bearer_token)),
      body = list(
        macAddress = mac_address,
        mode = mode,
        prevDateTime = day
      ),
      encode = "form"
    )
    
    device_data <- content(response, "parsed")
    status <- device_data$status
    
    # Check for error status or missing data
    if (!is.null(status) && status == 2) {
      cat(sprintf("No data available for %s on %s: %s\n", 
                  device_name, day, device_data$message))
      missing_data[[length(missing_data) + 1]] <- list(
        deviceName = device_name,
        date = day
      )
      next
    }
    
    device_data_list <- device_data$data
    
    # Handle missing data
    if (is.null(device_data_list) || length(device_data_list) == 0) {
      missing_data[[length(missing_data) + 1]] <- list(
        deviceName = device_name,
        date = day
      )
      next
    }
    
    # Add metadata to each data point
    for (j in seq_along(device_data_list)) {
      device_data_list[[j]]$deviceName <- device_name
      device_data_list[[j]]$macAddress <- mac_address
    }
    
    all_data <- c(all_data, device_data_list)
  }
}

# Convert to data frames
data_df <- bind_rows(all_data)
missing_df <- bind_rows(missing_data)

# Save to CSV
write.csv(data_df, 
          file = sprintf("uhoo_%s_%s.csv", start_date, end_date), 
          row.names = FALSE)
write.csv(missing_df, 
          file = sprintf("uhoo_missing_data_%s_%s.csv", start_date, end_date), 
          row.names = FALSE)


