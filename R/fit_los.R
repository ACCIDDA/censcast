# Fit a LOS survival curve by deconvolving (admissions, census).
#
# census(t) = sum over s <= t of admissions(s) * P(LOS > t - s)
#
# Given observed admissions and census, find the parametric survival
# curve P(LOS > d) whose convolution with admissions best matches
# census (least squares, parameters in log space, L-BFGS-B). Skip the
# first `skip` time steps of the loss because their census depends on
# admissions before the observation window starts.

#' Fit a length of stay survival curve from observed admissions and census
#'
#' Recovers `P(LOS > d)` by deconvolving an observed admissions and
#' census time series. Use this when you have last season's admissions
#' and census time series and want a data driven LOS for
#' [fcast_census()]. If you do not have such data, use [spec_los()]
#' with literature priors instead.
#'
#' If instead you have a line list (one observed length of stay per
#' patient), you do not need `fit_los()`. Build the empirical survival
#' from the vector directly and pass it to [fcast_census()]:
#' `surv <- 1 - stats::ecdf(los_values)(0:max_stay)`.
#'
#' @param data Data frame with one row per time step and two numeric
#'   columns: `admissions` (observed admissions at that time step) and
#'   `census` (observed census at that time step).
#' @param family Character. LOS distribution family to fit. One of
#'   `"negbin"`, `"normal"`, `"lognormal"`, `"geometric"` (same set as
#'   [spec_los()]). Default `"negbin"`.
#' @param max_stay Integer. Longest LOS modelled, in time step units
#'   of the data. The returned survival vector has length
#'   `max_stay + 1`. Default 50.
#' @param skip Integer. Number of time steps at the start of the
#'   series to ignore in the loss. Their census depends on admissions
#'   before the observation window, which we do not see. Default
#'   `max_stay`.
#' @return A numeric vector of length `max_stay + 1` giving
#'   `P(LOS > d)` for `d = 0..max_stay`, of class `los_fit`. Drops
#'   directly into [fcast_census()]. Fitted parameters and family are
#'   attached as attributes.
#' @examples
#' set.seed(1)
#' true_surv <- spec_los("negbin", mu = 3, k = 2, max_stay = 30)
#' admissions <- rpois(120, 20)
#' census <- stats::convolve(admissions, rev(true_surv), type = "open")[
#'   seq_along(admissions)
#' ]
#' fit <- fit_los(
#'   data.frame(admissions = admissions, census = census),
#'   family = "negbin", max_stay = 30
#' )
#' attr(fit, "params")
#' @export
fit_los <- function(data, family = "negbin", max_stay = 50, skip = max_stay) {
  k <- los_kernel(family)
  fit <- stats::optim(
    par = k$init,
    fn = los_sse,
    admissions = data$admissions,
    census = data$census,
    surv_fn = k$surv_fn,
    max_stay = max_stay,
    skip = skip,
    lower = k$lower,
    method = "L-BFGS-B"
  )
  surv <- safe_surv(k$surv_fn(fit$par, max_stay))
  params <- fit$par
  params[k$is_log] <- exp(params[k$is_log])
  structure(
    surv,
    class = c("los_fit", "numeric"),
    family = family,
    params = stats::setNames(params, k$param_names)
  )
}

#' @export
print.los_fit <- function(x, ...) {
  p <- attr(x, "params")
  cat(sprintf(
    "<los_fit> family=%s  %s  P(LOS>%d) = %.3g\n",
    attr(x, "family"),
    paste(sprintf("%s=%.3g", names(p), p), collapse = ", "),
    length(x) - 1L,
    x[length(x)]
  ))
  invisible(x)
}

