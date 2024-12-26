local PATTERN_EXPR = "^(.-)->(.+)$"
local MU_COLOR = Color(203, 117, 145)

local tblop = {}
local WMETA = {}

local function pack(...)
	local len, tbl = select("#", ...), { ... }
	local f = {}

	function f.unpack()
		return unpack(tbl, 1, len)
	end

	return setmetatable(tbl, {
		__index = function(self, key)
			return f[key] or tbl[key]
		end,
		_call = function()
			return len, tbl
		end
	})
end

local function wrap(inp)
	local val = {}
	local m = {}

	for k, v in next, inp do
		val[tonumber(k) and v or k] = v
	end
	for k, v in next, WMETA do
		m[k] = v
	end

	return setmetatable(val, m)
end

local function p(...)
	MsgC(MU_COLOR, "[mu] ")
	print(...)
end

local function ret(inp)
	local str = "return " .. inp
	if not inp:match("\n") and isfunction(CompileString(str, "", false)) then
		return str
	end

	return inp
end

local function arrow(inp)
	local args, func = inp:match(PATTERN_EXPR)
	if args and func then
		local code = string.format("return function(%s)\n%s\nend", args, ret(func))
		local out = CompileString(code, "mu_arrow")

		local env = getfenv(1)
		if env and out then
			setfenv(out, env)
		end

		if out then
			return out()
		end
	end
end

local function iter(tbl, func)
	local res = {}
	local err = {}
	local calls = 0

	local k, v = nil, nil
	while true do
		local s, e = pcall(function()
			while true do
				k, v = next(tbl, k)
				if k == nil then break end
				calls = calls + 1

				func(res, k, v)
			end
		end)

		if k ~= nil and not s then err[k] = e end
		if k == nil then break end
	end

	if table.Count(err) == calls then
		if calls ~= 0 then
			local _, e = next(err, nil)
			p(e)
		else
			p("no results")
			return
		end
	end

	local out = wrap(res)
	getmetatable(out).errors = err
	return out
end

function WMETA:__index(key)
	if tblop[key] then
		return function(_, ...)
			return tblop[key](self, ...)
		end
	end

	return iter(self, function(res, k, v)
		local target = v[key]

		if isfunction(target) then
			res[k] = function(_, ...)
				return target(v, ...)
			end
		else
			res[k] = target
		end
	end)
end

function WMETA:__newindex(key, val)
	iter(self, function(res, k, v)
		v[key] = val
	end)
end

function WMETA:__call(...)
	local args = pack(...)
	return iter(self, function(res, k, v)
		if isfunction(v) then
			local out = pack(v(args:unpack()))
			if #out ~= 1 then
				for _, val in next, out do
					res[#res + 1] = val
				end
			else
				res[k] = out[1]
			end
		end
	end)
end

function tblop:map(inp)
	local func
	if isstring(inp) and inp:find("->") then
		func = arrow(inp)
	elseif isfunction(inp) then
		func = inp
	else
		func = function(v, k)
			return v[inp]
		end
	end

	return iter(self, function(res, k, v)
		local out = pack(func(v, k))
		if #out ~= 1 then
			for _, val in next, out do
				res[#res + 1] = val
			end
		else
			res[k] = out[1]
		end
	end)
end

function tblop:filter(inp)
	local func
	if isstring(inp) and inp:find("->") then
		func = arrow(inp)
	elseif isfunction(inp) then
		func = inp
	else
		func = function(v, k)
			local flip = inp:sub(0, 1) == "!"
			local key = flip and inp:sub(2) or inp
			local out = isfunction(v[key]) and v[key](v) or v[key] ~= nil

			if flip then
				return not out
			else
				return out
			end
		end
	end

	return iter(self, function(res, k, v)
		if func(v, k) then
			res[k] = v
		end
	end)
end

function tblop:foreach(inp)
	local func
	if isstring(inp) and inp:find("->") then
		func = arrow(inp)
	elseif isfunction(inp) then
		func = inp
	else
		func = function(v, k)
			if isfunction(v[inp]) then
				v[inp](v)
			end
		end
	end

	for k, v in next, self do
		func(v, k)
	end
end

tblop.each = tblop.foreach

function tblop:keys()
	return iter(self, function(res, k, v)
		res[k] = k
	end)
end

function tblop:first()
	for _, v in next, self do
		return v
	end
end

function tblop:errors()
	return getmetatable(self).errors or {}
end

function tblop:get()
	return table.ClearKeys(self)
end

function tblop:IsValid()
	return false
end

local mu = {}
local META = {}

function META:__call(inp)
	return wrap(inp)
end

function META:__index(key)
	if mu[key] then
		return mu[key]
	end
end

local mu_ents = {}
local EMETA = {}

function EMETA:__call()
	return wrap(ents.GetAll())
end

function EMETA:__index(key)
	if mu_ents[key] then
		return mu_ents[key]
	end
end

function mu_ents.c(inp)
	return wrap(ents.FindByClass(inp))
end

function mu_ents.n(inp)
	return wrap(ents.FindByName(inp))
end

local mu_players = {}
local PMETA = {}
function PMETA:__call()
	return wrap(player.GetAll())
end

function PMETA:__index(key)
	if mu_players[key] then
		return mu_players[key]
	end
end

function mu_players.h()
	return wrap(player.GetHumans())
end

function mu_players.b()
	return wrap(player.GetBots())
end

mu.p = setmetatable({}, PMETA)

mu.e = setmetatable({}, EMETA)

_G.mu = setmetatable({}, META)

local function strsim(str1, str2)
    if str1:Trim() == "" or str2:Trim() == "" then return false end
	if str1 == str2 or string.find(str1, str2) or string.find(str2, str1) then
		return true
	end

	return false
end
local function find_ent(inp)
    -- search "_0000" as ent index
		local iStart, iEnd = string.find(inp, "^_%d+")
		if iStart then
			local iEntIndex = tonumber(string.sub(inp, iStart + 1, iEnd))
			local ent = Entity(iEntIndex)

			if ent:IsValid() then return ent end
		end

		-- search player names
			for _, ply in player.Iterator() do
				if strsim(inp:lower(), ply:Nick():lower()) then
					return ply
				end
			end

		-- search entities
			for _, ent in ents.Iterator() do
				if strsim(inp, ent:GetClass():lower()) then
					return ent
				end

				if ent.GetName and IsSimilar(inp, ent:GetName()) then
					return ent
				end
			end
	    return NULL
end

local function mu_env(p)
    local mu = _G.mu
    if CLIENT and not p then p = LocalPlayer() end
    if not (IsValid(p) and isentity(p) and p:IsPlayer()) then return end

    local tr = p:GetEyeTrace()

    local tbl = {
			me = p,
			wep = p:GetActiveWeapon(),
			trace = tr, tr = tr,
			this = tr.Entity,
			model = tr.Entity:IsValid() and tr.Entity:GetModel() or "",
			there = tr.HitPos,
			here = p:GetPos(),
			those = mu(ents.FindInSphere(tr.HitPos, 512)),
			hooks = hook.GetTable(),
			us = mu(ents.FindInSphere(p:GetPos(), 256)):filter("e->e:IsPlayer()"),
			all = mu.p(),
            allof = mu.e.c,
		}
    if SERVER then
        tbl.these = mu(constraint.GetAllConstrainedEntities(tr.Entity))
    end

		local env = setmetatable(tbl,{
			__index = function(t, k)
				if _G[k] ~= nil then return _G[k] end

				local ent = find_ent(k)
				if ent ~= NULL then return ent end

				return nil
			end,
			__newindex = _G
		})

		return env
end

_G._mu_env = mu_env