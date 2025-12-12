# R/gemini_client.R

#' Query the Gemini API to generate a layout for a SEM model.
#'
#' @param input_text The raw statistical text (e.g., from lavaan summary).
#' @param api_key The Google Gemini API key.
#' @return A list parsed from the JSON response, containing nodes and edges.
#' @importFrom httr2 request req_body_json req_headers req_retry req_perform resp_status resp_body_string resp_body_json
#' @importFrom stringr str_remove_all
#' @importFrom jsonlite fromJSON
#' @importFrom magrittr %>%
#' @export
query_gemini <- function(input_text, api_key) {
  if (missing(input_text) || !is.character(input_text) || nchar(input_text) == 0) {
    stop("`input_text` must be a non-empty character string.", call. = FALSE)
  }
  if (missing(api_key) || !is.character(api_key) || nchar(api_key) == 0) {
    stop("`api_key` must be a non-empty character string. Set GEMINI_API_KEY environment variable or pass api_key parameter.", call. = FALSE)
  }
  
  # Graceful failure for CRAN checks
  if (identical(Sys.getenv("_R_CHECK_FORCE_SUGGESTS_"), "true")) {
    message("Skipping Gemini API call during CRAN checks")
    return(list(
      nodes = data.frame(
        id = c("node1", "node2"),
        label = c("Node 1", "Node 2"),
        x = c(200, 600),
        y = c(400, 400),
        type = c("OBSERVED", "OBSERVED"),
        width = c(100, 100),
        height = c(60, 60)
      ),
      edges = data.frame(
        sourceId = c("node1"),
        targetId = c("node2"),
        label = c("0.25***"),
        lineType = c("straight"),
        isSignificant = c(TRUE),
        labelPosition = c(0.5)
      )
    ))
  }
  
  # FIX: Usiamo il modello 1.5-flash che è stabile e pubblico
  api_url <- paste0(
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=",
    api_key
  )
  
  # Construct the request body
  body <- list(
    contents = list(
      list(role = "user", parts = list(list(text = GEMINI_SYSTEM_PROMPT))),
      list(role = "model", parts = list(list(text = "Understood. I am ready to receive the statistical text."))),
      list(role = "user", parts = list(list(text = input_text)))
    ),
    generationConfig = list(
      temperature = 0.1,
      response_mime_type = "application/json"
    )
  )
  
  # Build and perform the request
  req <- request(api_url) %>%
    req_body_json(body) %>%
    req_headers("Content-Type" = "application/json") %>%
    req_retry(max_tries = 3)
  
  resp <- tryCatch(
    req_perform(req),
    httr2_error = function(e) {
      stop(
        "Gemini API request failed. Status: ", resp_status(e$resp), "\n",
        "Body: ", resp_body_string(e$resp),
        call. = FALSE
      )
    }
  )
  
  # Extract and clean the content
  raw_content <- resp_body_json(resp, check_type = FALSE)
  
  # Safety check for response structure
  if(length(raw_content$candidates) == 0) {
    stop("Gemini returned no candidates. The model might be overloaded.", call. = FALSE)
  }
  
  json_text <- raw_content$candidates[[1]]$content$parts[[1]]$text
  
  if (is.null(json_text)) {
    stop("Failed to extract JSON text from the Gemini API response.", call. = FALSE)
  }
  
  # Clean the response
  json_text_cleaned <- str_remove_all(json_text, "^```json\\n|\\n```$")
  
  # FIX: simplifyVector = TRUE aiuta a ottenere dataframe direttamente
  parsed_data <- tryCatch(
    fromJSON(json_text_cleaned, simplifyVector = TRUE),
    error = function(e) {
      stop("Failed to parse JSON from Gemini response. Raw text was:\n", json_text_cleaned, call. = FALSE)
    }
  )
  
  # Validate the structure
  if (!all(c("nodes", "edges") %in% names(parsed_data))) {
    stop("The parsed JSON from Gemini does not contain the expected 'nodes' and 'edges' keys.", call. = FALSE)
  }
  
  return(parsed_data)
}