#' Plot a fitted length of stay survival curve
#'
#' Renders the recovered survival curve `P(LOS > d)` for
#' `d = 0..max_stay` as a step line, with the family and fitted
#' parameters shown as a subtitle. Useful for sanity checking a
#' [fit_los()] result before passing it to [fcast_census()].
#'
#' @param x A `los_fit` object from [fit_los()].
#' @param ... Unused, present for S3 generic consistency.
#' @return A `ggplot` object.
#' @examples
#' set.seed(1)
#' true_surv <- spec_los("negbin", mu = 3, k = 2, max_stay = 30)
#' admissions <- rpois(120, 20)
#' census <- stats::convolve(admissions, rev(true_surv), type = "open")[
#'   seq_along(admissions)
#' ]
#' fit <- fit_los(
#'   data.frame(admissions = admissions, census = census),
#'   family = "negbin", max_stay = 30
#' )
#' plot(fit)
#' @export
plot.los_fit <- function(x, ...) {
  p <- attr(x, "params")
  subtitle <- paste0(
    "family = ", attr(x, "family"),
    ";  ",
    paste(sprintf("%s = %.3g", names(p), p), collapse = ", ")
  )
  df <- data.frame(d = seq_along(x) - 1L, surv = as.numeric(x))
  ggplot2::ggplot(df, ggplot2::aes(.data$d, .data$surv)) +
    ggplot2::geom_step(color = "#1e5396", linewidth = 0.6) +
    ggplot2::geom_point(color = "#1e5396", size = 1.5) +
    ggplot2::scale_y_continuous(limits = c(0, 1)) +
    ggplot2::labs(
      x = "Time steps since admission",
      y = "P(LOS > d)",
      subtitle = subtitle
    ) +
    ggplot2::theme_bw()
}

# --- internals ----------------------------------------------------------

# Force non-finite entries to 0 so a wild optim() step doesn't crash the
# convolution.
safe_surv <- function(s) {
  s[!is.finite(s)] <- 0
  s
}

# SSE between observed and predicted census, skipping the first `skip`
# days. Returns a large finite number if the prediction blows up so
# optim keeps moving.
los_sse <- function(log_params, admissions, census, surv_fn, max_stay, skip) {
  surv <- safe_surv(surv_fn(log_params, max_stay))
  pred <- predict_census(surv, admissions)
  idx <- seq(skip + 1L, length(admissions))
  sse <- sum((census[idx] - pred[idx])^2)
  if (is.finite(sse)) sse else 1e10
}

# Survival kernels for fit_los. Parameters are optimised in log space so
# they stay positive; surv_fn exponentiates internally. The lognormal's
# `meanlog` can be any real, so it is passed through unchanged.
los_kernel <- function(family) {
  ks <- list(
    negbin = list(
      param_names = c("mu", "k"),
      surv_fn = function(lp, max_stay) {
        1 - stats::pnbinom(0:max_stay, size = exp(lp[2]), mu = exp(lp[1]))
      },
      init = c(log(2), log(1)),
      lower = c(log(1e-6), log(1e-6)),
      is_log = c(TRUE, TRUE)
    ),
    normal = list(
      param_names = c("mu", "sigma"),
      surv_fn = function(lp, max_stay) {
        pmax(
          1 - stats::pnorm(0:max_stay, mean = exp(lp[1]), sd = exp(lp[2])),
          0
        )
      },
      init = c(log(5), log(2)),
      lower = c(log(1e-6), log(1e-6)),
      is_log = c(TRUE, TRUE)
    ),
    lognormal = list(
      param_names = c("meanlog", "sdlog"),
      surv_fn = function(lp, max_stay) {
        1 - stats::plnorm(0:max_stay, meanlog = lp[1], sdlog = exp(lp[2]))
      },
      init = c(1.5, log(0.5)),
      lower = c(-Inf, log(1e-6)),
      is_log = c(FALSE, TRUE)
    ),
    geometric = list(
      param_names = "mu",
      surv_fn = function(lp, max_stay) {
        mu <- exp(lp[1])
        (mu / (mu + 1))^(0:max_stay + 1)
      },
      init = log(5),
      lower = log(1e-6),
      is_log = TRUE
    )
  )
  k <- ks[[family]]
  if (is.null(k)) {
    stop(
      "Unknown family: ",
      family,
      ". Use one of: ",
      paste(names(ks), collapse = ", ")
    )
  }
  k
}
