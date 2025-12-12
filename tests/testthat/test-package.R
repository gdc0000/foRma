test_that("package loads correctly", {
  expect_true(requireNamespace("foRma", quietly = TRUE))
})

test_that("required dependencies are available", {
  expect_true(requireNamespace("ggplot2", quietly = TRUE))
  expect_true(requireNamespace("httr2", quietly = TRUE))
  expect_true(requireNamespace("jsonlite", quietly = TRUE))
  expect_true(requireNamespace("lavaan", quietly = TRUE))
})