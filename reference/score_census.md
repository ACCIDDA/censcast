# Score a census forecast against observed census

Joins on `(location, target_end_date)` and scores via
[`scoringutils::score()`](https://epiforecasts.io/scoringutils/reference/score.html).

## Usage

``` r
score_census(census_fc, truth)
```

## Arguments

- census_fc:

  Hubverse-format census forecast (output of
  [`fcast_census()`](https://accidda.github.io/censcast/reference/fcast_census.md)).

- truth:

  Hubverse target-data tibble of observed census (`target_end_date`,
  `target`, `location`, `observation`).

## Value

A `scoringutils` scored tibble.
