#' Parse SEM JSON from file or text
#'
#' Reads a JSON file or string representing a Structural Equation Model and
#' converts it into a list of two data frames: one for nodes and one for edges,
#' ready for plotting.
#'
#' @param json_data A path to a JSON file or a JSON string.
#' @return A list containing two data frames: `nodes_df` and `edges_df`.
#' @importFrom jsonlite fromJSON
#' @importFrom dplyr as_tibble
#' @export
#' @examples
#' \dontrun{
#'   json_file <- system.file("extdata", "example.json", package = "formasem")
#'   parsed_data <- parse_sem_json(json_file)
#'   nodes <- parsed_data$nodes_df
#'   edges <- parsed_data$edges_df
#' }
parse_sem_json <- function(json_data) {
  if (is.character(json_data) && (file.exists(json_data) || grepl("^https?://", json_data))) {
    model_data <- jsonlite::fromJSON(json_data, flatten = TRUE)
  } else if (is.character(json_data)) {
    model_data <- jsonlite::fromJSON(json_data, flatten = TRUE)
  } else {
    stop("`json_data` must be a valid file path, URL, or a JSON string.")
  }

  # Ensure nodes and edges are data frames
  nodes_df <- dplyr::as_tibble(model_data$nodes)
  edges_df <- dplyr::as_tibble(model_data$edges)

  if (!"id" %in% names(nodes_df)) {
    stop("Nodes data frame must contain an 'id' column.")
  }
  if (!"sourceId" %in% names(edges_df) || !"targetId" %in% names(edges_df)) {
    stop("Edges data frame must contain 'sourceId' and 'targetId' columns.")
  }

  return(list(nodes_df = nodes_df, edges_df = edges_df))
}
