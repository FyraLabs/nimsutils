# `{.dirty.}` is needed for nimble to actually "see" the `task` template here
# also, we cannot use strformat here, it doesn't work well in templates
template xtask*(taskname: untyped; description: string; body: untyped) {.callsite, dirty.} =
  task taskname, description:
    echo ""
    info "Running xtask "&getStrOfIdent(taskname)&": "&description
    var err = none(ref Exception)
    time_as xtask_time:
      try: body
      except Exception as e:
        error "xtask "&getStrOfIdent(taskname)&" received unhandled exception:\n" & ($e.name) & ": " & e.msg
        err = e.some
    info "xtask "&getStrOfIdent(taskname)&" finished: ⏲  "&nanoEpochToStr(xtask_time)&"s"
    echo ""
    if err.is_some:
      raise err.get
