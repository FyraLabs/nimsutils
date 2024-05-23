import common_imports
import_macros
import nimsutils

proc run*(cmd: string; quiet=false): tuple[output: string, exitCode: int] {.discardable.} =
  if not quiet:
    hint " $ " & cmd
  try:
    result = gorgeEx cmd
    if result.exitCode != 0:
      echo fmt"┌─ Fail to execute command: {cmd}"
      for line in result.output.splitLines:
        echo "│ "&line
      echo fmt"└─ Command returned exit code {$result.exitCode}"
      quit 1
  except CatchableError as e:
    echo fmt"Fail to execute command: {cmd}"
    raise e

proc run_quiet*(cmd: string): tuple[output: string, exitCode: int] {.discardable.} = run(cmd, true)

macro sh*(body: untyped): tuple[output: string, exitCode: int] {.discardable.} =
  body.expectKind nnkStmtList
  for stmt in body:
    echo repr stmt
