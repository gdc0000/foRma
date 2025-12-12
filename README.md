# foRma: Structural Equation Model Visualization with AI

[![CRAN status](https://www.r-pkg.org/badges/version/foRma)](https://cran.r-project.org/package=foRma)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/foRma)](https://cran.r-project.org/package=foRma)

The `foRma` package provides tools for visualizing Structural Equation Models (SEM) using AI-generated layouts. It integrates with the `lavaan` package and uses Google's Gemini API to create optimized, publication-quality SEM plots with both static and interactive options.

## Features

- **AI-Powered Layouts**: Automatic node positioning using Google Gemini API
- **Static Plots**: Publication-ready ggplot2 visualizations with APA formatting
- **Interactive Plots**: Drag-and-drop visNetwork widgets for exploration
- **Smart Styling**: Automatic significance-based path formatting
- **Variable Types**: Proper handling of latent (ellipses) and observed (rectangles) variables
- **APA Formatting**: Coefficient display with significance stars

## Installation

```r
# Install from CRAN
install.packages("foRma")

# Or install development version
devtools::install_github("gdc0000/foRma")
```

## Quick Start

```r
library(foRma)
library(lavaan)

# Set up Gemini API key
Sys.setenv(GEMINI_API_KEY = "your_api_key_here")

# Define and fit a model
model <- '
  visual  =~ x1 + x2 + x3
  textual =~ x4 + x5 + x6
  visual ~~ textual
'

data <- simulateData(model, sample.nobs = 100)
fit <- sem(model, data = data)

# Create visualization
plot <- visualize_sem(fit)
print(plot)
```

## API Setup

1. Get a Gemini API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Set the environment variable:
   ```r
   Sys.setenv(GEMINI_API_KEY = "your_api_key_here")
   ```

## Documentation

- [Getting Started vignette](https://cran.r-project.org/web/packages/foRma/vignettes/getting-started.html)
- [Function reference](https://cran.r-project.org/web/packages/foRma/foRma.pdf)

## License

MIT + file LICENSE

## Citation

```r
citation("foRma")
```

## Links

- [GitHub repository](https://github.com/gdc0000/foRma)
- [Issue tracker](https://github.com/gdc0000/foRma/issues)
- [CRAN page](https://cran.r-project.org/package=foRma)