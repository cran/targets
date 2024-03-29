tar_test("active$produce_exports(is_globalenv = FALSE)", {
  tar_runtime$fun <- "tar_make"
  on.exit(tar_runtime$fun <- NULL)
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
  out <- active$produce_exports(
    envir,
    path_store_default(),
    is_globalenv = FALSE
  )
  expect_equal(
    sort(names(out)),
    sort(
      c(
        ".tar_envir_5048826d",
        ".tar_path_store_5048826d",
        ".tar_fun_5048826d",
        ".tar_options_5048826d",
        ".tar_envvars_5048826d"
      )
    )
  )
  expect_true(is.character(out[[".tar_path_store_5048826d"]]))
  envir2 <- out[[".tar_envir_5048826d"]]
  expect_identical(envir, envir2)
  names <- c(".hidden", "visible")
  expect_equal(sort(names(envir2)), sort(names))
  expect_equal(envir2[[".hidden"]], "hidden")
  expect_equal(envir2[["visible"]], "visible")
})

tar_test("active$produce_exports(is_globalenv = TRUE)", {
  tar_runtime$fun <- "tar_make"
  on.exit(tar_runtime$fun <- NULL)
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
  out <- active$produce_exports(
    envir,
    path_store_default(),
    is_globalenv = TRUE
  )
  names <- c(
    ".hidden",
    "visible",
    ".tar_envir_5048826d",
    ".tar_path_store_5048826d",
    ".tar_fun_5048826d",
    ".tar_options_5048826d",
    ".tar_envvars_5048826d"
  )
  expect_equal(sort(names(out)), sort(names))
  expect_true(is.character(out[[".tar_path_store_5048826d"]]))
  expect_equal(out[[".tar_envir_5048826d"]], "globalenv")
  expect_equal(out[[".hidden"]], "hidden")
  expect_equal(out[["visible"]], "visible")
})

tar_test(".gitignore", {
  tar_script()
  path <- path_gitignore(path_store_default())
  expect_equal(path, file.path(path_store_default(), ".gitignore"))
  expect_false(file.exists(path))
  tar_make(callr_function = NULL)
  expect_true(file.exists(path))
  unlink(path)
  tar_make(callr_function = NULL)
  expect_false(file.exists(path))
})
