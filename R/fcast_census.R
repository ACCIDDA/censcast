# Convolve a hubverse admission forecast with a LOS survival vector.
#
# census(t) = sum over s <= t of admissions(s) * P(LOS > t - s)
#
# Linear, so quantile-by-quantile on the admission paths gives the
# census quantile forecast on the same hub schema.

#' Forecast census from a hubverse admission forecast
#'
#' @param forecast Hubverse model-output tibble (from
#'   [hubData::collect_hub()]).
#' @param los Numeric survival vector `P(LOS > d)`, e.g. from
#'   [los_spec()].
#' @param history Hubverse target time-series tibble (from
#'   [hubData::connect_target_timeseries()] then collected) — used as
#'   burn-in admissions before each forecast.
#' @return Same hubverse columns as `forecast`, with `value` now census.
#' @export
fcast_census <- function(forecast, los, history) {
  max_stay <- length(los) - 1L
  history  <- dplyr::filter(history, !is.na(.data$observation))

  forecast |>
    dplyr::filter(.data$output_type == "quantile") |>
    tidyr::nest(.by = c("model_id", "location", "reference_date"),
                .key = "fc") |>
    dplyr::mutate(fc = purrr::pmap(
      list(.data$location, .data$fc),
      \(loc, df) census_one(loc, df, los, history, max_stay)
    )) |>
    tidyr::unnest("fc")
}

# One (location, reference_date) group: prepend max_stay observed
# admissions, convolve per quantile, drop the burn-in. Empty tibble
# if not enough history.
census_one <- function(loc, df, los, history, max_stay) {
  past <- history |>
    dplyr::filter(.data$location == loc,
                  .data$target_end_date < min(df$target_end_date)) |>
    dplyr::arrange(.data$target_end_date) |>
    dplyr::pull(.data$observation) |>
    utils::tail(max_stay)
  if (length(past) < max_stay) return(df[0, ])
  df |>
    dplyr::arrange(.data$target_end_date) |>
    dplyr::mutate(
      value = predict_census(los, c(past, .data$value))[-seq_along(past)],
      .by   = "output_type_id"
    ) |>
    # Enforce quantile monotonicity per target_end_date.
    # FFT-based convolve() can introduce tiny crossings that scoringutils
    # rejects strictly (upper >= lower with no tolerance).
    dplyr::arrange(.data$target_end_date, as.numeric(.data$output_type_id)) |>
    dplyr::mutate(value = cummax(.data$value), .by = "target_end_date")
}

# census from admissions and a LOS survival vector.
predict_census <- function(los, admissions) {
  pred <- stats::convolve(admissions, rev(los), type = "open")[
    seq_along(admissions)
  ]
  pred[!is.finite(pred)] <- 0
  pred
}
