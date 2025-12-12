# R/parser.R

#' Parse JSON data and prepare data frames for plotting.
#'
#' @param json_data A string containing JSON data or a list parsed from JSON.
#' @return A list containing two data frames: 'nodes_df' and 'edges_df'.
#' @importFrom jsonlite fromJSON
#' @importFrom dplyr as_tibble bind_rows rename any_of left_join select mutate bind_cols
#' @importFrom purrr pmap_dfr
#' @importFrom magrittr %>%
#' @keywords internal
parse_and_prepare_data <- function(json_data) {
  # 1. Parsing iniziale
  if (is.character(json_data)) {
    data <- fromJSON(json_data, simplifyVector = TRUE)
  } else if (is.list(json_data)) {
    data <- json_data
  } else {
    stop("`json_data` must be a JSON string or a pre-parsed list.", call. = FALSE)
  }
  
  # ============================================================================
  # NODES HANDLING
  # ============================================================================
  if(is.data.frame(data$nodes)) {
    nodes_df <- as_tibble(data$nodes)
  } else {
    nodes_df <- bind_rows(data$nodes)
  }
  
  # 1. Normalizza nomi colonne
  colnames(nodes_df) <- tolower(colnames(nodes_df))
  
  # 2. Gestione Sinonimi Nodi (Es. "name" invece di "label")
  if("name" %in% names(nodes_df)) nodes_df <- rename(nodes_df, label = .data$name)
  
  # 3. SAFEGUARD CRITICA: Se manca 'label', usa 'id'
  if(!"label" %in% names(nodes_df)) {
    if("id" %in% names(nodes_df)) {
      nodes_df$label <- nodes_df$id
    } else {
      nodes_df$label <- "Node" # Fallback disperato
    }
  }
  
  # 4. Defaults Geometrici
  if(!"width" %in% names(nodes_df)) nodes_df$width <- 100
  if(!"height" %in% names(nodes_df)) nodes_df$height <- 60
  
  nodes_df$x <- as.numeric(nodes_df$x)
  nodes_df$y <- as.numeric(nodes_df$y)
  nodes_df$width <- as.numeric(nodes_df$width)
  nodes_df$height <- as.numeric(nodes_df$height)
  
  # ============================================================================
  # EDGES HANDLING
  # ============================================================================
  if(is.data.frame(data$edges)) {
    edges_df <- as_tibble(data$edges)
  } else {
    edges_df <- bind_rows(data$edges)
  }
  
  colnames(edges_df) <- tolower(colnames(edges_df))
  
  # Sinonimi Edge
  if("estimate" %in% names(edges_df)) edges_df <- rename(edges_df, label = .data$estimate)
  if("weight" %in% names(edges_df)) edges_df <- rename(edges_df, label = .data$weight)
  
  # Rinomina standard
  edges_df <- edges_df %>% rename(
    sourceId = any_of(c("sourceid", "source_id", "source")),
    targetId = any_of(c("targetid", "target_id", "target")),
    lineType = any_of(c("linetype", "line_type", "type")),
    isSignificant = any_of(c("issignificant", "significant", "significance")),
    labelPosition = any_of(c("labelposition", "label_pos", "pos"))
  )
  
  # --- SAFE DEFAULTS EDGES ---
  if(!"lineType" %in% names(edges_df)) {
    edges_df$lineType <- ifelse(.data$sourceId == .data$targetId, "curved", "straight")
  }
  if(!"isSignificant" %in% names(edges_df)) edges_df$isSignificant <- TRUE
  
  if(!"labelPosition" %in% names(edges_df)) {
    edges_df$labelPosition <- 0.5
  } else {
    edges_df$labelPosition <- as.numeric(edges_df$labelPosition)
    edges_df$labelPosition[is.na(edges_df$labelPosition)] <- 0.5
  }
  
  # Ensure Label Exists on Edges too
  if(!"label" %in% names(edges_df)) edges_df$label <- ""
  
  # Validation
  if(!all(c("sourceId", "targetId") %in% names(edges_df))) {
    stop("Edges JSON missing source/target IDs.", call.=FALSE)
  }
  
  # ============================================================================
  # GEOMETRY CALCULATION
  # ============================================================================
  
  # IMPORTANTE: Seleziona SOLO le colonne necessarie dai nodi per il join
  # Questo previene che nodes$label sovrascriva edges$label
  node_cols <- c("id", "x", "y", "type", "width", "height")
  
  edges_augmented <- edges_df %>%
    left_join(nodes_df %>% select(any_of(node_cols)), by = c("sourceId" = "id")) %>%
    rename(x_start_center = .data$x, y_start_center = .data$y, type.source = .data$type, width.source = .data$width, height.source = .data$height) %>%
    left_join(nodes_df %>% select(any_of(node_cols)), by = c("targetId" = "id"), suffix = c(".source", ".target")) %>%
    rename(x_end_center = .data$x, y_end_center = .data$y, type.target = .data$type, width.target = .data$width, height.target = .data$height)
  
  # Check links
  if(any(is.na(edges_augmented$x_start_center))) warning("Some edges have invalid sourceId")
  
  # Arrow Heads
  intersections_end <- edges_augmented %>%
    select(.data$x_start_center, .data$y_start_center, .data$x_end_center, .data$y_end_center, .data$type.target, .data$width.target, .data$height.target) %>%
    pmap_dfr(function(...) {
      args <- list(...)
      if(any(sapply(args, is.na))) {
        return(tibble(x = NA_real_, y = NA_real_))
      }
      result <- calculate_intersection(args[[1]], args[[2]], args[[3]], args[[4]], args[[5]], args[[6]], args[[7]])
      return(tibble(x = result$x, y = result$y))
    }) %>% rename(x_end = .data$x, y_end = .data$y)
  
  # Arrow Tails
  intersections_start <- edges_augmented %>%
    select(.data$x_end_center, .data$y_end_center, .data$x_start_center, .data$y_start_center, .data$type.source, .data$width.source, .data$height.source) %>%
    pmap_dfr(function(...) {
      args <- list(...)
      if(any(sapply(args, is.na))) {
        return(tibble(x = NA_real_, y = NA_real_))
      }
      result <- calculate_intersection(args[[1]], args[[2]], args[[3]], args[[4]], args[[5]], args[[6]], args[[7]])
      return(tibble(x = result$x, y = result$y))
    }) %>% rename(x_start = .data$x, y_start = .data$y)
  
  edges_final <- bind_cols(edges_augmented, intersections_start, intersections_end)
  
  # Label Positioning
  edges_final <- edges_final %>%
    mutate(
      label_x = .data$x_start + (.data$x_end - .data$x_start) * .data$labelPosition,
      label_y = .data$y_start + (.data$y_end - .data$y_start) * .data$labelPosition
    )
  
  return(list(nodes_df = nodes_df, edges_df = edges_final))
}