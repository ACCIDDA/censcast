test_that("plot_fan returns a ggplot", {
  fc <- tibble::tibble(
    model_id = "M", location = "X",
    reference_date = as.Date("2024-01-06"),
    horizon = rep(1:3, each = 5),
    target_end_date = rep(as.Date("2024-01-13") + 7L * (0:2), each = 5),
    target = "wk inc flu hosp",
    output_type = "quantile",
    output_type_id = rep(c("0.025", "0.25", "0.5", "0.75", "0.975"), 3),
    value = rep(c(80, 95, 110, 125, 140), 3)
  )
  expect_s3_class(plot_fan(fc), "ggplot")
})
