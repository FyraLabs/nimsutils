import std/[envvars, os, options, strutils, strformat, tables, cmdline, parseopt, syncio]

export envvars, os, options, strutils, strformat, tables, cmdline, parseopt, syncio

template import_macros* {.dirty.} = 
  import std/macros except debug, hint, info, warn, error, echo, `$`

import basedefs, btrfmt
export basedefs, btrfmt

# let's also assume if stdout is not available, then we are in nimscript
when defined(nimsuggest) and not defined(nimscript) or not defined(stdout):
  import system/nimscript except existsEnv # already in system
  export nimscript
