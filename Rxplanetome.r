install.packages(c("openai", "jsonlite", "optparse", "crayon", "knitr"))

library(openai)
library(jsonlite)
library(optparse)
library(crayon)
library(knitr)

display_help <- function() {
  cat(bold("Rxplanetome - An R tool for explaining code using AI\n\n"))
  cat("Usage:\n")
  cat("  Rscript Rxplanetome.r [options]\n\n")
  cat("Options:\n")
  cat("  --file=PATH     Path to the code file to explain\n")
  cat("  --model=MODEL   AI model to use (default: gpt-4o)\n")
  cat("  --markdown      Output explanation in markdown format\n")
  cat("  --output=PATH   Save explanation to file\n")
  cat("  --help          Display this help message\n\n")
  cat("Environment Variables:\n")
  cat("  OPENAI_API_KEY  Your OpenAI API key\n\n")
  cat("Example:\n")
  cat("  Rscript Rxplanetome.r --file=script.R --model=gpt-4o --markdown --output=explanation.md\n\n")
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

explain_code <- function(code, model = "gpt-3.5-turbo") {
  chat_messages <- list(
    list(role = "system", content = "Your name is BinkyBonky and You are a knowledgeable AI trained to explain code to people."),
    list(role = "user", content = paste("Please explain the following code and how to use it:\n", code))
  )
  
  response <- tryCatch(
    {
      openai$ChatCompletion$create(
        model = model,
        messages = chat_messages,
        max_tokens = 2048,
        temperature = 0.7,
        top_p = 1,
        frequency_penalty = 0,
        presence_penalty = 0
      )
    },
    error = function(e) {
      cat(red(bold("Failed to generate explanation: ")), conditionMessage(e), "\n")
      quit(save="no", status=1)
    }
  )
  
  explanation <- fromJSON(toJSON(response))$choices[[1]]$message$content
  return(explanation)
}

cat(blue("Analyzing file: "), basename(filename), "\n")
cat(blue("Using model: "), opt$model, "\n")

timer <- NULL
if (requireNamespace("later", quietly = TRUE)) {
  timer <- start_spinner()
}

explanation <- explain_code(code, model = opt$model)

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
