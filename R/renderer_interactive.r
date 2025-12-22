# R/renderer_interactive.R

#' Render an interactive SEM plot using visNetwork
#' @param json_data A list containing parsed JSON data with 'nodes' and 'edges' elements from the Gemini API response.
#' @return A visNetwork HTML widget containing the interactive SEM visualization.
#' @examples
#' \dontrun{
#' # This function is typically called internally by visualize_sem(interactive = TRUE)
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
#' # interactive_plot <- draw_sem_interactive(mock_data)
#' # print(interactive_plot)
#' }
#' @importFrom visNetwork visNetwork visPhysics visEdges visNodes visOptions visInteraction visLayout
#' @importFrom dplyr mutate select
#' @importFrom magrittr %>%

#' @export
draw_sem_interactive <- function(json_data) {
  
  parsed <- parse_and_prepare_data(json_data)
  nodes <- parsed$nodes_df
  edges <- parsed$edges_df
  
  # --- 1. PREPARAZIONE NODI PER VISNETWORK ---
  # visNetwork vuole colonne specifiche: id, label, shape, x, y
  vis_nodes <- nodes %>%
    mutate(
      # Mappa TYPE -> SHAPE
      shape = ifelse(.data$type == "LATENT", "ellipse", "box"),
      # Colori stile APA (Bianco con bordo nero)
      color.background = "white",
      color.border = "black",
      borderWidth = 2,
      # Font
      font.size = 20,
      font.face = "arial",
      # Coordinate (Gemini X/Y). 
      # visNetwork ha Y invertita rispetto a ggplot, quindi spesso non serve invertire
      x = .data$x, 
      y = .data$y 
    ) %>%
    select(.data$id, .data$label, .data$shape, .data$x, .data$y, .data$color.background, .data$color.border, .data$borderWidth, .data$font.size, .data$font.face)
  
  # --- 2. PREPARAZIONE ARCHI ---
  # visNetwork vuole: from, to, label, dashes, arrows
  vis_edges <- edges %>%
    mutate(
      from = .data$sourceId,
      to = .data$targetId,
      # Pulisci label
      label = gsub("^(-?)0\\.", "\\1.", .data$label),
      # Stile freccia
      arrows = "to",
      # Tratteggio se non significativo
      dashes = !.data$isSignificant,
      # Colore
      color = "black",
      # Smooth curves se lineType è curved
      smooth = ifelse(.data$lineType == "curved", TRUE, FALSE),
      # Sfondo bianco per le etichette
      font.background = "white",
      font.strokeWidth = 0 # Nessun bordo attorno al testo
    ) %>%
    select(.data$from, .data$to, .data$label, .data$arrows, .data$dashes, .data$color, .data$smooth, .data$font.background, .data$font.strokeWidth)
  
  # --- 3. COSTRUZIONE NETWORK ---
  vn <- visNetwork(vis_nodes, vis_edges) %>%
    # Impostazioni fisiche:
    # physics = FALSE significa "Usa le coordinate fisse di Gemini all'inizio".
    # L'utente può comunque trascinare i nodi, ma non "molleggiano" da soli.
    visPhysics(enabled = FALSE) %>%
    visEdges(
      smooth = list(type = "dynamic"), # Curve morbide
      font = list(size = 16, align = "horizontal") # Etichette orizzontali
    ) %>%
    visNodes(
      fixed = FALSE # Permette all'utente di spostarli!
    ) %>%
    visOptions(
      highlightNearest = TRUE, # Evidenzia connessioni al click
      nodesIdSelection = TRUE  # Menu a tendina per trovare nodi
    ) %>%
    visInteraction(
      dragNodes = TRUE, # ABILITA IL DRAG & DROP
      dragView = TRUE,
      zoomView = TRUE
    ) %>%
    visLayout(randomSeed = 123)
  
  return(vn)
}