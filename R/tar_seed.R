#' @title Get the random number generator seed of the target currently running.
#' @export
#' @family utilities
#' @description Get the random number generator seed
#'   of the target currently running.
#' @details A target's random number generator seed
#'   is a deterministic function of its name. In this way,
#'   each target runs with a reproducible seed so someone else
#'   running the same pipeline should get the same results,
#'   and no two targets in the same pipeline share the same seed.
#'   (Even dynamic branches have different names and thus different seeds.)
#'   You can retrieve the seed of a completed target
#'   with `tar_meta(your_target, seed)`
#'   and run `set.seed()` on the result to locally
#'   recreate the target's initial RNG state.
#' @return Integer of length 1. If invoked inside a `targets` pipeline,
#'   the return value is the seed of the target currently running,
#'   which is a deterministic function of the target name. Otherwise,
#'   the return value is `default`.
#' @param default Integer, value to return if `tar_seed()`
#'   is called on its own outside a `targets` pipeline.
#'   Having a default lets users run things without [tar_make()],
#'   which helps peel back layers of code and troubleshoot bugs.
#' @examples
#' tar_seed()
#' tar_seed(default = 123L)
#' if (identical(Sys.getenv("TAR_LONG_EXAMPLES"), "true")) {
#' tar_dir({ # tar_dir() runs code from a temporary directory.
#' tar_script(tar_target(returns_seed, tar_seed()), ask = FALSE)
#' tar_make()
#' tar_read(returns_seed)
#' })
#' }
tar_seed <- function(default = 1L) {
  default <- as.integer(default)
  assert_int(default)
  assert_scalar(default)
  if_any(
    exists(x = "target", envir = tar_envir_run, inherits = FALSE),
    get(x = "target", envir = tar_envir_run)$command$seed,
    as.integer(default)
  )
}
