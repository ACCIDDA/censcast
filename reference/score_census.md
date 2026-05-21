# Score a census forecast against observed census

Joins forecast quantiles to truth on `(location, target_end_date)` and
scores them with
[`scoringutils::score()`](https://epiforecasts.io/scoringutils/reference/score.html).
Returns the standard `scoringutils` per row score tibble (WIS
components, coverage, etc.).

## Usage

``` r
score_census(census_fcast, census_truth)
```

## Arguments

- census_fcast:

  Hubverse format census quantile forecast (output of
  [`fcast_census()`](https://accidda.github.io/censcast/reference/fcast_census.md)).

- census_truth:

  Hubverse target data tibble of observed census, with columns
  `target_end_date`, `target`, `location`, `observation`.

## Value

A `scoringutils` scored tibble, one row per (location, reference_date,
target_end_date, quantile).
