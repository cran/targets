#' @export
store_new.file <- function(class, file = NULL, resources = NULL) {
  store_file_new(file, resources)
}

store_file_new <- function(file = NULL, resources = NULL) {
  force(file)
  force(resources)
  enclass(environment(), c("tar_store_file", "tar_external", "tar_store"))
}

#' @export
store_assert_format_setting.file <- function(class) {
}

#' @export
store_read_path.tar_store_file <- function(store, path) {
  path
}

#' @export
store_write_object.tar_store_file <- function(store, object) {
}

#' @export
store_write_path.tar_store_file <- function(store, object, path) {
}

#' @export
store_produce_path.tar_store_file <- function(store, name, object) { # nolint
  object
}

#' @export
store_cast_object.tar_store_file <- function(store, object) { # nolint
  as.character(object)
}

#' @export
store_assert_format.tar_store_file <- function(store, object, name) { # nolint
  if (!is.character(object)) {
    throw_validate(
      "target ", name, " did not return a character. ",
      "dynamic files (targets with format = \"file\") must return ",
      "character vectors of file or directory paths."
    )
  }
}

#' @export
store_early_hash.tar_store_file <- function(store, target) { # nolint
  file_update_hash(store$file)
}

#' @export
store_late_hash.tar_store_file <- function(store, target) { # nolint
}

#' @export
store_ensure_correct_hash.tar_store_file <- function(
  store,
  storage,
  deployment
) {
  if_any(
    identical(deployment, "worker"),
    store_wait_correct_hash(store),
    assert_path(store$file$path)
  )
}
