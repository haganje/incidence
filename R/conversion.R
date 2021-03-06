#' Conversion of incidence objects
#'
#' These functions convert `incidence` objects into other classes.
#'
#' @rdname conversions
#'
#' @author Thibaut Jombart \email{thibautjombart@@gmail.com}, Rich Fitzjohn
#'
#' @importFrom stats as.ts
#'
#' @export
#'
#' @param x An `incidence` object, or an object to be converted as
#'   `incidence` (see details).
#'
#' @param ... Further arguments passed to other functions (no used).
#'
#' @param long A logical indicating if the output data.frame should be 'long', i.e. where a single
#' column containing 'groups' is added in case of data computed on several groups.
#'
#'
#' @export
#'
#'
#' @seealso the [incidence()] function to generate the 'incidence' objects.
#'
#'
#' @details Conversion to `incidence` objects should only be done when the
#'   original dates are not available. In such case, the argument `x`
#'   should be a matrix corresponding to the `$counts` element of an
#'   `incidence` object, i.e. giving counts with time intervals in rows and
#'   named groups in columns. In the absence of groups, a single unnamed columns
#'   should be given. `data.frame` and vectors will be coerced to a matrix.
#'
#'
#' @examples
#' ## create fake data
#' data <- c(0,1,1,2,1,3,4,5,5,5,5,4,4,26,6,7,9)
#' sex <- sample(c("m","f"), length(data), replace=TRUE)
#'
#' ## get incidence per group (sex)
#' i <- incidence(data, groups = sex)
#' i
#' plot(i)
#'
#' ## convert to data.frame
#' as.data.frame(i)
#'
#' ## same, 'long format'
#' as.data.frame(i, long = TRUE)
#'
#'
#'
#' ## conversion from a matrix of counts to an incidence object
#' i$counts
#' new_i <- as.incidence(i$counts, i$dates)
#' new_i
#' all.equal(i, new_i)
#'

as.data.frame.incidence <- function(x, ..., long = FALSE){
    counts  <- x$counts
    gnames  <- group_names(x)
    unnamed <- is.null(gnames) && ncol(counts) == 1L
    if (unnamed) {
        colnames(counts) <- "counts"
    }

    if ("isoweeks" %in% names(x)) {
      out <- cbind.data.frame(dates = x$dates,
                              isoweeks = x$isoweeks,
                              counts)
    } else {
      out <- cbind.data.frame(dates = x$dates, counts)
    }

    ## handle the long format here
    if (long && !unnamed) {
        groups <- factor(rep(gnames, each = nrow(out)), levels = gnames)
        counts <- as.vector(x$counts)
        if ("isoweeks" %in% names(x)) {
          out <- data.frame(dates = out$dates,
                            isoweeks = out$isoweeks,
                            counts = counts,
                            groups = groups)
        } else {
          out <- data.frame(dates = out$dates,
                            counts = counts,
                            groups = groups)
        }
    }
    out
}






## Conversion to 'incidence' class can be handy to plot and handle data for
## which incidence has already been computed. To ensure that the ouput is a
## correct object, we use the 'incidence' function on fake data that match the
## counts inputs. This avoids potential issues such as non-regular intervals
## (the first time interval is used for the entire data.

#' @export
#' @rdname conversions

as.incidence <- function(x, ...) {
  UseMethod("as.incidence", x)
}






#' @export
#'
#' @rdname conversions
#'
#' @param dates A vector of dates, each corresponding to the (inclusive) lower
#' limit of the bins.
#'
#' @param interval An integer indicating the time interval used in the
#'   computation of the incidence. If NULL, it will be determined from the first
#'   time interval between provided dates. If only one date is provided, it will
#'   trigger an error.
#'
#' @param isoweeks A logical indicating whether isoweeks should be used in the
#'   case of weekly incidence; defaults to `TRUE`.
#'

as.incidence.matrix <- function(x, dates = NULL, interval = NULL,
                                isoweeks = TRUE, ...) {

  if (is.null(dates)) {
    if (!is.null(interval)) {
      interval <- check_interval(interval)
      dates <- seq(1, length = nrow(x), by = interval)
    } else{
      dates <- seq(1, length = nrow(x), by = 1L)
    }
  }

  dates <- check_dates(dates, error_on_NA = TRUE)
  last_date <- max(dates)

  ## determine interval

  if (is.null(interval)) {
    if (length(dates) < 2L) {
      msg <- "Interval needs to be specified if there is only one date."
      stop(msg)
    } else {
      interval <- as.integer(diff(dates[1:2]))
    }
  } else {
    interval <- check_interval(interval)
  }


  ## generate fake dates

  x_vector <- as.vector(x)
  fake_dates <- rep(rep(dates, ncol(x)), x_vector)


  ## determine groups

  if (ncol(x) > 1L) {
    x_groups <- colnames(x)
    if (is.null(x_groups)) {
      msg <- "Columns should be named to label groups."
      stop(msg)
    }
    group_sizes <- colSums(x)
    fake_groups <- rep(x_groups, group_sizes)
  } else {
    fake_groups <- NULL
  }

  if (inherits(fake_dates, c("Date", "POSIXt"))) {
    incidence(fake_dates,
              interval = interval,
              groups = fake_groups,
              standard = isoweeks,
              last_date = last_date)
  } else {
    incidence(fake_dates,
            interval = interval,
            groups = fake_groups,
            last_date = last_date)
  }
}






#' @export
#'
#' @rdname conversions

as.incidence.data.frame <- function(x, dates = NULL, interval = NULL,
                                    isoweeks = TRUE, ...) {
  as.incidence(as.matrix(x), dates, interval, isoweeks, ...)
}






#' @export
#'
#' @rdname conversions

as.incidence.numeric <- function(x, dates = NULL, interval = NULL,
                                 isoweeks = TRUE, ...) {
  as.incidence(as.matrix(x), dates, interval, isoweeks, ...)
}
