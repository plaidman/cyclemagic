_addon.name    = 'CycleMagic'
_addon.author  = 'Plaidman'
_addon.version = '1.0.0'
_addon.command = "cma"

require('tables')
require('strings')

local data = require('spellnames')
local elements, spells = data.elements, data.spells

local cur_index = 1

function handle_active_command(class, rank, target)
	cast_spell(cur_index, class, rank, target)
end

function cast_spell(index, class, rank, target)
	class = string.lower(class)

	-- rank handling
	if rank == nil then
		rank = 1
	elseif tonumber(rank) == nil then
		-- a non-number was given for rank, it should be the target
		target = rank
		rank = 1
	else
		rank = tonumber(rank)
	end

	-- target handling
	if target == nil then
		target = T{"storm","enspell"}:contains(class) and "<me>" or "<t>"
	end
	target = string.lower(target)

	local cur_element = elements[index]
	local cur_spell_table = spells[cur_element][class]

	if cur_spell_table == nil or rank > #cur_spell_table then
		windower.add_to_chat(206, "Invalid Spell.") return
	end

	windower.chat.input("/ma \"" .. cur_spell_table[rank] .. "\" " .. target)
end

local ele_aliases = {
	lightning = "thunder",
	blizzard = "ice",
	aero = "wind",
	stone = "earth"
}

function handle_ele_command(_class, arg)
	arg = arg or "next"
	arg = string.lower(arg)

	if ele_aliases[arg] then
		arg = ele_aliases[arg]
	end

	if arg == "next" then
		cur_index = cur_index + 1
		if cur_index > #elements then cur_index = 1 end

	elseif arg == "prev" then
		cur_index = cur_index - 1
		if cur_index == 0 then cur_index = #elements end

	elseif elements:contains(arg) then
		cur_index = spells[arg].index or 1

	else
		windower.add_to_chat(206, "Invalid element.")
		return
	end

	windower.add_to_chat(206, "Current element: " .. elements[cur_index])
end

local handlers = {
	nuke    = handle_active_command,
	nukega  = handle_active_command,
	nukera  = handle_active_command,
	ancient = handle_active_command,
	storm   = handle_active_command,
	chain   = handle_active_command,
	enspell = handle_active_command,
	helix   = handle_active_command,
	ele     = handle_ele_command,
}

windower.register_event('addon command', function (command, ...)
	local args = {...}

	if handlers[command] then
		handlers[command](command, unpack(args))
	else
		windower.add_to_chat(206, "Invalid command.")
	end
end)
