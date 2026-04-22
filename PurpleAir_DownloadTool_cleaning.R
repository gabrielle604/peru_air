# 7-April-2026

# Load packages
library(readxl)
library(ggplot2)
library(dplyr)
library(stringr)
library(tidyr)
library(tidyverse)
library(janitor)
library(knitr)
library(kableExtra)
library(viridis)  # colorblind-friendly colors
library(httr2)
library(sf)
library(lme4)
library(broom)
library(broom.mixed)
library(osmdata)
library(nnet)
library(forcats)

# sensor history: https://api.purpleair.com/#api-sensors-get-sensor-history

# Fields: pm10.0_atm_a,pm10.0_atm_b,pm10.0_atm,voc_a,voc_b,voc,humidity,humidity_a,humidity_b,
  # temperature,temperature_a,temperature_b,pm2.5_atm_a,pm2.5_atm_b,pm2.5_atm

# date range: 22-01-01 to 26-01-10

# 1-month average

pa_129323 <- read_csv("/Users/gabriellebenoit/Documents/GitHub/peru_air/PurpleAir Download 4-7-2026(1)/129323 2022-01-01 2026-01-10 43200-Minute Average.csv",
                      show_col_types = FALSE
) %>% clean_names()

pa_159005 <- read_csv("/Users/gabriellebenoit/Documents/GitHub/peru_air/PurpleAir Download 4-7-2026(1)/159005 2022-01-01 2026-01-10 43200-Minute Average.csv",
                      show_col_types = FALSE
) %>% clean_names()

pa_159435 <- read_csv("/Users/gabriellebenoit/Documents/GitHub/peru_air/PurpleAir Download 4-7-2026(1)/159435 2022-01-01 2026-01-10 43200-Minute Average.csv",
                      show_col_types = FALSE
) %>% clean_names()

pa_159465 <- read_csv("/Users/gabriellebenoit/Documents/GitHub/peru_air/PurpleAir Download 4-7-2026(1)/159465 2022-01-01 2026-01-10 43200-Minute Average.csv",
                      show_col_types = FALSE
) %>% clean_names()

pa_159599 <- read_csv("/Users/gabriellebenoit/Documents/GitHub/peru_air/PurpleAir Download 4-7-2026(1)/159599 2022-01-01 2026-01-10 43200-Minute Average.csv",
                      show_col_types = FALSE
) %>% clean_names()

pa_180021 <- read_csv("/Users/gabriellebenoit/Documents/GitHub/peru_air/PurpleAir Download 4-7-2026(1)/180021 2022-01-01 2026-01-10 43200-Minute Average.csv",
                      show_col_types = FALSE
) %>% clean_names()

pa_180043 <- read_csv("/Users/gabriellebenoit/Documents/GitHub/peru_air/PurpleAir Download 4-7-2026(1)/180043 2022-01-01 2026-01-10 43200-Minute Average.csv",
                      show_col_types = FALSE
) %>% clean_names()

pa_180073 <- read_csv("/Users/gabriellebenoit/Documents/GitHub/peru_air/PurpleAir Download 4-7-2026(1)/180073 2022-01-01 2026-01-10 43200-Minute Average.csv",
                      show_col_types = FALSE
) %>% clean_names()

pa_180119 <- read_csv("/Users/gabriellebenoit/Documents/GitHub/peru_air/PurpleAir Download 4-7-2026(1)/180119 2022-01-01 2026-01-10 43200-Minute Average.csv",
                      show_col_types = FALSE
) %>% clean_names()

pa_180251 <- read_csv("/Users/gabriellebenoit/Documents/GitHub/peru_air/PurpleAir Download 4-7-2026(1)/180251 2022-01-01 2026-01-10 43200-Minute Average.csv",
                      show_col_types = FALSE
) %>% clean_names()

pa_180321 <- read_csv("/Users/gabriellebenoit/Documents/GitHub/peru_air/PurpleAir Download 4-7-2026(1)/180321 2022-01-01 2026-01-10 43200-Minute Average.csv",
                      show_col_types = FALSE
) %>% clean_names()

# sensors: 129323, 159005, 159435, 159465, 159599, 180021, 180043, 180073, 180119, 180251, 180321

# explicitly add sensor id
pa_129323 <- pa_129323 %>% mutate(sensor_id = "129323")
pa_159005 <- pa_159005 %>% mutate(sensor_id = "159005")
pa_159435 <- pa_159435 %>% mutate(sensor_id = "159435")
pa_159465 <- pa_159465 %>% mutate(sensor_id = "159465")
pa_159599 <- pa_159599 %>% mutate(sensor_id = "159599")
pa_180021 <- pa_180021 %>% mutate(sensor_id = "180021")
pa_180043 <- pa_180043 %>% mutate(sensor_id = "180043")
pa_180073 <- pa_180073 %>% mutate(sensor_id = "180073")
pa_180119 <- pa_180119 %>% mutate(sensor_id = "180119")
pa_180251 <- pa_180251 %>% mutate(sensor_id = "180251")
pa_180321 <- pa_180321 %>% mutate(sensor_id = "180321")


purpleair_all <- bind_rows(
  pa_129323, pa_159005, pa_159435, pa_159465, pa_159599, pa_180021, pa_180043, pa_180073, pa_180119, pa_180251, pa_180321
)

write.csv(purpleair_all, "/Users/gabriellebenoit/Documents/GitHub/peru_air/purpleair_all.csv", row.names = FALSE)
