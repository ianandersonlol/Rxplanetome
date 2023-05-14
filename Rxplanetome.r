# Install the openai package
# install.packages("openai")

# Load the necessary libraries
library(openai)
library(jsonlite)

# Set API key
Sys.setenv(OPENAI_API_KEY = "YOURAPIKEY")

# Select a file
filename <- file.choose()

# Read the file content
code <- tryCatch(
  {
    readChar(filename, file.info(filename)$size)
  },
  error = function(e) {
    cat("Failed to read file:", conditionMessage(e), "\n")
    quit("no", status = 1, runLast = FALSE)
  }
)

# Define a function to explain code
explain_code <- function(code) {
  chat_messages <- list(
    list(role = "system", content = "Your name is BinkyBonky and You are a knowledgeable AI trained to explain code to people."),
    list(role = "user", content = paste("Please explain the following code and how to use it:\n", code))
  )
  
  response <- tryCatch(
    {
      openai$ChatCompletion$create(
        model = "gpt-3.5-turbo",
        messages = chat_messages,
        max_tokens = 2048,
        temperature = 0.7,
        top_p = 1,
        frequency_penalty = 0,
        presence_penalty = 0
      )
    },
    error = function(e) {
      cat("Failed to generate explanation:", conditionMessage(e), "\n")
      quit("no", status = 1, runLast = FALSE)
    }
  )
  
  explanation <- fromJSON(toJSON(response))$choices[[1]]$message$content
  return(explanation)
}

# Generate the explanation
cat("Generating explanation, please wait...\n")
cat(explain_code(code), "\n")
