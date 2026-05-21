# Specify a length of stay survival vector from a parametric family

Returns `P(LOS > d)` for `d = 0, 1, ..., max_stay`. Use this when you do
not have observed census data to fit on and want to plug in literature
priors. The returned numeric vector drops straight into
[`fcast_census()`](https://accidda.github.io/censcast/reference/fcast_census.md).
Counterpart of
[`fit_los()`](https://accidda.github.io/censcast/reference/fit_los.md),
which recovers the same vector from data.

## Usage

``` r
spec_los(family, ..., max_stay = 50)
```

## Arguments

- family:

  Character. One of `"negbin"`, `"normal"`, `"lognormal"`,
  `"geometric"`.

- ...:

  Parameters for the chosen family (see above).

- max_stay:

  Integer. Longest LOS modelled, in time step units of the forecast
  (weeks for FluSight, days for daily hubs). The returned vector has
  length `max_stay + 1`.

## Value

Numeric vector of length `max_stay + 1` giving `P(LOS > d)` for
`d = 0..max_stay`.

## Details

Parameters per family:

- `negbin`: `mu` (mean), `k` (dispersion).

- `normal`: `mu` (mean), `sigma` (sd).

- `lognormal`: `meanlog`, `sdlog`.

- `geometric`: `mu` (mean).

## Examples

``` r
spec_los("negbin", mu = 2, k = 1.7, max_stay = 15)
#>  [1] 0.7334244982 0.4884632262 0.3097077035 0.1905373549 0.1148480795
#>  [6] 0.0682071206 0.0400544698 0.0233150557 0.0134749948 0.0077423467
#> [11] 0.0044267070 0.0025204178 0.0014298830 0.0008086636 0.0004560796
#> [16] 0.0002565996
```
