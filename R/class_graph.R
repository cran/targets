graph_init <- function(edges = NULL) {
  edges <- edges %|||% data_frame(from = character(0), to = character(0))
  upstream <- lookup_init(adjacency_list(from = edges$from, to = edges$to))
  downstream <- lookup_init(adjacency_list(from = edges$to, to = edges$from))
  graph_new(upstream, downstream)
}

graph_new <- function(upstream = NULL, downstream = NULL) {
  graph_class$new(upstream, downstream)
}

graph_class <- R6::R6Class(
  classname = "tar_queue",
  class = FALSE,
  portable = FALSE,
  cloneable = FALSE,
  public = list(
    upstream = NULL,
    downstream = NULL,
    initialize = function(
      upstream = NULL,
      downstream = NULL
    ) {
      self$upstream <- upstream
      self$downstream <- downstream
    },
    produce_degrees_upstream = function(names) {
      index <- 1L
      n <- length(names)
      out <- vector(mode = "integer", length = n)
      upstream <- .subset2(self, "upstream")
      while (index <= n) {
        out[index] <- length(.subset2(upstream, .subset(names, index)))
        index <- index + 1L
      }
      out
    },
    produce_degrees_downstream = function(names) {
      index <- 1L
      n <- length(names)
      out <- vector(mode = "integer", length = n)
      downstream <- .subset2(self, "downstream")
      while (index <= n) {
        out[index] <- length(.subset2(downstream, .subset(names, index)))
        index <- index + 1L
      }
      out
    },
    produce_upstream = function(name) {
      as.character(.subset2(.subset2(self, "upstream"), name))
    },
    produce_downstream = function(name) {
      as.character(.subset2(.subset2(self, "downstream"), name))
    },
    replace_upstream = function(name, from, to) {
      index <- .subset2(.subset2(self, "upstream"), name) == from
      self$upstream[[name]][index] <- to
    },
    insert_edges = function(edges) {
      join_edges(
        lookup = .subset2(self, "upstream"),
        from = .subset2(edges, "from"),
        to = .subset2(edges, "to")
      )
      join_edges(
        lookup = .subset2(self, "downstream"),
        from = .subset2(edges, "to"),
        to = .subset2(edges, "from")
      )
    },
    validate = function() {
      lapply(self$upstream, tar_assert_chr)
      lapply(self$downstream, tar_assert_chr)
      invisible()
    }
  )
)

adjacency_list <- function(from, to) {
  # Faster than tapply(X = from, INDEX = to, identity, simplify = FALSE):
  tapply(
    X = from,
    INDEX = factor(to, levels = unique.default(to)),
    FUN = identity,
    simplify = FALSE
  )
}

join_edges <- function(lookup, from, to) {
  new_edgelist <- adjacency_list(from = from, to = to)
  index <- 1L
  names <- names(new_edgelist)
  n <- length(names)
  bar <- cli_local_progress_bar_init(label = "joining graph edges", total = n)
  on.exit(cli_local_progress_bar_destroy(bar = bar))
  while (index <= n) {
    name <- .subset(names, index)
    new_from <- .subset2(new_edgelist, index)
    if (is.null(.subset2(lookup, name))) {
      lookup[[name]] <- new_from
    } else {
      lookup[[name]] <- unique.default(c(new_from, .subset2(lookup, name)))
    }
    index <- index + 1L
    cli_local_progress_bar_update(bar = bar, index = index)
  }
}

remove_loops <- function(edges) {
  edges[edges$from != edges$to, ]
}
