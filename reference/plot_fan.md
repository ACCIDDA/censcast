# Fan chart of a hubverse quantile forecast

Renders prediction interval ribbons plus the median as a ggplot. Works
on any hubverse quantile forecast, whether the values are admissions or
census. Any column not in the hubverse value triplet (`target_end_date`,
`horizon`, `output_type*`, `value`) is treated as a trajectory grouper,
so user added columns like `los` need no configuration.

## Usage

``` r
plot_fan(fcast, location = NULL, truth = NULL, intervals = c(0.5, 0.95))
```

## Arguments

- fcast:

  Hubverse format quantile tibble. Typically the output of
  [`fcast_census()`](https://accidda.github.io/censcast/reference/fcast_census.md),
  but any admission or census quantile forecast in hubverse shape works.

- location:

  Optional character. If supplied, both `fcast` and `truth` are filtered
  to this location before plotting.

- truth:

  Optional hubverse target data tibble (columns `target_end_date`,
  `target`, `location`, `observation`). Overlaid as a black line.

- intervals:

  Numeric vector of prediction interval widths in `(0, 1)`. Default
  `c(0.5, 0.95)`. One ribbon per interval.

## Value

A `ggplot` object.
