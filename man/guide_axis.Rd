% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/guide-axis.R
\name{guide_axis}
\alias{guide_axis}
\title{Axis guide}
\usage{
guide_axis(
  title = waiver(),
  theme = NULL,
  check.overlap = FALSE,
  angle = waiver(),
  n.dodge = 1,
  minor.ticks = FALSE,
  cap = "none",
  order = 0,
  position = waiver()
)
}
\arguments{
\item{title}{A character string or expression indicating a title of guide.
If \code{NULL}, the title is not shown. By default
(\code{\link[=waiver]{waiver()}}), the name of the scale object or the name
specified in \code{\link[=labs]{labs()}} is used for the title.}

\item{theme}{A \code{\link[=theme]{theme}} object to style the guide individually or
differently from the plot's theme settings. The \code{theme} argument in the
guide partially overrides, and is combined with, the plot's theme.}

\item{check.overlap}{silently remove overlapping labels,
(recursively) prioritizing the first, last, and middle labels.}

\item{angle}{Compared to setting the angle in \code{\link[=theme]{theme()}} / \code{\link[=element_text]{element_text()}},
this also uses some heuristics to automatically pick the \code{hjust} and \code{vjust} that
you probably want. Can be one of the following:
\itemize{
\item \code{NULL} to take the angles and \code{hjust}/\code{vjust} directly from the theme.
\item \code{waiver()} to allow reasonable defaults in special cases.
\item A number representing the text angle in degrees.
}}

\item{n.dodge}{The number of rows (for vertical axes) or columns (for
horizontal axes) that should be used to render the labels. This is
useful for displaying labels that would otherwise overlap.}

\item{minor.ticks}{Whether to draw the minor ticks (\code{TRUE}) or not draw
minor ticks (\code{FALSE}, default).}

\item{cap}{A \code{character} to cut the axis line back to the last breaks. Can
be \code{"none"} (default) to draw the axis line along the whole panel, or
\code{"upper"} and \code{"lower"} to draw the axis to the upper or lower break, or
\code{"both"} to only draw the line in between the most extreme breaks. \code{TRUE}
and \code{FALSE} are shorthand for \code{"both"} and \code{"none"} respectively.}

\item{order}{A positive \code{integer} of length 1 that specifies the order of
this guide among multiple guides. This controls in which order guides are
merged if there are multiple guides for the same position. If 0 (default),
the order is determined by a secret algorithm.}

\item{position}{Where this guide should be drawn: one of top, bottom,
left, or right.}
}
\description{
Axis guides are the visual representation of position scales like those
created with \link[=scale_x_continuous]{scale_(x|y)_continuous()} and
\link[=scale_x_discrete]{scale_(x|y)_discrete()}.
}
\examples{
# plot with overlapping text
p <- ggplot(mpg, aes(cty * 100, hwy * 100)) +
  geom_point() +
  facet_wrap(vars(class))

# axis guides can be customized in the scale_* functions or
# using guides()
p + scale_x_continuous(guide = guide_axis(n.dodge = 2))
p + guides(x = guide_axis(angle = 90))

# can also be used to add a duplicate guide
p + guides(x = guide_axis(n.dodge = 2), y.sec = guide_axis())
}
