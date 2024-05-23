import std/strutils

func lpad*(s: string, max: int): string =
  s & ' '.repeat(0.max(max - s.len))

template `:<`*(s: string, max: int): string =
  s.lpad max

func rpad*(s: string, max: int): string =
  ' '.repeat(0.max(max - s.len)) & s

template `:>`*(s: string, max: int): string =
  s.rpad max
