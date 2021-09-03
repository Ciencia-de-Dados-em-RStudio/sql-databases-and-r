##The portal_mammals database

#We will continue to explore the surveys data you are already familiar with from previous 
#lessons. 
#First, we are going to install the dbplyr package:
install.packages(c("dbplyr", "RSQLite"))

#The SQLite database is contained in a single file portal_mammals.sqlite that you generated during the SQL lesson. 
#If you don’t have it, you can download it from Figshare into the data_raw subdirectory using:
dir.create("./data_raw", showWarnings = FALSE)
download.file(url = "https://ndownloader.figshare.com/files/2292171",
              destfile = "./data_raw/portal_mammals.sqlite", mode = "wb")

##Connecting to databases
#We can point R to this database using:
  
library(dplyr)
library(dbplyr)

#This command uses 2 packages that helps dbplyr and dplyr talk to the SQLite database. 
#DBI is not something that you’ll use directly as a user. 
#It allows R to send commands to databases irrespective of the database management system used.
mammals <- DBI::dbConnect(RSQLite::SQLite(), "data_raw/portal_mammals.sqlite")
#This command does not load the data into the R session (as the read_csv() function did). 
#Instead, it merely instructs R to connect to the SQLite database contained in the portal_mammals.sqlite file.

#Let’s take a closer look at the mammals database we just connected to:
src_dbi(mammals)

#src:  sqlite 3.36.0 [/Users/jpalbino/Library/Mobile Documents/com~apple~CloudDocs/GitHub/sql-databases-and-r/data_raw/portal_mammals.sqlite]
#tbls: plots, species, surveys

#Just like a spreadsheet with multiple worksheets, a SQLite database can contain multiple tables. 
#In this case three of them are listed in the tbls row in the output above:
#•	plots
#•	species
#•	surveys
#Now that we know we can connect to the database, let’s explore how to get the data from its tables into R.

##Querying the database with the SQL syntax
#To connect to tables within a database, you can use the tbl() function from dplyr. 
#This function can be used to send SQL queries to the database. 
#To demonstrate this functionality, let’s select the columns “year”, “species_id”, and “plot_id” from the surveys table:
tbl(mammals, sql("SELECT year, species_id, plot_id FROM surveys"))
# Source:   SQL [?? x 3]
# Database: sqlite 3.36.0 [/Users/jpalbino/Library/Mobile
#   Documents/com~apple~CloudDocs/GitHub/sql-databases-and-r/data_raw/portal_mammals.sqlite]
#    year species_id plot_id
#   <int> <chr>        <int>
# 1  1977 NL               2
# 2  1977 NL               3
# 3  1977 DM               2
# 4  1977 DM               7
# 5  1977 DM               3
# 6  1977 PF               1
# 7  1977 PE               2
# 8  1977 DM               1
# 9  1977 DM               1
#10  1977 PF               6
# … with more rows

#With this approach you can use any of the SQL queries we have seen in the database lesson.
##Querying the database with the dplyr syntax

#One of the strengths of dplyr is that the same operation can be done using dplyr’s verbs instead of writing SQL. 
#First, we select the table on which to do the operations by creating the surveys object, and then we use the standard dplyr syntax as if it were a data frame:
surveys <- tbl(mammals, "surveys")
surveys %>%
  select(year, species_id, plot_id)
#In this case, the surveys object behaves like a data frame. Several functions that can be used with data frames can also be used on tables from a database. 
#For instance, the head() function can be used to check the first 10 rows of the table:
# Source:   lazy query [?? x 3]
# Database: sqlite 3.36.0 [/Users/jpalbino/Library/Mobile
#   Documents/com~apple~CloudDocs/GitHub/sql-databases-and-r/data_raw/portal_mammals.sqlite]
#      year species_id plot_id
#    <int> <chr>        <int>
# 1  1977 NL               2
# 2  1977 NL               3
# 3  1977 DM              2
# 4  1977 DM              7
# 5  1977 DM              3
# 6  1977 PF               1
# 7  1977 PE               2
# 8  1977 DM              1
# 9  1977 DM              1
#10  1977 PF              6
# … with more rows

#In this case, the surveys object behaves like a data frame. Several functions that can be used with data frames can also be used on tables from a database. 
#For instance, the head() function can be used to check the first 10 rows of the table:
head(surveys, n = 10)
# Source:   lazy query [?? x 9]
# Database: sqlite 3.36.0 [/Users/jpalbino/Library/Mobile
#   Documents/com~apple~CloudDocs/GitHub/sql-databases-and-r/data_raw/portal_mammals.sqlite]
#    record_id month   day  year plot_id species_id sex   hindfoot_length weight
#        <int> <int> <int> <int>   <int> <chr>      <chr>           <int>  <int>
#  1         1     7    16  1977       2 NL         M                  32     NA
#  2         2     7    16  1977       3 NL         M                  33     NA
#  3         3     7    16  1977       2 DM         F                  37     NA
#  4         4     7    16  1977       7 DM         M                  36     NA
#  5         5     7    16  1977       3 DM         M                  35     NA
#  6         6     7    16  1977       1 PF         M                  14     NA
#  7         7     7    16  1977       2 PE         F                  NA     NA
#  8         8     7    16  1977       1 DM         M                  37     NA
#  9         9     7    16  1977       1 DM         F                  34     NA
# 10        10     7    16  1977       6 PF         F                  20     NA

#This output of the head command looks just like a regular data.frame: 
#The table has 9 columns and the head() command shows us the first 10 rows. 

#However, some functions don’t work quite as expected. 
#For instance, let’s check how many rows there are in total using nrow():
nrow(surveys)
#[1] NA

#That’s strange - R doesn’t know how many rows the surveys table contains - it returns NA instead. 
#You might have already noticed that the first line of the head() output included ?? indicating that 
#the number of rows wasn’t known.
#The reason for this behavior highlights a key difference between using dplyr on datasets in memory 
#(e.g. loaded into your R session via read_csv()) and those provided by a database. 
#To understand it, we take a closer look at how dplyr communicates with our SQLite database.

#For example, the following SQL query returns the first 10 rows from the surveys table:
#SELECT *
#FROM `surveys`
#LIMIT 10

#Behind the scenes, dplyr:
#translates your R code into SQL
#submits it to the database
#translates the database’s response into an R data frame
#To lift the curtain, we can use dplyr’s show_query() function to show which SQL commands are actually sent to the database:
show_query(head(surveys, n = 10))

#dplyr can translate many different query types into SQL allowing us to, e.g., select() specific columns, filter() rows, or join tables.
#To see this in action, let’s compose a few queries with dplyr.

##Simple database queries
#First, let’s only request rows of the surveys table in which weight is less than 5 and keep only the species_id, sex, and weight columns.
surveys %>%
  filter(weight < 5) %>%
  select(species_id, sex, weight)
# Source:   lazy query [?? x 3]
# Database: sqlite 3.36.0 [/Users/jpalbino/Library/Mobile
#   Documents/com~apple~CloudDocs/GitHub/sql-databases-and-r/data_raw/portal_mammals.sqlite]
#species_id sex   weight
#    <chr>      <chr>  <int>
#  1 PF         M          4
#  2 PF         F          4
#  3 PF         NA         4
#  4 PF         F          4
#  5 PF         F          4
#  6 RM         M          4
#  7 RM         F          4
#  8 RM         M          4
#  9 RM         M          4
# 10 RM         M          4
# … with more rows







