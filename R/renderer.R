# R/renderer.R

#' Render the SEM plot from parsed data frames.
#' @param json_data A list containing parsed JSON data with 'nodes' and 'edges' elements from the Gemini API response.
#' @return A ggplot object containing the SEM visualization.
#' @examples
#' \dontrun{
#' # This function is typically called internally by visualize_sem()
#' # See ?visualize_sem for complete examples
#'
#' # Example with mock data
#' mock_data <- list(
#'   nodes = data.frame(
#'     id = "node1", label = "Var1", x = 200, y = 400,
#'     type = "OBSERVED", width = 100, height = 60
#'   ),
#'   edges = data.frame(
#'     sourceId = "node1", targetId = "node2",
#'     label = "0.25***", lineType = "straight",
#'     isSignificant = TRUE, labelPosition = 0.5
#'   )
#' )
#'
#' # plot <- draw_sem(mock_data)
#' # print(plot)
#' }
#' @importFrom ggplot2 ggplot geom_segment geom_curve geom_label geom_rect geom_text scale_linetype_manual scale_y_reverse theme_void theme margin element_rect coord_fixed aes arrow unit
#' @importFrom ggforce geom_ellipse
#' @importFrom dplyr filter
#' @importFrom stringr str_wrap
#' @importFrom rlang .data
#' @importFrom magrittr %>%

#' @export
draw_sem <- function(json_data) {
  parsed <- parse_and_prepare_data(json_data)
  nodes_df <- parsed$nodes_df
  edges_df <- parsed$edges_df

  # APA Clean up (Rimuove lo zero iniziale se presente)
  edges_df$label <- gsub("^(-?)0\\.", "\\1.", edges_df$label)

  latent_nodes <- nodes_df %>% filter(.data$type == "LATENT")
  observed_nodes <- nodes_df %>% filter(.data$type == "OBSERVED")
  straight_edges <- edges_df %>% filter(.data$lineType == "straight")
  curved_edges <- edges_df %>% filter(.data$lineType == "curved")

  p <- ggplot() +
    # ---------------------------------------------------------
    # LAYER 1: EDGES (Linee più eleganti)
    # ---------------------------------------------------------
    geom_segment(
      data = straight_edges,
      aes(x = .data$x_start, y = .data$y_start, xend = .data$x_end, yend = .data$y_end, linetype = factor(.data$isSignificant)),
      arrow = arrow(length = unit(0.3, "cm"), type = "closed"), # Punta leggermente più grande
      linewidth = 0.6, color = "black" # Linea più scura
    ) +
    geom_curve(
      data = curved_edges,
      aes(x = .data$x_start, y = .data$y_start, xend = .data$x_end, yend = .data$y_end, linetype = factor(.data$isSignificant)),
      arrow = arrow(length = unit(0.3, "cm"), ends = "both", type = "closed"),
      curvature = 0.25, linewidth = 0.6, color = "gray30"
    ) +

    # ---------------------------------------------------------
    # LAYER 2: EDGE LABELS (Il vero trucco estetico)
    # ---------------------------------------------------------
    geom_label(
      data = edges_df,
      aes(x = .data$label_x, y = .data$label_y, label = .data$label),
      size = 3.5, # Font più leggibile
      fill = "white", # Sfondo bianco
      color = "black",
      label.size = NA, # <--- RIMUOVE IL BORDO BRUTTO (Il segreto)
      label.padding = unit(0.2, "lines"), # Più respiro
      fontface = "plain"
    ) +

    # ---------------------------------------------------------
    # LAYER 3: NODES (Stile Minimal)
    # ---------------------------------------------------------
    geom_ellipse(
      data = latent_nodes,
      aes(x0 = .data$x, y0 = .data$y, a = .data$width / 2, b = .data$height / 2, angle = 0),
      fill = "white", color = "black", linewidth = 1.0 # Bordo nodo più spesso
    ) +
    geom_rect(
      data = observed_nodes,
      aes(xmin = .data$x - .data$width / 2, xmax = .data$x + .data$width / 2, ymin = .data$y - .data$height / 2, ymax = .data$y + .data$height / 2),
      fill = "white", color = "black", linewidth = 1.0 # Bordo nodo più spesso
    ) +

    # ---------------------------------------------------------
    # LAYER 4: NODE LABELS
    # ---------------------------------------------------------
    geom_text(
      data = nodes_df,
      aes(x = .data$x, y = .data$y, label = stringr::str_wrap(.data$label, width = 12)),
      size = 3.8,
      fontface = "bold",
      lineheight = 0.9
    ) +

    # ---------------------------------------------------------
    # THEME
    # ---------------------------------------------------------
    scale_linetype_manual(values = c("TRUE" = "solid", "FALSE" = "dashed")) +
    scale_y_reverse() +
    theme_void() +
    theme(
      legend.position = "none",
      plot.margin = margin(30, 30, 30, 30), # Margini ampi
      plot.background = element_rect(fill = "white", color = NA) # Sfondo pagina bianco
    ) +
    coord_fixed()

  return(p)
}
