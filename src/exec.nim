import common_imports
import nimsutils
import basedefs

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
  except:
    echo fmt"Fail to execute command: {cmd}"
    quit 1

proc run_quiet*(cmd: string): tuple[output: string, exitCode: int] {.discardable.} = run(cmd, true)

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
  return fileExists("/usr/lib64/"&f) or fileExists("/usr/lib/"&f) or fileExists(
      DESTDIR/"lib64/"&f) or fileExists(DESTDIR/"lib64/"&f)
  # if not x:
  #   error "Cannot find pkgconfig for: " & id
  #   error "This package is a required build dependency."
  #   quit 1
