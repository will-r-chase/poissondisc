#fast poisson disc sampling algorithm
#Robert Bridson https://www.cs.ubc.ca/~rbridson/docs/bridson-siggraph07-poissondisk.pdf
#R implementation by Will Chase (@W_R_Chase)

#maybe add back the check to see if the sample point is already in our grid


#' Poisson disc sampling
#'
#' Generates a set of (x, y) points that are never closer than some minimum distance in a canvas of given width and height.
#'
#' @param width The canvas width (numeric)
#' @param height The canvas height (numeric)
#' @param min_dist The minimum distance between points (numeric)
#' @param k Samples to choose before rejection (numeric), this should usually stay at 30
#' @param init The initial point, if not specified, will be randomly picked, otherwise specify as a numeric vector (x, y)
#'
#' @return A data frame with the x and y coordinates of the points.
#' @export
#'
#' @examples
#' #generate a set of points within a 400x400 canvas with a minimum distance of 20
#' pts <- poisson_disc(400, 400, 20)
#'
#'
poisson_disc <- function(width, height, min_dist, k = 30, init = NULL) {
  if(!is.numeric(width)) {stop("width must be a numeric value")}
  if(!is.numeric(height)) {stop("height must be a numeric value")}
  if(!is.numeric(min_dist)) {stop("min_dist must be a numeric value")}
  if(!is.numeric(k)) {stop("k must be a numeric value")}
  if(!is.null(init) & !is.numeric(init)) {stop("n must be a numeric vector of length 2")}
  if(!is.null(init) & length(init) != 2) {stop("n must be a numeric vector of length 2")}

  #calc dist between 2 points
  #can we remove sqrt? would make it faster
  eu_dist <- function(a, b) {
    sqrt((a["x"] - b["x"])^2 + (a["y"] - b["y"])^2)
  }

  grid <- list() #background grid
  active <- list() #active list
  ordered <- list() #for plotting points
  w <- min_dist/sqrt(2) #cell size is r/sqrt(n)

  #define # of cols and rows in array
  cols <- floor(width/w)
  rows <- floor(height/w)

  #fill background grid with NA
  for(i in 1:(cols*rows)) {
    grid[[i]] <- NA
  }

  #pick a random point to initialize
  if(is.null(init)) {
    x <- stats::runif(1, 0, width)
    y <- stats::runif(1, 0, height)
    pos_init <- c(x = x, y = y)
  } else {
    x <- init[1]
    y <- init[2]
    pos_init <- c(x = x, y = y)
  }

  i <- floor(x / w) + 1 #call i the column index
  j <- floor(y / w) + 1 #j is row index

  grid[[(i + j * cols)-cols]] <- pos_init #find the grid index and insert the initial point
  active <- c(active, list(pos_init)) #insert initial point into active list

  #loop until no more active points
  while(length(active) > 0) {
    #choose a random index from the active list
    rand_index <- floor(stats::runif(1, 1, length(active)))
    pos <- active[[rand_index]]
    found <- FALSE

    for(n in 1:k) {
      #choose a random point between r-2r around the active point
      a <- stats::runif(1, 0, 2*pi)
      m <- stats::runif(1, min_dist, 2*min_dist)
      sample <- c(x = m*cos(a), y = m*sin(a)) + pos

      #get col/row index of sample point
      col <- floor(sample["x"]/w) + 1
      row <- floor(sample["y"]/w) + 1

      if(col > 1 & row > 1 & col < cols & row < rows) {
        ok <- TRUE
        #check each neighboring square to see if empty
        for(i in -1:1) {
          for(j in -1:1) {
            index <- ((col + i) + (row + j) * cols) - cols
            neighbor <- grid[[index]]
            #if not empty, calc dist b/w sample and point in neighbor
            #think it's ok to suppress warnings here
            #it's just warning if it's not empty cus there's 2 element, x&y
            suppressWarnings(if(!is.na(neighbor)) {
              d <- eu_dist(sample, neighbor)
              #if they're too close, we wont keep the new point
              if(d < min_dist) {
                ok <- FALSE
              }
            })
          }
        }
        #if they're acceptable distance, we keep the sample point and add to active
        if(ok) {
          found <- TRUE
          grid[[(col + row * cols) - cols]] <- sample
          active <- c(active, list(sample))
          ordered <- c(ordered, list(sample))
          break()
        }
      }
    }
    #remove the old active point
    if(!found) {
      active[[rand_index]] <- NULL
    }
  }

  as.data.frame(Reduce(rbind, ordered))
}
