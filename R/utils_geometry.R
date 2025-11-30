#' Calculate Intersection of a Line and a Node Shape
#'
#' This is a generic helper function that dispatches to the correct shape
#' intersection function based on the node type.
#'
#' @param line_start A numeric vector `c(x, y)` for the line's starting point (source node center).
#' @param line_end A numeric vector `c(x, y)` for the line's ending point (target node center).
#' @param node_center A numeric vector `c(x, y)` for the center of the node.
#' @param node_type The type of the node, either "LATENT" (ellipse) or "OBSERVED" (rectangle).
#' @param node_width The width of the node.
#' @param node_height The height of the node.
#' @return A numeric vector `c(x, y)` representing the intersection point on the node's perimeter.
#' @keywords internal
calculate_intersection <- function(line_start, line_end, node_center, node_type, node_width, node_height) {
  if (node_type == "LATENT") {
    .intersection_line_ellipse(line_start, line_end, node_center, node_width, node_height)
  } else if (node_type == "OBSERVED") {
    .intersection_line_rectangle(line_start, line_end, node_center, node_width, node_height)
  } else {
    # Default to the node center if type is unknown
    node_center
  }
}

#' Calculate intersection between a line segment and a rectangle
#' @noRd
.intersection_line_rectangle <- function(p1, p2, rect_center, width, height) {
  x1 <- p1[1]
  y1 <- p1[2]
  x2 <- p2[1]
  y2 <- p2[2]

  cx <- rect_center[1]
  cy <- rect_center[2]
  w <- width / 2
  h <- height / 2

  # Rectangle boundaries
  left <- cx - w
  right <- cx + w
  top <- cy + h # ggplot y-axis is reversed
  bottom <- cy - h

  # Calculate line slope and intercept
  dx <- x2 - x1
  dy <- y2 - y1

  # Handle vertical or horizontal lines
  if (dx == 0 && dy == 0) return(c(cx, cy))
  if (dx == 0) { # Vertical line
    return(c(x1, ifelse(y1 > y2, top, bottom)))
  }
  if (dy == 0) { # Horizontal line
    return(c(ifelse(x1 > x2, right, left), y1))
  }
  
  # Find intersection points with the four lines of the rectangle
  # y = m*x + c
  m <- dy / dx
  c <- y1 - m * x1

  intersections <- list()
  
  # Top edge (y = top)
  x_top <- (top - c) / m
  if (x_top >= left && x_top <= right) intersections <- append(intersections, list(c(x_top, top)))
  
  # Bottom edge (y = bottom)
  x_bottom <- (bottom - c) / m
  if (x_bottom >= left && x_bottom <= right) intersections <- append(intersections, list(c(x_bottom, bottom)))
  
  # Left edge (x = left)
  y_left <- m * left + c
  if (y_left >= bottom && y_left <= top) intersections <- append(intersections, list(c(left, y_left)))
  
  # Right edge (x = right)
  y_right <- m * right + c
  if (y_right >= bottom && y_right <= top) intersections <- append(intersections, list(c(right, y_right)))
  
  # Find the intersection point that is closest to the other node center (p2)
  if (length(intersections) == 0) {
      return(p1) # Should not happen if line crosses the rect
  }
  
  # Of the valid intersection points, find the one on the segment from p1 to p2.
  # A point is on the segment if it's between the bounding box of p1 and p2.
  valid_points <- Filter(function(pt) {
    (pt[1] >= min(x1, x2) && pt[1] <= max(x1, x2) &&
     pt[2] >= min(y1, y2) && pt[2] <= max(y1, y2))
  }, intersections)

  if(length(valid_points) == 0) {
     # If no point is on the direct segment, it means the center of the node is inside
     # the other. We return the point closest to the *target* point p2.
     dists <- sapply(intersections, function(pt) sqrt((pt[1] - x2)^2 + (pt[2] - y2)^2))
     return(intersections[[which.min(dists)]])
  }

  # From the points on the segment, choose the one closest to the *start* point p1.
  dists <- sapply(valid_points, function(pt) sqrt((pt[1] - x1)^2 + (pt[2] - y1)^2))
  return(valid_points[[which.min(dists)]])
}

#' Calculate intersection between a line segment and an ellipse
#' @noRd
.intersection_line_ellipse <- function(p1, p2, ellipse_center, width, height) {
    # Using the robust method from Paul Bourke's geometry page.
    # http://www.paulbourke.net/geometry/ellipse/
    x1 <- p1[1]
    y1 <- p1[2]
    x2 <- p2[1]
    y2 <- p2[2]
    
    h <- ellipse_center[1]
    k <- ellipse_center[2]
    a <- width / 2  # semi-major axis
    b <- height / 2 # semi-minor axis

    # Shift line to be relative to ellipse center at (0,0)
    x1_rel <- x1 - h
    y1_rel <- y1 - k
    x2_rel <- x2 - h
    y2_rel <- y2 - k

    # Quadratic equation components
    A <- (x2_rel - x1_rel)^2 / a^2 + (y2_rel - y1_rel)^2 / b^2
    B <- 2 * (x1_rel * (x2_rel - x1_rel) / a^2 + y1_rel * (y2_rel - y1_rel) / b^2)
    C <- x1_rel^2 / a^2 + y1_rel^2 / b^2 - 1

    # Solve for u (parametric value for line segment)
    discriminant <- B^2 - 4 * A * C

    if (discriminant < 0) {
        # No real intersection, return original point (center of the node)
        return(p1)
    }

    # Two possible intersection points
    u1 <- (-B + sqrt(discriminant)) / (2 * A)
    u2 <- (-B - sqrt(discriminant)) / (2 * A)
    
    # We are looking for the intersection point that lies on the segment p1-p2,
    # which corresponds to a u value between 0 and 1.
    u <- NA
    if (u1 >= 0 && u1 <= 1) {
      u <- u1
    }
    if (u2 >= 0 && u2 <= 1 && (!is.na(u) && u2 < u || is.na(u))) {
      u <- u2
    }
    
    # If no intersection is on the segment (e.g., one node inside another),
    # find the closest intersection to the start point p1.
    if(is.na(u)){
        if (u1 < u2) u <- u1 else u <- u2
    }
    
    # Calculate intersection coordinates and shift back to original coordinate system
    ix <- x1 + (x2 - x1) * u
    iy <- y1 + (y2 - y1) * u

    return(c(ix, iy))
}
