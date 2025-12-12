# R/wrappers.R

#' High-level function to visualize a Structural Equation Model.
#' @param object Fitted model object (lavaan).
#' @param api_key Gemini API Key.
#' @param interactive Logical. If TRUE, returns a drag-and-drop HTML widget. If FALSE (default), returns a static ggplot.
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
  
  cat("Analyzing Model...\n")
  gemini_json <- query_gemini(summary_text, api_key)
  
  if (interactive) {
    cat("Launching Interactive Studio...\n")
    return(draw_sem_interactive(gemini_json))
  } else {
    cat("Rendering Static Plot...\n")
    return(draw_sem(gemini_json))
  }
}