# Length of stay distributions: P(LOS > d) for d = 0..max_stay.
#
# Pick a parametric family. The returned numeric vector goes straight
# into fcast_census(). No class, no validation.

#' Specify a length of stay survival vector from a parametric family
#'
#' Returns `P(LOS > d)` for `d = 0, 1, ..., max_stay`. Use this when
#' you do not have observed census data to fit on and want to plug in
#' literature priors. The returned numeric vector drops straight into
#' [fcast_census()]. Counterpart of [fit_los()], which recovers the
#' same vector from data.
#'
#' Parameters per family:
#' * `negbin`: `mu` (mean), `k` (dispersion).
#' * `normal`: `mu` (mean), `sigma` (sd).
#' * `lognormal`: `meanlog`, `sdlog`.
#' * `geometric`: `mu` (mean).
#'
#' @param family Character. One of `"negbin"`, `"normal"`,
#'   `"lognormal"`, `"geometric"`.
#' @param ... Parameters for the chosen family (see above).
#' @param max_stay Integer. Longest LOS modelled, in time step units
#'   of the forecast (weeks for FluSight, days for daily hubs). The
#'   returned vector has length `max_stay + 1`.
#' @return Numeric vector of length `max_stay + 1` giving
#'   `P(LOS > d)` for `d = 0..max_stay`.
#' @examples
#' spec_los("negbin", mu = 2, k = 1.7, max_stay = 15)
#' @export
spec_los <- function(family, ..., max_stay = 50) {
  d <- 0:max_stay
  p <- list(...)
  switch(
    family,
    negbin = 1 - stats::pnbinom(d, size = p$k, mu = p$mu),
    normal = pmax(1 - stats::pnorm(d, mean = p$mu, sd = p$sigma), 0),
    lognormal = 1 - stats::plnorm(d, meanlog = p$meanlog, sdlog = p$sdlog),
    geometric = (p$mu / (p$mu + 1))^(d + 1)
  )
}
