% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tar_delete.R
\name{tar_delete}
\alias{tar_delete}
\title{Delete locally stored target return values.}
\usage{
tar_delete(names)
}
\arguments{
\item{names}{Names of the targets to remove from \verb{_targets/objects/}.
You can supply symbols, a character vector,
or \code{tidyselect} helpers like \code{\link[=starts_with]{starts_with()}}.}
}
\description{
Delete the return values of targets in \verb{_targets/objects/}.
but keep the records in \verb{_targets/meta/meta}.
Dynamic files and cloud data (e.g. \code{format = "file"}
and \code{format = "aws_parquet"}) are not deleted.
}
\details{
For patterns recorded in the metadata, all the branches
will be deleted. For patterns no longer in the metadata,
branches are left alone.
}
\examples{
if (identical(Sys.getenv("TAR_LONG_EXAMPLES"), "true")) {
tar_dir({ # tar_dir() runs code from a temporary directory.
tar_script({
  list(
    tar_target(y1, 1 + 1),
    tar_target(y2, 1 + 1),
    tar_target(z, y1 + y2)
  )
}, ask = FALSE)
tar_make()
tar_delete(starts_with("y")) # Only deletes y1 and y2.
tar_make() # y1 and y2 rebuild but return same values, so z is up to date.
})
}
}
\seealso{
Other clean: 
\code{\link{tar_destroy}()},
\code{\link{tar_invalidate}()},
\code{\link{tar_prune}()}
}
\concept{clean}
