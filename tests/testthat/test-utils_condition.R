tar_test("tar_throw_prelocal()", {
  expect_error(
    tar_throw_prelocal("x"),
    class = "tar_condition_prelocal"
  )
})

tar_test("tar_throw_run() forwards custom error condition", {
  out <- tryCatch(
    tar_throw_run("x", class = c("my_class_1", "my_class_2")),
    error = function(condition) class(condition)
  )
  expect_true("my_class_1" %in% out)
  expect_true("my_class_2" %in% out)
})

tar_test("special case in safe_condition_class()", {
  class <- c("rlib_error_package_not_found", "another")
  expect_equal(safe_condition_class(class), "another")
})
