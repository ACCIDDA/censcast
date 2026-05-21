# Toy weekly admission history

Synthetic weekly admission counts for one location, in the standard
hubverse target data shape. Covers 53 weeks before
`reference_date = 2024-12-21` plus 4 weeks of overlap with the horizons
in
[admission_forecast](https://accidda.github.io/censcast/reference/admission_forecast.md),
so the same series can also serve as the `admission_history` argument of
[`fcast_census()`](https://accidda.github.io/censcast/reference/fcast_census.md).

## Usage

``` r
admission_history
```

## Format

A tibble with columns `target_end_date`, `target`, `location`,
`observation` (weekly admissions).

## Details

In a real workflow this comes from a hub's target time series, e.g.
[`hubData::connect_target_timeseries()`](https://hubverse-org.github.io/hubData/reference/connect_target_timeseries.html).
