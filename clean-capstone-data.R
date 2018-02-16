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