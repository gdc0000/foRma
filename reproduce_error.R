library(foRma)
library(dplyr)

# Mock data missing lineType
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
        label = c("0.25***")
        # lineType is missing
    )
)

# This should trigger the error
tryCatch(
    {
        result <- foRma:::parse_and_prepare_data(mock_json)
        print("Success!")
    },
    error = function(e) {
        print(paste("Caught error:", e$message))
    }
)
