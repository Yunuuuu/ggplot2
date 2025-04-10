
test_that("check_device checks R versions correctly", {

  # Most widely supported device
  file <- withr::local_tempfile(fileext = ".pdf")
  withr::local_pdf(file)

  # R 4.0.0 doesn't support any new features
  with_mocked_bindings(
    getRversion = function() package_version("4.0.0"),
    expect_snapshot_warning(check_device("gradients")),
    .package = "base"
  )

  # R 4.1.0 doesn't support vectorised patterns
  with_mocked_bindings(
    getRversion = function() package_version("4.1.0"),
    expect_snapshot_warning(check_device("gradients")),
    .package = "base"
  )

  # R 4.1.0 does support clipping paths
  with_mocked_bindings(
    getRversion = function() package_version("4.1.0"),
    expect_true(check_device("clippingPaths"), "R 4.1.0 does not support"),
    .package = "base"
  )

  # Glyphs are only supported in R 4.3.0 onwards
  with_mocked_bindings(
    getRversion = function() package_version("4.2.0"),
    expect_snapshot_warning(check_device("glyphs")),
    .package = "base"
  )

  # R 4.2.0 does support vectorised patterns
  with_mocked_bindings(
    getRversion = function() package_version("4.2.0"),
    expect_true(check_device("patterns")),
    .package = "base"
  )
})

test_that("check_device finds device capabilities", {
  skip_if(
    getRversion() < "4.2.0",
    "R version < 4.2.0 does doesn't have proper `dev.capabilities()`."
  )
  file <- withr::local_tempfile(fileext = ".pdf")
  withr::local_pdf(file)
  with_mocked_bindings(
    dev.capabilities = function() list(clippingPaths = TRUE),
    expect_true(check_device("clippingPaths")),
    .package = "grDevices"
  )

  with_mocked_bindings(
    dev.capabilities = function() list(clippingPaths = FALSE),
    expect_snapshot_warning(check_device("clippingPaths")),
    .package = "grDevices"
  )

  with_mocked_bindings(
    dev.cur = function() c(foobar = 1),
    expect_snapshot_warning(check_device(".test_feature")),
    .package = "grDevices"
  )

})

test_that("check_device finds ragg capabilities", {
  skip_if(
    getRversion() < "4.2.0" || !is_installed("ragg", version = "1.2.6"),
    "Cannot test {ragg} capabilities."
  )
  tmp <- withr::local_tempfile(fileext = ".tiff")
  ragg::agg_tiff(tmp)

  expect_true(check_device("gradients"))
  expect_snapshot_warning(check_device("compositing"))

  dev.off()
})

test_that("check_device finds svglite capabilities", {
  skip_if(
    getRversion() < "4.2.0" || !is_installed("svglite", version = "2.1.2"),
    "Cannot test {svglite} capabilities."
  )
  tmp <- withr::local_tempfile(fileext = ".svg")
  withr::local_envvar(TESTTHAT = "false") # To not trigger vdiffr rules
  svglite::svglite(tmp)

  expect_true(check_device("gradients"))
  expect_snapshot_warning(check_device("compositing"))

  dev.off()
})
