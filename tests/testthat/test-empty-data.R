df0 <- data_frame(mpg = numeric(0), wt = numeric(0), am = numeric(0), cyl = numeric(0))

test_that("layers with empty data are silently omitted", {
  # Empty data (no visible points)
  d <- ggplot(df0, aes(mpg,wt)) + geom_point()
  expect_equal(nrow(get_layer_data(d)), 0)

  d <- ggplot() + geom_point(data = df0, aes(mpg,wt))
  expect_equal(nrow(get_layer_data(d)), 0)

  # Regular mtcars data, x=mpg, y=wt, normal points and points from empty data frame
  d <- ggplot(mtcars, aes(mpg, wt)) + geom_point() + geom_point(data = df0)
  expect_equal(nrow(get_layer_data(d, 1)), nrow(mtcars))
  expect_equal(nrow(get_layer_data(d, 2)), 0)

  # Regular mtcars data, but points only from empty data frame
  d <- ggplot(mtcars, aes(mpg, wt)) + geom_point(data = df0)
  expect_equal(nrow(get_layer_data(d, 1)), 0)
})

test_that("plots with empty data and vectors for aesthetics work", {
  d <- ggplot(NULL, aes(1:5, 1:5)) + geom_point()
  expect_equal(nrow(get_layer_data(d)), 5)

  d <- ggplot(data_frame(), aes(1:5, 1:5)) + geom_point()
  expect_equal(nrow(get_layer_data(d)), 5)

  d <- ggplot() + geom_point(aes(1:5, 1:5))
  expect_equal(nrow(get_layer_data(d)), 5)
})

test_that("layers with empty data are silently omitted with facet_wrap", {
  # Empty data, facet_wrap, throws error
  d <- ggplot(df0, aes(mpg, wt)) +
    geom_point() +
    facet_wrap(~cyl)
  expect_snapshot(get_layer_data(d), error = TRUE)

  d <- d + geom_point(data = mtcars)
  expect_equal(nrow(get_layer_data(d, 1)), 0)
  expect_equal(nrow(get_layer_data(d, 2)), nrow(mtcars))
})

test_that("layers with empty data are silently omitted with facet_grid", {
  d <- ggplot(df0, aes(mpg, wt)) +
    geom_point() +
    facet_grid(am ~ cyl)
  expect_snapshot(get_layer_data(d), error = TRUE)

  d <- d + geom_point(data = mtcars)
  expect_equal(nrow(get_layer_data(d, 1)), 0)
  expect_equal(nrow(get_layer_data(d, 2)), nrow(mtcars))
})

test_that("empty data overrides plot defaults", {
  test_that("Should error when totally empty data frame because there's no x and y", {
    skip_if(getRversion() <= "4.4.0")
    d <- ggplot(mtcars, aes(mpg, wt)) +
      geom_point() +
      geom_point(data = data_frame())
    expect_snapshot(get_layer_data(d), error = TRUE)
  })

  # No extra points when x and y vars don't exist but are set
  d <- ggplot(mtcars, aes(mpg, wt)) +
    geom_point() +
    geom_point(data = data_frame(), x = 20, y = 3)
  expect_equal(nrow(get_layer_data(d, 1)), nrow(mtcars))
  expect_equal(nrow(get_layer_data(d, 2)), 0)

  # No extra points when x and y vars are empty, even when aesthetics are set
  d <- ggplot(mtcars, aes(mpg, wt)) +
    geom_point() +
    geom_point(data = df0, x = 20, y = 3)
  expect_equal(nrow(get_layer_data(d, 1)), nrow(mtcars))
  expect_equal(nrow(get_layer_data(d, 2)), 0)
})

test_that("layer inherits data from plot when data = NULL", {
  d <- ggplot(mtcars, aes(mpg, wt)) +
    geom_point(data = NULL)
  expect_equal(nrow(get_layer_data(d)), nrow(mtcars))
})

test_that("empty layers still generate one grob per panel", {
  df <- data_frame(x = 1:3, y = c("a", "b", "c"))

  d <- ggplot(df, aes(x, y)) +
    geom_point(data = df[0, ]) +
    geom_point() +
    facet_wrap(~y)

  expect_length(get_layer_grob(d), 3)
})

test_that("missing layers generate one grob per panel", {
  df <- data_frame(x = 1:4, y = rep(1:2, 2), g = rep(1:2, 2))
  base <- ggplot(df, aes(x, y)) + geom_point(shape = NA, na.rm = TRUE)

  expect_length(get_layer_grob(base), 1)
  expect_length(get_layer_grob(base + facet_wrap(~ g)), 2)
})
