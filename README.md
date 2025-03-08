# Rxplanetome

A powerful R tool to explain code with AI using OpenAI's models.

## Overview

Rxplanetome is an R tool designed to provide clear explanations for code. It leverages OpenAI's AI models to generate human-readable explanations of any code file or snippet.

## Features

- Command-line interface with support for multiple options
- Interactive R function for use within RStudio
- Explain code snippets directly
- Explain entire active document in RStudio
- Uses OpenAI's GPT-4o by default (customizable)
- Interactive file selection if no file is specified
- Markdown output formatting
- Save explanations to file
- Progress indicator during API calls
- Comprehensive error handling
- Safety checks for file type and size

## Dependencies

```R
install.packages(c("openai", "jsonlite", "optparse", "crayon", "knitr", "rstudioapi"))
```

## API Key Setup

To use Rxplanetome, you need an OpenAI API key. Set it as an environment variable:

```sh
# In your terminal
export OPENAI_API_KEY='your-api-key'

# In R
Sys.setenv(OPENAI_API_KEY = 'your-api-key')
```

## Usage

### Command-Line Usage

```sh
Rscript Rxplanetome.r
```

When run without arguments, Rxplanetome will prompt you to select a file interactively.

### Command-line Options

```sh
Rscript Rxplanetome.r --file=script.R --model=gpt-4o --markdown --output=explanation.md
```

Available options:

- `--file=PATH`: Path to the code file to explain
- `--model=MODEL`: AI model to use (default: gpt-4o)
- `--markdown`: Output explanation in markdown format
- `--output=PATH`: Save explanation to file
- `--help`: Display help message

### Interactive Usage in R/RStudio

First, source the file:

```R
source("path/to/Rxplanetome.r")
```

Then use the `rxplain()` function:

```R
# Explain a code snippet directly
rxplain("function() { print('hello world') }")

# Explain selected code in RStudio
# (Select code first, then run this command)
rxplain()

# Explain the entire current document in RStudio
rxplain(all = TRUE)

# Specify model and output options
rxplain(all = TRUE, model = "gpt-4o", markdown = TRUE, output = "explanation.md")
```

### Examples

```sh
# CLI: Explain a Python file and save the explanation as markdown
Rscript Rxplanetome.r --file=/path/to/script.py --markdown --output=explanation.md

# In R: Explain a code snippet
rxplain("for(i in 1:10) { print(i) }")

# In RStudio: Explain the entire current document
rxplain(all = TRUE)
```

## Restrictions

- Limited to R, Rmd, and md files for safety
- Maximum file size: 1000 lines
