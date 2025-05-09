tar_test("run timestamp reporter", {
  pipeline <- pipeline_init(list(target_init("x", quote(0))))
  for (index in seq_len(2L)) {
    local <- local_init(pipeline, reporter = "timestamp")
    expect_message(local$run())
  }
})

tar_test("run timestamp reporter with a error and saved workspace", {
  tar_option_set(workspace_on_error = TRUE)
  pipeline <- pipeline_init(
    list(
      target_init("x", quote(stop(123)))
    )
  )
  local <- local_init(pipeline, reporter = "timestamp")
  expect_error(expect_message(local$run()), class = "tar_condition_run")
})

tar_test("run timestamp reporter workspace upload", {
  reporter <- reporter_init("timestamp")
  expect_message(reporter$report_workspace_upload(tar_target(s, 1)))
})

tar_test("run timestamp reporter with a warning", {
  pipeline <- pipeline_init(list(target_init("x", quote(warning(123)))))
  local <- local_init(pipeline, reporter = "timestamp")
  suppressWarnings(
    expect_warning(local$run(), class = "tar_condition_run")
  )
})

tar_test("run timestamp reporter with a cancellation", {
  pipeline <- pipeline_init(
    list(target_init("x", quote(targets::tar_cancel())))
  )
  local <- local_init(pipeline, reporter = "timestamp")
  expect_message(local$run())
})

tar_test("timestamp reporter retry message", {
  x <- timestamp_new()
  expect_message(x$report_retry(tar_target(x, TRUE)))
})

tar_test("report_pattern()", {
  x <- timestamp_new()
  expect_message(x$report_pattern(tar_target(x, TRUE, pattern = map(y))))
})

tar_test("validate timestamp reporter", {
  expect_silent(reporter_init("timestamp")$validate())
})
