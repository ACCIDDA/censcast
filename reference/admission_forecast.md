# Toy weekly admission quantile forecast

Synthetic hubverse format admission quantile forecast for 4 weeks after
`reference_date = 2024-12-21`, paired with
[admission_history](https://accidda.github.io/censcast/reference/admission_history.md).

## Usage

``` r
admission_forecast
```

## Format

A tibble with the standard hubverse model output columns.

## Details

In a real workflow this comes from a forecasting hub, e.g.
`hubData::connect_hub() |> collect_hub()`.
