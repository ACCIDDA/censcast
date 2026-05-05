# Forecast census from a hubverse admission forecast

Forecast census from a hubverse admission forecast

## Usage

``` r
fcast_census(forecast, los, history)
```

## Arguments

- forecast:

  Hubverse model-output tibble (from
  [`hubData::collect_hub()`](https://hubverse-org.github.io/hubData/reference/collect_hub.html)).

- los:

  Numeric survival vector `P(LOS > d)`, e.g. from
  [`los_spec()`](https://accidda.github.io/censcast/reference/los_spec.md).

- history:

  Hubverse target time-series tibble (from
  [`hubData::connect_target_timeseries()`](https://hubverse-org.github.io/hubData/reference/connect_target_timeseries.html)
  then collected) — used as burn-in admissions before each forecast.

## Value

Same hubverse columns as `forecast`, with `value` now census.
