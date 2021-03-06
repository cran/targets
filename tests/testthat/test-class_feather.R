tar_test("feather format", {
  skip_on_cran()
  skip_if_not_installed("arrow")
  envir <- new.env(parent = baseenv())
  envir$f <- function() {
    data.frame(x = 1, y = 2)
  }
  x <- target_init(
    name = "abc",
    expr = quote(f()),
    format = "feather"
  )
  builder_update_build(x, envir = envir)
  builder_update_paths(x)
  builder_update_object(x)
  exp <- envir$f()
  expect_equal(arrow::read_feather(x$store$file$path), exp)
  expect_equal(target_read_value(x)$object, exp)
  expect_silent(target_validate(x))
})

tar_test("bad compression level throws error", {
  skip_on_cran()
  skip_if_not_installed("arrow")
  tar_script({
    list(
      tar_target(
        abc,
        data.frame(x = 1, y = 2),
        format = "feather",
        resources = list(compression = "bad")
      )
    )
  })
  expect_error(tar_make(callr_function = NULL))
})

tar_test("feather packages", {
  x <- tar_target(x, 1, format = "feather")
  out <- store_get_packages(x$store)
  expect_equal(out, "arrow")
})

tar_test("feather format captures error messages", {
  tar_script(tar_target(x, stop("message123"), format = "feather"))
  expect_error(
    tar_make(callr_function = NULL),
    class = "tar_condition_run"
  )
  expect_equal(tar_meta(x, error)$error, "message123")
})

tar_test("same with error = \"continue\"", {
  tar_script(
    tar_target(x, stop("message123"), format = "feather", error = "continue")
  )
  tar_make(callr_function = NULL)
  expect_equal(tar_meta(x, error)$error, "message123")
})

tar_test("feather format cannot store non-data-frames", {
  tar_script(tar_target(x, 1:2, format = "feather"))
  expect_error(
    tar_make(callr_function = NULL),
    class = "tar_condition_validate"
  )
})

tar_test("same with error = \"continue\"", {
  tar_script(tar_target(x, 1:2, format = "feather", error = "continue"))
  expect_error(
    tar_make(callr_function = NULL),
    class = "tar_condition_validate"
  )
})

tar_test("does not inherit from tar_external", {
  store <- tar_target(x, "x_value", format = "feather")$store
  expect_false(inherits(store, "tar_external"))
})

tar_test("store_row_path()", {
  store <- tar_target(x, "x_value", format = "feather")$store
  store$file$path <- "path"
  expect_equal(store_row_path(store), NA_character_)
})

tar_test("store_path_from_record()", {
  store <- tar_target(x, "x_value", format = "feather")$store
  record <- record_init(name = "x", path = "path", format = "feather")
  expect_equal(store_path_from_record(store, record), path_objects("x"))
})
