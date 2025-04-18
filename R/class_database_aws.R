# Covered in semi-automated cloud tests.
# nocov start
database_aws_new <- function(
  lookup = NULL,
  path = NULL,
  key = NULL,
  header = NULL,
  logical_columns = NULL,
  integer_columns = NULL,
  numeric_columns = NULL,
  list_columns = NULL,
  list_column_modes = NULL,
  resources = NULL
) {
  database_aws_class$new(
    lookup = lookup,
    path = path,
    key = key,
    header = header,
    logical_columns = logical_columns,
    integer_columns = integer_columns,
    numeric_columns = numeric_columns,
    list_columns = list_columns,
    list_column_modes = list_column_modes,
    resources = resources
  )
}

database_aws_class <- R6::R6Class(
  classname = "tar_database_aws",
  inherit = database_class,
  class = FALSE,
  portable = FALSE,
  cloneable = FALSE,
  public = list(
    validate = function() {
      super$validate()
      tar_assert_inherits(
        self$resources$aws,
        "tar_resources_aws",
        msg = paste(
          "Resources must be supplied to the `targets` AWS ",
          "database class. Set resources with tar_option_set()"
        )
      )
      resources_validate(self$resources$aws)
    },
    download = function(verbose = TRUE) {
      if (verbose) {
        tar_print(
          "Downloading AWS cloud object ",
          self$key,
          " to local file ",
          self$path
        )
      }
      aws <- self$resources$aws
      dir_create(dirname(self$path))
      aws_s3_download(
        file = self$path,
        key = self$key,
        bucket = aws$bucket,
        region = aws$region,
        endpoint = aws$endpoint,
        args = aws$args,
        max_tries = aws$max_tries %|||% 5L
      )
      invisible()
    },
    download_workspace = function(name, store, verbose = TRUE) {
      path <- path_workspace(store, name)
      key <- path_workspace(dirname(dirname(self$key)), name)
      aws <- self$resources$aws
      if (verbose) {
        tar_print(
          "Downloading AWS workspace file ",
          key,
          " to local file ",
          path
        )
      }
      dir_create(dirname(path))
      aws_s3_download(
        file = path,
        key = key,
        bucket = aws$bucket,
        region = aws$region,
        endpoint = aws$endpoint,
        args = aws$args,
        max_tries = aws$max_tries %|||% 5L
      )
      invisible()
    },
    upload = function(verbose = TRUE) {
      if (verbose) {
        tar_print(
          "Uploading local file ",
          self$path,
          " to AWS cloud object ",
          self$key
        )
      }
      aws <- self$resources$aws
      file <- file_init(path = path)
      file_ensure_hash(file)
      aws_s3_upload(
        file = self$path,
        key = self$key,
        bucket = aws$bucket,
        region = aws$region,
        endpoint = aws$endpoint,
        metadata = list(
          "targets-database-hash" = file$hash,
          "targets-database-size" = file$size,
          "targets-database-time" = file$time
        ),
        part_size = aws$part_size,
        args = aws$args,
        max_tries = aws$max_tries %|||% 5L
      )
      invisible()
    },
    upload_workspace = function(target, meta, reporter) {
      name <- target_get_name(target)
      path <- path_workspace(meta$store, name)
      key <- path_workspace(dirname(dirname(self$key)), name)
      aws <- self$resources$aws
      aws_s3_upload(
        file = path,
        key = key,
        bucket = aws$bucket,
        region = aws$region,
        endpoint = aws$endpoint,
        part_size = aws$part_size,
        args = aws$args,
        max_tries = aws$max_tries %|||% 5L
      )
      reporter$report_workspace_upload(target)
      invisible()
    },
    head = function() {
      aws <- self$resources$aws
      head <- aws_s3_head(
        key = self$key,
        bucket = aws$bucket,
        region = aws$region,
        endpoint = aws$endpoint,
        args = aws$args,
        max_tries = aws$max_tries %|||% 5L
      )
      list(
        exists = !is.null(head),
        hash = head$Metadata$`targets-database-hash`,
        size = head$Metadata$`targets-database-size`,
        time = head$Metadata$`targets-database-time`
      )
    },
    delete_cloud = function(verbose = TRUE) {
      if (verbose) {
        tar_print("Deleting AWS cloud object ", self$key)
      }
      aws <- self$resources$aws
      aws_s3_delete(
        key = self$key,
        bucket = aws$bucket,
        region = aws$region,
        endpoint = aws$endpoint,
        args = aws$args,
        max_tries = aws$max_tries %|||% 5L
      )
    },
    delete_cloud_workspaces = function() {
      prefix <- dirname(path_workspace(dirname(dirname(self$key)), "x"))
      aws <- self$resources$aws
      names <- names(
        aws_s3_list_etags(
          prefix = prefix,
          bucket = aws$bucket,
          page_size = 1000L,
          verbose = FALSE,
          region = aws$region,
          endpoint = aws$endpoint,
          args = aws$args,
          max_tries = aws$max_tries %|||% 5L,
          seconds_timeout = aws$seconds_timeout,
          close_connection = aws$close_connection,
          s3_force_path_style = aws$s3_force_path_style
        )
      )
      aws_s3_delete_objects(
        objects = lapply(names, function(x) list(Key = x)),
        bucket = aws$bucket,
        batch_size = 1000L,
        region = aws$region,
        endpoint = aws$endpoint,
        args = aws$args,
        max_tries = aws$max_tries %|||% 5L,
        seconds_timeout = aws$seconds_timeout,
        close_connection = aws$close_connection,
        s3_force_path_style = aws$s3_force_path_style,
        verbose = FALSE
      )
      invisible()
    }
  )
)
# nocov end
