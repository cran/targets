verbose_new <- function() {
  verbose_class$new()
}

verbose_class <- R6::R6Class(
  classname = "tar_verbose",
  inherit = reporter_class,
  class = FALSE,
  portable = FALSE,
  cloneable = FALSE,
  public = list(
    report_started = function(target, progress = NULL) {
      cli_start(target_get_name(target), target_get_type_cli(target))
    },
    report_built = function(target, progress = NULL) {
      cli_built(target_get_name(target), target_get_type_cli(target))
    },
    report_skipped = function(target, progress = NULL) {
      cli_skip(target_get_name(target), target_get_type_cli(target))
    },
    report_errored = function(target, progress = NULL) {
      cli_error(target_get_name(target), target_get_type_cli(target))
    },
    report_canceled = function(target = NULL, progress = NULL) {
      cli_cancel(target_get_name(target), target_get_type_cli(target))
    },
    report_workspace = function(target) {
      cli_workspace(target_get_name(target))
    },
    report_end = function(progress = NULL) {
      progress$cli_end()
      super$report_end(progress)
    }
  )
)
