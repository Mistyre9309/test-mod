-- menu template made by Blockyyy

local menu = false

local function close_menu()
	menu = false
	selectedOption = 1
	disable_time_stop_including_mario()
end

local m = gMarioStates[0]
-- Define menu options
local menuOptions = {
	{ label = "Better Wing Cap",     id = BWC,   status = gpt(m, BWC),   description = "Improved flight" },
	{ label = "Cap Throw",           id = CT,    status = gpt(m, CT),    description = "Exchange power-ups!" },
	{ label = "Air Turn",            id = AT,    status = gpt(m, AT),    description = "Air turning" },
	{ label = "Ground Pound Dive",   id = GPD,   status = gpt(m, GPD),   description = "Dive from a ground pound" },
	{ label = "Ground Pound Extras", id = GPE,   status = gpt(m, GPE),   description = "Give your ground pound more OOOF" },
	{ label = "No Fall Damage",      id = FD,    status = gpt(m, FD),    description = "OOOF" },
	{ label = "Rolling",             id = ROLL,  status = gpt(m, ROLL),  description = "I roll" },
	{ label = "No Steep Jumps",      id = SJ,    status = gpt(m, SJ),    description = "Wah; Hoo; Woo; Hoo; *sliding*" },
	{ label = "Twirl",               id = TWIRL, status = gpt(m, TWIRL), description = "Yippee!" },
	{ label = "Wall Slide",          id = WS,    status = gpt(m, WS),    description = "Slide along walls" },
	{ label = "No Air Dive",         id = RAD,   status = gpt(m, RAD),   description = "No Air Dive" },

	{ label = "Exit", description = "Exit the menu." },
}

-- Initialize the selected option
local selectedOption = 1
local prevOption = 1 -- for hover sound effect

-- Set the scale factor for the menu
local menuScale = 2.0 -- Adjust this value as needed
local w = djui_hud_get_screen_width()
local h = djui_hud_get_screen_height()
local titleY = 150

-- Add a title for the menu
local menuTitle = "SillySettings"

-- Cursor!
local cursor = get_texture_info("texture_menu_idle_hand")

local function drawMenu()
	enable_time_stop_including_mario()

	djui_hud_set_color(0, 0, 0, 200)
	djui_hud_render_rect(0, 0, w, h)

	-- Set text color and position for the title
	djui_hud_set_color(255, 255, 255, 255)
	djui_hud_set_font(FONT_HUD)
	local titleX = (w - djui_hud_measure_text(menuTitle) * menuScale * 2.5) / 2

	-- Draw the title
	djui_hud_print_text(menuTitle, titleX, titleY, menuScale * 2.5)
	djui_hud_set_font(FONT_NORMAL)

	-- Set text color and position for the menu options
	local textY = titleY + h/10
	local textSpacing = 30 * menuScale
	local rectPadding = 5 * menuScale

	for i, option in ipairs(menuOptions) do
		local textWidth = djui_hud_measure_text(option.label)
		local textX = (w - textWidth * menuScale) / 2

		if i == selectedOption then
			-- Draw black rectangle behind the selected option
			-- Draw the description with a smaller scale
			local descX = (w - djui_hud_measure_text(option.description) * (menuScale - 0.5)) / 2
			local descY = textY + (#menuOptions+1) * textSpacing
			djui_hud_set_color(255, 255, 255, 255)
			djui_hud_set_font(FONT_NORMAL)
			djui_hud_print_text(option.description, descX, descY, menuScale - 0.5)
			local optionWidth = textWidth * menuScale + rectPadding * 2
			local optionHeight = 16 * menuScale + rectPadding * 2
			djui_hud_set_color(0, 255, 255, 150)
			djui_hud_render_rect(textX - rectPadding, textY + (i - 1) * textSpacing, optionWidth, optionHeight + 5)
		end

		-- Set text color based on the status
		if option.status == nil then
			djui_hud_set_color(255, 255, 255, 255) -- White for "OK"
		elseif option.status then
			djui_hud_set_color(0, 255, 0, 255) -- Green for "On"
		else
			djui_hud_set_color(255, 0, 0, 255) -- Red for "Off"
		end

		-- Draw the menu option with scale
		djui_hud_print_text(option.label, textX, textY + (i - 1) * textSpacing, menuScale)
	end
end

local cooldown = 5
local cooldownCounter = 0

local function updateMenu()
	local stickY = m.controller.stickY
	local mouseX = djui_hud_get_mouse_x()
	local mouseY = djui_hud_get_mouse_y()

	djui_hud_render_texture(cursor, mouseX - 8, mouseY - 8, 2, 2)

	local gp = m.marioObj.header.gfx.cameraToObject
	if cooldownCounter > 0 then
		cooldownCounter = cooldownCounter - 1
	else
		if stickY > 0.5 then
			-- Move selection down
			selectedOption = selectedOption - 1
			cooldownCounter = cooldown
		elseif stickY < -0.5 then
			-- Move selection up
			selectedOption = selectedOption + 1
			cooldownCounter = cooldown
		elseif m.controller.buttonPressed & START_BUTTON ~= 0 then
            close_menu()
        end
	end
	if m.controller.buttonPressed & (A_BUTTON|B_BUTTON) ~= 0 then
		stop_sound(SOUND_MENU_CHANGE_SELECT, gp)
		play_sound(SOUND_MENU_CLICK_FILE_SELECT, gp)
		local option = menuOptions[selectedOption]
		-- Execute the selected menu option
		if option.id then
			flick(option.id)
			option.status = gpt(m, option.id)
		else close_menu() end
	end

	for i, option in ipairs(menuOptions) do
		local textWidth = djui_hud_measure_text(option.label)
		local textX = (w - textWidth * menuScale) / 2
		local textY = titleY + h/10 + (i - 1) * (30 * menuScale)
		local optionWidth = (textWidth + 10) * menuScale
		local optionHeight = (16 + 10) * menuScale

		-- Check if the mouse is within the bounds of the option
		if mouseX >= textX and mouseX <= textX + optionWidth and mouseY >= textY and mouseY <= textY + optionHeight then
			selectedOption = i
		end
	end

	if selectedOption < 1 then
		selectedOption = #menuOptions
	elseif selectedOption > #menuOptions then
		selectedOption = 1
	end

	if prevOption ~= selectedOption then
		play_sound(SOUND_MENU_CHANGE_SELECT, gp)
		prevOption = selectedOption
	end

	if is_game_paused() then
		close_menu()
	end
end

-- Main loop
local function hud_render()
	if not menu then return end
	djui_hud_set_resolution(RESOLUTION_DJUI)

	w = djui_hud_get_screen_width()
	h = djui_hud_get_screen_height()
	titleY = h/10
	menuScale = h/600
	drawMenu()
	updateMenu()
end

local function menu_command()
	menu = true
	return true
end

hook_chat_command("sillymoves", "to configure the moveset", menu_command)
hook_event(HOOK_ON_HUD_RENDER, hud_render)