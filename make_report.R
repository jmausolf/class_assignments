# Download files

library(curl)
library(tidyverse)
library(rvest)
library(stringr)
library(jsonlite)
library(httr)
library(data.tree)
library(magrittr)
library(lubridate)

speakers <- c('luis_bettencourt', 'ben_zhao', 'santo_fortunato', 'damon_centola', 'guanglei_hong')


#######################################
## Functions

make_weekly_report <- function(speaker, total_comments = FALSE){
  
  url_base <- "https://api.github.com/repos/uchicago-computation-workshop/NAME/issues?per_page=1000"
  url <- str_replace(url_base, "NAME", speaker)
  print(url)

  issues <- fromJSON(url, simplifyDataFrame = FALSE)
  comments <- as.Node(issues)
  report_all_comment <- comments %>% ToDataFrameTable(
    username = function(x) x$user$login,
    userid = function(x) x$user$id,
    "title",
    "body",
    "created_at") %>%
    arrange(created_at) %>% #sort from oldest to newest 
    unique()
    
    # keep only the first comment from a user (if more than one) for a speaker
    if(isTRUE(total_comments)){
      return(report_all_comment);
    } else
      report_first_comment <- report_all_comment %>% 
        distinct(username, userid, .keep_all = TRUE) 
      return(report_first_comment);
}


make_report <- function(speakers, total_comments = TRUE){
  
  output <- vector("list", length(speakers))
  
  if(isTRUE(total_comments)){
    for(i in seq_along(output)){
      output[[i]] <- make_weekly_report(speakers[[i]], total_comments = TRUE)
      } ;
  }
    
  if(!isTRUE(total_comments)){
    for(i in seq_along(output)){
      output[[i]] <- make_weekly_report(speakers[[i]], total_comments = FALSE)
      } ;
  }

  df <- do.call(rbind, output) %>% 
    mutate(date = as.Date(created_at)) %>% 
      group_by(username) %>% 
      mutate(total_count = n()) %>% 
      unique()
  return(df)
}


#######################################
## GET Github Comments
comments_full <- make_report(speakers, total_comments = TRUE)
comments_single <- make_report(speakers, total_comments = FALSE)

#graph of contributions
graph_df <- comments_single %>% 
  mutate(date = as.Date(created_at)) %>% 
  group_by(date) %>% 
  mutate(daily_count = n()) %>% 
  unique() %>% 
  ggplot(aes(date, daily_count)) +
    geom_line()


#######################################
## Load Usernames, Full Names File

fullnames <- read_csv("github_usernames_full_names.csv") %>%
  rename(username = 'GitHub User ID',
         fullname = 'Full Legal Name (Lastname, First Middle)',
         email = 'University of Chicago Email') %>% 
  #select(username, fullname) %>% 
  filter(!is.na(username))


#######################################
## Merge and Make Reports


#Example Report (Single Comments)
report_single_weekly_comment <- full_join(comments_single, fullnames) %>% 
  select(fullname, username, userid, email, total_count) %>% 
  arrange(fullname) %>% 
  arrange(desc(total_count)) %>% 
  filter(!is.na(fullname)) %>% 
  unique() %>% 
  write_csv("report_single_weekly_comment_MACSS.csv", col_names = TRUE)


#Example Report (All Comments)
report_all_weekly_comment <- full_join(comments_full, fullnames) %>% 
  select(fullname, username, userid, email, total_count) %>% 
  arrange(fullname) %>% 
  arrange(desc(total_count)) %>%
  filter(!is.na(fullname)) %>% 
  unique() %>% 
  write_csv("report_all_comments_MACSS.csv", col_names = TRUE)


#Example Report (Non-MACSS Students/Staff/Facults)
report_non_MACSS <- anti_join(comments_single, fullnames) %>% 
  select(username, userid, total_count) %>% 
    arrange(desc(total_count)) %>%
    unique() %>% 
  write_csv("report_single_weekly_comment_non_MACSS.csv", col_names = TRUE)


