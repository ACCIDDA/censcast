# Fit a length of stay survival curve from observed admissions and census

Recovers `P(LOS > d)` by deconvolving an observed admissions and census
time series. Use this when you have last season's admissions and census
time series and want a data driven LOS for
[`fcast_census()`](https://accidda.github.io/censcast/reference/fcast_census.md).
If you do not have such data, use
[`spec_los()`](https://accidda.github.io/censcast/reference/spec_los.md)
with literature priors instead.

## Usage

``` r
fit_los(data, family = "negbin", max_stay = 50, skip = max_stay)
```

## Arguments

- data:

  Data frame with one row per time step and two numeric columns:
  `admissions` (observed admissions at that time step) and `census`
  (observed census at that time step).

- family:

  Character. LOS distribution family to fit. One of `"negbin"`,
  `"normal"`, `"lognormal"`, `"geometric"` (same set as
  [`spec_los()`](https://accidda.github.io/censcast/reference/spec_los.md)).
  Default `"negbin"`.

- max_stay:

  Integer. Longest LOS modelled, in time step units of the data. The
  returned survival vector has length `max_stay + 1`. Default 50.

- skip:

  Integer. Number of time steps at the start of the series to ignore in
  the loss. Their census depends on admissions before the observation
  window, which we do not see. Default `max_stay`.

## Value

A numeric vector of length `max_stay + 1` giving `P(LOS > d)` for
`d = 0..max_stay`, of class `los_fit`. Drops directly into
[`fcast_census()`](https://accidda.github.io/censcast/reference/fcast_census.md).
Fitted parameters and family are attached as attributes.

## Details

If instead you have a line list (one observed length of stay per
patient), you do not need `fit_los()`. Build the empirical survival from
the vector directly and pass it to
[`fcast_census()`](https://accidda.github.io/censcast/reference/fcast_census.md):
`surv <- 1 - stats::ecdf(los_values)(0:max_stay)`.

## Examples

``` r
set.seed(1)
true_surv <- spec_los("negbin", mu = 3, k = 2, max_stay = 30)
admissions <- rpois(120, 20)
census <- stats::convolve(admissions, rev(true_surv), type = "open")[
  seq_along(admissions)
]
fit <- fit_los(
  data.frame(admissions = admissions, census = census),
  family = "negbin", max_stay = 30
)
attr(fit, "params")
#>       mu        k 
#> 2.999999 1.999998 
```
