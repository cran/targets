tar_test("tar_target_raw() works", {
  tar_option_set(envir = new.env(parent = baseenv()))
  x <- tar_target_raw("x", expression(get_data()))
  expect_silent(target_validate(x))
  expect_equal(target_get_name(x), "x")
  expect_equal(x$command$string, "expression(get_data())")
  expect_equal(x$settings$description, character(0L))
})

tar_test("tar_target_raw() description", {
  x <- tar_target_raw("x", expression(get_data()), description = "info")
  expect_silent(target_validate(x))
  expect_equal(x$settings$description, "info")
})

tar_test("tar_target_raw() gets priorities", {
  x <- tar_target_raw("x", quote(get_data()), priority = 0)
  expect_equal(x$settings$priority, 0)
})

tar_test("tar_target_raw() defines pattens correctly", {
  x <- tar_target_raw("x", expression(1), pattern = expression(map(y)))
  expect_silent(target_validate(x))
  expect_equal(x$settings$pattern, expression(map(y)))
  expect_equal(x$settings$dimensions, "y")
})

tar_test("tar_target_raw() receives options", {
  tar_option_set(format = "file")
  x <- tar_target_raw("x", "y")
  expect_equal(x$settings$format, "file")
})

tar_test("can set deps", {
  out <- tar_target_raw(
    "notebook",
    command = quote(abc)
  )
  expect_equal(out$deps, "abc")
  expect_true(grepl("abc", out$command$string))
  out <- tar_target_raw(
    "notebook",
    command = quote(abc),
    deps = "xyz"
  )
  expect_equal(out$deps, "xyz")
  expect_true(grepl("abc", out$command$string))
})

tar_test("can set string", {
  out <- tar_target_raw(
    "notebook",
    command = quote(abc)
  )
  expect_equal(out$deps, "abc")
  expect_true(grepl("abc", out$command$string))
  out <- tar_target_raw(
    "notebook",
    command = quote(abc),
    string = "xyz"
  )
  expect_equal(out$deps, "abc")
  expect_equal(out$command$string, "xyz")
})

tar_test("no name", {
  expect_error(
    tar_target_raw(command = quote(1)),
    class = "tar_condition_validate"
  )
})

tar_test("no command", {
  expect_error(tar_target_raw("abc"), class = "tar_condition_validate")
})

tar_test("declaring a target does not run its command", {
  x <- tar_target_raw("y", quote(file.create("x")))
  expect_false(file.exists("x"))
})
