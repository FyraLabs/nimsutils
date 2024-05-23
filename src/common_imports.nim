import std/[envvars, os, options, strutils, strformat, tables, cmdline, parseopt]

export envvars, os, options, strutils, strformat, tables, cmdline, parseopt

template import_macros* {.dirty.} = 
  import std/macros except debug, hint, info, warn, error, echo, `$`

import basedefs, btrfmt
export basedefs, btrfmt

when defined(nimsuggest) and not defined(nimscript):
  import system/nimscript except existsEnv # already in system
  export nimscript
