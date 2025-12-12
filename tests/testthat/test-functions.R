test_that("visualize_sem function exists and has correct signature", {
  expect_true(exists("visualize_sem"))
  expect_type(visualize_sem, "closure")
  
  # Test parameter validation - API key is checked first
  expect_error(
    visualize_sem("not_a_model", api_key = ""),
    "`api_key` must be a non-empty character string"
  )
  
  # Test with missing API key
  expect_error(
    visualize_sem("not_a_model", api_key = ""),
    "No Gemini API key found"
  )
  
  # Skip API tests during CRAN checks
  skip_on_cran()
  
  # Test with valid API key but invalid model - expect API error since dummy key is invalid
  expect_error(
    visualize_sem("not_a_model", api_key = "dummy_key"),
    "Gemini API request failed"
  )
})

test_that("query_gemini function validates inputs", {
  expect_true(exists("query_gemini"))
  expect_type(query_gemini, "closure")
  
  # Test input validation
  expect_error(
    query_gemini("", "dummy_key"),
    "`input_text` must be a non-empty character string"
  )
  
  expect_error(
    query_gemini("dummy_text", ""),
    "`api_key` must be a non-empty character string"
  )
  
  # Test graceful failure during CRAN checks
  old_env <- Sys.getenv("_R_CHECK_FORCE_SUGGESTS_")
  Sys.setenv("_R_CHECK_FORCE_SUGGESTS_" = "true")
  
  result <- query_gemini("dummy_text", "dummy_key")
  expect_true(is.list(result))
  expect_true("nodes" %in% names(result))
  expect_true("edges" %in% names(result))
  
  # Restore environment
  if (old_env == "") {
    Sys.unsetenv("_R_CHECK_FORCE_SUGGESTS_")
  } else {
    Sys.setenv("_R_CHECK_FORCE_SUGGESTS_" = old_env)
  }
})