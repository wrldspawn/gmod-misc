-- the AddCSLuaFile call is in the module and so if the server doesn't load it, clients can't use it
-- (needed for showclips and eventually showtriggers)
require("niknaks")