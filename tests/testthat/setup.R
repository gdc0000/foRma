# Test configuration for foRma package
# This file ensures tests run properly during CRAN checks

# Skip tests that require external services during CRAN checks
skip_on_cran <- function() {
  if (identical(Sys.getenv("_R_CHECK_FORCE_SUGGESTS_"), "true")) {
    skip("Skipping test during CRAN checks")
  }
}

# Mock data for testing without API calls
mock_gemini_response <- function() {
  list(
    nodes = data.frame(
      id = c("visual", "textual", "x1", "x2"),
      label = c("Visual", "Textual", "x1", "x2"),
      x = c(200, 600, 100, 100),
      y = c(300, 300, 200, 400),
      type = c("LATENT", "LATENT", "OBSERVED", "OBSERVED"),
      width = c(120, 120, 80, 80),
      height = c(80, 80, 50, 50)
    ),
    edges = data.frame(
      sourceId = c("visual", "visual"),
      targetId = c("x1", "x2"),
      label = c("0.75***", "0.68***"),
      lineType = c("straight", "straight"),
      isSignificant = c(TRUE, TRUE),
      labelPosition = c(0.5, 0.5)
    )
  )
}