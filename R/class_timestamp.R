timestamp_new <- function() {
  timestamp_class$new()
}

timestamp_class <- R6::R6Class(
  classname = "tar_timestamp",
  inherit = reporter_class,
  class = FALSE,
  portable = FALSE,
  cloneable = FALSE,
  public = list(
    report_running = function(target, progress = NULL) {
      cli_target(
        target_get_name(target),
        target_get_type_cli(target),
        time_stamp = TRUE
      )
    },
    report_skipped = function(target, progress) {
      cli_skip(
        target_get_name(target),
        target_get_type_cli(target),
        time_stamp = TRUE
      )
    },
    report_errored = function(target, progress = NULL) {
      cli_error(
        target_get_name(target),
        target_get_type_cli(target),
        time_stamp = TRUE
      )
    },
    report_cancelled = function(target = NULL, progress = NULL) {
      cli_cancel(
        target_get_name(target),
        target_get_type_cli(target),
        time_stamp = TRUE
      )
    },
    report_workspace = function(target) {
      cli_workspace(target_get_name(target), time_stamp = TRUE)
    },
    report_end = function(progress = NULL) {
      progress$cli_end(time_stamp = TRUE)
      super$report_end(progress)
    }
  )
)