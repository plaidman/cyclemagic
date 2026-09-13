_addon.name    = 'CycleMagic'
_addon.author  = 'Plaidman'
_addon.version = '1.0.0'
_addon.command = "cma"

require('tables')
require('strings')
local texts = require('texts')
local config = require('config')

local data = require('spellnames')
local skillchains, elements, spells = data.skillchains, data.elements, data.spells

local defaults = {
	display = {x = 150, y = 175, visible = true},
}
local settings = config.load(defaults)
local display = nil

local cur_index = 1
local temp_index = 1
local temp_reset = 0
local should_inc_temp = true
local last_skillchain = nil
local skillchain_reset = 0

function update_display()
	if display == nil then return end;

	local active = format_line("Active Element", elements[cur_index])
	local temp = temp_reset == 0 and ""
		or format_line("\nTemp Element", elements[temp_index])
	local sc = skillchain_reset == 0 and ""
		or format_line("\nSkillchain", elements[skillchains[last_skillchain].index])

	display:text("Cycle Magic\n---------\n" .. active .. temp .. sc)
end

function format_line(prefix, element)
	local colors = spells[element].colors

	return "\\cs(" .. colors[1] .. ","..colors[2] .. "," .. colors[3] .. ")"
		.. prefix .. ": " .. string.ucfirst(element) .. "\\cr"
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
		target = (class == "storm") and "<me>" or "<t>"
	end
	target = string.lower(target)

	local cur_element = elements[index]
	local cur_spell_table = spells[cur_element][class]

	if cur_spell_table == nil or rank > #cur_spell_table then
		windower.add_to_chat(206, "Invalid Spell.") return
	end

	windower.chat.input("/ma \"" .. cur_spell_table[rank] .. "\" " .. target)

	temp_reset = os.time() + 7
	if index == temp_index then
		should_inc_temp = true
	end
end

function handle_cycle_command(class, rank, target)
	local index = temp_index

	if last_skillchain then
		index = skillchains[last_skillchain].index or index
	end

	cast_spell(index, class, rank, target)
end

function handle_active_command(class, rank, target)
	cast_spell(cur_index, class, rank, target)
end

function handle_helix_command(class, rank, target)
	local index = cur_index

	if last_skillchain then
		index = skillchains[last_skillchain].index or index
	end

	cast_spell(index, class, rank, target)
end

function increment_temp_index()
	if not should_inc_temp then return end

	should_inc_temp = false
	temp_index = temp_index + 1
	-- wrap around. but ignore light and dark, hence the -2
	if temp_index > #elements-2 then temp_index = 1 end
	temp_reset = os.time() + 7
	update_display()
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

	elseif elements:contains(arg) then
		cur_index = spells[arg].index or 0

	else
		windower.add_to_chat(206, "Invalid element.")
		return
	end

	temp_index = cur_index
	update_display()
end

local handlers = {
	nuke    = handle_cycle_command,
	nukega  = handle_cycle_command,
	nukera  = handle_cycle_command,
	ancient = handle_cycle_command,
	storm   = handle_active_command,
	chain   = handle_active_command,
	helix   = handle_helix_command,
	ele     = handle_ele_command,
}

function handle_load_event()
	if not settings.display.visible then return end
	if windower.ffxi.get_player() == nil then return end

	if display == nil then
		display = texts.new()

		display:pos_x(settings.display.x)
		display:pos_y(settings.display.y)
		display:visible(settings.display.visible)
		display:bg_alpha(192)
		display:pad(5)
	end

	update_display()
end
windower.register_event('load', handle_load_event)
windower.register_event('login', handle_load_event)

windower.register_event('logout', function()
	settings.display.x = display:pos_x()
	settings.display.y = display:pos_y()
	config.save(settings, 'all')

	display:destroy()
	display = nil
end)

windower.register_event('prerender', function()
	if temp_reset > 0 and os.time() >= temp_reset then
		temp_index = cur_index
		temp_reset = 0
		update_display()
	end

	if skillchain_reset > 0 and os.time() >= skillchain_reset then
		last_skillchain = nil
		skillchain_reset = 0
		update_display()
	end
end)

windower.register_event('addon command', function (command, ...)
	local args = {...}

	if handlers[command] then
		handlers[command](command, unpack(args))
	else
		windower.add_to_chat(206, "Invalid command.")
	end
end)

windower.register_event('action', function(act)
	local player = windower.ffxi.get_player()
	if not player then return end
	if act.actor_id ~= player.id then return end

	local category = act.category
	-- Category 4: Successfully finished casting a spell
	if category ~= 4 then return end

	if should_inc_temp then
		increment_temp_index()
		should_inc_temp = false
	end
end)

windower.register_event('incoming chunk', function(id, original)
	if id ~= 0x28 then return end

	local action_packet = windower.packets.parse_action(original)

	for _, target in pairs(action_packet.targets) do
		local battle_target = windower.ffxi.get_mob_by_target("bt")

		if battle_target == nil then return end
		if target.id ~= battle_target.id then return end

		for _, action in pairs(target.actions) do
			if action.add_effect_message < 288 then return end
			if action.add_effect_message > 301 then return end

			last_skillchain = action.add_effect_message
			skillchain_reset = os.time() + 10
			update_display()
		end
	end
end)
