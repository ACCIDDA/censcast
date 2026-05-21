# Fan chart for a hubverse format quantile forecast.

#' Fan chart of a hubverse quantile forecast
#'
#' Renders prediction interval ribbons plus the median as a ggplot.
#' Works on any hubverse quantile forecast, whether the values are
#' admissions or census. Any column not in the hubverse value triplet
#' (`target_end_date`, `horizon`, `output_type*`, `value`) is treated
#' as a trajectory grouper, so user added columns like `los` need no
#' configuration.
#'
#' @param fcast Hubverse format quantile tibble. Typically the
#'   output of [fcast_census()], but any admission or census quantile
#'   forecast in hubverse shape works.
#' @param location Optional character. If supplied, both `fcast`
#'   and `truth` are filtered to this location before plotting.
#' @param truth Optional hubverse target data tibble (columns
#'   `target_end_date`, `target`, `location`, `observation`).
#'   Overlaid as a black line.
#' @param intervals Numeric vector of prediction interval widths in
#'   `(0, 1)`. Default `c(0.5, 0.95)`. One ribbon per interval.
#' @return A `ggplot` object.
#' @export
plot_fan <- function(
  fcast,
  location = NULL,
  truth = NULL,
  intervals = c(0.5, 0.95)
) {
  if (!is.null(location)) {
    fcast <- dplyr::filter(fcast, .data$location == .env$location)
    if (!is.null(truth)) {
      truth <- dplyr::filter(truth, .data$location == .env$location)
    }
  }

  ids <- setdiff(
    names(fcast),
    c("target_end_date", "horizon", "output_type", "output_type_id", "value")
  )
  wide <- fcast |>
    dplyr::filter(.data$output_type == "quantile") |>
    dplyr::mutate(q = as.numeric(.data$output_type_id)) |>
    dplyr::select(dplyr::all_of(ids), "target_end_date", "q", "value") |>
    tidyr::pivot_wider(
      names_from = "q",
      values_from = "value",
      names_prefix = "q"
    ) |>
    tidyr::unite(".gid", dplyr::all_of(ids), sep = "|", remove = FALSE)

  p <- ggplot2::ggplot(
    wide,
    ggplot2::aes(.data$target_end_date, group = .data$.gid)
  )
  for (w in sort(intervals, decreasing = TRUE)) {
    p <- p +
      ggplot2::geom_ribbon(
        ggplot2::aes(
          ymin = .data[[paste0("q", (1 - w) / 2)]],
          ymax = .data[[paste0("q", 1 - (1 - w) / 2)]]
        ),
        fill = "#1e5396",
        alpha = 0.18 + (1 - w) * 0.20
      )
  }
  p <- p +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$q0.5),
      color = "#1e5396",
      linewidth = 0.5
    )
  if (!is.null(truth)) {
    p <- p +
      ggplot2::geom_line(
        data = dplyr::filter(truth, !is.na(.data$observation)),
        ggplot2::aes(.data$target_end_date, .data$observation),
        color = "black",
        inherit.aes = FALSE
      )
  }
  p + ggplot2::theme_bw() + ggplot2::labs(x = NULL, y = NULL)
}
