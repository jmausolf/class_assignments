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


#Past Speakers
fall_speakers <- c('luis_bettencourt', 'ben_zhao', 'santo_fortunato', 'damon_centola', 'guanglei_hong')

#Current Speakers
speakers <- c('ali_hortacsu', 'anna_mueller', 'james_evans', 'richard_evans')
dates <- c('2018-01-11', '2018-01-18', '2018-01-25', '2018-02-01')


#######################################
## Functions
#######################################

make_weekly_report <- function(speaker, workshop_date = NULL, total_comments = FALSE){
  
  url_base <- "https://api.github.com/repos/uchicago-computation-workshop/NAME/issues?per_page=1000"
  url <- str_replace(url_base, "NAME", speaker)
  print(url)

  issues <- fromJSON(url, simplifyDataFrame = FALSE)
  comments <- as.Node(issues)
  df <- comments %>% ToDataFrameTable(
    username = function(x) x$user$login,
    userid = function(x) x$user$id,
    "title",
    "body",
    "created_at") %>%
    arrange(created_at) %>% #sort from oldest to newest 
    mutate(date = as.Date(created_at)) %>%
    unique()
    
    # keep only the first comment from a user (if more than one) for a speaker
    if(isTRUE(total_comments)){
      print("[*] keeping all comments per speaker");
    } else
      print("[*] keeping only single comment per speaker");
      df <- df %>% distinct(username, userid, .keep_all = TRUE);


    # keep only comments before or on workshop date
    if(is_null(workshop_date)){
      print("[*] comments on all dates accepted")
    } else {
      print(paste("[*] keeping only comments before or day of workshop:", as.character(workshop_date), sep = " "))
      df <- df %>% filter(date <=  workshop_date)
    }

    return(df)
}


make_report <- function(speakers, dates, total_comments = TRUE){

  output <- vector("list", length(speakers))
  
  if(is_null(dates)){
    
    if(isTRUE(total_comments)){
      for(i in seq_along(output)){
        output[[i]] <- make_weekly_report(speakers[[i]], NULL, total_comments = TRUE)
      } ;
    }
    
    if(!isTRUE(total_comments)){
      for(i in seq_along(output)){
        output[[i]] <- make_weekly_report(speakers[[i]], NULL, total_comments = FALSE)
      } ;
    }
  } else {
    if(isTRUE(total_comments)){
      for(i in seq_along(output)){
        output[[i]] <- make_weekly_report(speakers[[i]], dates[[i]], total_comments = TRUE)
        } ;
    }
  
    if(!isTRUE(total_comments)){
      for(i in seq_along(output)){
        output[[i]] <- make_weekly_report(speakers[[i]], dates[[i]], total_comments = FALSE)
        } ;
    }
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
#######################################

comments_full <- make_report(speakers, NULL, total_comments = TRUE)
comments_single <- make_report(speakers, NULL, total_comments = FALSE)
comments_single_dated <- make_report(speakers, dates, total_comments = FALSE)

#graph of contributions
comments_single_dated %>%
  mutate(date = as.Date(created_at)) %>%
  group_by(date) %>%
  mutate(daily_count = n()) %>%
  unique() %>%
  ggplot(aes(date, daily_count)) +
    geom_line() +
    geom_point()
ggsave("contributions.png")



#######################################
## Load Usernames, Full Names File
#######################################

fullnames <- read_csv("github_usernames_full_names.csv") %>%
  rename(username = 'GitHub User ID',
         fullname = 'Full Legal Name (Lastname, First Middle)',
         email = 'University of Chicago Email') %>%
  filter(!is.na(username))



#######################################
## Merge and Make Reports
#######################################


#Report (Single Comments, Date Resticted)
report_single_dated <- full_join(comments_single_dated, fullnames) %>%
  select(fullname, username, userid, email, total_count) %>%
  arrange(fullname) %>%
  arrange(desc(total_count)) %>%
  filter(!is.na(fullname)) %>%
  unique() %>%
  write_csv("report_single_weekly_comment_MACSS.csv", col_names = TRUE)



#Report (Single Comments)
report_single <- full_join(comments_single, fullnames) %>%
  select(fullname, username, userid, email, total_count) %>%
  arrange(fullname) %>%
  arrange(desc(total_count)) %>%
  filter(!is.na(fullname)) %>%
  unique() %>%
  write_csv("report_single_weekly_comment_MACSS.csv", col_names = TRUE)



#Report (All Comments)
report_all <- full_join(comments_full, fullnames) %>%
  select(fullname, username, userid, email, total_count) %>%
  arrange(fullname) %>%
  arrange(desc(total_count)) %>%
  filter(!is.na(fullname)) %>%
  unique() %>%
  write_csv("report_all_comments_MACSS.csv", col_names = TRUE)



#Report (Non-MACSS Students/Staff/Facults)
report_non_MACSS <- anti_join(comments_single, fullnames) %>%
  select(username, userid, total_count) %>%
    arrange(desc(total_count)) %>%
    unique() %>%
  write_csv("report_single_weekly_comment_non_MACSS.csv", col_names = TRUE)



