builder_new <- function(
  command = NULL,
  settings = NULL,
  cue = NULL,
  value = NULL,
  metrics = NULL,
  store = NULL,
  file = NULL,
  subpipeline = NULL
) {
  out <- new.env(parent = emptyenv(), hash = FALSE)
  out$command <- command
  out$settings <- settings
  out$cue <- cue
  out$value <- value
  out$metrics <- metrics
  out$store <- store
  out$file <- file
  out$subpipeline <- subpipeline
  enclass(out, builder_s3_class)
}

builder_s3_class <- c("tar_builder", "tar_target")

#' @export
target_update_depend.tar_builder <- function(target, pipeline, meta) {
  lookup <- .subset2(meta, "depends")
  name <- target_get_name(target)
  object <- meta$produce_depend(target, pipeline)
  lookup[[name]] <- object
}

#' @export
target_bootstrap.tar_builder <- function(
  target,
  pipeline,
  meta,
  branched_over = FALSE
) {
  record <- target_bootstrap_record(target, meta)
  target$store <- record_bootstrap_store(record)
  target$file <- record_bootstrap_file(record)
  pipeline_set_target(pipeline, target)
  invisible()
}

#' @export
target_read_value.tar_builder <- function(target, pipeline = NULL) {
  command <- target$command
  load_packages(packages = command$packages, library = command$library)
  object <- store_read_object(target$store, target$file)
  iteration <- target$settings$iteration
  value_init(object, iteration)
}

#' @export
target_prepare.tar_builder <- function(
  target,
  pipeline,
  scheduler,
  meta,
  pending = FALSE
) {
  if (package_installed("autometric (>= 0.1.0)")) {
    phase <- paste("prepare:", target_get_name(target))
    autometric::log_phase_set(phase = phase)
    on.exit(autometric::log_phase_reset())
  }
  target_patternview_dispatched(target, pipeline, scheduler)
  scheduler$progress$register_dispatched(target)
  scheduler$reporter$report_dispatched(
    target = target,
    progress = scheduler$progress,
    pending = pending
  )
  if (identical(target$settings$retrieval, "main")) {
    target_ensure_deps_main(target, pipeline)
  }
  builder_update_subpipeline(target, pipeline)
}

# nocov start
# Tested in tests/aws/test-class_aws_qs.R (bucket deleted later).
#' @export
target_should_run.tar_builder <- function(target, meta) {
  tryCatch(
    builder_should_run(target, meta),
    error = function(error) {
      message <- paste0(
        "could not check target ",
        target_get_name(target),
        ". ",
        conditionMessage(error)
      )
      expr <- as.expression(as.call(list(quote(stop), message)))
      target$command$expr <- expr
      target$settings$deployment <- "main"
      TRUE
    }
  )
}
# nocov end

# Willing to ignore high cyclomatic complexity score.
# nolint start
builder_should_run <- function(target, meta) {
  cue <- .subset2(target, "cue")
  if (cue_meta_exists(cue, target, meta)) return(TRUE)
  row <- .subset2(meta, "get_row")(target_get_name(target))
  if (cue_meta(cue, target, meta, row)) return(TRUE)
  if (cue_always(cue, target, meta)) return(TRUE)
  if (cue_never(cue, target, meta)) return(FALSE)
  if (cue_command(cue, target, meta, row)) return(TRUE)
  if (cue_depend(cue, target, meta, row)) return(TRUE)
  if (cue_format(cue, target, meta, row)) return(TRUE)
  if (cue_repository(cue, target, meta, row)) return(TRUE)
  if (cue_iteration(cue, target, meta, row)) return(TRUE)
  if (cue_seed(cue, target, meta, row)) return(TRUE)
  if (cue_file(cue, target, meta, row)) return(TRUE)
  FALSE
}
# nolint end

#' @export
target_should_run_worker.tar_builder <- function(target) {
  identical(target$settings$deployment, "worker")
}

#' @export
target_needs_worker.tar_builder <- function(target) {
  identical(target$settings$deployment, "worker")
}

#' @export
target_run.tar_builder <- function(
  target,
  envir,
  path_store,
  on_worker = FALSE
) {
  if (package_installed("autometric (>= 0.1.0)")) {
    autometric::log_phase_set(phase = target_get_name(target))
    on.exit(autometric::log_phase_reset())
  }
  on.exit(builder_unset_tar_runtime(), add = TRUE)
  on.exit(target$subpipeline <- NULL, add = TRUE)
  if (!identical(target$settings$retrieval, "none")) {
    target_ensure_deps_worker(target, target$subpipeline)
  }
  frames <- frames_produce(envir, target, target$subpipeline)
  builder_set_tar_runtime(target, frames)
  store_update_stage_early(
    store = target$store,
    file = target$file,
    name = target_get_name(target),
    path_store = path_store
  )
  runtime_increment_targets_run(tar_runtime)
  target_gc(target)
  builder_update_build(target, frames_get_envir(frames))
  builder_ensure_paths(target, path_store)
  builder_ensure_object(target, "worker", on_worker)
  builder_ensure_object(target, "none", on_worker)
  target
}

