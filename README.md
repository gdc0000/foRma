# `foRma`: An R Package for Visualizing Structural Equation Models

`foRma` is a rule-based rendering engine that transforms a specific JSON input, representing a Structural Equation Model (SEM), into a high-quality, publication-ready static image. It is built using a minimal set of powerful R packages: `ggplot2`, `ggforce`, and `dplyr`.

## Features
- **Publication-Quality Graphics**: Creates beautiful diagrams suitable for academic papers and presentations.
- **ggplot2-based**: Leverages the power and flexibility of the `ggplot2` ecosystem.
- **No System Dependencies**: Purely R-based. Does not require external programs like Graphviz or Java.
- **Intelligent Arrow Drawing**: Automatically calculates the precise intersection between arrows and the boundary of nodes (ellipses or rectangles), ensuring a clean, professional look.
- **Standard SEM Visuals**:
    - **Latent** variables are rendered as ellipses.
    - **Observed** variables are rendered as rectangles.
    - **Regressions** are straight, single-headed arrows.
    - **Covariances** are curved, double-headed arrows.
    - **Path significance** is shown with solid (significant) or dashed (non-significant) lines.

---

## Tutorial: Your First SEM Plot

This guide will walk you through creating your first SEM diagram with `foRma`.

### Step 1: Understand the JSON Input

The "brain" of your plot is a JSON file that describes every part of your model. You don't need to calculate layout positions; you just need to provide the data.

The JSON has two main parts: `nodes` and `edges`.

- **`nodes`**: These are your variables. A latent variable (like "Factor A") has `type: "LATENT"`, and an observed variable (like a survey item) has `type: "OBSERVED"`. Each node has an `id`, a `label` to display, and `x`, `y` coordinates for its center.
- **`edges`**: These are the paths between your variables. An edge connects a `sourceId` to a `targetId`. It has a `label` (the coefficient), a `lineType` (`straight` for regression, `curved` for covariance), and a boolean `isSignificant`.

Here is the example from `graph_data.json`:
```json
{
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
}
```

### Step 2: Get R Ready

1.  **Install R and RStudio**: If you haven't already, download and install R and RStudio.
2.  **Install Packages**: `foRma` requires a few other packages to work. Open RStudio and run this command in the console:
    ```R
    install.packages(c("ggplot2", "ggforce", "jsonlite", "dplyr", "purrr"))
    ```
3.  **Load the `foRma` functions**: To use the package, you need to load its functions into your R session. You can do this by "sourcing" the files. Make sure your R session's working directory is set to the `foRma` folder.
    ```R
    # Load all the functions needed to draw the plot
    source("R/parser.R")
    source("R/utils_geometry.R")
    source("R/renderer.R")
    ```

### Step 3: Write the R Script to Create the Plot

Now for the fun part. Create a new R script in RStudio and add the following code:

```R
# Define the path to your data
my_json_file <- "graph_data.json"

# Call the main drawing function
# This reads the JSON and creates the plot object
my_sem_plot <- draw_sem(json_data = my_json_file)

# Print the plot to the screen
print(my_sem_plot)

# Save the plot to a file (e.g., a PNG)
# You can also save to PDF, SVG, etc. by changing the filename
ggsave(
  "my_first_sem_plot.png",
  plot = my_sem_plot,
  width = 7,
  height = 5,
  dpi = 300
)
```

### Step 4: Run the Script!

Run your script. You will see your plot appear in the "Plots" pane of RStudio, and a high-quality `my_first_sem_plot.png` file will be saved in your project directory.

---

## Technical Documentation

This section details the internal architecture and functions of the `foRma` package.

### Package Architecture

The package logic is split into three main files:

1.  **`R/parser.R`**: This is the input layer. Its primary role is to ingest the user-provided JSON (either as a file path or a raw string), validate it, and transform it into clean `tibble` (data frame) objects that the rest of the package can work with.
2.  **`R/utils_geometry.R`**: This is the computational core of the package. It solves the critical problem of connecting arrows to the edge of a node rather than its center. It contains mathematical functions to calculate the exact intersection point between a line segment (representing an edge) and the perimeter of a rectangle or an ellipse.
3.  **`R/renderer.R`**: This is the rendering engine. It orchestrates the entire plotting process. It calls the parser to get the data, uses the geometry utilities to calculate precise start/end coordinates for every arrow, and then systematically builds the final `ggplot` object layer by layer. The coordinate system is inverted (`scale_y_reverse()`) to match the common top-left origin of many diagramming tools.

### Core Functions

-   **`draw_sem(json_data)`**: The main, user-facing function.
    -   `json_data`: A `character` string which can be a path to a valid JSON file or a string containing the JSON data itself.
    -   Returns: A `ggplot` object, which can be printed or further customized.

-   **`parse_sem_json(json_data)`**: The internal parsing function.
    -   `json_data`: File path or JSON string.
    -   Returns: A `list` containing two `tibbles`: `nodes_df` and `edges_df`.

-   **`calculate_intersection(...)`**: The internal geometry helper. It dispatches to either `.intersection_line_ellipse` or `.intersection_line_rectangle` based on the node `type`. The functions solve a system of equations for the line and the shape boundary to find the intersection point on the line segment that lies on the shape's perimeter.

### Expected JSON Schema

For the package to work, the input JSON must strictly adhere to the following structure.

#### Node Object
Located in the `nodes` array.
| Field         | Type      | Description                                                 | Example      |
|---------------|-----------|-------------------------------------------------------------|--------------|
| `id`          | `String`  | A unique identifier for the node.                           | `"lat1"`     |
| `x`           | `Number`  | The horizontal coordinate of the node's center.             | `400`        |
| `y`           | `Number`  | The vertical coordinate of the node's center.               | `100`        |
| `label`       | `String`  | The text to be displayed inside the node.                   | `"Factor A"` |
| `type`        | `String`  | The node's shape. Must be `"LATENT"` or `"OBSERVED"`.       | `"LATENT"`   |
| `width`       | `Number`  | The total width of the node.                                | `100`        |
| `height`      | `Number`  | The total height of the node.                               | `60`         |

#### Edge Object
Located in the `edges` array.
| Field           | Type      | Description                                                       | Example       |
|-----------------|-----------|-------------------------------------------------------------------|---------------|
| `id`            | `String`  | A unique identifier for the edge.                                 | `"e1"`        |
| `sourceId`      | `String`  | The `id` of the node where the edge starts.                       | `"lat1"`      |
| `targetId`      | `String`  | The `id` of the node where the edge ends.                         | `"obs1"`      |
| `label`         | `String`  | The text label for the edge (e.g., path coefficient).             | `"0.85"`      |
| `isSignificant` | `Boolean` | If `true`, the line is solid. If `false`, the line is dashed.      | `true`        |
| `lineType`      | `String`  | The type of path. Must be `"straight"` or `"curved"`.             | `"straight"`  |

