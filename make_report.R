# Download files

library(curl)
library(geonames)
library(tidyverse)
library(rvest)
library(stringr)
library(jsonlite)
library(httr)

url <- "https://api.github.com/repos/uchicago-computation-workshop/guanglei_hong/issues"
url <- "https://api.github.com/repos/uchicago-computation-workshop/guanglei_hong/issues?per_page=1000"

json_file <- fromJSON(url, flatten = TRUE) %>% 
  select(user.login, user.id, body, everything() ) %>% 
  unique()

