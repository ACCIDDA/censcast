#' Toy hubverse flu admission history
#'
#' Synthetic weekly admission counts for one location, in the standard
#' hubverse target-data shape. Covers 53 weeks before
#' `reference_date = 2024-12-21` plus 4 weeks of overlap with the
#' horizons in [flu_forecast], so the same series can also serve as
#' truth in [score_census()].
#'
#' @format A tibble with columns `target_end_date`, `target`,
#'   `location`, `observation`.
"flu_history"

#' Toy hubverse flu admission forecast
#'
#' Synthetic hubverse-format admission quantile forecast, paired with
#' [flu_history] for use in examples and the vignette.
#'
#' @format A tibble with the standard hubverse model-output columns.
"flu_forecast"
