make_history <- function(loc = "X",
                         target = "wk inc flu hosp",
                         from = as.Date("2024-01-06"),
                         n = 30, lambda = 100) {
  set.seed(1)
  tibble::tibble(
    target_end_date = seq(from, by = 7, length.out = n),
    target          = target,
    location        = loc,
    observation     = stats::rpois(n, lambda)
  )
}

make_forecast <- function(loc = "X",
                          ref = as.Date("2024-07-27"),
                          target = "wk inc flu hosp",
                          horizons = 1:4,
                          q_levels = c(0.1, 0.5, 0.9),
                          value_fun = function(q) {
                            ifelse(q == 0.5, 120,
                            ifelse(q == 0.1,  80, 160))
                          }) {
  grid <- expand.grid(h = horizons, q = q_levels,
                      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  tibble::tibble(
    model_id        = "M",
    location        = loc,
    reference_date  = ref,
    horizon         = as.integer(grid$h),
    target_end_date = ref + grid$h * 7L,
    target          = target,
    output_type     = "quantile",
    output_type_id  = as.character(grid$q),
    value           = value_fun(grid$q)
  )
}

test_that("fcast_census preserves hubverse columns", {
  los <- los_spec("geometric", mu = 1.5, max_stay = 8)
  out <- fcast_census(make_forecast(), los, make_history())
  expect_named(
    out,
    c("model_id", "location", "reference_date", "horizon",
      "target_end_date", "target", "output_type",
      "output_type_id", "value"),
    ignore.order = TRUE
  )
})

test_that("fcast_census matches a manual convolution per quantile", {
  los  <- los_spec("geometric", mu = 1.5, max_stay = 8)
  hist <- make_history(n = 30)
  fc   <- make_forecast(q_levels = 0.5, value_fun = function(q) 120)

  out  <- fcast_census(fc, los, hist) |>
    dplyr::arrange(target_end_date)

  past   <- utils::tail(hist$observation, 8)
  manual <- censcast:::predict_census(los, c(past, rep(120, 4)))[-seq_along(past)]
  expect_equal(out$value, manual)
})

test_that("fcast_census drops groups with insufficient history", {
  los  <- los_spec("negbin", mu = 0.5, k = 1, max_stay = 50)
  hist <- make_history(n = 5)
  out  <- fcast_census(make_forecast(), los, hist)
  expect_equal(nrow(out), 0)
})

test_that("fcast_census handles multiple locations independently", {
  los  <- los_spec("geometric", mu = 1.5, max_stay = 8)
  hist <- dplyr::bind_rows(
    make_history("X", lambda = 100),
    make_history("Y", lambda = 200)
  )
  fc <- dplyr::bind_rows(
    make_forecast("X" ),
    make_forecast("Y", value_fun = function(q) 240)
  )
  out <- fcast_census(fc, los, hist)
  expect_setequal(unique(out$location), c("X", "Y"))
})
