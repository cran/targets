% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils_language.R
\name{tar_language}
\alias{tar_language}
\alias{tar_deparse_language}
\alias{tar_deparse_safe}
\alias{tar_tidy_eval}
\alias{tar_tidyselect_eval}
\title{Language}
\usage{
tar_deparse_language(expr)

tar_deparse_safe(expr, collapse = "\\n", backtick = TRUE)

tar_tidy_eval(expr, envir, tidy_eval)

tar_tidyselect_eval(names_quosure, choices)
}
\arguments{
\item{expr}{A language object to modify or deparse.}

\item{collapse}{Character of length 1, delimiter in deparsing.}

\item{backtick}{logical indicating whether symbolic names should be
    enclosed in backticks if they do not follow the standard syntax.}

\item{envir}{An environment to find objects for tidy evaluation.}

\item{tidy_eval}{Logical of length 1, whether to apply tidy evaluation.}

\item{names_quosure}{An \code{rlang} quosure with \code{tidyselect} expressions.}

\item{choices}{A character vector of choices for character elements
returned by tidy evaluation.}
}
\description{
These functions help with metaprogramming in
packages built on top of \code{targets}.
}
\details{
\itemize{
\item \code{tar_deparse_language()} is a wrapper around \code{tar_deparse_safe()}
which leaves character vectors and \code{NULL} objects alone,
which helps with subsequent user input validation.
\item \code{tar_deparse_safe()} is a wrapper around \code{base::deparse()}
with a custom set of fast default settings and guardrails
to ensure the output always has length 1.
\item \code{tar_tidy_eval()} applies tidy evaluation to a language object
and returns another language object.
\item \code{tar_tidyselect_eval()} applies \code{tidyselect} selection with
some special guardrails around \code{NULL} inputs.
}
}
\examples{
tar_deparse_language(quote(run_model()))
}
\seealso{
Other utilities to extend targets: 
\code{\link{tar_assert}},
\code{\link{tar_condition}},
\code{\link{tar_test}()}
}
\concept{utilities to extend targets}
