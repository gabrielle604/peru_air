library(httr)
library(dplyr)
library(lubridate)

# Extract the data from your API response
response_data <- content(device_data_day, "parsed")

# Convert the nested list to a data frame
df <- bind_rows(response_data$data)

# Convert Unix timestamp to datetime
df <- df %>%
  mutate(
    datetime = as_datetime(timestamp, tz = "UTC"),
    # If you want local time (UTC-5 for Bogota)
    datetime_local = with_tz(datetime, tzone = "America/Bogota")
  )

# View the data
print(df)

# Or view specific columns
df %>%
  select(datetime_local, temperature, humidity, pm25, co2, tvoc) %>%
  head(10)





library(purrr)

# Function to fetch device data
get_device_data <- function(mac_address, date, token) {
  response <- POST(
    "https://api.uhooinc.com/v1/devicedata",
    add_headers(Authorization = paste("Bearer", token)),
    body = list(
      macAddress = mac_address,
      mode = "day",
      prevDateTime = paste(date, "00:00:00")
    ),
    encode = "form"
  )
  
  data <- content(response, "parsed")
  
  if (!is.null(data$data) && length(data$data) > 0) {
    df <- bind_rows(data$data)
    df$macAddress <- mac_address
    df$date <- date
    return(df)
  }
  return(NULL)
}

# Your devices
devices <- c(
  "e415f654da82",  # uHoo 1
  "60b6e1afeedc",  # uHoo 2
  "60b6e1af59e1",  # uHoo 4
  "60b6e1af6f4f"   # uHoo 5
)

# Date range
dates <- seq(as.Date("2025-02-01"), as.Date("2025-03-01"), by = "day")

# Fetch all data (this will take time - consider adding Sys.sleep() between calls)
all_data <- map_dfr(devices, function(device) {
  map_dfr(dates, function(date) {
    cat("Fetching", device, "for", as.character(date), "\n")
    Sys.sleep(1)  # Be polite to the API
    get_device_data(device, as.character(date), token)
  })
})

# Convert timestamps and clean up
all_data <- all_data %>%
  mutate(
    datetime = as_datetime(timestamp, tz = "UTC"),
    datetime_local = with_tz(datetime, tzone = "America/Bogota")
  ) %>%
  select(macAddress, datetime, datetime_local, everything(), -timestamp, -date)

# Save to file
write.csv(all_data, "uhoo_data.csv", row.names = FALSE)









df %>%
  group_by() %>%
  summarise(
    mean_temp = mean(temperature, na.rm = TRUE),
    mean_humidity = mean(humidity, na.rm = TRUE),
    mean_pm25 = mean(pm25, na.rm = TRUE),
    mean_co2 = mean(co2, na.rm = TRUE),
    mean_tvoc = mean(tvoc, na.rm = TRUE)
  )