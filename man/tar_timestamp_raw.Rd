% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tar_timestamp_raw.R
\name{tar_timestamp_raw}
\alias{tar_timestamp_raw}
\title{Get the timestamp(s) of a target (raw version).}
\usage{
tar_timestamp_raw(
  name = NULL,
  format = NULL,
  tz = NULL,
  parse = NULL,
  store = targets::tar_config_get("store")
)
}
\arguments{
\item{name}{Character of length 1, name of the target.}

\item{format}{Deprecated in \code{targets} version 0.6.0 (2021-07-21).}

\item{tz}{Deprecated in \code{targets} version 0.6.0 (2021-07-21).}

\item{parse}{Deprecated in \code{targets} version 0.6.0 (2021-07-21).}

\item{store}{Character of length 1, path to the
\code{targets} data store. Defaults to \code{tar_config_get("store")},
which in turn defaults to \verb{_targets/}.
When you set this argument, the value of \code{tar_config_get("store")}
is temporarily changed for the current function call.
See \code{\link[=tar_config_get]{tar_config_get()}} and \code{\link[=tar_config_set]{tar_config_set()}} for details
about how to set the data store path persistently
for a project.}
}
\value{
If the target is not recorded in the metadata
or cannot be parsed correctly, then
\code{tar_timestamp_raw()} returns a \code{POSIXct} object at \verb{1970-01-01 UTC}.
}
\description{
Get the time that a target last ran successfully.
}
\details{
\code{tar_timestamp_raw()} is like \code{tar_timestamp()} except
it accepts a character string for \code{name} instead of a symbol.
\code{tar_timestamp_raw()} checks the metadata in \verb{_targets/meta/meta},
not the actual data. Time stamps are recorded only for targets that
run commands: just non-branching targets and individual dynamic
branches.
}
\examples{
if (identical(Sys.getenv("TAR_EXAMPLES"), "true")) { # for CRAN
tar_dir({ # tar_dir() runs code from a temp dir for CRAN.
tar_script({
  list(tar_target(x, 1))
}, ask = FALSE)
tar_make()
# Get the timestamp.
tar_timestamp_raw("x")
# We can use the timestamp to cancel the target
# if it already ran within the last hour.
# Be sure to set `cue = tar_cue(mode = "always")`
# if you want the target to always check the timestamp.
tar_script({
  list(
  tar_target(
    x,
    tar_cancel((Sys.time() - tar_timestamp_raw()) < 3600),
    cue = tar_cue(mode = "always")
  )
)}, ask = FALSE)
tar_make()
})
}
}
\seealso{
Other time: 
\code{\link{tar_newer}()},
\code{\link{tar_older}()},
\code{\link{tar_timestamp}()}
}
\concept{time}
