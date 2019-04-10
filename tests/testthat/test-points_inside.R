context("points inside canvas")

test_that("points inside", {
  points <- poisson_disc(100, 100, 10)
  outside_x <- points$x[points$x > 100 | points$x < 0]
  outside_y <- points$y[points$y > 100 | points$y < 0]

  expect_equal(length(outside_x), 0)
  expect_equal(length(outside_y), 0)
})
