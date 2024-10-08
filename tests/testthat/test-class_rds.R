tar_test("rds update_object()", {
  x <- target_init(name = "abc", expr = quote(a), format = "rds")
  builder_update_build(x, tmpenv(a = "123"))
  builder_update_paths(x, path_store_default())
  expect_false(file.exists(x$store$file$path))
  expect_true(is.na(x$store$file$hash))
  store_update_stage_early(x$store, "abc", path_store_default())
  builder_update_object(x)
  expect_true(file.exists(x$store$file$path))
  expect_false(is.na(x$store$file$hash))
  path <- file.path("_targets", "objects", "abc")
  expect_equal(readRDS(path), "123")
  expect_equal(target_read_value(x)$object, "123")
})

tar_test("misspelled format", {
  expect_error(
    tar_target(x, 1, format = "r2ds"),
    class = "tar_condition_validate"
  )
})

tar_test("rds packages", {
  x <- tar_target(x, 1, format = "rds")
  out <- store_get_packages(x$store)
  expect_equal(out, character(0))
})

tar_test("does not inherit from tar_external", {
  store <- tar_target(x, "x_value", format = "rds")$store
  expect_false(inherits(store, "tar_external"))
})

tar_test("store_row_path()", {
  store <- tar_target(x, "x_value", format = "rds")$store
  store$file$path <- "path"
  expect_equal(store_row_path(store), NA_character_)
})

tar_test("store_path_from_record()", {
  store <- tar_target(x, "x_value", format = "rds")$store
  record <- record_init(name = "x", path = "path", format = "rds")
  expect_equal(
    store_path_from_record(store, record, path_store_default()),
    path_objects(path_store_default(), "x")
  )
})
