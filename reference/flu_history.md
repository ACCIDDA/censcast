# Toy hubverse flu admission history

Synthetic weekly admission counts for one location, in the standard
hubverse target-data shape. Covers 53 weeks before
`reference_date = 2024-12-21` plus 4 weeks of overlap with the horizons
in
[flu_forecast](https://accidda.github.io/censcast/reference/flu_forecast.md),
so the same series can also serve as truth in
[`score_census()`](https://accidda.github.io/censcast/reference/score_census.md).

## Usage

``` r
flu_history
```

## Format

A tibble with columns `target_end_date`, `target`, `location`,
`observation`.