#' @export
target_run_worker.tar_builder <- function(
  target,
  envir,
  path_store,
  fun,
  options,
  envvars
) {
  if (package_installed("autometric (>= 0.1.0)")) {
    autometric::log_phase_set(phase = target_get_name(target))
    on.exit(autometric::log_phase_reset())
  }
  set_envvars(envvars)
  tar_options$import(options)
  envir <- if_any(identical(envir, "globalenv"), globalenv(), envir)
  tar_option_set(envir = envir)
  tar_runtime$store <- path_store
  tar_runtime$fun <- fun
  builder_unmarshal_subpipeline(target)
  target_run(target, envir, path_store, on_worker = TRUE)
  builder_marshal_value(target)
  target
}

#' @export
target_skip.tar_builder <- function(
  target,
  pipeline,
  scheduler,
  meta,
  active
) {
  target_update_queue(target, scheduler)
  name <- target_get_name(target)
  row <- .subset2(meta, "get_row")(name)
  path <- store_path_from_name(
    store = .subset2(target, "store"),
    format = .subset2(row, "format"),
    name = name,
    path = unlist(.subset2(row, "path")),
    path_store = .subset2(meta, "store")
  )
  file_repopulate(
    file = .subset2(target, "file"),
    path = path,
    data = .subset2(row, "data")
  )
  pipeline_set_target(pipeline, target)
  if (active) {
    builder_ensure_workspace(
      target = target,
      pipeline = pipeline,
      scheduler = scheduler,
      meta = meta
    )
  }
  progress <- .subset2(scheduler, "progress")
  if_any(
    active,
    .subset2(progress, "register_skipped")(target),
    .subset2(progress, "assign_skipped")(target_get_name(target))
  )
  .subset2(.subset2(scheduler, "reporter"), "report_skipped")(
    target,
    .subset2(scheduler, "progress")
  )
}

#' @export
target_conclude.tar_builder <- function(target, pipeline, scheduler, meta) {
  if (package_installed("autometric (>= 0.1.0)")) {
    phase <- paste("conclude:", target_get_name(target))
    autometric::log_phase_set(phase = phase)
    on.exit(autometric::log_phase_reset())
  }
  on.exit(builder_unset_tar_runtime(), add = TRUE)
  builder_set_tar_runtime(target, NULL)
  target_update_queue(target, scheduler)
  builder_ensure_workspace(
    target = target,
    pipeline = pipeline,
    scheduler = scheduler,
    meta = meta
  )
  builder_ensure_object(target, "main", on_worker = FALSE)
  builder_ensure_correct_hash(target)
  builder_handle_warnings(target, scheduler)
  switch(
    metrics_outcome(target$metrics),
    cancel = builder_cancel(target, pipeline, scheduler, meta),
    error = builder_error(target, pipeline, scheduler, meta),
    completed = builder_completed(target, pipeline, scheduler, meta)
  )
  NextMethod()
}

builder_completed <- function(target, pipeline, scheduler, meta) {
  store_cache_path(target$store, target$file$path)
  target_ensure_buds(target, pipeline, scheduler)
  meta$insert_record(target_produce_record(target, pipeline, meta))
  target_patternview_meta(target, pipeline, meta)
  pipeline_set_target(pipeline, target)
  if (!is.null(target$value)) {
    pipeline_register_loaded(pipeline, target_get_name(target))
  }
  scheduler$progress$register_completed(target)
  scheduler$reporter$report_completed(target, scheduler$progress)
}

builder_error <- function(target, pipeline, scheduler, meta) {
  target_restore_buds(target, pipeline, scheduler, meta)
  builder_record_error_meta(target, pipeline, meta)
  target_patternview_meta(target, pipeline, meta)
  builder_handle_error(target, pipeline, scheduler, meta)
}

builder_cancel <- function(target, pipeline, scheduler, meta) {
  target_restore_buds(target, pipeline, scheduler, meta)
  scheduler$progress$register_canceled(target)
  scheduler$reporter$report_canceled(target, scheduler$progress)
  target_patternview_canceled(target, pipeline, scheduler)
}

#' @export
target_debug.tar_builder <- function(target) {
  debug <- tar_options$get_debug()
  should_debug <- length(debug) &&
    (target_get_name(target) %in% debug) &&
    interactive()
  if (should_debug) {
    # Covered in tests/interactive/test-debug.R
    # nocov start
    target$command$expr <- c(
      expression(targets::tar_debug_instructions()),
      expression(browser()),
      target$command$expr
    )
    target$cue$mode <- "always"
    target$settings$deployment <- "main"
    # nocov end
  }
}

