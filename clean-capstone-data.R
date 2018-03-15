library(plyr)
library(dplyr)
library(dbplyr)
library(tidyverse)
library(data.table)
customers_export <- read_csv("~/Documents/DataScienceSpringboard/springboard-capstone/customers_export.csv")
full_email_list <- read_csv("~/Documents/DataScienceSpringboard/springboard-capstone/full-email-listBD.csv")

#Remove rows with no email address from the customer export
customers_export <- customers_export[!(customers_export$Email == "NA"),]

#Join the tables together, matching emails, and keeping all data from both tables
customer_data_full <- join(full_email_list, customers_export, by = "Email")

#Add a unique ID to each row
customer_data_full$ID <- 1:nrow(customer_data_full)
write_csv(customer_data_full, "customers_with_names.csv")

#Remove identifying info
customer_data_full$Email <- NULL
customer_data_full$`First Name` <- NULL
customer_data_full$`Last Name` <- NULL
customer_data_full$`Address1` <- NULL
customer_data_full$`Address2` <- NULL
customer_data_full$`Name` <- NULL

#Save anonymized data
write_csv(customer_data_full, "email-list-anon.csv")


#Remove unneeded columns
customer_data_full$Chakra = NULL
customer_data_full$`Radical Beauty Newsletter Signup`=NULL
customer_data_full$Company = NULL
customer_data_full$Phone = NULL
customer_data_full$`Accepts Marketing` = NULL
customer_data_full$`Tax Exempt` = NULL
customer_data_full$`Province Code` = NULL
customer_data_full$Note = NULL
customer_data_full$`Country Code` = NULL

#Clean up column names
names(customer_data_full)[1]<-"city1"
names(customer_data_full)[2]<-"state"
names(customer_data_full)[3]<-"zip_code"
names(customer_data_full)[4]<-"country1"
names(customer_data_full)[5]<-"bulk_email_status"
names(customer_data_full)[6]<-"unsub_date"
names(customer_data_full)[7]<-"first_campaign"
names(customer_data_full)[8]<-"first_content"
names(customer_data_full)[9]<-"contact_tags"
names(customer_data_full)[10]<-"date_added"
names(customer_data_full)[11]<-"spent_to_date"
names(customer_data_full)[12]<-"last_activity"
names(customer_data_full)[13]<-"city2"
names(customer_data_full)[14]<-"province"
names(customer_data_full)[15]<-"country"
names(customer_data_full)[16]<-"zip"
names(customer_data_full)[17]<-"total_spent_sh"
names(customer_data_full)[18]<-"order_quantity_sh"
names(customer_data_full)[19]<-"tags_sh"
names(customer_data_full)[20]<-"id"

#Combine State and Province columns, with priority for Province info
customer_data_full <- customer_data_full %>%
  mutate(state_corrected = if_else(is.na(province), state, province))

#Combine city1 and city2 columns, with priority for city2 info
customer_data_full <- customer_data_full %>%
  mutate(city_corrected = if_else(is.na(city2), city1, city2))

#Combine zip1 and zip2 columns, with priority for zip2 info
customer_data_full <- customer_data_full %>%
  mutate(zip_corrected = if_else(is.na(zip), zip_code, zip))

#Combine country1 and country columns, with priority for country info
customer_data_full <- customer_data_full %>%
  mutate(country_corrected = if_else(is.na(country), country1, country))

#Turn Contact Tags into a searchable list
customer_data_full <- customer_data_full %>%
  mutate(tags = map(contact_tags, function(x) unlist(strsplit(x, ","))))

#Create Total Spent/per time period to resolve the different lifespans of each customer
#turn date fields from chr to dates
customer_data_full$last_activity <- customer_data_full$last_activity %>% as.POSIXct(format="%m-%d-%Y %I:%M %p")
customer_data_full$date_added <- customer_data_full$date_added %>% as.POSIXct(format="%m-%d-%Y %I:%M %p")

#convert spent_to_date to numeric, by removing dollar sign from beginning and converting
customer_data_full$spent_to_date <- substring(customer_data_full$spent_to_date, 2)
customer_data_full$spent_to_date <- as.numeric(customer_data_full$spent_to_date)
#then create total_spent column from whichever is larger of total_spent_sh or spent_to_date
customer_data_full <- customer_data_full %>%
  mutate(total_spent = if_else(total_spent_sh > spent_to_date & !is.na(total_spent_sh), total_spent_sh, spent_to_date))
#then create lifespan of customer, including through current day, if no Unsub Date is present
customer_data_full <- customer_data_full %>% 
  mutate(lifespan = ifelse(is.na(last_activity), Sys.time() - date_added , last_activity - date_added))
#convert lifespan to days from seconds
customer_data_full$lifespan <- customer_data_full$lifespan / 86400
#minimum lifespan of 1 day (even if they only signed up for an hour, we're still going to say they were 1 day)
customer_data_full$lifespan <- ifelse(customer_data_full$lifespan < 1, 1, customer_data_full$lifespan)
#new column avg_daily_spend_lifespan
customer_data_full$avg_daily_spend_lifespan <- customer_data_full$total_spent / customer_data_full$lifespan


#Save anonymized data
write_csv(customer_data_full, "customer_data_full.csv")
