#' Draw a Structural Equation Model
#'
#' Renders a SEM diagram from JSON data using ggplot2. It handles node and edge
#' rendering, applies visual styles for significance, and ensures arrows connect
#' cleanly to node perimeters.
#'
#' @param json_data A path to a JSON file or a JSON string for the SEM.
#' @return A ggplot object representing the SEM diagram.
#' @import ggplot2
#' @import ggforce
#' @import dplyr
#' @import purrr
#' @export
#' @examples
#' \dontrun{
#'   json_string <- '{
#'     "nodes": [
#'       {"id": "lat1", "x": 400, "y": 100, "label": "Factor A", "type": "LATENT", "width": 100, "height": 60},
#'       {"id": "obs1", "x": 300, "y": 300, "label": "Item 1", "type": "OBSERVED", "width": 80, "height": 50},
#'       {"id": "obs2", "x": 500, "y": 300, "label": "Item 2", "type": "OBSERVED", "width": 80, "height": 50}
#'     ],
#'     "edges": [
#'       {"id": "e1", "sourceId": "lat1", "targetId": "obs1", "label": "0.85", "isSignificant": true, "lineType": "straight"},
#'       {"id": "e2", "sourceId": "lat1", "targetId": "obs2", "label": "0.72", "isSignificant": true, "lineType": "straight"},
#'       {"id": "e3", "sourceId": "obs1", "targetId": "obs2", "label": "0.30", "isSignificant": false, "lineType": "curved"}
#'     ]
#'   }'
#'   sem_plot <- draw_sem(json_string)
#'   print(sem_plot)
#' }
draw_sem <- function(json_data) {
  # 1. Parse JSON
  parsed_data <- parse_sem_json(json_data)
  nodes_df <- parsed_data$nodes_df
  edges_df <- parsed_data$edges_df

  # 2. Prepare edge data with coordinates
  edges_with_coords <- edges_df %>%
    left_join(nodes_df %>% select(id, x, y, type, width, height), by = c("sourceId" = "id")) %>%
    rename(x_start_center = x, y_start_center = y, type_start = type, width_start = width, height_start = height) %>%
    left_join(nodes_df %>% select(id, x, y, type, width, height), by = c("targetId" = "id")) %>%
    rename(x_end_center = x, y_end_center = y, type_end = type, width_end = width, height_end = height)

  # 3. Calculate precise start/end points on node perimeters
  edge_endpoints <- pmap_dfr(edges_with_coords, function(...) {
    edge <- list(...)
    
    start_node_center <- c(edge$x_start_center, edge$y_start_center)
    end_node_center <- c(edge$x_end_center, edge$y_end_center)
    
    # For covariances (curved), arrows go both ways. We find intersection for both.
    if (edge$lineType == "curved") {
       start_point <- calculate_intersection(start_node_center, end_node_center, start_node_center, edge$type_start, edge$width_start, edge$height_start)
       end_point <- calculate_intersection(end_node_center, start_node_center, end_node_center, edge$type_end, edge$width_end, edge$height_end)
    } else { # For regressions (straight)
       start_point <- calculate_intersection(start_node_center, end_node_center, start_node_center, edge$type_start, edge$width_start, edge$height_start)
       end_point <- calculate_intersection(end_node_center, start_node_center, end_node_center, edge$type_end, edge$width_end, edge$height_end)
    }

    tibble(
      id = edge$id,
      x_start = start_point[1],
      y_start = start_point[2],
      x_end = end_point[1],
      y_end = end_point[2]
    )
  })

  # Join calculated endpoints back to the main edges data frame
  edges_final <- edges_with_coords %>%
    left_join(edge_endpoints, by = "id") %>%
    mutate(
      # Position for edge labels
      label_x = (x_start + x_end) / 2,
      label_y = (y_start + y_end) / 2,
      # Adjustments for curved labels
      label_x = if_else(lineType == "curved", (x_start_center + x_end_center)/2, label_x),
      label_y = if_else(lineType == "curved", pmin(y_start_center, y_end_center) + abs(x_start - x_end)/4, label_y)
    )

  # 4. Separate nodes and edges for plotting
  latent_nodes <- nodes_df %>% filter(type == "LATENT")
  observed_nodes <- nodes_df %>% filter(type == "OBSERVED")
  
  straight_edges <- edges_final %>% filter(lineType == "straight")
  curved_edges <- edges_final %>% filter(lineType == "curved")

  # Create a data frame for labels that should be drawn (non-empty)
  edge_labels_to_draw <- edges_final %>%
    filter(!is.na(label) & label != "")

  # 5. Build the plot
  p <- ggplot() +
    # Layer 1: Edges
    # Straight edges (regressions)
    geom_segment(
      data = straight_edges,
      aes(x = x_start, y = y_start, xend = x_end, yend = y_end, linetype = factor(isSignificant)),
      arrow = arrow(length = unit(3, "mm"), type = "closed")
    ) +
    # Curved edges (covariances)
    geom_curve(
      data = curved_edges,
      aes(x = x_start, y = y_start, xend = x_end, yend = y_end, linetype = factor(isSignificant)),
      curvature = -0.2, # Fixed curvature for now
      arrow = arrow(length = unit(3, "mm"), ends = "both", type = "closed")
    ) +

    # Layer 2: Edge Labels
    geom_label(
      data = edge_labels_to_draw,
      aes(x = label_x, y = label_y, label = label),
      fill = "white",
      label.size = NA, # No border
      size = 3.5
    ) +
    
    # Layer 3: Nodes
    # Latent variables (Ellipses)
    geom_ellipse(
      data = latent_nodes,
      aes(x0 = x, y0 = y, a = width / 2, b = height / 2, angle = 0),
      fill = "white", color = "black", linewidth = 0.7
    ) +
    # Observed variables (Rectangles)
    geom_rect(
      data = observed_nodes,
      aes(xmin = x - width / 2, xmax = x + width / 2, ymin = y - height / 2, ymax = y + height / 2),
      fill = "white", color = "black", linewidth = 0.7
    ) +
    
    # Layer 4: Node Labels
    geom_text(
      data = nodes_df,
      aes(x = x, y = y, label = label),
      size = 4.5,
      fontface = "bold"
    ) +
    
    # Visual settings
    scale_linetype_manual(values = c("TRUE" = "solid", "FALSE" = "dashed"), guide = "none") +
    coord_fixed() +
    scale_y_reverse() + # Invert y-axis to match common diagram layouts (0,0 at top-left)
    theme_void() +
    theme(
      plot.background = element_rect(fill = "white", color = NA)
    )

  return(p)
}
