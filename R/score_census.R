# Score a hubverse-format census forecast against observed census.

#' Score a census forecast against observed census
#'
#' Joins on `(location, target_end_date)` and scores via
#' [scoringutils::score()].
#'
#' @param census_fc Hubverse-format census forecast (output of
#'   [fcast_census()]).
#' @param truth Hubverse target-data tibble of observed census
#'   (`target_end_date`, `target`, `location`, `observation`).
#' @return A `scoringutils` scored tibble.
#' @export
score_census <- function(census_fc, truth) {
  truth <- truth |>
    dplyr::filter(!is.na(.data$observation)) |>
    dplyr::summarise(
      observed = mean(.data$observation),
      .by = c("target_end_date", "location")
    )

  census_fc |>
    dplyr::filter(.data$output_type == "quantile") |>
    dplyr::inner_join(truth, by = c("location", "target_end_date")) |>
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
