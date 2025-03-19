local data = file.Read("pole/rope2beam - surf_commune_too_beta5.txt", "DATA")
data = data:gsub("\r", "")

local lines = string.Explode("\n", data)

local mapdata = {
	remove = {},
	add = {},
	modify = {},
}

local BLOCK_TYPE_TO_NAME = {
	"add",
	"remove",
	"modify",
}

local function ParseBuffer(buffer, block_type)
	local block_name = BLOCK_TYPE_TO_NAME[block_type]
	local block = mapdata[block_name]

	block[#block + 1] = util.KeyValuesToTable("block\n" .. buffer, true, true)
end

local current_block = 0
local in_block = false
local in_sub_block = false
local buffer = ""
for i, line in ipairs(lines) do
	line = line:Trim()
	if string.match(line, "^;") then
		continue
	elseif string.match(line, ":$") then
		if line == "add:" then
			current_block = 1
		elseif line == "filter:" or line == "remove:" then
			current_block = 2
		elseif line == "modify:" then
			current_block = 3
		else
			if current_block == 3 then
				if line ~= "match:" and line ~= "replace:" and line ~= "delete:" and line ~= "insert:" then
					Msg("[Stripper] ")
					print("Unknown modify block found: " .. line .. " (line " .. i .. ")")
				else
					in_sub_block = true
					buffer = buffer .. line:gsub(":$", "") .. "\n"
				end
			else
				Msg("[Stripper] ")
				print("Unknown block found: " .. line .. " (line " .. i .. ")")
			end
		end
	else
		if line == "{" then
			if current_block == 0 then
				Msg("[Stripper] ")
				print("Trying to start a new block without a type (line " .. i .. ")")
			elseif current_block ~= 3 and in_block then
				Msg("[Stripper] ")
				print("Trying to start a new block in a non-modify block (line " .. i .. ")")
			else
				in_block = true
				buffer = buffer .. "{\n"
			end
		elseif line == "}" then
			if not in_block then
				Msg("[Stripper] ")
				print("Stray closing bracket on line " .. i)
			else
				buffer = buffer .. "}\n"

				if not in_sub_block then
					ParseBuffer(buffer, current_block)
					buffer = ""
					in_block = false
				end

				if current_block == 3 and in_sub_block then
					in_sub_block = false
				end
			end
		elseif line:match('^"') then
			buffer = buffer .. line .. "\n"
		else
			if #line > 0 then
				Msg("[Stripper] ")
				print("Bad line: " .. i)
			end
		end
	end
end

--PrintTable(mapdata)

for i, entry in ipairs(mapdata.add) do
	local classname
	local keyvalues = {}

	for k, v in next, entry do
		if k == "classname" then
			classname = v
		elseif k == "texture" then
			if v == "sprites/laserbeam.vmt" then
				v = "sprites/physgbeamb.vmt"
			end
			keyvalues[k] = v
		else
			keyvalues[k] = v
		end
	end

	if not classname then
		Msg("[Stripper] ")
		print("Failed to get classname for an add")
		continue
	end

	if not keyvalues.targetname then
		keyvalues.targetname = "stripper_" .. i
	end

	local ent = ents.Create(classname)
	if not IsValid(ent) then
		Msg("[Stripper] ")
		print("Failed to create a " .. classname)
		continue
	end

	for k, v in next, keyvalues do
		ent:SetKeyValue(k, v)
	end

	ent:Spawn()
end
