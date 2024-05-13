import common_imports
import_macros

proc asBool*(s: string): bool =
  return not (["no", "0", "", "false", "off"].contains s.toLower)

proc parseParams*(): tuple[kws: Table[string, string], args: seq[string],
    envs: Table[string, string]] =
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

let (KWARGS*, ARGS*, CMDENVS*) = parseParams()

template suppress*(exception: typedesc[Exception], code: untyped) =
  try: code
  except exception: discard

# Ref: https://github.com/beef331/nimtrest/wiki/Code-snippets#check-if-top-level
macro isTopLevelImpl(o: typed): untyped =
  newLit o.owner.symKind == nskModule

template isTopLevel*(): bool =
  type A = distinct void
  isTopLevelImpl(A)

macro getStrOfIdent*(ident: untyped): string =
  ident.expectKind nnkIdent
  ident.toStrLit
