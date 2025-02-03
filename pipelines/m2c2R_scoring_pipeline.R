# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# STEP 1: INSTALL & LOAD REQUIRED PACKAGES ----
if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools")
if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")

devtools::install_github("nelsonroque/m2c2R", force = TRUE)
library(m2c2R)
library(tidyverse)

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

## INSTALL CUSTOM FUNCTIONS ----

read_cog_data <- function(file) {
  if (length(file) > 0) {
    return(m2c2R::read_m2c2_local(file, na = ".") %>% distinct())
  } else {
    warning(paste("No file found for:", file))
    return(NULL)
  }
}

score_task <- function(raw_data, score_function) {
  if (!is.null(raw_data)) {
    return(score_function(raw_data))
  } else {
    return(NULL)
  }
}

summary_task <- function(scored_data, summary_function, group_vars) {
  if (!is.null(scored_data)) {
    return(summary_function(scored_data, group_var = group_vars))
  } else {
    return(NULL)
  }
}

validate_rows <- function(raw_data, scored_data, task_name) {
  if (!is.null(raw_data) && !is.null(scored_data)) {
    same_rows <- nrow(raw_data) == nrow(scored_data)
    message(task_name, ": ", ifelse(same_rows, "PASS", "FAIL"))
    return(same_rows)
  } else {
    return(FALSE)
  }
}

export_data <- function(data, path = getwd(), ts = TRUE, tz = "UTC") {
  dname <- deparse(substitute(data))
  
  # Ensure the output directory exists
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
  
  # Generate timestamp if needed
  if (ts) {
    ts_v <- m2c2R::make_tidy_datetime()
    filename <- paste0(dname, "_", ts_v, ".csv")
  } else {
    filename <- paste0(dname, ".csv")
  }
  
  # Construct full file path
  file_path <- file.path(path, filename)
  
  # Write CSV file
  readr::write_csv(data, file_path)
  
  message("File saved: ", file_path)
}

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# STEP 2: LIST FILES IN DIRECTORY ----
files_in_zip <- list.files('data/out 2022_05_26/', recursive = TRUE, full.names = TRUE)
print(files_in_zip)

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# STEP 3: IDENTIFY COGNITIVE TASK FILES ----
# This would the prefix in the `data` folder
fn_cogtask_dotmemory <- files_in_zip[grepl("Dot-Memory_", files_in_zip)]
fn_cogtask_symbolsearch <- files_in_zip[grepl("Symbol-Search_", files_in_zip)]

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# STEP 4: READ RAW COGNITIVE DATA ----
raw_cogtask_dotmemory <- read_cog_data(fn_cogtask_dotmemory)
raw_cogtask_symbolsearch <- read_cog_data(fn_cogtask_symbolsearch)

# chop ghost cols

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# STEP 5: SCORE TRIAL-LEVEL DATA ----
scored_cogtask_dotmemory <- score_task(raw_cogtask_dotmemory, m2c2R::score_dot_memory)
scored_cogtask_symbolsearch <- score_task(raw_cogtask_symbolsearch, m2c2R::score_symbol_search)

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# STEP 6: SUMMARIZE DATA BY PARTICIPANT ----
summary_cogtask_dotmemory_person <- summary_task(scored_cogtask_dotmemory, m2c2R::summary_dot_memory, c("participant_id"))
summary_cogtask_symbolsearch_person <- summary_task(scored_cogtask_symbolsearch, m2c2R::summary_symbol_search, c("participant_id"))

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# STEP 7: SUMMARIZE DATA BY PARTICIPANT & SESSION ----
summary_cogtask_dotmemory_personsession <- summary_task(scored_cogtask_dotmemory, m2c2R::summary_dot_memory, c("participant_id", "session_uuid"))
summary_cogtask_symbolsearch_personsession <- summary_task(scored_cogtask_symbolsearch, m2c2R::summary_symbol_search, c("participant_id", "session_uuid"))

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# STEP 8: DATA INTEGRITY CHECK (ROW VALIDATION) ----
validate_rows(raw_cogtask_dotmemory, scored_cogtask_dotmemory, "Dot Memory")
validate_rows(raw_cogtask_symbolsearch, scored_cogtask_symbolsearch, "Symbol Search")

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# STEP 9: EXPORT DATA ----
# Create output directory if it doesn’t exist
if (!dir.exists("output")) {
  dir.create("output")
}

# Export raw data
export_data(raw_cogtask_dotmemory, "output/")
export_data(raw_cogtask_symbolsearch, "output/")

# Export scored data
export_data(scored_cogtask_dotmemory, "output/")
export_data(scored_cogtask_symbolsearch, "output/")

# Export summary data
export_data(summary_cogtask_dotmemory_person, "output/")
export_data(summary_cogtask_symbolsearch_person, "output/")

export_data(summary_cogtask_dotmemory_personsession, "output/")
export_data(summary_cogtask_symbolsearch_personsession, "output/")

# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# FINAL MESSAGE ----
message("Data processing completed successfully!")
