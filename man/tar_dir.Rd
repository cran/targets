% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tar_dir.R
\name{tar_dir}
\alias{tar_dir}
\title{Execute code in a temporary directory.}
\usage{
tar_dir(code)
}
\arguments{
\item{code}{User-defined code.}
}
\value{
Return value of the user-defined code.
}
\description{
Not a user-side function. Just for CRAN.
}
\details{
Runs code inside a new \code{tempfile()} directory
in order to avoid writing to the user's file space.
Used in examples and tests in order to comply with CRAN policies.
}
\examples{
tar_dir(file.create("only_exists_in_tar_dir"))
file.exists("only_exists_in_tar_dir")
}
\keyword{internal}
