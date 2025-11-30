#' Run a Full Example of Drawing a SEM Plot
#'
#' This function provides a demonstration of the package's capabilities.
#' It loads a sample JSON file, calls the main drawing function,
#' and prints the resulting plot.
#'
#' Note: This function is intended for demonstration purposes and is not
#' typically called directly by users in their own analyses. Instead, users should
#' call `draw_sem()` with their own data. For the function to find the example file,
#' the package must be installed.
#'
#' @param json_file_path The path to the JSON file. Defaults to the package's
#'   sample `graph_data.json` file.
#' @return Invisibly returns the ggplot object.
#' @export
#' @examples
#' \dontrun{
#'   # To run this example, you need the package installed.
#'   # You can also run it by sourcing the R files and providing a path to the JSON.
#'   # For example:
#'   # source("R/parser.R")
#'   # source("R/utils_geometry.R")
#'   # source("R/renderer.R")
#'   # plot <- draw_sem("graph_data.json")
#'   # print(plot)
#'
#'   run_example()
#' }
run_example <- function(json_file_path = "graph_data.json") {
  if (!file.exists(json_file_path)) {
    warning(paste(
      "Could not find the example file:", json_file_path, ".",
      "Please ensure it's in your working directory."
    ))
    # Create a dummy file if not found, using the provided reference JSON
    json_content <- '{
      "nodes": [
        {"id": "lat1", "x": 400, "y": 100, "label": "Factor A", "type": "LATENT", "width": 100, "height": 60},
        {"id": "obs1", "x": 300, "y": 300, "label": "Item 1", "type": "OBSERVED", "width": 80, "height": 50},
        {"id": "obs2", "x": 500, "y": 300, "label": "Item 2", "type": "OBSERVED", "width": 80, "height": 50}
      ],
      "edges": [
        {"id": "e1", "sourceId": "lat1", "targetId": "obs1", "label": "0.85", "isSignificant": true, "lineType": "straight"},
        {"id": "e2", "sourceId": "lat1", "targetId": "obs2", "label": "0.72", "isSignificant": true, "lineType": "straight"},
        {"id": "e3", "sourceId": "obs1", "targetId": "obs2", "label": "0.30", "isSignificant": false, "lineType": "curved"}
      ]
    }'
    writeLines(json_content, json_file_path)
    message("Created a sample 'graph_data.json' file.")
  }

  # Call the main rendering function
  sem_plot <- draw_sem(json_file_path)

  # Print the plot
  print(sem_plot)

  # Return the plot object invisibly
  invisible(sem_plot)
}

# You can run this function directly in an interactive session
# after sourcing the necessary files.
# For example:
# source("R/parser.R"); source("R/utils_geometry.R"); source("R/renderer.R")
# run_example()
