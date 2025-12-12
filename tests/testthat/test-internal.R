test_that("parse_and_prepare_data function works correctly", {
  expect_true(exists("parse_and_prepare_data"))
  expect_type(parse_and_prepare_data, "closure")
  
  # Test with mock JSON data
  mock_json <- list(
    nodes = data.frame(
      id = c("node1", "node2"),
      label = c("Node 1", "Node 2"),
      x = c(200, 600),
      y = c(400, 400),
      type = c("OBSERVED", "LATENT"),
      width = c(100, 120),
      height = c(60, 80)
    ),
    edges = data.frame(
      sourceId = c("node1"),
      targetId = c("node2"),
      label = c("0.25***"),
      lineType = c("straight"),
      isSignificant = c(TRUE),
      labelPosition = c(0.5)
    )
  )
  
  result <- parse_and_prepare_data(mock_json)
  
  expect_true(is.list(result))
  expect_true("nodes_df" %in% names(result))
  expect_true("edges_df" %in% names(result))
  expect_true(nrow(result$nodes_df) == 2)
  expect_true(nrow(result$edges_df) == 1)
})

test_that("calculate_intersection function works correctly", {
  expect_true(exists("calculate_intersection"))
  expect_type(calculate_intersection, "closure")
  
  # Test simple case
  result <- calculate_intersection(0, 0, 100, 100, "OBSERVED", 80, 50)
  expect_true(is.list(result))
  expect_true("x" %in% names(result))
  expect_true("y" %in% names(result))
})

test_that("draw_sem function creates ggplot object", {
  expect_true(exists("draw_sem"))
  expect_type(draw_sem, "closure")
  
  # Test with mock data
  mock_json <- list(
    nodes = data.frame(
      id = c("node1", "node2"),
      label = c("Node 1", "Node 2"),
      x = c(200, 600),
      y = c(400, 400),
      type = c("OBSERVED", "LATENT"),
      width = c(100, 120),
      height = c(60, 80)
    ),
    edges = data.frame(
      sourceId = c("node1"),
      targetId = c("node2"),
      label = c("0.25***"),
      lineType = c("straight"),
      isSignificant = c(TRUE),
      labelPosition = c(0.5)
    )
  )
  
  result <- draw_sem(mock_json)
  expect_s3_class(result, "ggplot")
})

test_that("draw_sem_interactive function creates visNetwork object", {
  expect_true(exists("draw_sem_interactive"))
  expect_type(draw_sem_interactive, "closure")
  
  # Test with mock data
  mock_json <- list(
    nodes = data.frame(
      id = c("node1", "node2"),
      label = c("Node 1", "Node 2"),
      x = c(200, 600),
      y = c(400, 400),
      type = c("OBSERVED", "LATENT")
    ),
    edges = data.frame(
      sourceId = c("node1"),
      targetId = c("node2"),
      label = c("0.25***"),
      lineType = c("straight"),
      isSignificant = c(TRUE)
    )
  )
  
  result <- draw_sem_interactive(mock_json)
  expect_s3_class(result, "visNetwork")
})