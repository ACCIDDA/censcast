# Synthesise (admissions, census) from a known survival curve and check
# fit_los() recovers it. Convolution-based fitting is exact under no
# noise once we skip the burn-in.

sim_data <- function(true_surv, n = 200, lambda = 20, seed = 1) {
  set.seed(seed)
  admissions <- stats::rpois(n, lambda)
  census <- stats::convolve(admissions, rev(true_surv), type = "open")[
    seq_along(admissions)
  ]
  # Census of the first length(true_surv)-1 rows is incomplete (no
  # admissions before t = 1); fit_los's `skip` argument drops them.
  data.frame(admissions = admissions, census = census)
}

test_that("fit_los returns a vector of the right shape with attributes", {
  d <- sim_data(spec_los("negbin", mu = 3, k = 2, max_stay = 30))
  fit <- fit_los(d, family = "negbin", max_stay = 30)

  expect_length(fit, 31L)
  expect_s3_class(fit, "los_fit")
  expect_true(all(fit >= 0 & fit <= 1))
  expect_true(all(diff(fit) <= 1e-9))
  expect_setequal(names(attr(fit, "params")), c("mu", "k"))
  expect_equal(attr(fit, "family"), "negbin")
})

test_that("fit_los recovers a known negbin survival curve", {
  true_surv <- spec_los("negbin", mu = 3, k = 2, max_stay = 30)
  d <- sim_data(true_surv)
  fit <- fit_los(d, family = "negbin", max_stay = 30)

  # No noise in the simulation, so the loss minimum should reproduce
  # the truth almost exactly.
  expect_lt(max(abs(fit - true_surv)), 1e-3)
  p <- attr(fit, "params")
  expect_equal(p[["mu"]], 3, tolerance = 1e-2)
  expect_equal(p[["k"]],  2, tolerance = 1e-2)
})

test_that("fit_los output drops into fcast_census unchanged", {
  d <- sim_data(spec_los("negbin", mu = 2, k = 1.5, max_stay = 20))
  fit <- fit_los(d, family = "negbin", max_stay = 20)

  hist <- tibble::tibble(
    target_end_date = seq(as.Date("2024-01-06"), by = 7, length.out = 30),
    target          = "wk inc flu hosp",
    location        = "X",
    observation     = stats::rpois(30, 100)
  )
  fc <- tibble::tibble(
    model_id        = "M",
    location        = "X",
    reference_date  = as.Date("2024-07-27"),
    horizon         = 1:4,
    target_end_date = as.Date("2024-07-27") + (1:4) * 7L,
    target          = "wk inc flu hosp",
    output_type     = "quantile",
    output_type_id  = "0.5",
    value           = 120
  )
  out <- fcast_census(fc, fit, hist)
  expect_equal(nrow(out), 4L)
  expect_true(all(is.finite(out$value)))
})

test_that("fit_los rejects unknown family", {
  d <- sim_data(spec_los("negbin", mu = 2, k = 1.5, max_stay = 20))
  expect_error(fit_los(d, family = "weibull"), "Unknown family")
})

test_that("print.los_fit produces a one-line summary", {
  d <- sim_data(spec_los("negbin", mu = 2, k = 1.5, max_stay = 20))
  fit <- fit_los(d, family = "negbin", max_stay = 20)
  expect_output(print(fit), "los_fit.*family=negbin.*mu=.*k=")
})

test_that("plot.los_fit returns a ggplot of the survival curve", {
  d <- sim_data(spec_los("negbin", mu = 2, k = 1.5, max_stay = 20))
  fit <- fit_los(d, family = "negbin", max_stay = 20)
  p <- plot(fit)
  expect_s3_class(p, "ggplot")
  # The underlying data frame should have one row per d = 0..max_stay.
  expect_equal(nrow(p$data), 21L)
})
