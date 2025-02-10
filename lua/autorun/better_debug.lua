AddCSLuaFile()

function debug.getupvalues(f)
  local i, t = 0, {}

  while true do
    i = i + 1
    local key, val = debug.getupvalue(f, i)
    if not key then break end
    t[key] = val
  end

  return t
end

function debug.Trace()
  local level = 2

  MsgN("Trace:")

  while true do
    local index = level - 1
    local indent = ("  "):rep(index)

    local info = debug.getinfo(level, "Sln")
    if not info then break end

    if info.what == "C" then
      MsgN(Format("%s%i. %s - [Native]", indent, index, info.name or "???"))
    else
      MsgN(Format("%s%i. %s - %s:%i", indent, index, info.name or "???", info.short_src or "???", info.currentline or -1))
    end

    level = level + 1
  end
end

