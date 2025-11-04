# ---- uHoo Partner API ----
library(httr)

# 1. Replace this with your Partner client code
code <- "13fabf19ff7a06bee519861d1f547835305b0788abad3b34"

# 2. Generate access token
token_response <- POST(
  "https://api.uhooinc.com/v1/generatetoken",
  body = list(code = code),
  encode = "form"
)

# Check token response
token_data <- content(token_response, "parsed")
print(token_data)

# Extract the access token
token <- token_data$access_token

# 3. Use the token to get device list
response <- GET(
  "https://api.uhooinc.com/v1/devicelist",
  add_headers(Authorization = paste("Bearer", token))
)

## You can substitute "https://api.uhooinc.com/v1/devicelist" 
  # with any other valid endpoint (e.g. /devicedata).

# 4. View parsed response
content(response, "parsed")








library(httr)

# Generate token
code <- "13fabf19ff7a06bee519861d1f547835305b0788abad3b34"
token_response <- POST(
  "https://api.uhooinc.com/v1/generatetoken",
  body = list(code = code),
  encode = "form"
)
token_data <- content(token_response, "parsed")
token <- token_data$access_token

# Get device data - DAY mode
# Use macAddress (not serialNumber) and proper datetime format
device_data_day <- POST(
  "https://api.uhooinc.com/v1/devicedata",
  add_headers(Authorization = paste("Bearer", token)),
  body = list(
    macAddress = "e415f654da82",  # Use macAddress from your device list
    mode = "day",
    prevDateTime = "2025-03-01 00:00:00"  # Use YYYY-MM-DD 00:00:00 format for day mode
  ),
  encode = "form"
)

# View the response
content(device_data_day, "parsed")

