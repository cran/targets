tar_test("active$produce_exports(is_globalenv = FALSE)", {
  active <- active_new()
  envir <- new.env(parent = emptyenv())
  envir$target <- tar_target(x, 1)
  envir$pipeline <- pipeline_init()
  envir$algo <- local_init()
  envir$.hidden <- "hidden"
  envir$visible <- "visible"
  expect_true(inherits(envir$target, "tar_target"))
  expect_true(inherits(envir$pipeline, "tar_pipeline"))
  expect_true(inherits(envir$algo, "tar_algorithm"))
  out <- active$produce_exports(envir, is_globalenv = FALSE)
  expect_equal(names(out), ".tar_envir_5048826d")
  envir2 <- out[[".tar_envir_5048826d"]]
  expect_identical(envir, envir2)
  names <- c(".hidden", "visible")
  expect_equal(sort(names(envir2)), sort(names))
  expect_equal(envir2[[".hidden"]], "hidden")
  expect_equal(envir2[["visible"]], "visible")
})

tar_test("active$produce_exports(is_globalenv = TRUE)", {
  active <- active_new()
  envir <- new.env(parent = emptyenv())
  envir$target <- tar_target(x, 1)
  envir$pipeline <- pipeline_init()
  envir$algo <- local_init()
  envir$.hidden <- "hidden"
  envir$visible <- "visible"
  expect_true(inherits(envir$target, "tar_target"))
  expect_true(inherits(envir$pipeline, "tar_pipeline"))
  expect_true(inherits(envir$algo, "tar_algorithm"))
  out <- active$produce_exports(envir, is_globalenv = TRUE)
  names <- c(".hidden", "visible", ".tar_envir_5048826d")
  expect_equal(sort(names(out)), sort(names))
  expect_equal(out[[".tar_envir_5048826d"]], "globalenv")
  expect_equal(out[[".hidden"]], "hidden")
  expect_equal(out[["visible"]], "visible")
})
