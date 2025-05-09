tar_test("mask_pointers()", {
  str <- "function (x, y, z) \n.Call(<pointer: 0x116937930>, x, y, z)"
  x <- mask_pointers(str)
  expect_true(grepl("function", x))
  expect_true(grepl("Call", x))
  expect_false(grepl("pointer: 0x", x))
  expect_true(grepl("pointer: 0x", str))
})

tar_test("keyvalue_field()", {
  x <- c("bucket=bu", "region=reg", "key=sdfasdf")
  expect_equal(
    keyvalue_field(x = x, pattern = "^bucket="),
    "bu"
  )
  expect_equal(
    keyvalue_field(x = x, pattern = "^region="),
    "reg"
  )
  expect_equal(
    keyvalue_field(x = x, pattern = "^key="),
    "sdfasdf"
  )
})

tar_test("omit_null()", {
  x <- list(e = 1L, a = NULL, c = 2L, d = NULL, b = 3L)
  expect_length(x, 5)
  expect_named(x, c("e", "a", "c", "d", "b"))
  y <- omit_null(x)
  expect_equal(y, list(e = 1L, c = 2L, b = 3L))
  expect_length(y, 3)
  expect_named(y, c("e", "c", "b"))
})

tar_test("supported_args()", {
  f <- function(a, b, c = "c_default", d = "d_default", x = "x_default") {
  }
  args <- list(
    a = "a_value",
    b = "b_value",
    c = "c_value",
    d = NULL,
    e = "nope",
    f = NULL
  )
  out <- supported_args(fun = f, args = args)
  expect_equal(
    out,
    list(
      a = "a_value",
      b = "b_value",
      c = "c_value"
    )
  )
})

tar_test("setdiff_chr()", {
  expect_equal(setdiff_chr("x", character(0L)), "x")
  expect_equal(setdiff_chr(character(0L), "x"), character(0L))
  expect_equal(setdiff(c("d", "a", "b"), "a"), c("d", "b"))
})

tar_test("sort_chr()", {
  expect_equal(sort_chr(c("a", "b")), c("a", "b"))
  expect_equal(sort_chr(character(0L)), character(0L))
  expect_equal(sort_chr(""), "")
  expect_equal(sort_chr(NULL), character(0L))
})
