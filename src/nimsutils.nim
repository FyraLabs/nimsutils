#!/usr/bin/env nim
import common_imports
import_macros
import basedefs

proc error*(msg: string) {.raises: [].}

proc env*(key: string, default: string = ""): string {.raises: [].} =
  suppress KeyError: return CMDENVS[key]
  if existsEnv key: return getEnv key
  if default != "": return default
  error fmt"`${key}` is undefined and no default value is provided."
  error fmt"Please define it as an argument (e.g. `{key}=my_value`) or as an environment variable."
  quit 1

macro `@=`*(key: untyped, value: string) =
  key.expectKind nnkIdent
  let s = key.strVal
  quote do:
    let `key` = env(`s`, `value`)
    when isTopLevel(): export `key`

# === logging ===

type Color* = tuple[r, g, b: int]

type FullColor* = tuple[fg: Option[Color], bg: Option[Color]]

type LogLevel* = ref object of RootObj
  severity*: int
  name*: string
  namecolor*: FullColor
  textcolor*: FullColor

const reset_ansi = "\x1b[0m"

proc `$`*(color: FullColor): string =
  result = "\x1b["
  if color.fg.is_some and color.bg.is_none:
    let (r, g, b) = color.fg.get
    return result & fmt"38;2;{r};{g};{b}m"
  if color.fg.is_none and color.bg.is_some:
    let (r, g, b) = color.bg.get
    return result & fmt"48;2;{r};{g};{b}m"
  if color.fg.is_none and color.bg.is_none:
    return reset_ansi
  let (r, g, b) = color.fg.get
  let (x, y, z) = color.bg.get
  return result & fmt"38;2;{r};{g};{b};48;2;{x};{y};{z}m"

type LogLevels = enum
  llvTrace = 10
  llvDebug = 20
  llvHint = 30
  llvInfo = 40
  llvNote = 50
  llvWarn = 60
  llvError = 70
  llvFatal = 80

proc log*(level: LogLevel, msg: string) {.raises: [].} =
  DEBUG @= "0"
  VERBOSITY @= "20"
  if DEBUG.asBool and level.severity <= llvDebug.int:
    return
  try:
    if level.severity < VERBOSITY.parseInt: return
  except ValueError:
    return
  COLOR @= "1"
  let namecolor = if COLOR.asBool: $level.namecolor else: ""
  let textcolor = if COLOR.asBool: $level.textcolor else: ""
  let reset = if COLOR.asBool: reset_ansi else: ""
  let lines = msg.splitLines
  echo fmt"{namecolor}{level.name:>10}:{textcolor} {lines[0]}{reset}"
  for line in lines[1..^1]:
    echo fmt"{namecolor}        ...{textcolor} {line}{reset}"

# colors determined using sonokai: https://github.com/sainnhe/sonokai
let
  logLvlTrace* = LogLevel(severity: llvTrace.int, name: "Trace", namecolor: (some((0x7f, 0x84, 0x90)), none(Color)), textcolor: (some((0x7f, 0x84, 0x90)), none(Color)))
  logLvlDebug* = LogLevel(severity: llvDebug.int, name: "Debug", namecolor: (some((0x7f, 0x84, 0x90)), none(Color)), textcolor: (none(Color), none(Color)))
  logLvlHint* = LogLevel(severity: llvHint.int, name: "Hint", namecolor: (some((0x9e, 0xd0, 0x72)), none(Color)), textcolor: (none(Color), none(Color)))
  logLvlInfo* = LogLevel(severity: llvInfo.int, name: "Info", namecolor: (some((0x76, 0xcc, 0xe0)), none(Color)), textcolor: (some((0x76, 0xcc, 0xe0)), none(Color)))
  logLvlNote* = LogLevel(severity: llvNote.int, name: "Note", namecolor: (some((0x90, 0xe5, 0xff)), none(Color)), textcolor: (some((0x9e, 0xd0, 0x72)), none(Color)))
  logLvlWarn* = LogLevel(severity: llvWarn.int, name: "Warn", namecolor: (some((0xe7, 0xc6, 0x64)), none(Color)), textcolor: (some((0xfe, 0xd7, 0x5a)), none(Color)))
  logLvlError* = LogLevel(severity: llvError.int, name: "Error", namecolor: (some((0xfc, 0x5d, 0x7c)), none(Color)), textcolor: (some((0xff, 0x60, 0x88)), none(Color)))
  logLvlFatal* = LogLevel(severity: llvFatal.int, name: "Fatal", namecolor: (some((0xb3, 0x9d, 0xf3)), none(Color)), textcolor: (some((0xff, 0x60, 0x88)), none(Color)))

proc trace*(msg: string) = log(logLvlTrace, msg)
proc debug*(msg: string) = log(logLvlDebug, msg)
proc hint*(msg: string) = log(logLvlHint, msg)
proc info*(msg: string) = log(logLvlInfo, msg)
proc note*(msg: string) = log(logLvlNote, msg)
proc warn*(msg: string) = log(logLvlWarn, msg)
proc error*(msg: string) = log(logLvlError, msg)
proc fatal*(msg: string) = log(logLvlFatal, msg)

import exec, time, xtask

export exec, basedefs, time, xtask, common_imports
