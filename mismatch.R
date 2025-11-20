library(httr)
library(dplyr)
library(lubridate)
library(ggplot2)
library(purrr)
library(tidyr)
library(jsonlite)

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

cat(sprintf("\n=== Available devices ===\n"))
for (i in seq_along(device_list)) {
  cat(sprintf("%d. %s (MAC: %s)\n", 
              i, 
              device_list[[i]]$deviceName, 
              device_list[[i]]$macAddress))
}

# Date range for data collection
start_date <- "2022-04-01"
end_date <- "2023-05-31"

cat(sprintf("\n=== Collecting data from %s to %s ===\n", start_date, end_date))

dates_to_process <- generate_dates(start_date, end_date)

all_data <- list()
missing_data <- list()
successful_requests <- 0
failed_requests <- 0

# Process only devices at positions 1 and 3 (uHoo 1 and uHoo 4)
device_positions <- c(1, 3)

for (pos in device_positions) {
  device <- device_list[[pos]]
  device_name <- device$deviceName
  mac_address <- device$macAddress
  mode <- "day"
  
  cat(sprintf("\n--- Processing device position %d: %s ---\n", 
              pos, device_name))
  
  for (day in dates_to_process) {
    if (successful_requests %% 50 == 0) {
      cat(sprintf("Progress: %d successful requests so far...\n", successful_requests))
    }
    
    # Check if token needs refresh (tokens last 10 minutes)
    # Refresh token every 100 requests to be safe
    if ((successful_requests + failed_requests) %% 100 == 0 && 
        (successful_requests + failed_requests) > 0) {
      cat("Refreshing bearer token...\n")
      token_response <- POST(
        url = paste0(base_uri, generate_token_endpoint),
        body = list(code = client_id),
        encode = "form"
      )
      data <- content(token_response, "parsed")
      bearer_token <- data$access_token
    }
    
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
      missing_data[[length(missing_data) + 1]] <- list(
        deviceName = device_name,
        date = day
      )
      failed_requests <- failed_requests + 1
      next
    }
    
    device_data_list <- device_data$data
    
    # Handle missing data
    if (is.null(device_data_list) || length(device_data_list) == 0) {
      missing_data[[length(missing_data) + 1]] <- list(
        deviceName = device_name,
        date = day
      )
      failed_requests <- failed_requests + 1
      next
    }
    
    # Add metadata to each data point
    for (j in seq_along(device_data_list)) {
      device_data_list[[j]]$deviceName <- device_name
      device_data_list[[j]]$macAddress <- mac_address
    }
    
    all_data <- c(all_data, device_data_list)
    successful_requests <- successful_requests + 1
  }
}

cat(sprintf("\n=== Data Collection Complete ===\n"))
cat(sprintf("Successful requests: %d\n", successful_requests))
cat(sprintf("Failed/missing requests: %d\n", failed_requests))

# Convert to data frames
data_df <- bind_rows(all_data)
missing_df <- bind_rows(missing_data)

# Analyze what data is actually available
if (nrow(data_df) > 0) {
  cat("\n=== Available Data Summary ===\n")
  
  # Date range with data
  data_df <- data_df %>%
    mutate(datetime = as_datetime(timestamp, tz = "UTC"),
           date = as.Date(datetime))
  
  cat(sprintf("Total records: %d\n", nrow(data_df)))
  cat(sprintf("Actual date range: %s to %s\n", 
              min(data_df$date), max(data_df$date)))
  
  # Summary by device
  device_summary <- data_df %>%
    group_by(deviceName) %>%
    summarise(
      records = n(),
      first_date = min(date),
      last_date = max(date),
      days_with_data = n_distinct(date)
    )
  
  print(device_summary)
  
  # PM2.5 specific data
  pm25_df <- data_df %>%
    select(deviceName, macAddress, datetime, date, pm25) %>%
    mutate(pm25 = as.numeric(pm25)) %>%
    arrange(datetime)
  
  # PM2.5 summary statistics
  cat("\n=== PM2.5 Summary Statistics (µg/m³) ===\n")
  pm25_summary <- pm25_df %>%
    group_by(deviceName) %>%
    summarise(
      mean_pm25 = mean(pm25, na.rm = TRUE),
      median_pm25 = median(pm25, na.rm = TRUE),
      min_pm25 = min(pm25, na.rm = TRUE),
      max_pm25 = max(pm25, na.rm = TRUE),
      sd_pm25 = sd(pm25, na.rm = TRUE)
    )
  
  print(pm25_summary)
  
  # Save all data
  write.csv(data_df, 
            file = sprintf("uhoo_all_data_%s_%s.csv", start_date, end_date), 
            row.names = FALSE)
  
  write.csv(pm25_df, 
            file = sprintf("uhoo_pm25_data_%s_%s.csv", start_date, end_date), 
            row.names = FALSE)
  
  write.csv(missing_df, 
            file = sprintf("uhoo_missing_data_%s_%s.csv", start_date, end_date), 
            row.names = FALSE)
  
  write.csv(device_summary,
            file = sprintf("uhoo_device_summary_%s_%s.csv", start_date, end_date),
            row.names = FALSE)
  
  write.csv(pm25_summary,
            file = sprintf("uhoo_pm25_summary_%s_%s.csv", start_date, end_date),
            row.names = FALSE)
  
  # Create comparison plot for PM2.5
  ggplot(pm25_df, aes(x = datetime, y = pm25, color = deviceName)) +
    geom_line(alpha = 0.7) +
    labs(
      title = "PM2.5 Levels: uHoo 1 vs uHoo 4",
      subtitle = sprintf("%s to %s", start_date, end_date),
      x = "Date/Time (UTC)",
      y = "PM2.5 (µg/m³)",
      color = "Device"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(face = "bold"),
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "bottom"
    )
  
  ggsave(sprintf("uhoo_pm25_comparison_%s_%s.png", start_date, end_date), 
         width = 12, height = 6, dpi = 300)
  
  cat("\n=== Files Created ===\n")
  cat(sprintf("- uhoo_all_data_%s_%s.csv\n", start_date, end_date))
  cat(sprintf("- uhoo_pm25_data_%s_%s.csv\n", start_date, end_date))
  cat(sprintf("- uhoo_device_summary_%s_%s.csv\n", start_date, end_date))
  cat(sprintf("- uhoo_pm25_summary_%s_%s.csv\n", start_date, end_date))
  cat(sprintf("- uhoo_pm25_comparison_%s_%s.png\n", start_date, end_date))
  cat(sprintf("- uhoo_missing_data_%s_%s.csv\n", start_date, end_date))
  
} else {
  cat("\nNo data found for any device in the specified date range.\n")
}