#' @export
target_get_packages.tar_builder <- function(target) {
  packages_command <- target$command$packages
  packages_store <- store_get_packages(target$store)
  sort_chr(unique(c(packages_command, packages_store)))
}

#' @export
target_validate.tar_builder <- function(target) {
  NextMethod()
  if (!is.null(target$store)) {
    store_validate(target$store)
  }
  if (!is.null(target$metrics)) {
    metrics_validate(target$metrics)
  }
}

builder_update_subpipeline <- function(target, pipeline) {
  target$subpipeline <- pipeline_produce_subpipeline(
    pipeline,
    target
  )
}

builder_marshal_subpipeline <- function(target) {
  subpipeline <- target$subpipeline
  retrieval <- target$settings$retrieval
  if (!is.null(subpipeline) && identical(retrieval, "main")) {
    pipeline_marshal_values(subpipeline)
  }
}

builder_unmarshal_subpipeline <- function(target) {
  subpipeline <- target$subpipeline
  retrieval <- target$settings$retrieval
  if (!is.null(subpipeline) && identical(retrieval, "main")) {
    pipeline_unmarshal_values(target$subpipeline)
  }
  patterns <- fltr(
    pipeline_get_names(subpipeline),
    ~inherits(pipeline_get_target(subpipeline, .x), "tar_pattern")
  )
  map(
    setdiff(patterns, target$settings$dimensions),
    ~target_ensure_value(pipeline_get_target(subpipeline, .x), subpipeline)
  )
}

builder_handle_warnings <- function(target, scheduler) {
  if (metrics_has_warnings(target$metrics)) {
    scheduler$progress$assign_warned(target_get_name(target))
  }
}

builder_handle_error <- function(target, pipeline, scheduler, meta) {
  scheduler$progress$register_errored(target)
  scheduler$reporter$report_errored(target, scheduler$progress)
  target_patternview_errored(target, pipeline, scheduler)
  switch(
    target$settings$error,
    continue = builder_error_continue(target, scheduler),
    abridge = scheduler$abridge(target),
    trim = scheduler$trim(target, pipeline),
    stop = builder_error_exit(target, pipeline, scheduler, meta),
    null = builder_error_null(target, pipeline, scheduler, meta),
    workspace = builder_error_exit(target, pipeline, scheduler, meta)
  )
}

builder_error_continue <- function(target, scheduler) {
  store_unload(store = target$store, target = target)
  scheduler$reporter$report_error(target$metrics$error)
}

builder_error_exit <- function(target, pipeline, scheduler, meta) {
  tar_runtime$traceback <- target$metrics$traceback
  tar_throw_run(target$metrics$error, class = target$metrics$error_class)
}

builder_error_null <- function(target, pipeline, scheduler, meta) {
  target_ensure_buds(target, pipeline, scheduler)
  record <- target_produce_record(target, pipeline, meta)
  record$data <- "error"
  meta$insert_record(record)
  target_patternview_meta(target, pipeline, meta)
  pipeline_set_target(pipeline, target)
  pipeline_register_loaded(pipeline, target_get_name(target))
  scheduler$progress$register_errored(target)
}

builder_ensure_workspace <- function(target, pipeline, scheduler, meta) {
  if (builder_should_save_workspace(target)) {
    builder_save_workspace(target, pipeline, scheduler, meta)
  }
}

builder_should_save_workspace <- function(target) {
  names <- c(target_get_name(target), target_get_parent(target))
  because_named <- any(names %in% .subset2(tar_options, "workspaces"))
  has_error <- metrics_has_error(.subset2(target, "metrics"))
  if_error <- .subset2(tar_options, "get_workspace_on_error")() ||
    identical(.subset2(.subset2(target, "settings"), "error"), "workspace")
  because_error <- if_error && has_error
  because_named || because_error
}

builder_save_workspace <- function(target, pipeline, scheduler, meta) {
  workspace_save(
    workspace = workspace_init(target, pipeline),
    path_store = meta$store
  )
  scheduler$reporter$report_workspace(target)
  meta$database$upload_workspace(target, meta, scheduler$reporter)
}

builder_record_error_meta <- function(target, pipeline, meta) {
  record <- target_produce_record(target, pipeline, meta)
  meta$handle_error(record)
  meta$insert_record(record)
}

builder_update_build <- function(target, envir) {
  build <- command_produce_build(target$command, target$seed, envir)
  target$metrics <- build$metrics
  object <- build$object
  object <- tryCatch(
    builder_resolve_object(target, build),
    error = function(error) builder_error_internal(target, error, "_build_")
  )
  if (!identical(target$settings$storage, "none")) {
    target$value <- value_init(object, target$settings$iteration)
  }
  builder_update_format(target)
  invisible()
}

