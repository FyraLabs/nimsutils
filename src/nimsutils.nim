#!/usr/bin/env nim
import std/[envvars, os, options, strutils, strformat, cmdline, tables, parseopt, macros, syncio]

proc asBool*(s: string): bool =
  return not (["no", "0", "", "false", "off"].contains s.toLower)

proc parseParams*(): tuple[kws: Table[string, string], args: seq[string], envs: Table[string, string]] =
  var p = initOptParser(commandLineParams().join(" "))
  for kind, key, val in p.getopt:
    case kind
    of cmdArgument:
      let x = key.split("=", 1)
      if x.len == 1:
        result.args &= key
      else:
        result.envs[x[0]] = x[1]
    of cmdLongOption, cmdShortOption:
      result.kws[key] = val
    else: discard

let (KWARGS, ARGS, CMDENVS) = parseParams()

proc env*(key: string, default: string = ""): string =
  if key in CMDENVS:
    return CMDENVS[key]
  if existsEnv key:
    return getEnv key
  if default != "":
    return default
  # FIXME: somehow use `error()`?
  echo fmt"E: `${key}` is undefined and no default value is provided."
  echo fmt"E: Please define it by passing it as an argument (e.g. `{key}=my_value`) or as an environment variable."
  quit 1

macro `@=`*(key: untyped, value: string) =
  key.expectKind nnkIdent
  let s = key.strVal
  quote do:
    let `key` = env(`s`, `value`)

# === logging ===

type Color* = tuple[r, g, b: int]

type FullColor* = tuple[fg: Option[Color], bg: Option[Color]]

type LogLevel* = ref object of RootObj
  severity*: int
  name*: string
  namecolor*: FullColor
  textcolor*: FullColor

proc `$`*(color: FullColor): string =
  result = "\x1b["
  if color.fg.is_some and color.bg.is_none:
    let (r, g, b) = color.fg.get
    return result & fmt"38;2;{r};{g};{b}m"
  if color.fg.is_none and color.bg.is_some:
    let (r, g, b) = color.bg.get
    return result & fmt"48;2;{r};{g};{b}m"
  let (r, g, b) = color.fg.get
  let (x, y, z) = color.bg.get
  return result & fmt"38;2;{r};{g};{b};48;2;{x};{y};{z}m"

const reset_ansi = "\x1b[0m"

type LogLevels = enum
  llvTrace = 10
  llvDebug = 20
  llvHint = 30
  llvInfo = 40
  llvWarn = 50
  llvError = 60
  llvFatal = 70

proc log*(level: LogLevel, msg: string) =
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
  echo "{namecolor}{level.name}{textcolor}: {msg}{reset}".fmt

# colors determined using sonokai: https://github.com/sainnhe/sonokai
let
  logLvlTrace = LogLevel(severity: llvTrace.int, name: "trace", namecolor: (some(( 0xb3, 0x9d, 0xf3 )), none(Color)), textcolor: (some(( 0x7f, 0x84, 0x90 )), none(Color)))
  logLvlDebug = LogLevel(severity: llvDebug.int, name: "debug", namecolor: (some(( 0x7f, 0x84, 0x90 )), none(Color)), textcolor: (none(Color), none(Color)))
  logLvlHint  = LogLevel(severity: llvHint.int,  name: " hint", namecolor: (some(( 0x9e, 0xd0, 0x72 )), none(Color)), textcolor: (none(Color), none(Color)))
  logLvlInfo  = LogLevel(severity: llvInfo.int,  name: " info", namecolor: (some(( 0x76, 0xcc, 0xe0 )), none(Color)), textcolor: (some(( 0x76, 0xcc, 0xe0 )), none(Color)))
  logLvlWarn  = LogLevel(severity: llvWarn.int,  name: " warn", namecolor: (some(( 0xe7, 0xc6, 0x64 )), none(Color)), textcolor: (some(( 0xfe, 0xd7, 0x5a )), none(Color)))
  logLvlError = LogLevel(severity: llvError.int, name: "error", namecolor: (some(( 0xfc, 0x5d, 0x7c )), none(Color)), textcolor: (some(( 0xff, 0x60, 0x88 )), none(Color)))
  logLvlFatal = LogLevel(severity: llvFatal.int, name: "fatal", namecolor: (none(Color), some(( 0xff, 0x60, 0x77 ))), textcolor: (some(( 0xfc, 0x5d, 0x7c )), none(Color)))

proc trace*(msg: string) = log(logLvlTrace, msg)
proc debug*(msg: string) = log(logLvlDebug, msg)
proc hint*(msg: string) = log(logLvlHint, msg)
proc info*(msg: string) = log(logLvlInfo, msg)
proc warn*(msg: string) = log(logLvlWarn, msg)
proc error*(msg: string) = log(logLvlError, msg)
proc fatal*(msg: string) = log(logLvlFatal, msg)

# === some helper functions ===

proc run*(cmd: string) =
  echo "$ " & cmd
  try:
    let result = gorgeEx cmd
    if result.exitCode != 0:
      echo fmt"┌─ Fail to execute command: {cmd}"
      for line in result.output.splitLines:
        echo "┊ "&line
      echo fmt"└─ Command returned exit code {$result.exitCode}"
      quit 1
  except:
    echo fmt"Fail to execute command: {cmd}"
    quit 1

proc `/`*(left, right: string): string =
  assert not right.startsWith '/'
  if left.endsWith '/':
    return left & right
  return left & '/' & right

DESTDIR @= "/usr"
PKGCONFIG_CHECK @= "1"

proc pkgconfig*(id: string): bool =
  if not PKGCONFIG_CHECK.asBool: return
  let f = "pkgconfig/"&id&".pc"
  return fileExists("/usr/lib64/"&f) or fileExists("/usr/lib/"&f) or fileExists(DESTDIR/"lib64/"&f) or fileExists(DESTDIR/"lib64/"&f)
  # if not x:
  #   error "Cannot find pkgconfig for: " & id
  #   error "This package is a required build dependency."
  #   quit 1

export DESTDIR, PKGCONFIG_CHECK, KWARGS, ARGS, CMDENVS
