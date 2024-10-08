% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tar_errored.R
\name{tar_errored}
\alias{tar_errored}
\title{List errored targets.}
\usage{
tar_errored(names = NULL, store = targets::tar_config_get("store"))
}
\arguments{
\item{names}{Optional, names of the targets. If supplied, the
output is restricted to the selected targets.
The object supplied to \code{names} should be \code{NULL} or a
\code{tidyselect} expression like \code{\link[=any_of]{any_of()}} or \code{\link[=starts_with]{starts_with()}}
from \code{tidyselect} itself, or \code{\link[=tar_described_as]{tar_described_as()}} to select target names
based on their descriptions.}

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
A character vector of errored targets.
}
\description{
List targets whose progress is \code{"errored"}.
}
\section{Storage access}{

Several functions like \code{tar_make()}, \code{tar_read()}, \code{tar_load()},
\code{tar_meta()}, and \code{tar_progress()} read or modify
the local data store of the pipeline.
The local data store is in flux while a pipeline is running,
and depending on how distributed computing or cloud computing is set up,
not all targets can even reach it. So please do not call these
functions from inside a target as part of a running
pipeline. The only exception is literate programming
target factories in the \code{tarchetypes} package such as \code{tar_render()}
and \code{tar_quarto()}.
}

\examples{
if (identical(Sys.getenv("TAR_EXAMPLES"), "true")) { # for CRAN
tar_dir({ # tar_dir() runs code from a temp dir for CRAN.
tar_script({
  library(targets)
  library(tarchetypes)
  list(
    tar_target(x, seq_len(2)),
    tar_target(y, 2 * x, pattern = map(x))
  )
}, ask = FALSE)
tar_make()
tar_errored()
tar_errored(starts_with("y_")) # see also any_of()
})
}
}
\seealso{
Other progress: 
\code{\link{tar_canceled}()},
\code{\link{tar_completed}()},
\code{\link{tar_dispatched}()},
\code{\link{tar_poll}()},
\code{\link{tar_progress}()},
\code{\link{tar_progress_branches}()},
\code{\link{tar_progress_summary}()},
\code{\link{tar_skipped}()},
\code{\link{tar_watch}()},
\code{\link{tar_watch_server}()},
\code{\link{tar_watch_ui}()}
}
\concept{progress}
