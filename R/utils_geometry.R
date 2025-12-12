# R/utils_geometry.R

#' Calculate the intersection of a line segment and a node's bounding box.
#' With retraction to prevents arrowheads from piercing the shape.
#'
#' @param x_start Source x
#' @param y_start Source y
#' @param x_end Target x
#' @param y_end Target y
#' @param node_type 'OBSERVED' or 'LATENT'
#' @param w width
#' @param h height
#' @return list(x, y)
#' @keywords internal
calculate_intersection <- function(x_start, y_start, x_end, y_end, node_type, w, h) {
  
  # 1. Calcolo intersezione pura (Matematica)
  if (node_type == "OBSERVED") {
    dx <- x_start - x_end
    dy <- y_start - y_end
    if (dx == 0 && dy == 0) return(list(x = x_end, y = y_end))
    
    slope_diag <- (h / 2) / (w / 2)
    
    if (abs(dy / dx) < slope_diag) {
      ix <- if (dx > 0) x_end + w / 2 else x_end - w / 2
      iy <- y_end + dy * (w / 2 / abs(dx))
    } else {
      iy <- if (dy > 0) y_end + h / 2 else y_end - h / 2
      ix <- x_end + dx * (h / 2 / abs(dy))
    }
  } else { # LATENT (Ellisse)
    a <- w / 2
    b <- h / 2
    dx <- x_start - x_end
    dy <- y_start - y_end
    if (dx == 0 && dy == 0) return(list(x = x_end, y = y_end))
    
    t <- sqrt(1 / ((dx^2 / a^2) + (dy^2 / b^2)))
    ix <- x_end + t * dx
    iy <- y_end + t * dy
  }
  
  # 2. RETRACTION (Il trucco per la grafica pulita)
  # Accorciamo la freccia di 2 pixel lungo il vettore di direzione
  # così la punta si appoggia delicatamente al bordo.
  
  # Vettore dall'intersezione verso l'origine (start)
  vec_x <- x_start - ix
  vec_y <- y_start - iy
  len <- sqrt(vec_x^2 + vec_y^2)
  
  padding <- 3 # pixel di "respiro"
  
  if (len > padding) {
    # Normalizza e accorcia
    ix <- ix + (vec_x / len) * padding
    iy <- iy + (vec_y / len) * padding
  }
  
  return(list(x = ix, y = iy))
}