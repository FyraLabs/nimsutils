import src/nimsutils

warn "hai"
debug $KWARGS
debug $ARGS
debug $CMDENVS
note "hey you should look at me"
fatal "NYAAAAAA"

xtask hai, "nyaaao~":
  raise newException(Exception, "nya?")

echo $epochNanoNow()
