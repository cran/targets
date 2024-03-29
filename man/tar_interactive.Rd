% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tar_interactive.R
\name{tar_interactive}
\alias{tar_interactive}
\title{Run if Target Markdown interactive mode is on.}
\usage{
tar_interactive(code)
}
\arguments{
\item{code}{R code to run if Target Markdown interactive mode
is turned on.}
}
\value{
If Target Markdown interactive mode is turned on,
the function returns the result of running the code.
Otherwise, the function invisibly returns \code{NULL}.
}
\description{
In Target Markdown, run the enclosed code
only if interactive mode is activated. Otherwise,
do not run the code.
}
\details{
Visit <books.ropensci.org/targets/literate-programming.html>
to learn about Target Markdown and interactive mode.
}
\examples{
tar_interactive(message("In interactive mode."))
}
\seealso{
Other Target Markdown: 
\code{\link{tar_engine_knitr}()},
\code{\link{tar_noninteractive}()},
\code{\link{tar_toggle}()}
}
\concept{Target Markdown}
