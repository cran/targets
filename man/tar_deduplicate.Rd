% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tar_deduplicate.R
\name{tar_deduplicate}
\alias{tar_deduplicate}
\title{Deduplicate meta and progress databases (deprecated).}
\usage{
tar_deduplicate(meta = TRUE, progress = TRUE)
}
\arguments{
\item{meta}{Logical, whether to deduplicate the meta database file
at \verb{_targets/meta/meta}.}

\item{progress}{Logical, whether to deduplicate the progress database file
at \verb{_targets/meta/progress}.}
}
\value{
Nothing.
}
\description{
Deprecated in version 0.3.0 (2020-03-06).
Deduplication happens automatically before and after the pipeline runs.
}
\details{
Removes duplicated entries in the meta and progress
databases in order to lighten storage. These databases are located
in the \verb{_targets/meta/meta} and \verb{_targets/meta/progress} files,
where \verb{_targets} is the a folder at the project root.
No essential data is removed, so
this is simply a form of garbage collection.
}
\keyword{internal}
