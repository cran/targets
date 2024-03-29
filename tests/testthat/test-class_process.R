tar_test("process database subkey", {
  out <- process_init()
  expect_equal(
    out$database$key,
    file.path(path_store_default(), "meta", "process")
  )
})

tar_test("process$produce_process()", {
  x <- process_init()
  out <- x$produce_process()
  expect_equal(sort(colnames(out)), sort(c("name", "value")))
  names <- c("pid", "version_r", "version_targets")
  expect_true(all(names %in% out$name))
  expect_true(all(nzchar(out$value)))
  expect_true(is.finite(as.integer(out$value[out$name == "pid"])))
  expect_false(file.exists(x$database$path))
})

tar_test("process$update_process()", {
  x <- process_init()
  x$update_process()
  out <- x$get_process()
  expect_equal(sort(colnames(out)), sort(c("name", "value")))
  names <- c("pid", "version_r", "version_targets")
  expect_true(all(names %in% out$name))
  expect_true(all(nzchar(out$value)))
  expect_true(is.finite(as.integer(out$value[out$name == "pid"])))
  expect_false(file.exists(x$database$path))
})

tar_test("process$read_process()", {
  x <- process_init()
  expect_false(file.exists(x$database$path))
  x$record_process()
  expect_true(file.exists(x$database$path))
  out <- x$read_process()
  expect_equal(sort(colnames(out)), sort(c("name", "value")))
  names <- c("pid", "version_r", "version_targets")
  expect_true(all(names %in% out$name))
  expect_true(all(nzchar(out$value)))
  expect_true(is.finite(as.integer(out$value[out$name == "pid"])))
})

tar_test("process$record_process()", {
  x <- process_init()
  expect_false(file.exists(x$database$path))
  x$record_process()
  expect_true(file.exists(x$database$path))
  out <- readLines(x$database$path)
  expect_true(any(grepl("pid", out)))
  expect_true(any(grepl("version_r", out)))
  expect_true(any(grepl("version_targets", out)))
})

tar_test("pid from tar_make(callr_function = NULL)", {
  x <- process_init()
  tar_script(tar_target(x_target, 1))
  expect_false(file.exists(path_process(path_store_default())))
  tar_make(callr_function = NULL)
  expect_true(file.exists(path_process(path_store_default())))
  out <- process_init(path_store_default())$read_process()
  pid <- as.integer(out$value[out$name == "pid"])
  expect_equal(pid, Sys.getpid())
})

tar_test("pid from tar_make()", {
  skip_cran()
  x <- process_init()
  tar_script(tar_target(x, 1))
  expect_false(file.exists(path_process(path_store_default())))
  tar_make(reporter = "silent")
  expect_true(file.exists(path_process(path_store_default())))
  out <- process_init(path_store_default())$read_process()
  pid <- as.integer(out$value[out$name == "pid"])
  expect_false(pid == Sys.getpid())
})

tar_test("process$validate()", {
  x <- process_init()
  expect_silent(x$validate())
})
