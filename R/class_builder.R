builder_new <- function(
  command = NULL,
  settings = NULL,
  cue = NULL,
  value = NULL,
  metrics = NULL,
  store = NULL,
  subpipeline = NULL
) {
  force(command)
  force(settings)
  force(cue)
  force(value)
  force(metrics)
  force(store)
  force(subpipeline)
  enclass(environment(), c("tar_builder", "tar_target"))
}

#' @export
target_update_depend.tar_builder <- function(target, pipeline, meta) {
  depends <- meta$depends
  memory_set_object(
    depends,
    target_get_name(target),
    meta$produce_depend(target, pipeline)
  )
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
  invisible()
}

#' @export
target_read_value.tar_builder <- function(target, pipeline = NULL) {
  command <- target$command
  load_packages(packages = command$packages, library = command$library)
  object <- store_read_object(target$store)
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
  target_patternview_dispatched(target, pipeline, scheduler)
  scheduler$progress$register_dispatched(target)
  scheduler$reporter$report_dispatched(
    target = target,
    progress = scheduler$progress,
    pending = pending
  )
  builder_ensure_deps(target, pipeline, "main")
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
  cue <- target$cue
  if (cue_record_exists(cue, target, meta)) return(TRUE)
  record <- meta$get_record(target_get_name(target))
  if (cue_record(cue, target, meta, record)) return(TRUE)
  if (cue_always(cue, target, meta)) return(TRUE)
  if (cue_never(cue, target, meta)) return(FALSE)
  if (cue_command(cue, target, meta, record)) return(TRUE)
  if (cue_depend(cue, target, meta, record)) return(TRUE)
  if (cue_format(cue, target, meta, record)) return(TRUE)
  if (cue_repository(cue, target, meta, record)) return(TRUE)
  if (cue_iteration(cue, target, meta, record)) return(TRUE)
  if (cue_seed(cue, target, meta, record)) return(TRUE)
  if (cue_file(cue, target, meta, record)) return(TRUE)
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
target_run.tar_builder <- function(target, envir, path_store) {
  on.exit({
    builder_unset_tar_runtime()
    target$subpipeline <- NULL
  })
  target_gc(target)
  builder_ensure_deps(target, target$subpipeline, "worker")
  frames <- frames_produce(envir, target, target$subpipeline)
  builder_set_tar_runtime(target, frames)
  store_update_stage_early(target$store, target$settings$name, path_store)
  builder_update_build(target, frames_get_envir(frames))
  builder_ensure_paths(target, path_store)
  builder_ensure_object(target, "worker")
  builder_ensure_object(target, "none")
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
  envir <- if_any(identical(envir, "globalenv"), globalenv(), envir)
  tar_option_set(envir = envir)
  tar_runtime$store <- path_store
  tar_runtime$fun <- fun
  tar_options$import(options)
  set_envvars(envvars)
  builder_unmarshal_subpipeline(target)
  target_run(target, envir, path_store)
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
  file_repopulate(target$store$file, meta$get_record(target_get_name(target)))
  if (active) {
    builder_ensure_workspace(
      target = target,
      pipeline = pipeline,
      scheduler = scheduler,
      meta = meta
    )
  }
  if_any(
    active,
    scheduler$progress$register_skipped(target),
    scheduler$progress$assign_skipped(target)
  )
  scheduler$reporter$report_skipped(target, scheduler$progress)
}

#' @export
target_conclude.tar_builder <- function(target, pipeline, scheduler, meta) {
  on.exit(builder_unset_tar_runtime())
  builder_set_tar_runtime(target, NULL)
  target_update_queue(target, scheduler)
  builder_handle_warnings(target, scheduler)
  builder_ensure_workspace(
    target = target,
    pipeline = pipeline,
    scheduler = scheduler,
    meta = meta
  )
  builder_ensure_object(target, "main")
  builder_ensure_correct_hash(target)
  switch(
    metrics_outcome(target$metrics),
    cancel = builder_cancel(target, pipeline, scheduler, meta),
    error = builder_error(target, pipeline, scheduler, meta),
    completed = builder_completed(target, pipeline, scheduler, meta)
  )
  NextMethod()
}

builder_completed <- function(target, pipeline, scheduler, meta) {
  store_cache_path(target$store, target$store$file$path)
  target_ensure_buds(target, pipeline, scheduler)
  meta$insert_record(target_produce_record(target, pipeline, meta))
  target_patternview_meta(target, pipeline, meta)
  pipeline_register_loaded(pipeline, target_get_name(target))
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
target_sync_file_meta.tar_builder <- function(target, meta) {
  store_sync_file_meta(target$store, target, meta)
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

builder_ensure_deps <- function(target, pipeline, retrieval) {
  if (!identical(target$settings$retrieval, retrieval)) {
    return()
  }
  tryCatch(
    target_ensure_deps(target, pipeline),
    error = function(error) {
      message <- paste0(
        "could not load dependencies of target ",
        target_get_name(target),
        ". ",
        conditionMessage(error)
      )
      expr <- as.expression(as.call(list(quote(stop), message)))
      target$command$expr <- expr
      target$settings$deployment <- "main"
    }
  )
}

builder_update_subpipeline <- function(target, pipeline) {
  target$subpipeline <- pipeline_produce_subpipeline(
    pipeline,
    target_get_name(target)
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
    names(subpipeline$targets),
    ~inherits(pipeline_get_target(subpipeline, .x), "tar_pattern")
  )
  map(
    setdiff(patterns, target$settings$dimensions),
    ~target_ensure_value(pipeline_get_target(subpipeline, .x), subpipeline)
  )
}

builder_handle_warnings <- function(target, scheduler) {
  if (metrics_has_warnings(target$metrics)) {
    scheduler$progress$assign_warned(target)
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
  because_named <- any(names %in% tar_options$get_workspaces())
  has_error <- metrics_has_error(target$metrics)
  if_error <- tar_options$get_workspace_on_error() ||
    identical(target$settings$error, "workspace")
  because_error <- if_error && has_error
  because_named || because_error
}

builder_save_workspace <- function(target, pipeline, scheduler, meta) {
  workspace_save(
    workspace = workspace_init(target, pipeline),
    path_store = meta$store
  )
  scheduler$reporter$report_workspace(target)
}

builder_record_error_meta <- function(target, pipeline, meta) {
  record <- target_produce_record(target, pipeline, meta)
  meta$handle_error(record)
  meta$insert_record(record)
}

builder_update_build <- function(target, envir) {
  build <- command_produce_build(target$command, envir)
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
  if (!builder_should_save(target)) {
    return(build$object)
  }
  store_assert_format(target$store, build$object, target_get_name(target))
  store_convert_object(target$store, build$object)
}

builder_ensure_paths <- function(target, path_store) {
  if (builder_should_save(target)) {
    tryCatch(
      builder_update_paths(target, path_store),
      error = function(error) builder_error_internal(target, error, "_paths_")
    )
  }
}

builder_update_paths <- function(target, path_store) {
  name <- target_get_name(target)
  store_update_path(target$store, name, target$value$object, path_store)
  store_update_stage_late(target$store, name, target$value$object, path_store)
  store_hash_early(target$store)
}

builder_unload_value <- function(target) {
  settings <- target$settings
  clear <- identical(settings$deployment, "worker") &&
    identical(settings$storage, "worker")
  if (clear) {
    store_unload(store = target$store, target = target)
  }
}

builder_update_object <- function(target) {
  on.exit(builder_unload_value(target))
  file_validate_path(target$store$file$path)
  if (!identical(target$settings$storage, "none")) {
    store_write_object(target$store, target$value$object)
  }
  store_hash_late(target$store)
  store_upload_object(target$store)
}

builder_should_save <- function(target) {
  error_null <- identical(target$settings$error, "null") &&
    metrics_has_error(target$metrics)
  !metrics_terminated_early(target$metrics) || error_null
}

builder_ensure_object <- function(target, storage) {
  context <- identical(target$settings$storage, storage)
  if (context && builder_should_save(target)) {
    tryCatch(
      builder_update_object(target),
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
  store_ensure_correct_hash(target$store, storage, deployment)
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
  exists <- meta$exists_record(target_get_name(target))
  record <- if_any(
    exists,
    meta$get_record(target_get_name(target)),
    NA
  )
  cue_record <- if_any(
    exists,
    cue_record(cue, target, meta, record),
    TRUE
  )
  list(
    name = target_get_name(target),
    record = if_any(exists, cue_record, TRUE),
    always = cue_always(cue, target, meta),
    never = cue_never(cue, target, meta),
    command = if_any(cue_record, NA, cue_command(cue, target, meta, record)),
    depend = if_any(cue_record, NA, cue_depend(cue, target, meta, record)),
    format = if_any(cue_record, NA, cue_format(cue, target, meta, record)),
    repository = if_any(
      cue_record,
      NA,
      cue_repository(cue, target, meta, record)
    ),
    iteration = if_any(
      cue_record,
      NA,
      cue_iteration(cue, target, meta, record)
    ),
    file = if_any(cue_record, NA, cue_file(cue, target, meta, record)),
    seed = if_any(cue_record, NA, cue_seed(cue, target, meta, record))
  )
}
