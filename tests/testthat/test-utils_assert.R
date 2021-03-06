tar_test("assert_package()", {
  expect_error(assert_package("_illegal"), class = "tar_condition_targets")
})

tar_test("assert_chr_no_delim()", {
  expect_error(assert_chr_no_delim(0L), class = "tar_condition_validate")
  expect_error(assert_chr_no_delim("a|b"), class = "tar_condition_validate")
  expect_error(assert_chr_no_delim("a*b"), class = "tar_condition_validate")
})

tar_test("assert_dag() on a non-igraph", {
  expect_error(assert_dag(123), class = "tar_condition_validate")
})

tar_test("assert_dag() on a non-dag", {
  edges <- data_frame(from = c("a", "b"), to = c("b", "a"))
  igraph <- igraph::graph_from_data_frame(edges)
  expect_error(assert_dag(igraph), class = "tar_condition_validate")
})

tar_test("assert_dag() on a dag", {
  edges <- data_frame(from = c("a", "b"), to = c("b", "c"))
  igraph <- igraph::graph_from_data_frame(edges)
  expect_silent(assert_dag(igraph))
})

tar_test("assert_ge()", {
  expect_silent(assert_ge(2L, 1L))
  expect_silent(assert_ge(2L, 2L))
  expect_error(assert_ge(1L, 2L), class = "tar_condition_validate")
})

tar_test("assert_flag()", {
  expect_silent(assert_flag("x", letters))
  expect_error(assert_flag("xyz", letters), class = "tar_condition_validate")
})

tar_test("assert_function()", {
  expect_error(assert_function("not"), class = "tar_condition_validate")
})

tar_test("assert_df()", {
  expect_silent(assert_df(data_frame(x = 1)))
  expect_error(assert_df(TRUE), class = "tar_condition_validate")
})

tar_test("assert_in()", {
  expect_silent(assert_in("x", letters))
  expect_error(assert_in("xyz", letters), class = "tar_condition_validate")
})

tar_test("assert_not_in()", {
  expect_silent(assert_not_in("xyz", letters))
  expect_error(assert_not_in("x", letters), class = "tar_condition_validate")
})

tar_test("assert_inherits()", {
  expect_silent(assert_inherits(data_frame(x = 1), "data.frame"))
  expect_error(
    assert_inherits(TRUE, "data.frame"),
    class = "tar_condition_validate"
  )
})

tar_test("assert_le()", {
  expect_silent(assert_le(1L, 2L))
  expect_silent(assert_le(2L, 2L))
  expect_error(assert_le(2L, 1L), class = "tar_condition_validate")
})

tar_test("assert_lgl()", {
  expect_silent(assert_lgl(FALSE))
  expect_error(assert_lgl("abc"), class = "tar_condition_validate")
})

tar_test("assert_list()", {
  expect_silent(assert_list(list("abc")))
  expect_error(assert_list("abc"), class = "tar_condition_validate")
})

tar_test("assert_nonempty()", {
  expect_silent(assert_nonempty("abc"))
  expect_silent(assert_nonempty(NA_character_))
  expect_error(assert_nonempty(NULL), class = "tar_condition_validate")
  expect_error(assert_nonempty(character(0)), class = "tar_condition_validate")
})

tar_test("assert_none_na()", {
  expect_silent(assert_none_na("abc"))
  expect_error(
    assert_none_na(NA_character_),
    class = "tar_condition_validate"
  )
})

tar_test("assert_nonmissing()", {
  expect_silent(assert_nonmissing("abc"))
  expect_error(
    assert_nonmissing(substitute()),
    class = "tar_condition_validate"
  )
})

tar_test("assert_nzchar()", {
  expect_silent(assert_nzchar("abc"))
  expect_error(assert_nzchar(c("a", "")), class = "tar_condition_validate")
})

tar_test("assert_path()", {
  file.create("x")
  expect_error(assert_path(c("x", "y")), class = "tar_condition_validate")
  file.create("y")
  expect_silent(assert_path(c("x", "y")))
})

tar_test("assert_store()", {
  expect_error(assert_store(), class = "tar_condition_validate")
  dir.create("_targets")
  expect_silent(assert_store())
})

tar_test("assert_target", {
  expect_silent(assert_target(tar_target(x, 1)))
  expect_error(assert_target(1), class = "tar_condition_validate")
  expect_error(assert_target(list()), class = "tar_condition_validate")
})

tar_test("assert_target_list", {
  expect_silent(assert_target_list(list(tar_target(x, 1))))
  expect_silent(assert_target_list(list()))
  expect_error(
    assert_target_list(tar_target(x, 1)),
    class = "tar_condition_validate"
  )
  expect_error(assert_target_list(123), class = "tar_condition_validate")
})

tar_test("assert_script()", {
  old <- Sys.getenv("TAR_WARN")
  on.exit(Sys.setenv(TAR_WARN = old))
  Sys.setenv(TAR_WARN = "true")
  expect_error(assert_script(), class = "tar_condition_validate")
  file.create("_targets.R")
  expect_silent(assert_script())
  writeLines("tar_make()", "_targets.R")
  expect_error(assert_script(), class = "tar_condition_validate")
  tar_script({
    library(targets)
    pkgload::load_all()
    list(tar_target(x, 1))
  })
  expect_warning(assert_script(), class = "tar_condition_validate")
})

tar_test("assert_true()", {
  expect_silent(assert_true(TRUE, "x"))
  expect_error(assert_true(FALSE, "x"), class = "tar_condition_validate")
})

tar_test("assert_unique_targets()", {
  expect_silent(assert_unique_targets(letters))
  expect_error(
    assert_unique_targets(c("a", "a", "b", "b")),
    class = "tar_condition_validate"
  )
})
