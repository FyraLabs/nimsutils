import common_imports
import exec

# FIXME: using the `date` command is cheating!!! ;-;


proc epochNanoNow*(): uint64 =
  # FIXME: are there faster ways to get the time?
  # FIXME: this only works on unix for obvious reasons
  # WARN: NEVER import `std/times` or `std/monotimes`
  #  ...: which doesn't work in nimscript
  let (s, _) = run_quiet "/usr/bin/date '+%s %N'"
  let x = s.splitWhitespace
  let sec = x[0].parseInt.uint64
  let nano = x[1].parseInt.uint64
  sec * uint64(1e9) + nano

proc epochSecNow*(): int =
  let (s, _) = run_quiet "/usr/bin/date '+%s'"
  s.splitWhitespace[0].parseInt

proc nanoEpochToStr*(time: uint64, precision = 3): string =
  # pray that this is precise enough (unfortunate lossy conversion)
  (time.float64*1e-9).formatFloat(format=ffDecimal, precision=precision)

template time*(action: string, code: untyped) =
  block:
    let start = epochNanoNow()
    code
    info fmt"{action}: ⏲  {nanoEpochToStr(epochNanoNow() - start)}s"

template time_as*(timevar: untyped, code: untyped) =
  ## Assign to `timevar` the time used on running the code block.
  ## `timevar` would be in nanoseconds.
  ##
  ## See also:
  ## - [nanoEpochToStr()]
  ## - [time()]
  let timevar = block:
    let start = epochNanoNow()
    code
    epochNanoNow() - start
