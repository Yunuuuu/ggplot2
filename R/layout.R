# The job of `Layout` is to coordinate:
# * The coordinate system
# * The faceting specification
# * The individual position scales for each panel
#
# This includes managing the parameters for the facet and the coord
# so that we don't modify the ggproto object in place.

create_layout <- function(facet, coord, layout = NULL) {
  layout <- layout %||% Layout
  check_inherits(layout, "Layout")
  ggproto(NULL, layout, facet = facet, coord = coord)
}

#' @rdname ggplot2-ggproto
#' @format NULL
#' @usage NULL
#' @export
Layout <- ggproto("Layout", NULL,
  # The coordinate system and its parameters
  coord = NULL,
  coord_params = list(),

  # The faceting specification and its parameters
  facet = NULL,
  facet_params = list(),

  # A data frame giving the layout of the data into panels
  layout = NULL,

  # Per panel scales and params
  panel_scales_x = NULL,
  panel_scales_y = NULL,
  panel_params = NULL,

  setup = function(self, data, plot_data = data_frame0(), plot_env = emptyenv()) {
    data <- c(list(plot_data), data)

    # Setup facets
    self$facet_params <- self$facet$setup_params(data, self$facet$params)
    self$facet_params$plot_env <- plot_env
    data <- self$facet$setup_data(data, self$facet_params)

    # Setup coords
    self$coord_params <- self$coord$setup_params(data)
    data <- self$coord$setup_data(data, self$coord_params)

    # Generate panel layout
    self$layout <- self$facet$compute_layout(data, self$facet_params)
    self$layout <- self$coord$setup_layout(self$layout, self$coord_params)
    check_layout(self$layout)

    # Add panel coordinates to the data for each layer
    lapply(data[-1], self$facet$map_data,
      layout = self$layout,
      params = self$facet_params
    )
  },

  # Assemble the facet fg & bg, the coord fg & bg, and the layers
  # Returns a gtable
  render = function(self, panels, data, theme, labels) {
    facet_bg <- self$facet$draw_back(data,
      self$layout,
      self$panel_scales_x,
      self$panel_scales_y,
      theme,
      self$facet_params
    )
    facet_fg <- self$facet$draw_front(
      data,
      self$layout,
      self$panel_scales_x,
      self$panel_scales_y,
      theme,
      self$facet_params
    )

    # Draw individual panels, then assemble into gtable
    panels <- lapply(seq_along(panels[[1]]), function(i) {
      panel <- lapply(panels, `[[`, i)
      panel <- c(facet_bg[i], panel, facet_fg[i])
      panel <- self$coord$draw_panel(panel, self$panel_params[[i]], theme)
      ggname(paste("panel", i, sep = "-"), panel)
    })
    plot_table <- self$facet$draw_panels(
      panels,
      self$layout,
      self$panel_scales_x,
      self$panel_scales_y,
      self$panel_params,
      self$coord,
      data,
      theme,
      self$facet_params
    )
    plot_table <- self$facet$set_panel_size(plot_table, theme)

    # Draw individual labels, then add to gtable
    labels <- self$coord$labels(
      list(
        x = self$resolve_label(self$panel_scales_x[[1]], labels),
        y = self$resolve_label(self$panel_scales_y[[1]], labels)
      ),
      self$panel_params[[1]]
    )
    labels <- self$render_labels(labels, theme)
    self$facet$draw_labels(
      plot_table,
      self$layout,
      self$panel_scales_x,
      self$panel_scales_y,
      self$panel_params,
      self$coord,
      data,
      theme,
      labels,
      self$params
    )
  },

  train_position = function(self, data, x_scale, y_scale) {
    # Initialise scales if needed, and possible.
    layout <- self$layout
    if (is.null(self$panel_scales_x)) {
      self$panel_scales_x <- self$facet$init_scales(layout, x_scale = x_scale,
        params = self$facet_params)$x
    }
    if (is.null(self$panel_scales_y)) {
      self$panel_scales_y <- self$facet$init_scales(layout, y_scale = y_scale,
        params = self$facet_params)$y
    }

    self$facet$train_scales(
      self$panel_scales_x,
      self$panel_scales_y,
      layout,
      data,
      self$facet_params
    )
  },

  map_position = function(self, data) {
    layout <- self$layout

    lapply(data, function(layer_data) {
      match_id <- NULL

      # Loop through each variable, mapping across each scale, then joining
      # back together
      x_vars <- intersect(self$panel_scales_x[[1]]$aesthetics, names(layer_data))
      if (length(x_vars) > 0) {
        match_id <- match(layer_data$PANEL, layout$PANEL)
        names(x_vars) <- x_vars
        SCALE_X <- layout$SCALE_X[match_id]
        new_x <- scale_apply(layer_data, x_vars, "map", SCALE_X, self$panel_scales_x)
        layer_data[, x_vars] <- new_x
      }

      y_vars <- intersect(self$panel_scales_y[[1]]$aesthetics, names(layer_data))
      if (length(y_vars) > 0) {
        if (is.null(match_id)) {
          match_id <- match(layer_data$PANEL, layout$PANEL)
        }
        names(y_vars) <- y_vars
        SCALE_Y <- layout$SCALE_Y[match_id]
        new_y <- scale_apply(layer_data, y_vars, "map", SCALE_Y, self$panel_scales_y)
        layer_data[, y_vars] <- new_y
      }

      layer_data
    })
  },

  reset_scales = function(self) {
    if (!self$facet$shrink) return()
    lapply(self$panel_scales_x, function(s) s$reset())
    lapply(self$panel_scales_y, function(s) s$reset())
    invisible()
  },

  finish_data = function(self, data) {
    lapply(data, self$facet$finish_data,
      layout = self$layout,
      x_scales = self$panel_scales_x,
      y_scales = self$panel_scales_y,
      params = self$facet_params
    )
  },

  get_scales = function(self, i) {
    this_panel <- self$layout[self$layout$PANEL == i, ]

    list(
      x = self$panel_scales_x[[this_panel$SCALE_X]],
      y = self$panel_scales_y[[this_panel$SCALE_Y]]
    )
  },

  setup_panel_params = function(self) {
    # Fudge for CoordFlip and CoordPolar - in place modification of
    # scales is not elegant, but it is pragmatic
    self$coord$modify_scales(self$panel_scales_x, self$panel_scales_y)

    # We only need to setup panel params once for unique combinations of x/y
    # scales. These will be repeated for duplicated combinations.
    index <- vec_unique_loc(self$layout$COORD)
    order <- vec_match(self$layout$COORD, self$layout$COORD[index])

    scales_x <- self$panel_scales_x[self$layout$SCALE_X[index]]
    scales_y <- self$panel_scales_y[self$layout$SCALE_Y[index]]

    panel_params <- Map(
      self$coord$setup_panel_params,
      scales_x, scales_y,
      MoreArgs = list(params = self$coord_params)
    )[order] # `[order]` does the repeating

    # Let Facet modify `panel_params` for each panel
    self$panel_params <- self$facet$setup_panel_params(panel_params, self$coord)

    invisible()
  },

  setup_panel_guides = function(self, guides, layers) {

    # Like in `setup_panel_params`, we only need to setup guides for unique
    # combinations of x/y scales.
    index <- vec_unique_loc(self$layout$COORD)
    order <- vec_match(self$layout$COORD, self$layout$COORD[index])

    self$panel_params <- lapply(
      self$panel_params[index],
      self$coord$setup_panel_guides,
      guides,
      self$coord_params
    )

    self$panel_params <- lapply(
      self$panel_params,
      self$coord$train_panel_guides,
      layers,
      self$coord_params
    )[order]

    invisible()
  },

  resolve_label = function(self, scale, labels) {
    aes <- scale$aesthetics[[1]]

    prim_scale <- scale$name
    seco_scale <- (scale$sec_name %||% waiver)()

    prim_label <- labels[[aes]]
    seco_label <- labels[[paste0("sec. aes")]]

    prim_guide <- seco_guide <- waiver()

    order <- scale$axis_order()

    panel <- self$panel_params[[1]]$guides
    if (!is.null(panel)) {
      position <- scale$position
      aes <- switch(position, left = , right = "y", "x")
      params <- panel$get_params(paste0(aes, c("", ".sec")))
      if (!is.null(params)) {
        prim_guide <- params[[1]]$title
        seco_guide <- params[[2]]$title
        position   <- scale$position
        if ((params[[1]]$position %||% position) != position) {
          order <- rev(order)
        }
      }
    }

    primary   <- scale$make_title(prim_guide, prim_scale, prim_label)
    secondary <- scale$make_sec_title(seco_guide, seco_scale, seco_label)
    if (is.derived(secondary)) {
      secondary <- primary
    }

    list(primary = primary, secondary = secondary)[order]
  },

  render_labels = function(self, labels, theme) {
    label_grobs <- lapply(names(labels), function(label) {
      lapply(c(1, 2), function(i) {
        modify <- if (i == 1) {
          switch(label, x = ".top", y = ".left")
        } else {
          switch(label, x = ".bottom", y = ".right")
        }
        if (is.null(labels[[label]][[i]]) || is.waiver(labels[[label]][[i]]))
          return(zeroGrob())

        element_render(
          theme = theme,
          element = paste0("axis.title.", label, modify),
          label = labels[[label]][[i]],
          margin_x = label == "y",
          margin_y = label == "x"
        )
      })
    })
    names(label_grobs) <- names(labels)
    label_grobs
  }
)

# Helpers -----------------------------------------------------------------

# Function for applying scale method to multiple variables in a given
# data set.  Implement in such a way to minimize copying and hence maximise
# speed
scale_apply <- function(data, vars, method, scale_id, scales) {
  if (length(vars) == 0) return()
  if (nrow(data) == 0) return()

  if (anyNA(scale_id)) {
    cli::cli_abort("{.arg scale_id} must not contain any {.val NA}.")
  }

  scale_index <- split_with_index(seq_along(scale_id), scale_id, length(scales))

  lapply(vars, function(var) {
    pieces <- lapply(seq_along(scales), function(i) {
      scales[[i]][[method]](vec_slice(data[[var]], scale_index[[i]]))
    })
    # Remove empty vectors to avoid coercion issues with vctrs
    pieces[lengths(pieces) == 0] <- NULL
    o <- order(unlist(scale_index))[seq_len(sum(lengths(pieces)))]
    vec_c(!!!pieces)[o]
  })
}
