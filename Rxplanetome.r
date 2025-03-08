# Install required packages if not already installed
if (!requireNamespace("openai", quietly = TRUE) ||
    !requireNamespace("jsonlite", quietly = TRUE) ||
    !requireNamespace("optparse", quietly = TRUE) ||
    !requireNamespace("crayon", quietly = TRUE) ||
    !requireNamespace("knitr", quietly = TRUE) ||
    !requireNamespace("rstudioapi", quietly = TRUE)) {
  install.packages(c("openai", "jsonlite", "optparse", "crayon", "knitr", "rstudioapi"))
}

library(openai)
library(jsonlite)
library(optparse)
library(crayon)
library(knitr)
library(rstudioapi)

display_help <- function() {
  cat(bold("Rxplanetome - An R tool for explaining code using AI\n\n"))
  cat("Usage:\n")
  cat("  1. Command Line: Rscript Rxplanetome.r [options]\n")
  cat("  2. In R/RStudio: source('Rxplanetome.r') then use rxplain() function\n\n")
  cat("Command Line Options:\n")
  cat("  --file=PATH     Path to the code file to explain\n")
  cat("  --model=MODEL   AI model to use (default: gpt-4o)\n")
  cat("  --markdown      Output explanation in markdown format\n")
  cat("  --output=PATH   Save explanation to file\n")
  cat("  --help          Display this help message\n\n")
  cat("rxplain() Function Usage:\n")
  cat("  rxplain(code_snippet = NULL, all = FALSE, model = \"gpt-4o\", markdown = FALSE, output = NULL)\n\n")
  cat("rxplain() Parameters:\n")
  cat("  code_snippet    Direct code snippet to explain (optional)\n")
  cat("  all             If TRUE, explains the entire current document in RStudio\n")
  cat("  model           AI model to use (default: gpt-4o)\n")
  cat("  markdown        If TRUE, outputs explanation in markdown format\n")
  cat("  output          Path to save explanation to file (optional)\n\n")
  cat("Environment Variables:\n")
  cat("  OPENAI_API_KEY  Your OpenAI API key\n\n")
  cat("Examples:\n")
  cat("  1. CLI: Rscript Rxplanetome.r --file=script.R --model=gpt-4o --markdown --output=explanation.md\n")
  cat("  2. In R: rxplain(\"function() { print('hello') }\")\n")
  cat("  3. In RStudio: Select code and run rxplain()\n")
  cat("  4. In RStudio: rxplain(all = TRUE) to explain entire current document\n\n")
  cat("Restrictions:\n")
  cat("  - Limited to R, Rmd, and md files\n")
  cat("  - Maximum file size: 1000 lines\n\n")
}

start_spinner <- function() {
  spinner_chars <- c("-", "\\", "|", "/")
  cat("\r", spinner_chars[1], " Generating explanation... ")
  
  i <- 1
  progress_timer <- NULL
  
  progress_timer <<- later::later(function() {
    repeat {
      i <<- (i %% length(spinner_chars)) + 1
      cat("\r", spinner_chars[i], " Generating explanation... ")
      Sys.sleep(0.1)
    }
  }, 0)
  
  return(progress_timer)
}

stop_spinner <- function(timer) {
  if (!is.null(timer)) {
    later::cancel(timer)
  }
  cat("\r                             \r")
}

option_list <- list(
  make_option(c("--file"), type="character", default=NULL, 
              help="Path to the code file to explain"),
  make_option(c("--model"), type="character", default="gpt-4o", 
              help="AI model to use [default: gpt-4o]"),
  make_option(c("--markdown"), action="store_true", default=FALSE,
              help="Output explanation in markdown format"),
  make_option(c("--output"), type="character", default=NULL,
              help="Save explanation to file"),
  make_option(c("--help"), action="store_true", default=FALSE,
              help="Display help message")
)

opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

if (opt$help) {
  display_help()
  quit(save="no", status=0)
}

api_key <- Sys.getenv("OPENAI_API_KEY")
if (api_key == "") {
  cat(red(bold("Error: OPENAI_API_KEY environment variable not set.\n")))
  cat("Please set your API key using:\n")
  cat("  Sys.setenv(OPENAI_API_KEY = 'your-api-key')\n")
  cat("  # or in terminal: export OPENAI_API_KEY='your-api-key'\n\n")
  quit(save="no", status=1)
}

Sys.setenv(OPENAI_API_KEY = api_key)

filename <- opt$file
if (is.null(filename)) {
  cat(blue("No file specified. Please select a file using the file dialog.\n"))
  filename <- file.choose()
}

if (!file.exists(filename)) {
  cat(red(bold("Error: File not found - ")), filename, "\n")
  quit(save="no", status=1)
}

code <- tryCatch(
  {
    readChar(filename, file.info(filename)$size)
  },
  error = function(e) {
    cat(red(bold("Failed to read file: ")), conditionMessage(e), "\n")
    quit(save="no", status=1)
  }
)

explain_code <- function(code, filename = NULL, model = "gpt-4o") {
  # Determine filename if not provided
  if (is.null(filename)) {
    filename_part <- "code snippet"
  } else {
    filename_part <- paste("the file", basename(filename))
  }
  
  chat_messages <- list(
    list(role = "system", content = "Your name is BinkyBonky and You are a knowledgeable AI trained to explain code to people."),
    list(role = "user", content = paste("Please explain the following code from", filename_part, "and how to use it:\n", code))
  )
  
  response <- tryCatch(
    {
      openai$ChatCompletion$create(
        model = model,
        messages = chat_messages,
        temperature = 0.7,
        top_p = 1,
        frequency_penalty = 0,
        presence_penalty = 0
      )
    },
    error = function(e) {
      cat(red(bold("Failed to generate explanation: ")), conditionMessage(e), "\n")
      return(paste("Error: Failed to generate explanation -", conditionMessage(e)))
    }
  )
  
  explanation <- fromJSON(toJSON(response))$choices[[1]]$message$content
  return(explanation)
}

