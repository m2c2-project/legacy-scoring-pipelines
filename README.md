# M2C2 Legacy Cognitive Task Data Processing Pipeline

This R script processes cognitive task data from M2C2, from the Survey Dolphin era, including reading, scoring, summarizing, validating, and exporting results. It ensures efficient and reproducible analysis of cognitive performance data.

---

## 📌 Features
- ✅ Reads and processes raw cognitive task data.
- ✅ Scores trial-level performance using **m2c2R**.
- ✅ Summarizes data at both **participant** and **session** levels.
- ✅ Performs **row validation** to check data integrity.
- ✅ Exports processed data into structured output files.

---

## 📜 Example Pipeline
No need to copy-paste from this README! The full example pipeline is available [here](https://github.com/m2c2-project/legacy-scoring-pipelines/blob/main/pipelines/m2c2R_scoring_pipeline.R).

🔹 Use the provided script directly to avoid errors.
🔹 Make sure to update file paths to match your data location.
🔹 If you run into issues, check that all required packages are installed.

Stick to the example pipeline, and you'll be processing data like a pro in no time! 🚀

---

## ⚙️ Prerequisites

### 📦 Required R Packages
Before running the script, make sure you have the following R packages installed:

- `devtools`
- `tidyverse`
- `m2c2R` (installed from GitHub)

### 🖥️ Opening R Properly
Always open this project using the .Rproj file. This ensures that all directory paths remain relative, preventing messy absolute paths that can break your workflow (yuck! 🤢).

Using .Rproj keeps everything organized, reproducible, and hassle-free. 🚀

### 📥 Installation
Run the following commands in **R** to install the necessary packages:

```r
if (!requireNamespace("devtools", quietly = TRUE)) install.packages("devtools")
if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")

devtools::install_github("nelsonroque/m2c2R", force = TRUE)
library(m2c2R)
library(tidyverse)
```

---

## 🚀 How to Use the Script

### **Step 1: Define Input Data Directory**
📌 **Important Note**: 
- Make sure your raw data files are **organized in a folder**.
- Update the path in `list.files()` to **match your actual data location**.

Please note, the path in the example code below, 'data/out_2022_05_26/' is just a placeholder,

🔹 Make sure to update it to match the actual location of your data files.
🔹 If your data is stored elsewhere, replace this with the correct folder path in the script:

```r
files_in_zip <- list.files('data/out_2022_05_26/', recursive = TRUE, full.names = TRUE)
print(files_in_zip) # Check that the files are correctly listed
```

---

### **Step 2: Identify Cognitive Task Files**
📌 **Important Note**:
- Be sure you **know the exact names** of your cognitive tasks.
- The script will search for files containing `"Dot-Memory_"` and `"Symbol-Search_"`. If your task names are different, **update these patterns** accordingly.

```r
fn_cogtask_dotmemory <- files_in_zip[grepl("Dot-Memory_", files_in_zip)]
fn_cogtask_symbolsearch <- files_in_zip[grepl("Symbol-Search_", files_in_zip)]
```

---

### **Step 3: Read Raw Cognitive Data**
The function `read_cog_data()` reads each file and removes duplicates.

```r
read_cog_data <- function(file) {
  if (length(file) > 0) {
    return(m2c2R::read_m2c2_local(file, na = ".") %>% distinct())
  } else {
    warning(paste("No file found for:", file))
    return(NULL)
  }
}

raw_cogtask_dotmemory <- read_cog_data(fn_cogtask_dotmemory)
raw_cogtask_symbolsearch <- read_cog_data(fn_cogtask_symbolsearch)
```

---

### **Step 4: Score Trial-Level Data**
Each task is scored using its corresponding M2C2 function.

```r
score_task <- function(raw_data, score_function) {
  if (!is.null(raw_data)) {
    return(score_function(raw_data))
  } else {
    return(NULL)
  }
}

scored_cogtask_dotmemory <- score_task(raw_cogtask_dotmemory, m2c2R::score_dot_memory)
scored_cogtask_symbolsearch <- score_task(raw_cogtask_symbolsearch, m2c2R::score_symbol_search)
```

---

### **Step 5: Summarize Data by Participant**
Summarizes scored data at the **participant level**.

```r
summary_task <- function(scored_data, summary_function, group_vars) {
  if (!is.null(scored_data)) {
    return(summary_function(scored_data, group_var = group_vars))
  } else {
    return(NULL)
  }
}

summary_cogtask_dotmemory_person <- summary_task(scored_cogtask_dotmemory, m2c2R::summary_dot_memory, c("participant_id"))
summary_cogtask_symbolsearch_person <- summary_task(scored_cogtask_symbolsearch, m2c2R::summary_symbol_search, c("participant_id"))
```

---

### **Step 6: Summarize Data by Participant & Session**
Summarizes scored data at the **participant-session level**.

```r
summary_cogtask_dotmemory_personsession <- summary_task(scored_cogtask_dotmemory, m2c2R::summary_dot_memory, c("participant_id", "session_uuid"))
summary_cogtask_symbolsearch_personsession <- summary_task(scored_cogtask_symbolsearch, m2c2R::summary_symbol_search, c("participant_id", "session_uuid"))
```

---

### **Step 7: Data Integrity Check (Row Validation)**
📌 **Important Note**:  
- This ensures that **scoring did not affect the number of rows**.
- A `"PASS"` message means the row count before and after scoring is the same.

```r
validate_rows <- function(raw_data, scored_data, task_name) {
  if (!is.null(raw_data) && !is.null(scored_data)) {
    same_rows <- nrow(raw_data) == nrow(scored_data)
    message(task_name, ": ", ifelse(same_rows, "PASS", "FAIL"))
    return(same_rows)
  } else {
    return(FALSE)
  }
}

validate_rows(raw_cogtask_dotmemory, scored_cogtask_dotmemory, "Dot Memory")
validate_rows(raw_cogtask_symbolsearch, scored_cogtask_symbolsearch, "Symbol Search")
```

---

### **Step 8: Export Processed Data**
📌 **Important Note**:  
- The script saves output files in the `output/` directory.
- **Change the directory path if needed**.
- **Timestamps can be disabled** by setting `ts = FALSE`.

#### **Export Function**
```r
export_data <- function(data, path = "output/", ts = TRUE, tz = "UTC") {
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
```

#### **Export Data to the Output Folder**
```r
export_data(raw_cogtask_dotmemory, "output/")
export_data(raw_cogtask_symbolsearch, "output/")

export_data(scored_cogtask_dotmemory, "output/")
export_data(scored_cogtask_symbolsearch, "output/")

export_data(summary_cogtask_dotmemory_person, "output/")
export_data(summary_cogtask_symbolsearch_person, "output/")

export_data(summary_cogtask_dotmemory_personsession, "output/")
export_data(summary_cogtask_symbolsearch_personsession, "output/")
```

---

### ✅ **Final Step: Completion Message**
Once the script runs successfully, you’ll see:

```r
message("Data processing completed successfully!")
```

---

## 📂 Output Files
By default, processed data files will be stored in:

📁 **`output/` directory**

| File Type | Description |
|-----------|-------------|
| `raw_*` | Original raw cognitive task data |
| `scored_*` | Scored trial-level data |
| `summary_*_person` | Summarized data at participant level |
| `summary_*_personsession` | Summarized data at participant-session level |

---

## 📢 Notes & Recommendations
- 🛠 **Double-check your cognitive task filenames** (`Dot-Memory_`, `Symbol-Search_`). Adjust the script if necessary.
- 💾 **Change the export path** if you prefer to store output elsewhere.
- ⏳ **Run row validation** to confirm data integrity after scoring.

---

## 🎯 Conclusion
This script efficiently processes cognitive task data, ensuring structured outputs for further analysis. 🚀 Happy analyzing!
