#' Paging
#' 
#' Helper functions that make paging easier in
#' the RStudio Connect Server API.
#' 
#' @rdname paging
#' 
#' @param client A Connect client object
#' @param req The request that needs to be paged
#' @param limit A row limit
#' 
#' @return The aggregated results from all requests
#' 
#' @export
page_cursor <- function(client, req, limit = Inf) {
  qreq <- rlang::enquo(req)
  
  prg <- progress::progress_bar$new(
    format = "downloading page :current (:tick_rate/sec) :elapsedfull",
    total = NA,
    clear = FALSE
  )
  
  prg$tick()
  response <- rlang::eval_tidy(qreq)
  
  res <- response$results
  while(!is.null(response$paging$`next`) && length(res) < limit) {
    prg$tick()
    response <- client$GET_URL(response$paging$`next`)
    res <- c(res, response$results)
  }
  return(res)
}
# TODO: Decide if this `limit = Inf` is helpful or a hack...
#       it is essentially a "row limit" on paging