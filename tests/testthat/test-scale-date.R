base_time <- function(tz = "") {
  as.POSIXct(strptime("2015-06-01", "%Y-%m-%d", tz = tz))
}

df <- data_frame(
  time1 = base_time("") + 0:6 * 3600,
  time2 = base_time("UTC") + 0:6 * 3600,
  time3 = base_time("Australia/Lord_Howe") + (0:6 + 13) * 3600, # has half hour offset
  y = seq_along(base_time)
)

test_that("inherits timezone from data", {
  if (!is.null(attr(df$time1, "tzone")))
     skip("Local time zone not available")

  # Local time
  p <- ggplot(df, aes(y = y)) + geom_point(aes(time1))
  sc <- get_panel_scales(p)$x

  expect_true(identical(sc$timezone, NULL))
  expect_equal(sc$get_labels()[1], "00:00")

  # UTC
  p <- ggplot(df, aes(y = y)) + geom_point(aes(time2))
  sc <- get_panel_scales(p)$x
  expect_equal(sc$timezone, "UTC")
  expect_equal(sc$get_labels()[1], "00:00")
})


test_that("first timezone wins", {
  p <- ggplot(df, aes(y = y)) +
    geom_point(aes(time2)) +
    geom_point(aes(time3), colour = "red") +
    scale_x_datetime(date_breaks = "hour", date_labels = "%H:%M")
  sc <- get_panel_scales(p)$x
  expect_equal(sc$timezone, "UTC")
})

test_that("not cached across calls", {
  scale_x <- scale_x_datetime(date_breaks = "hour", date_labels = "%H:%M")

  p1 <- ggplot(df, aes(y = y)) + geom_point(aes(time2)) + scale_x
  p2 <- ggplot(df, aes(y = y)) + geom_point(aes(time3)) + scale_x

  expect_equal(get_panel_scales(p1)$x$timezone, "UTC")
  expect_equal(get_panel_scales(p2)$x$timezone, "Australia/Lord_Howe")
})

test_that("time scale date breaks and labels work", {
  skip_if_not_installed("hms")

  d <- c(base_time(), base_time() + 5 * 24 * 3600) - base_time()

  sc <- scale_x_time(date_breaks = "1 day", date_labels = "%d")
  sc$train(d)

  breaks <- sc$get_breaks()
  expect_length(breaks, 6)
  labels <- sc$get_labels(breaks)
  expect_equal(labels, paste0("0", 1:6))
})

test_that("datetime size scales work", {
  p <- ggplot(df, aes(y = y)) + geom_point(aes(time1, size = time1))

  # Default size range is c(1, 6)
  expect_equal(range(get_layer_data(p)$size), c(1, 6))
})

test_that("datetime alpha scales work", {
  p <- ggplot(df, aes(y = y)) + geom_point(aes(time1, alpha = time1))

  # Default alpha range is c(0.1, 1.0)
  expect_equal(range(get_layer_data(p)$alpha), c(0.1, 1.0))
})

test_that("datetime colour scales work", {
  p <- ggplot(df, aes(y = y)) +
    geom_point(aes(time1, colour = time1)) +
    scale_colour_datetime()

  expect_equal(range(get_layer_data(p)$colour), c("#132B43", "#56B1F7"))
})

test_that("date(time) scales throw warnings when input is incorrect", {
  p <- ggplot(data.frame(x = 1, y = 1), aes(x, y)) + geom_point()

  expect_snapshot_warning(ggplot_build(p + scale_x_date()))
  expect_snapshot_warning(ggplot_build(p + scale_x_datetime()))

  expect_snapshot(
    ggplot_build(p + scale_x_date(date_breaks = c(11, 12))),
    error = TRUE
  )

  expect_snapshot(
    ggplot_build(p + scale_x_date(date_minor_breaks = c(11, 12))),
    error = TRUE
  )

  expect_snapshot(
    ggplot_build(p + scale_x_date(date_labels = c(11, 12))),
    error = TRUE
  )
})
