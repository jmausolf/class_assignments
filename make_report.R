# Download files

library(curl)
library(tidyverse)
library(rvest)
library(stringr)
library(jsonlite)
library(httr)
#devtools::install_github("gluc/data.tree")
library(data.tree)
library(magrittr)
library(lubridate)


#url <- "https://api.github.com/repos/uchicago-computation-workshop/guanglei_hong/issues"
#url <- "https://api.github.com/repos/uchicago-computation-workshop/guanglei_hong/issues?per_page=1000"

url_base <- "https://api.github.com/repos/uchicago-computation-workshop/NAME/issues?per_page=1000"
speakers <- c('luis_bettencourt', 'ben_zhao', 'santo_fortunato', 'damon_centola', 'guanglei_hong')

for(name in speakers){
  url <- str_replace(url_base, "NAME", name)
  print(url)
}


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

# x <- make_weekly_report("ben_zhao", total_comments = TRUE)
# y <- make_weekly_report("ben_zhao")

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


# speakers <- c('ben_zhao')
# test <- make_report(speakers, total_comments = FALSE)
# 
# 
# output <- vector("list", length(speakers))
# for(i in seq_along(output)){
#   output[[i]] <- make_weekly_report(speakers[[i]])
# }
# 
# df <- do.call(rbind, output)


#graph
graph_df <- df %>% 
  #select(cycle, pid3, pid2, cid, occ) %>% 
  mutate(date = as.Date(created_at)) %>% 
  group_by(date) %>% 
  mutate(daily_count = n()) %>% 
  unique()


ggplot(data = graph_df, aes(date, daily_count)) +
  geom_line()
  

# 
# comments <- df %>% 
#   mutate(date = as.Date(created_at)) %>% 
#   group_by(username) %>% 
#   mutate(total_count = n()) %>% 
#   unique()

# Comments, All
comments_full <- make_report(speakers, total_comments = TRUE)
comments_single <- make_report(speakers, total_comments = FALSE)


#######################################
## Load Usernames, Full Names File

fullnames <- read_csv("github_usernames_full_names.csv") %>%
  rename(username = 'GitHub User ID',
         fullname = 'Full Legal Name (Lastname, First Middle)',
         email = 'University of Chicago Email') %>% 
  select(username, fullname) %>% 
  filter(!is.na(username))


#######################################
## Merge
report0 <- anti_join(comments, fullnames)
report <- full_join(comments, fullnames)

#Example Report (Single Comments)
report_single_weekly_comment <- full_join(comments_single, fullnames) %>% 
  select(fullname, username, userid, total_count) %>% 
  arrange(fullname) %>% 
  arrange(desc(total_count)) %>% 
  unique()


report_all_weekly_comment <- full_join(comments_full, fullnames) %>% 
  select(fullname, username, userid, total_count) %>% 
  arrange(fullname) %>% 
  arrange(desc(total_count)) %>% 
  unique()

