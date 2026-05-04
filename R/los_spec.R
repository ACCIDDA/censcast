# Length-of-stay distributions: P(LOS > d) for d = 0..max_stay.
#
# Pick a parametric family or pass a survival vector directly to
# fcast_census(). No class, no validation — just numeric vectors.

#' Length-of-stay survival vector
#'
#' Returns `P(LOS > d)` for `d = 0, 1, ..., max_stay`. Pick a family
#' and pass its parameters via `...`:
#'
#' * `negbin`    — `mu`, `k`
#' * `normal`    — `mu`, `sigma`
#' * `lognormal` — `meanlog`, `sdlog`
#' * `geometric` — `mu`
#'
#' @param family Character. One of `"negbin"`, `"normal"`,
#'   `"lognormal"`, `"geometric"`.
#' @param ... Family parameters (see above).
#' @param max_stay Longest LOS modelled, in time-step units of the
#'   forecast (weeks for FluSight, days for daily hubs).
#' @return Numeric vector of length `max_stay + 1`.
#' @examples
#' los_spec("negbin", mu = 2, k = 1.7, max_stay = 15)
#' @export
los_spec <- function(family, ..., max_stay = 50) {
  d <- 0:max_stay
  p <- list(...)
  switch(family,
    negbin    = 1 - stats::pnbinom(d, size = p$k, mu = p$mu),
    normal    = pmax(1 - stats::pnorm(d, mean = p$mu, sd = p$sigma), 0),
    lognormal = 1 - stats::plnorm(d, meanlog = p$meanlog, sdlog = p$sdlog),
    geometric = (p$mu / (p$mu + 1))^(d + 1)
  )
}
