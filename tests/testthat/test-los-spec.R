test_that("los_spec returns a survival vector of correct length", {
  s <- los_spec("negbin", mu = 2, k = 1.7, max_stay = 10)
  expect_length(s, 11L)
  expect_true(all(s >= 0 & s <= 1))
  expect_true(all(diff(s) <= 1e-9))
})

test_that("each family produces a non-increasing survival in [0, 1]", {
  for (fam in list(
    list("negbin",    list(mu = 2, k = 1.7)),
    list("normal",    list(mu = 5, sigma = 2)),
    list("lognormal", list(meanlog = 1.5, sdlog = 0.5)),
    list("geometric", list(mu = 3))
  )) {
    s <- do.call(los_spec, c(family = fam[[1]], fam[[2]], list(max_stay = 20)))
    expect_length(s, 21L)
    expect_true(all(s >= 0 & s <= 1))
    expect_true(all(diff(s) <= 1e-9))
  }
})
