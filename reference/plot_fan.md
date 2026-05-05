# Fan chart of a hubverse quantile forecast

Returns a ggplot of prediction-interval ribbons + median line. Any
column not in the hubverse data triplet (`target_end_date`, `horizon`,
`output_type*`, `value`) is treated as a trajectory grouper, so
user-added columns like `los` work out of the box.

## Usage

``` r
plot_fan(x, location = NULL, truth = NULL, intervals = c(0.5, 0.95))
```

## Arguments

- x:

  Hubverse-format quantile tibble.

- location:

  Optional location to filter on.

- truth:

  Optional hubverse target-data tibble to overlay in black.

- intervals:

  Prediction-interval widths in `(0, 1)`. Default `c(0.5, 0.95)`.

## Value

A `ggplot`.
