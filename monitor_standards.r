# ------------------------------------------------------------------------------
# ---- NHS Standards & Collections Monitor ----

# ------------------------------------------------------------------------------

# Set CRAN mirror for packages
options(repos="https://cloud.r-project.org/")

# Install packages needed to temp folder
install.packages(c("rvest", "dplyr", "readr", "digest", "stringr"))

# Load packages needed from library into workspace
library(rvest)
library(dplyr)
library(readr)
library(digest)
library(stringr)

# Set url to webscrape from 
url <- "https://digital.nhs.uk/data-and-information/information-standards/governance/latest-activity/standards-and-collections"

# ------------------------------------------------------------------------------
# Scrape page 
page <- read_html(url)

# Extract all tables (Approved + Current + Draft)
tables <- page |> html_elements("table")

data_list <- lapply(tables, html_table)

data <- bind_rows(data_list)

# Clean column names
names(data) <- make.names(names(data))

# Remove empty rows
data <- data |> filter(if_any(everything(), ~ !is.na(.)))

# ------------------------------------------------------------------------------
# Create fingerprint 
current_hash <- digest(data, algo = "md5")

# Load previous hash
hash_file <- "data/last_hash.txt"
snapshot_file <- "data/last_snapshot.csv"

if (file.exists(hash_file)) {
  old_hash <- readLines(hash_file)
} else {
  old_hash <- ""
}

# Compare 
changed <- current_hash != old_hash

cat("Changed:", changed, "\n")

# Save new state
writeLines(current_hash, hash_file)
write_csv(data, snapshot_file)

# Create flag file for GitHub Actions
if (changed) {
  writeLines("changed", "data/change_flag.txt")
} else {
  writeLines("no_change", "data/change_flag.txt")
}
