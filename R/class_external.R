#' @export
store_row_path.tar_external <- function(store) {
  store$file$path
}

#' @export
store_path_from_record.tar_external <- function(store, record) {
  record$path
}
