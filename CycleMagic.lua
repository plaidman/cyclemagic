_addon.name    = 'CycleMagic'
_addon.author  = 'Plaidman'
_addon.version = '1.0.0'
_addon.command = "cma"

require('tables')
require('strings')
local packets = require('packets')

local ele_indices = T{fire=1,wind=2,thunder=3,earth=4,ice=5,water=6,light=7,dark=8}
local elements = T{"fire","wind","thunder","earth","ice","water","light","dark"}

spells = {
	fire = {
		nuke = {"Fire","Fire II","Fire III","Fire IV","Fire V","Fire VI"},
		nukega = {"Firaga","Firaga II","Firaga III","Firaja"},
		nukera = {"Fira","Fira II","Fira III"},
		ancient = {"Flare","Flare II"},
		helix = {"Pyrohelix","Pyrohelix II"},
		storm = {"Firestorm","Firestorm II"},
		chain = {"Stone","Fire"},
	},
	wind = {
		nuke = {"Aero","Aero II","Aero III","Aero IV","Aero V","Aero VI"},
		nukega = {"Aeroga","Aeroga II","Aeroga III","Aeroja"},
		nukera = {"Aerora","Aerora II","Aerora III"},
		ancient = {"Tornado","Tornado II"},
		helix = {"Anemohelix","Anemohelix II"},
		storm = {"Windstorm","Windstorm II"},
		chain = {"Stone","Aero"},
	},
	thunder = {
		nuke = {"Thunder","Thunder II","Thunder III","Thunder IV","Thunder V","Thunder VI"},
		nukega = {"Thundaga","Thundaga II","Thundaga III","Thundaja"},
		nukera = {"Thundara","Thundara II","Thundara III"},
		ancient = {"Burst","Burst II"},
		helix = {"Ionohelix","Ionohelix II"},
		storm = {"Thunderstorm","Thunderstorm II"},
		chain = {"Water","Thunder"},
	},
	ice = {
		nuke = {"Blizzard","Blizzard II","Blizzard III","Blizzard IV","Blizzard V","Blizzard VI"},
		nukega = {"Blizzaga","Blizzaga II","Blizzaga III","Blizzaja"},
		nukera = {"Blizzara","Blizzara II","Blizzara III"},
		ancient = {"Freeze","Freeze II"},
		helix = {"Cryohelix","Cryohelix II"},
		storm = {"Hailstorm","Hailstorm II"},
		chain = {"Water","Blizzard"},
	},
	earth = {
		nuke = {"Stone","Stone II","Stone III","Stone IV","Stone V","Stone VI"},
		nukega = {"Stonega","Stonega II","Stonega III","Stoneja"},
		nukera = {"Stonera","Stonera II","Stonera III"},
		ancient = {"Quake","Quake II"},
		helix = {"Geohelix","Geohelix II"},
		storm = {"Sandstorm","Sandstorm II"},
		chain = {"Fire","Stone"},
	},
	water = {
		nuke = {"Water","Water II","Water III","Water IV","Water V","Water VI"},
		nukega = {"Waterga","Waterga II","Waterga III","Waterja"},
		nukera = {"Watera","Watera II","Watera III"},
		ancient = {"Flood","Flood II"},
		helix = {"Hydrohelix","Hydrohelix II"},
		storm = {"Rainstorm","Rainstorm II"},
		chain = {"Stone","Water"},
	},
	light = {
		nuke = {"Fire","Fire II","Fire III","Fire IV","Fire V","Fire VI"},
		nukega = {"Firaga","Firaga II","Firaga III","Firaja"},
		nukera = {"Fira","Fira II","Fira III"},
		ancient = {"Flare","Flare II"},
		helix = {"Luminohelix","Luminohelix II"},
		storm = {"Aurorastorm","Aurorastorm II"},
		chain = {"Fire","Thunder"},
	},
	dark = {
		nuke = {"Stone","Stone II","Stone III","Stone IV","Stone V","Stone VI"},
		nukega = {"Stonega","Stonega II","Stonega III","Stoneja"},
		nukera = {"Stonera","Stonera II","Stonera III"},
		ancient = {"Quake","Quake II"},
		helix = {"Noctohelix","Noctohelix II"},
		storm = {"Umbrastorm","Umbrastorm II"},
		chain = {"Aero","Noctohelix"},
	},
}

local cur_index = 1
local temp_index = 1
local temp_reset = 0

function cast_spell(index, class, rank, target)
	class = string.lower(class)

	if rank == nil then
		rank = 1

	elseif tonumber(rank) == nil then
		-- a non-number was given for rank, it should be the target
		target = rank
		rank = 1

	else
		rank = tonumber(rank)
	end

	if target == nil then
		target = (class == "storm") and "<me>" or "<t>"
	end
	target = string.lower(target)

	local cur_element = elements[index]
	local cur_spell_table = spells[cur_element][class]

	if cur_spell_table == nil or rank > #cur_spell_table then
		windower.add_to_chat(206, "Invalid Spell.") return
	end

	windower.chat.input("/ma \""..cur_spell_table[rank].."\" "..target)
end

function handle_cnuke_command(class, rank, target)
	-- remove 'c' prefix from type
	class = string.sub(class, 2)
	cast_spell(temp_index, class, rank, target)

	-- tried to cast a c-nuke, extend temp reset timer
	temp_reset = os.time() + 7
end

function handle_nuke_command(class, rank, target)
	cast_spell(cur_index, class, rank, target)

	temp_reset = os.time() + 7
	if (temp_index == cur_index) then
		-- increment temp so we don't cast the same element with a c-spell
		increment_temp_index()
	end
end

function increment_temp_index()
	temp_index = temp_index + 1
	if temp_index > #elements-2 then temp_index = 1 end
	temp_reset = os.time() + 7
	windower.add_to_chat(206, "Temp Element is now: "..string.ucfirst(elements[temp_index]))
end

function handle_ele_command(_class, arg)
	arg = arg or "next"
	arg = string.lower(arg)

	if arg == "next" then
		cur_index = cur_index + 1
		if cur_index > #elements then cur_index = 1 end

	elseif arg == "prev" then
		cur_index = cur_index - 1
		if cur_index == 0 then cur_index = #elements end

	elseif arg == "show" then
		-- fall down to the show command

	elseif arg == "temp" then
		increment_temp_index()
		return;

	elseif elements:contains(arg) then
		cur_index = ele_indices[arg] or 0

	else
		windower.add_to_chat(206, "Invalid element.")
		return
	end

	temp_index = cur_index
	windower.add_to_chat(206, "Active Element is now: "..string.ucfirst(elements[cur_index]))
end

handlers = {
	nuke = handle_nuke_command,
	nukega = handle_nuke_command,
	nukera = handle_nuke_command,
	ancient = handle_nuke_command,
	helix = handle_nuke_command,
	storm = handle_nuke_command,
	chain = handle_nuke_command,

	cnuke = handle_cnuke_command,
	cnukega = handle_cnuke_command,
	cnukera = handle_cnuke_command,
	cancient = handle_cnuke_command,

	ele = handle_ele_command,
}

windower.register_event('addon command', function (command, ...)
	local args = {...}

	if handlers[command] then
		handlers[command](command, unpack(args))
	else
		windower.add_to_chat(206, "Invalid command.")
	end
end)

windower.register_event('prerender', function()
	if (temp_reset == 0) then return end
	if (os.time() < temp_reset) then return end

	temp_index = cur_index
	temp_reset = 0
	windower.add_to_chat(206, "Temp Element has been reset: "..string.ucfirst(elements[cur_index]))
end)
