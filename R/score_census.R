# Score a hubverse format census forecast against observed census.

#' Score a census forecast against observed census
#'
#' Joins forecast quantiles to truth on `(location, target_end_date)`
#' and scores them with [scoringutils::score()]. Returns the standard
#' `scoringutils` per row score tibble (WIS components, coverage, etc.).
#'
#' @param census_fcast Hubverse format census quantile forecast (output
#'   of [fcast_census()]).
#' @param census_truth Hubverse target data tibble of observed census,
#'   with columns `target_end_date`, `target`, `location`, `observation`.
#' @return A `scoringutils` scored tibble, one row per (location,
#'   reference_date, target_end_date, quantile).
#' @export
score_census <- function(census_fcast, census_truth) {
  census_truth <- census_truth |>
    dplyr::filter(!is.na(.data$observation)) |>
    dplyr::summarise(
      observed = mean(.data$observation),
      .by = c("target_end_date", "location")
    )

  census_fcast |>
    dplyr::filter(.data$output_type == "quantile") |>
    dplyr::inner_join(census_truth, by = c("location", "target_end_date")) |>
    dplyr::transmute(
      model           = .data$model_id,
      .data$location,
      .data$reference_date,
      .data$target_end_date,
      .data$horizon,
      quantile_level  = as.numeric(.data$output_type_id),
      predicted       = .data$value,
      .data$observed
    ) |>
    scoringutils::as_forecast_quantile() |>
    scoringutils::score()
}
