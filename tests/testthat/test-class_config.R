tar_test("config$validate()", {
  path <- tempfile()
  out <- config_init(path)
  expect_silent(out$validate())
  file.create(path)
  expect_silent(out$validate())
  out$ensure()
  expect_silent(out$validate())
})

tar_test("config$get_value()", {
  path <- tempfile()
  out <- config_init(path = path)
  expect_null(out$get_value("store"))
  writeLines("store: path", path)
  expect_equal(out$get_value("store"), "path")
  expect_equal(out$get_value("store"), "path")
  writeLines("store: path2", path)
  expect_equal(out$get_value("store"), "path2")
  unlink(path)
  expect_null(out$get_value("store"))
  writeLines("store: path3", path)
  expect_equal(out$get_value("store"), "path3")
})

tar_test("path_store() with config$get_value(\"store\")", {
  tar_config$unset_lock()
  expect_equal(path_store(), "_targets")
  writeLines("store: path", "_targets.yaml")
  expect_equal(path_store(), "path")
  expect_equal(path_store(), "path")
  writeLines("store: path2", "_targets.yaml")
  expect_equal(path_store(), "path2")
  unlink("_targets.yaml")
  expect_equal(path_store(), "_targets")
  writeLines("store: path3", "_targets.yaml")
  expect_equal(path_store(), "path3")
})

tar_test("config$set_value() on an empty _targets.yaml", {
  path <- tempfile()
  out <- config_init(path = path)
  out$set_value(name = "store", "path2")
  expect_equal(out$get_value("store"), "path2")
  expect_true(any(grepl("path2", readLines(path))))
})

tar_test("config$set_value() on a _targets.yaml with other settings", {
  path <- tempfile()
  lines <- c("store: path1", "other: value")
  writeLines(lines, path)
  out <- config_init(path = path)
  out$set_value(name = "store", "path2")
  expect_equal(out$get_value("store"), "path2")
  lines <- readLines(path)
  expect_true(any(grepl("path2", readLines(path))))
  expect_true(any(grepl("value", readLines(path))))
})

tar_test("locking", {
  path <- tempfile()
  out <- config_init(path = path)
  out$set_value(name = "store", "path2")
  expect_equal(out$get_value("store"), "path2")
  out$set_lock()
  expect_equal(out$get_value("store"), "path2")
  out$set_value(name = "store", "path3")
  expect_equal(out$get_value("store"), "path2")
  expect_true(any(grepl("path2", readLines(path))))
  writeLines("store: path3", path)
  expect_equal(out$get_value("store"), "path2")
  out$unset_lock()
  expect_equal(out$get_value("store"), "path3")
  out$set_value(name = "store", "path4")
  expect_true(any(grepl("path4", readLines(path))))
  expect_equal(out$get_value("store"), "path4")
})
