import private/types
import std/[options, tables]

proc `?`*(x: HttpHeaders, key: string): Option[string] =
  if x.hasKey(key):
    some(x[key])
  else:
    none(string)
