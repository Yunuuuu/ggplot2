#' Scales for shapes, aka glyphs
#'
#' `scale_shape()` maps discrete variables to six easily discernible shapes.
#' If you have more than six levels, you will get a warning message, and the
#' seventh and subsequent levels will not appear on the plot. Use
#' [scale_shape_manual()] to supply your own values. You can not map
#' a continuous variable to shape unless `scale_shape_binned()` is used. Still,
#' as shape has no inherent order, this use is not advised.
#'
#' @param solid Should the shapes be solid, `TRUE`, or hollow,
#'   `FALSE`?
#' @inheritParams discrete_scale
#' @inheritDotParams discrete_scale -expand -position -scale_name -palette
#' @rdname scale_shape
#' @details
#' Shapes can be referred to by number or name. Shapes in \[0, 20\] do not
#' support a fill aesthetic, whereas shapes in \[21, 25\] do.
#'
#' \if{html}{\figure{shape_table.svg}{All shapes by number and name}}
#' \if{latex}{\figure{shape_table.pdf}}
#'
#' @seealso
#' The documentation for [differentiation related aesthetics][aes_linetype_size_shape].
#'
#' Other shape scales: [scale_shape_manual()], [scale_shape_identity()].
#'
#' The `r link_book("shape section", "scales-other#sec-scale-shape")`
#' @export
#' @examples
#' set.seed(596)
#' dsmall <- diamonds[sample(nrow(diamonds), 100), ]
#'
#' (d <- ggplot(dsmall, aes(carat, price)) + geom_point(aes(shape = cut)))
#' d + scale_shape(solid = TRUE) # the default
#' d + scale_shape(solid = FALSE)
#' d + scale_shape(name = "Cut of diamond")
#'
#' # To change order of levels, change order of
#' # underlying factor
#' levels(dsmall$cut) <- c("Fair", "Good", "Very Good", "Premium", "Ideal")
#'
#' # Need to recreate plot to pick up new data
#' ggplot(dsmall, aes(price, carat)) + geom_point(aes(shape = cut))
#'
#' # Show a list of available shapes
#' df_shapes <- data.frame(shape = 0:24)
#' ggplot(df_shapes, aes(0, 0, shape = shape)) +
#'   geom_point(aes(shape = shape), size = 5, fill = 'red') +
#'   scale_shape_identity() +
#'   facet_wrap(~shape) +
#'   theme_void()
scale_shape <- function(name = waiver(), ..., solid = NULL, aesthetics = "shape") {
  palette <- if (!is.null(solid)) pal_shape(solid) else NULL
  discrete_scale(aesthetics, name = name, palette = palette, ...)
}

#' @rdname scale_shape
#' @export
scale_shape_binned <- function(name = waiver(), ..., solid = TRUE, aesthetics = "shape") {
  palette <- if (!is.null(solid)) pal_binned(pal_shape(solid)) else NULL
  binned_scale(aesthetics, name = name, palette = palette, ...)
}

#' @rdname scale_shape
#' @export
#' @usage NULL
scale_shape_discrete <- scale_shape

#' @rdname scale_shape
#' @export
#' @usage NULL
scale_shape_ordinal <- function(...) {
  cli::cli_warn("Using shapes for an ordinal variable is not advised")
  args <- list2(...)
  args$call <- args$call %||% current_call()
  exec(scale_shape, !!!args)
}

#' @rdname scale_shape
#' @export
#' @usage NULL
scale_shape_continuous <- function(...) {
  cli::cli_abort(c(
    "A continuous variable cannot be mapped to the {.field shape} aesthetic.",
    "i" = "Choose a different aesthetic or use {.fn scale_shape_binned}."
  ))
}