# Function to check if a file is valid and safe to process
is_valid_file <- function(filepath) {
  # Check if file exists
  if (!file.exists(filepath)) {
    return(list(valid = FALSE, reason = paste("File not found:", filepath)))
  }
  
  # Check file extension
  file_ext <- tolower(tools::file_ext(filepath))
  valid_extensions <- c("r", "rmd", "md")
  if (!(file_ext %in% valid_extensions)) {
    return(list(valid = FALSE, reason = paste("Invalid file type:", file_ext, ". Only R, Rmd, and md files are supported.")))
  }
  
  # Check file size (line count)
  line_count <- length(readLines(filepath))
  if (line_count > 1000) {
    return(list(valid = FALSE, reason = paste("File too large:", line_count, "lines. Maximum allowed is 1000 lines.")))
  }
  
  return(list(valid = TRUE, reason = ""))
}

# Main function for importable usage
rxplain <- function(code_snippet = NULL, all = FALSE, model = "gpt-4o", markdown = FALSE, output = NULL) {
  # Check if API key is set
  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (api_key == "") {
    cat(red(bold("Error: OPENAI_API_KEY environment variable not set.\n")))
    cat("Please set your API key using:\n")
    cat("  Sys.setenv(OPENAI_API_KEY = 'your-api-key')\n")
    return(invisible(NULL))
  }
  
  # Determine what code to explain
  if (!is.null(code_snippet)) {
    # Explain provided code snippet
    code <- code_snippet
    filename <- NULL
  } else if (all && requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    # Explain entire current document
    context <- rstudioapi::getSourceEditorContext()
    code <- context$contents
    filename <- context$path
    
    # Verify file is valid for processing
    if (filename != "") {
      validity <- is_valid_file(filename)
      if (!validity$valid) {
        cat(red(bold(validity$reason)), "\n")
        return(invisible(NULL))
      }
    }
  } else {
    # Try to get selection from RStudio
    if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
      context <- rstudioapi::getSourceEditorContext()
      selection <- context$selection[[1]]
      if (selection$text != "") {
        code <- selection$text
        filename <- context$path
      } else {
        # No selection, ask for file
        cat(blue("No code selected. Please select a file using the file dialog.\n"))
        filename <- file.choose()
        
        # Verify file is valid for processing
        validity <- is_valid_file(filename)
        if (!validity$valid) {
          cat(red(bold(validity$reason)), "\n")
          return(invisible(NULL))
        }
        
        code <- readChar(filename, file.info(filename)$size)
      }
    } else {
      # Not in RStudio, ask for file
      cat(blue("Please select a file using the file dialog.\n"))
      filename <- file.choose()
      
      # Verify file is valid for processing
      validity <- is_valid_file(filename)
      if (!validity$valid) {
        cat(red(bold(validity$reason)), "\n")
        return(invisible(NULL))
      }
      
      code <- readChar(filename, file.info(filename)$size)
    }
  }
  
  if (!is.null(filename) && filename != "") {
    cat(blue("Analyzing file: "), basename(filename), "\n")
  } else {
    cat(blue("Analyzing code snippet\n"))
  }
  cat(blue("Using model: "), model, "\n")
  
  timer <- NULL
  if (requireNamespace("later", quietly = TRUE)) {
    timer <- start_spinner()
  }
  
  explanation <- explain_code(code, filename, model = model)
  
  if (!is.null(timer)) {
    stop_spinner(timer)
  }
  
  if (markdown) {
    cat(blue(bold("\nExplanation (Markdown):\n\n")))
    cat(explanation, "\n")
  } else {
    cat(green(bold("\nExplanation:\n\n")))
    cat(explanation, "\n")
  }
  
  if (!is.null(output)) {
    output_file <- output
    tryCatch(
      {
        writeLines(explanation, output_file)
        cat(blue("\nExplanation saved to: "), output_file, "\n")
      },
      error = function(e) {
        cat(red(bold("Failed to save explanation: ")), conditionMessage(e), "\n")
      }
    )
  }
  
  # Return explanation invisibly for programmatic use
  return(invisible(explanation))
}

# CLI script execution part
if (!interactive()) {
  cat(blue("Analyzing file: "), basename(filename), "\n")
  cat(blue("Using model: "), opt$model, "\n")
  
  timer <- NULL
  if (requireNamespace("later", quietly = TRUE)) {
    timer <- start_spinner()
  }
  
  explanation <- explain_code(code, filename, model = opt$model)
  
  if (!is.null(timer)) {
    stop_spinner(timer)
  }
  
  if (opt$markdown) {
    cat(blue(bold("\nExplanation (Markdown):\n\n")))
    cat(explanation, "\n")
  } else {
    cat(green(bold("\nExplanation:\n\n")))
    cat(explanation, "\n")
  }
  
  if (!is.null(opt$output)) {
    output_file <- opt$output
    tryCatch(
      {
        writeLines(explanation, output_file)
        cat(blue("\nExplanation saved to: "), output_file, "\n")
      },
      error = function(e) {
        cat(red(bold("Failed to save explanation: ")), conditionMessage(e), "\n")
      }
    )
  }
}
