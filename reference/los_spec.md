# Length-of-stay survival vector

Returns `P(LOS > d)` for `d = 0, 1, ..., max_stay`. Pick a family and
pass its parameters via `...`:

## Usage

``` r
los_spec(family, ..., max_stay = 50)
```

## Arguments

- family:

  Character. One of `"negbin"`, `"normal"`, `"lognormal"`,
  `"geometric"`.

- ...:

  Family parameters (see above).

- max_stay:

  Longest LOS modelled, in time-step units of the forecast (weeks for
  FluSight, days for daily hubs).

## Value

Numeric vector of length `max_stay + 1`.

## Details

- `negbin` — `mu`, `k`

- `normal` — `mu`, `sigma`

- `lognormal` — `meanlog`, `sdlog`

- `geometric` — `mu`

## Examples

``` r
los_spec("negbin", mu = 2, k = 1.7, max_stay = 15)
#>  [1] 0.7334244982 0.4884632262 0.3097077035 0.1905373549 0.1148480795
#>  [6] 0.0682071206 0.0400544698 0.0233150557 0.0134749948 0.0077423467
#> [11] 0.0044267070 0.0025204178 0.0014298830 0.0008086636 0.0004560796
#> [16] 0.0002565996
```
