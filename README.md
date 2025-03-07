# Rxplanetome

A powerful R tool to explain code with AI using OpenAI's models.

## Overview

Rxplanetome is an R tool designed to provide clear explanations for code. It leverages OpenAI's AI models to generate human-readable explanations of any code file.

## Features

- Command-line interface with support for multiple options
- Uses OpenAI's GPT-4o by default (customizable)
- Interactive file selection if no file is specified
- Markdown output formatting
- Save explanations to file
- Progress indicator during API calls
- Comprehensive error handling

## Dependencies

```R
install.packages(c("openai", "jsonlite", "optparse", "crayon", "knitr"))
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

### Basic Usage

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

### Example

```sh
# Explain a Python file and save the explanation as markdown
Rscript Rxplanetome.r --file=/path/to/script.py --markdown --output=explanation.md

# Use a different model
Rscript Rxplanetome.r --file=/path/to/script.js --model=gpt-3.5-turbo
```
