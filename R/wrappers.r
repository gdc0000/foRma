# R/wrappers.R

#' High-level function to visualize a Structural Equation Model.
#' @param object Fitted model object (lavaan).
#' @param api_key Gemini API Key.
#' @param interactive Logical. If TRUE, returns a drag-and-drop HTML widget. If FALSE (default), returns a static ggplot.
#' @return Either a ggplot object (static) or visNetwork HTML widget (interactive) containing the SEM visualization.
#' @examples
#' \dontrun{
#' library(lavaan)
#' # Define a simple SEM model
#' model <- 'visual =~ x1 + x2 + x3'
#' data <- simulateData(model, sample.nobs = 100)
#' fit <- sem(model, data = data)
#' 
#' # Set API key
#' Sys.setenv(GEMINI_API_KEY = "your_api_key_here")
#' 
#' # Create static plot
#' static_plot <- visualize_sem(fit, interactive = FALSE)
#' 
#' # Create interactive plot
#' interactive_plot <- visualize_sem(fit, interactive = TRUE)
#' }
#' @importFrom utils capture.output
#' @importFrom magrittr %>%
#' @export
visualize_sem <- function(object, api_key = Sys.getenv("GEMINI_API_KEY"), interactive = FALSE) {
  
  if (!requireNamespace("lavaan", quietly = TRUE)) {
    stop("Package 'lavaan' is required but not installed. Please install it with: install.packages('lavaan')", call. = FALSE)
  }
  
  # Check API key availability
  if (api_key == "") {
    stop("No Gemini API key found. Please set GEMINI_API_KEY environment variable or pass api_key parameter. See ?visualize_sem for setup instructions.", call. = FALSE)
  }
  
  # 1. Capture Summary
  summary_text <- tryCatch({
    paste(capture.output(lavaan::summary(object, standardized = TRUE, nd = 3)), collapse = "\n")
  }, error = function(e) stop("Summary capture failed."))
  
  message("Analyzing Model...")
  gemini_json <- query_gemini(summary_text, api_key)
  
  if (interactive) {
    message("Launching Interactive Studio...")
    return(draw_sem_interactive(gemini_json))
  } else {
    message("Rendering Static Plot...")
    return(draw_sem(gemini_json))
  }
}