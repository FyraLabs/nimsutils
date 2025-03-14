import src/nimsutils
# Package

version       = "0.1.0"
author        = "madonuko"
description   = "Common utils for Nimscript"
license       = "MIT"
srcDir        = "src"


# Dependencies
requires "nim >= 2.0.2"

xtask mytask, "description of mytask":
  hint "hi"
  trace "https://youtu.be/Tl62BvTYUVA"
  debug "huh?"
  note "My Notice"
  warn "My Warning"
  error "My Error"
  fatal "NYAAAAAA"
  run "echo 'Hello World'"
  run "!@#$%^ouch bad command"