builder_update_format <- function(target) {
  store_reformat_auto(target)
  store_reformat_null(target)
}

builder_resolve_object <- function(target, build) {
  no_storage_expected <- !builder_expect_storage(target)
  storage_off <- identical(target$settings$storage, "none")
  if (no_storage_expected || storage_off) {
    return(build$object)
  }
  store_assert_format(target$store, build$object, target_get_name(target))
  store_convert_object(target$store, build$object)
}

builder_ensure_paths <- function(target, path_store) {
  if (builder_expect_storage(target)) {
    tryCatch(
      builder_update_paths(target, path_store),
      error = function(error) builder_error_internal(target, error, "_paths_")
    )
  }
}

builder_update_paths <- function(target, path_store) {
  name <- target_get_name(target)
  store_update_path(
    store = target$store,
    file = target$file,
    name = name,
    object = target$value$object,
    path_store = path_store
  )
  store_update_stage_late(
    store = target$store,
    file = target$file,
    name = name,
    object = target$value$object,
    path_store = path_store
  )
  store_hash_early(target$store, target$file)
}

builder_unload_value <- function(target, on_worker) {
  if (on_worker && identical(target$settings$storage, "worker")) {
    store_unload(store = target$store, target = target)
  }
}

builder_update_object <- function(target, on_worker = FALSE) {
  on.exit(builder_unload_value(target, on_worker))
  file_validate_path(target$file$path)
  if (!identical(target$settings$storage, "none")) {
    withCallingHandlers(
      store_write_object(target$store, target$file, target$value$object),
      warning = function(condition) {
        if (length(target$metrics$warnings) < 51L) {
          target$metrics$warnings <- paste(
            c(target$metrics$warnings, build_message(condition)),
            collapse = ". "
          )
        }
        warning(as_immediate_condition(condition))
        invokeRestart("muffleWarning")
      }
    )
  }
  store_hash_late(target$store, target$file)
  store_upload_object(target$store, target$file)
}

builder_expect_storage <- function(target) {
  error_null <- identical(target$settings$error, "null") &&
    metrics_has_error(target$metrics)
  !metrics_terminated_early(target$metrics) && !error_null
}

builder_ensure_object <- function(target, storage, on_worker) {
  context <- identical(target$settings$storage, storage)
  if (context && builder_expect_storage(target)) {
    tryCatch(
      builder_update_object(target, on_worker),
      error = function(error) builder_error_internal(target, error, "_store_")
    )
  }
}

builder_error_internal <- function(target, error, prefix) {
  target$metrics <- metrics_new(
    seconds = NA_real_,
    error = build_message(error, prefix),
    traceback = "No traceback available."
  )
  target
}

builder_ensure_correct_hash <- function(target) {
  if (!metrics_terminated_early(target$metrics)) {
    tryCatch(
      builder_wait_correct_hash(target),
      error = function(error) builder_error_internal(target, error, "_hash_")
    )
  }
}

builder_wait_correct_hash <- function(target) {
  storage <- target$settings$storage
  deployment <- target$settings$deployment
  store_ensure_correct_hash(target$store, target$file, storage, deployment)
}

builder_set_tar_runtime <- function(target, frames) {
  tar_runtime$target <- target
  tar_runtime$frames <- frames
}

builder_unset_tar_runtime <- function() {
  tar_runtime$target <- NULL
  tar_runtime$frames <- NULL
}

builder_marshal_value <- function(target) {
  if (identical(target$settings$storage, "main")) {
    target_marshal_value(target)
  }
}

builder_unmarshal_value <- function(target) {
  if (identical(target$settings$storage, "main")) {
    target_unmarshal_value(target)
  }
}

builder_sitrep <- function(target, meta) {
  cue <- target$cue
  missing <- cue_meta_exists(cue, target, meta)
  row <- if_any(
    missing,
    NA,
    meta$get_row(target_get_name(target))
  )
  cue_meta <- if_any(
    missing,
    TRUE,
    cue_meta(cue, target, meta, row)
  )
  list(
    name = target_get_name(target),
    meta = cue_meta,
    always = cue_always(cue, target, meta),
    never = cue_never(cue, target, meta),
    command = if_any(cue_meta, NA, cue_command(cue, target, meta, row)),
    depend = if_any(cue_meta, NA, cue_depend(cue, target, meta, row)),
    format = if_any(cue_meta, NA, cue_format(cue, target, meta, row)),
    repository = if_any(
      cue_meta,
      NA,
      cue_repository(cue, target, meta, row)
    ),
    iteration = if_any(
      cue_meta,
      NA,
      cue_iteration(cue, target, meta, row)
    ),
    file = if_any(cue_meta, NA, cue_file(cue, target, meta, row)),
    seed = if_any(cue_meta, NA, cue_seed(cue, target, meta, row))
  )
}
