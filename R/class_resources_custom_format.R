resources_custom_format_init <- function(
  envvars = NULL
) {
  resources_custom_format_new(
    envvars = envvars
  )
}

resources_custom_format_new <- function(
  envvars = NULL
) {
  out <- new.env(parent = emptyenv(), hash = FALSE)
  out$envvars <- envvars
  enclass(out, resources_custom_format_s3_class)
}

resources_custom_format_s3_class <- c(
  "tar_resources_custom_format",
  "tar_resources"
)

#' @export
resources_validate.tar_resources_custom_format <- function(resources) {
  if (!is.null(resources$envvars)) {
    tar_assert_chr(resources$envvars)
    tar_assert_none_na(resources$envvars)
    tar_assert_named(resources$controller)
  }
}

#' @export
print.tar_resources_custom_format <- function(x, ...) {
  cat(
    "<tar_resources_custom_format>\n ",
    paste0(paste_list(as.list(x)), collapse = "\n  ")
  )
}
