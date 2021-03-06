# Exponential backoff algorithm
# similar to https://en.wikipedia.org/wiki/Exponential_backoff
backoff_init <- function(min = 0.01, max = 5, rate = 1.5) {
  backoff_new(
    min = max(sqrt(.Machine$double.eps), min),
    max = max,
    rate = rate,
    index = 0L
  )
}

backoff_new <- function(
  min = NULL,
  max = NULL,
  rate = NULL,
  index = NULL
) {
  backoff_class$new(
    min = min,
    max = max,
    rate = rate,
    index = index
  )
}

backoff_class <- R6::R6Class(
  classname = "tar_backoff",
  class = FALSE,
  portable = FALSE,
  cloneable = FALSE,
  public = list(
    min = NULL,
    max = NULL,
    rate = NULL,
    index = NULL,
    initialize = function(
      min = NULL,
      max = NULL,
      rate = NULL,
      index = NULL
    ) {
      self$min <- min
      self$max <- max
      self$rate <- rate
      self$index <- index
    },
    reset = function() {
      self$index <- 0L
    },
    increment = function() {
      self$index <- min(self$index + 1L, as.integer(1e9))
    },
    bound = function() {
      min(self$max, (self$min) * ((self$rate) ^ (self$index)))
    },
    interval = function() {
      stats::runif(n = 1L, min = self$min, max = self$bound())
    },
    wait = function() {
      Sys.sleep(self$interval())
      self$increment()
    },
    validate = function() {
      assert_scalar(self$min)
      assert_scalar(self$max)
      assert_scalar(self$rate)
      assert_scalar(self$index)
      assert_dbl(self$min)
      assert_dbl(self$max)
      assert_dbl(self$rate)
      assert_int(self$index)
      assert_ge(self$min, sqrt(.Machine$double.eps))
      assert_ge(self$max, self$min)
      assert_ge(self$rate, 1)
      assert_ge(self$index, 0L)
    }
  )
)
