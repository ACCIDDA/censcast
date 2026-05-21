# Convolve a hubverse admission forecast with a LOS survival vector.
#
# census(t) = sum over s <= t of admissions(s) * P(LOS > t - s)
#
# Linear, so quantile by quantile on the admission paths gives the
# census quantile forecast on the same hub schema.

#' Forecast census from a hubverse admission forecast
#'
#' Convolves a hubverse admission quantile forecast with a length of
#' stay survival vector to produce a hubverse census quantile forecast.
#'
#' Census on the first forecast day depends on admissions before the
#' forecast starts, because patients already in hospital are still
#' occupying beds. `admission_history` supplies those pre forecast
#' admissions so the convolution can see the full `max_stay` window.
#' Groups with fewer than `max_stay` historical observations before
#' their `reference_date` are dropped silently.
#'
#' @param admission_fcast Hubverse model output tibble of admission
#'   quantile forecasts (output of `hubData::collect_hub()`). One row
#'   per (model, location, reference_date, horizon, quantile).
#' @param los Numeric survival vector `P(LOS > d)` of length
#'   `max_stay + 1`. Use [spec_los()] for literature priors or
#'   [fit_los()] for a data driven fit.
#' @param admission_history Hubverse target time series tibble of
#'   observed admissions (output of
#'   `hubData::connect_target_timeseries()` then collected). Must
#'   cover at least `max_stay` time steps immediately before each
#'   `reference_date` in `admission_fcast`.
#' @return A tibble with the same hubverse columns as `admission_fcast`,
#'   with `value` now representing census instead of admissions.
#' @export
fcast_census <- function(admission_fcast, los, admission_history) {
  max_stay <- length(los) - 1L
  admission_history <- dplyr::filter(
    admission_history, !is.na(.data$observation)
  )

  admission_fcast |>
    dplyr::filter(.data$output_type == "quantile") |>
    tidyr::nest(
      .by = c("model_id", "location", "reference_date"),
      .key = "fc"
    ) |>
    dplyr::mutate(
      fc = purrr::pmap(
        list(.data$location, .data$fc),
        \(loc, df) census_one(loc, df, los, admission_history, max_stay)
      )
    ) |>
    tidyr::unnest("fc")
}

# One (location, reference_date) group: prepend max_stay observed
# admissions, convolve per quantile, drop the burn in. Empty tibble
# if not enough history.
census_one <- function(loc, df, los, admission_history, max_stay) {
  past <- admission_history |>
    dplyr::filter(
      .data$location == loc,
      .data$target_end_date < min(df$target_end_date)
    ) |>
    dplyr::arrange(.data$target_end_date) |>
    dplyr::pull(.data$observation) |>
    utils::tail(max_stay)
  if (length(past) < max_stay) {
    return(df[0, ])
  }
  df |>
    dplyr::arrange(.data$target_end_date) |>
    dplyr::mutate(
      value = predict_census(los, c(past, .data$value))[-seq_along(past)],
      .by = "output_type_id"
    ) |>
    # Enforce quantile monotonicity per target_end_date.
    # FFT-based convolve() can introduce tiny crossings that scoringutils
    # rejects strictly (upper >= lower with no tolerance).
    dplyr::arrange(.data$target_end_date, as.numeric(.data$output_type_id)) |>
    dplyr::mutate(value = cummax(.data$value), .by = "target_end_date")
}

# Census from admissions and a LOS survival vector.
predict_census <- function(los, admissions) {
  pred <- stats::convolve(admissions, rev(los), type = "open")[
    seq_along(admissions)
  ]
  pred[!is.finite(pred)] <- 0
  pred
}
