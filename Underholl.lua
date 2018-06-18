local Underhollow = {}

Underhollow.Enabled = Menu.AddOption({"Utility", "UnderHollowMap"}, "{1} Enabled", "v0.1.1")
Underhollow.Map_X = Menu.AddOption({"Utility", "UnderHollowMap"}, "{2} Map X", "X screen coordinate", 0, 4000, 2)
Underhollow.Map_Y = Menu.AddOption({"Utility","UnderHollowMap"}, "{3} Map Y", "Y screen coordinate", 0, 4000, 2)
Underhollow.Map_Size = Menu.AddOption({"Utility","UnderHollowMap"}, "{4} Map Size", "Map scale", 50, 400, 5)
Underhollow.Font = Renderer.LoadFont("Tahoma", 15, Enum.FontWeight.EXTRABOLD)
Underhollow.MapFont = Renderer.LoadFont("Tahoma", 10, Enum.FontWeight.EXTRABOLD)

local map_x, map_y
local map_h, map_w
local box_size_x
local box_size_y
local dist_between_x
local dist_between_y
local x_offset, y_offset
local box_size

local screen_x, screen_y = Renderer.GetScreenSize()
local map_size_base = 174
local map_size = math.floor(screen_y * 0.226)
local scale = math.floor((map_size / map_size_base) * 100)

local map_size_x, map_size_y = 12000, 13000
local box_size_x_base = 16.4
local box_size_y_base = 12.9
local dist_between_x_base = 2.5
local dist_between_y_base = 1
local x_offset_base, y_offset_base = 12, 20
local box_size_base = 5
local font_base = 12

function Underhollow.OnMenuOptionChange(option, old, new)
	if option == Underhollow.Map_X then
		map_x = new
		Config.WriteInt("UnderHollowMap", "Map_X", new)
	elseif option == Underhollow.Map_Y then
		map_y = new
		Config.WriteInt("UnderHollowMap", "Map_Y", new)
	elseif option == Underhollow.Map_Size then
		box_size_x = box_size_x_base * (new / 100)
		box_size_y = box_size_y_base * (new / 100)
		dist_between_x = dist_between_x_base * (new / 100)
		dist_between_y = dist_between_y_base * (new / 100)
		x_offset = math.floor(x_offset_base * (new / 100))
		y_offset = math.floor(y_offset_base * (new / 100))
		map_h = math.floor(map_size_base * (new / 100))
		map_w = map_h
		box_size = math.floor(box_size_base * (new / 100))
		Config.WriteInt("UnderHollowMap", "Map_Size", new)
		Underhollow.MapFont = Renderer.LoadFont("Tahoma", math.floor(font_base * (new / 100)), Enum.FontWeight.EXTRABOLD)
	end
end

local last_attack = {}
function Underhollow.OnGameStart()
	last_attack = {}
end

function Underhollow.OnParticleUpdate(particle)
	if particle.controlPoint == 0 and particle.position then
		Underhollow.AddRomStatusDelayed(particle.position, "particle", 2)
	end
end

function Underhollow.DrawCircle(pos, radius, degree)
	local x, y, visible = Renderer.WorldToScreen(pos + Vector(0, radius, 0))
	if visible == 1 then
		for angle = 0, 360 / degree do
			local x1, y1 = Renderer.WorldToScreen(pos + Vector(0, radius, 0):Rotated(Angle(0, angle * degree, 0)))
			Renderer.DrawLine(x, y, x1, y1)
			x, y = x1, y1
		end
	end
end

local room_status = {}
function Underhollow.AddRomStatus(vec, status)
	local scaled_x = math.ceil(vec:GetX() / 2559) + 3
	local scaled_y = 7 - (math.ceil(vec:GetY() / 2058) + 3)
	if not room_status[scaled_x] then
		room_status[scaled_x] = {}
	end
	room_status[scaled_x][scaled_y] = status
end

local delayed_status = {}
function Underhollow.AddRomStatusDelayed(vec, status, show_time)
	table.insert(delayed_status, {vec = vec, status = status, show_time = show_time + GameRules.GetGameTime()})
end

function Underhollow.OnDraw()

	if not Underhollow.Init then
		Menu.SetValue(Underhollow.Map_X, Config.ReadInt("UnderHollowMap", "Map_X", math.floor(screen_x * 0.164)))
		Menu.SetValue(Underhollow.Map_Y, Config.ReadInt("UnderHollowMap", "Map_Y", math.floor(screen_y - map_size) - 1))
		Menu.SetValue(Underhollow.Map_Size, Config.ReadInt("UnderHollowMap", "Map_Size", scale))
		Underhollow.OnMenuOptionChange(Underhollow.Map_X, 0, Config.ReadInt("UnderHollowMap", "Map_X", math.floor(screen_x * 0.164)))
		Underhollow.OnMenuOptionChange(Underhollow.Map_Y, 0, Config.ReadInt("UnderHollowMap", "Map_Y", math.floor(screen_y - map_size) - 1))
		Underhollow.OnMenuOptionChange(Underhollow.Map_Size, 0, Config.ReadInt("UnderHollowMap", "Map_Size", scale))
		Underhollow.Init = true
	end

	local myHero = Heroes.GetLocal()

	if not myHero then return end

	room_status = {}
	for i, Unit in pairs(NPCs.GetAll()) do
		local name = NPC.GetUnitName(Unit)
		local UnitPos = Entity.GetAbsOrigin(Unit)
		local x, y, visible = Renderer.WorldToScreen(UnitPos)
		if Entity.IsAlive(Unit) then
			if Entity.GetMaxHealth(Unit) ~= Entity.GetHealth(Unit) then
				Renderer.SetDrawColor(255, 0, 0, 255)
			else
				Renderer.SetDrawColor(255, 255, 255, 20)
			end

			if name == "npc_dota_cavern_gate_destructible_tier1" then
				Underhollow.DrawOnMapBox(UnitPos, box_size)
			elseif name == "npc_dota_cavern_gate_destructible_tier2" then
				Underhollow.DrawOnMapBox(UnitPos, box_size)
			elseif name == "npc_dota_cavern_gate_destructible_tier3" then
				Underhollow.DrawOnMapBox(UnitPos, box_size)
			elseif name == "npc_dota_cavern_gate_blocked" then
				Underhollow.DrawOnMapFilledBox(UnitPos, box_size)
			elseif name == "npc_treasure_chest" then
				Underhollow.AddRomStatus(UnitPos, "chest")
			elseif name == "npc_treasure_chest_anim" or name == "npc_special_treasure_chest_anim" then
				Underhollow.AddRomStatus(UnitPos, "chest_anim")
			elseif name == "npc_special_treasure_chest" then
				Underhollow.AddRomStatus(UnitPos, "spec_chest")
			elseif name == "npc_dota_room_destroyed_dummy2" then
				Underhollow.AddRomStatus(UnitPos, "none")
			elseif name == "npc_dota_cavern_shop" then
				Renderer.SetDrawColor(127, 255, 255, 255)
				Underhollow.DrawOnMapFilledBox(UnitPos, box_size)
			end
		elseif UnitPos:Length2DSqr() > 0 then
			Underhollow.AddRomStatus(UnitPos, "attacking")
		end
	end

	for i, state in pairs(delayed_status) do
		if state.show_time < GameRules.GetGameTime() then
			table.remove(delayed_status, i)
		else
			Underhollow.AddRomStatus(state.vec, state.status)
		end
	end

	Renderer.SetDrawColor(255, 255, 255, 20)
	Renderer.DrawOutlineRect(map_x, map_y, map_w, map_h)
	for i = 0, 7 do
		for j = 0, 7 do
			Renderer.SetDrawColor(255, 255, 255, 20)
			local filled = false
			if room_status[j] and room_status[j][i] then
				local status = room_status[j][i]
				if status == "attacking" then
					Renderer.SetDrawColor(128, 0, 0, 100)
					filled = true
				elseif status == "particle" then
					Renderer.SetDrawColor(128, 128, 0, 100)
					filled = true
				elseif status == "chest_anim" then
					Renderer.SetDrawColor(0, 0, 128, 255)
				elseif status == "chest" then
					Renderer.SetDrawColor(255, 127, 55, 100)
					filled = true
				elseif status == "spec_chest" then
					Renderer.SetDrawColor(255, 255, 0, 100)
					filled = true
				end
			end
			if filled then
				Renderer.DrawFilledRect(math.floor(map_x + ((box_size_x + dist_between_x) * j) + x_offset), math.floor(map_y + ((box_size_y + dist_between_y) * (i + 1)) + y_offset), math.floor(box_size_x), math.floor(box_size_y))
			else
				Renderer.DrawOutlineRect(math.floor(map_x + ((box_size_x + dist_between_x) * j) + x_offset), math.floor(map_y + ((box_size_y + dist_between_y) * (i + 1)) + y_offset), math.floor(box_size_x), math.floor(box_size_y))
			end
		end
	end

	for i, Unit in pairs(NPCs.GetAll()) do
		local name = NPC.GetUnitName(Unit)
		local UnitPos = Entity.GetAbsOrigin(Unit)
		local x, y, visible = Renderer.WorldToScreen(UnitPos)
		if Entity.IsAlive(Unit) then
			if visible == 1 then
				Renderer.SetDrawColor(255, 255, 255, 255)
				if name == "npc_dota_crate" then
					Renderer.SetDrawColor(255, 180, 120, 255)
					Underhollow.DrawCircle(UnitPos, 75, 90)
				elseif name == "npc_dota_cavern_shop" then
					Renderer.SetDrawColor(127, 255, 255, 255)
					Underhollow.DrawCircle(UnitPos, 75, 90)
				elseif name == "npc_special_treasure_chest" then
					Renderer.SetDrawColor(255, 255, 0, 255)
					Underhollow.DrawCircle(UnitPos, 125, 60)
				elseif name == "npc_treasure_chest" then
					Renderer.SetDrawColor(255, 127, 55, 255)
					Underhollow.DrawCircle(UnitPos, 75, 90)
				elseif name == "npc_dota_creature_ghost" then
					Renderer.SetDrawColor(255, 255, 255, 255)
					Renderer.DrawText(Underhollow.Font, x, y, "ghost")
				elseif name == "npc_dota_minimage" then
					Renderer.SetDrawColor(255, 255, 255, 255)
					Renderer.DrawText(Underhollow.Font, x, y, "mage")
				elseif name == "npc_dota_creature_techies_land_mine" then
					Renderer.SetDrawColor(255, 0, 0, 255)
					Underhollow.DrawCircle(UnitPos, 200, 20)
				elseif name == "npc_dota_creature_armed_dynamite" then
					Renderer.SetDrawColor(255, 0, 0, 255)
					Underhollow.DrawCircle(UnitPos, 500, 20)
					local modif = NPC.GetModifier(Unit, "modifier_creature_armed_dynamite")
					if modif then
						local last_time = math.floor((4 - (GameRules.GetGameTime() - Modifier.GetCreationTime(modif))) * 100) / 100
						if last_time > 0 then
							Renderer.DrawText(Underhollow.Font, x, y, last_time)
						end
					end
				elseif name == "npc_dota_creature_dark_willow" then
					local ability = NPC.GetAbilityByIndex(Unit, 0)
					if Ability.GetCooldownTimeLeft(ability) ~= 0 then
						Renderer.SetDrawColor(255, 255, 255, 255)
						Renderer.DrawText(Underhollow.Font, x, y, math.floor(Ability.GetCooldownTimeLeft(ability)))
					end
				elseif name == "npc_dota_creature_big_viper" then
					local ability = NPC.GetAbilityByIndex(Unit, 0)
					if Ability.GetCooldownTimeLeft(ability) ~= 0 then
						Renderer.SetDrawColor(255, 255, 255, 255)
						Renderer.DrawText(Underhollow.Font, x, y, math.floor(Ability.GetCooldownTimeLeft(ability)))
					end
				elseif name == "npc_dota_creature_enigma" then
					local ability = NPC.GetAbilityByIndex(Unit, 3)
					if Ability.GetCooldownTimeLeft(ability) ~= 0 then
						Renderer.SetDrawColor(255, 255, 255, 255)
						Renderer.DrawText(Underhollow.Font, x, y, math.floor(Ability.GetCooldownTimeLeft(ability)))
					end
				elseif name == "npc_dota_ranged_creep_linear" then
					if NPC.IsAttacking(Unit) then
						last_attack[Unit] = GameRules.GetGameTime()
					end
					if last_attack[Unit] and GameRules.GetGameTime() - last_attack[Unit] < 3 then
						Renderer.SetDrawColor(255, 255, 255, 255)
						Renderer.DrawText(Underhollow.Font, x, y, math.floor(3 - (GameRules.GetGameTime() - last_attack[Unit])))
					end
				-- elseif name then
					-- Renderer.DrawText(Underhollow.Font, x, y, name)
				end
			end
		elseif UnitPos:Length2DSqr() > 0 then
			Renderer.SetDrawColor(255, 0, 0, 255)
			Underhollow.DrawOnMapText(UnitPos, "V")
		end
	end
	Renderer.SetDrawColor(255, 255, 0, 255)
	Underhollow.DrawOnMapText(Entity.GetAbsOrigin(myHero), "u")
end

function Underhollow.DrawOnMapText(pos, text)
	local x, y = pos:GetX(), pos:GetY()
	local x_scaled, y_scaled = (x / map_size_x) * (map_w / 2), (y / map_size_y) * (map_h / 2)
	Renderer.DrawTextCentered(Underhollow.MapFont, math.floor(map_x + map_w / 2 + x_scaled), math.floor(map_y + map_h / 2 - y_scaled), text, 1)
end

function Underhollow.DrawOnMapBox(pos, size)
	local half_size = math.floor(size / 2)
	local x, y = pos:GetX(), pos:GetY()
	local x_scaled, y_scaled = (x / map_size_x) * (map_w / 2), (y / map_size_y) * (map_h / 2)
	Renderer.DrawOutlineRect(math.floor(map_x + map_w / 2 + x_scaled) - half_size, math.floor(map_y + map_h / 2 - y_scaled) - half_size, size, size)
end

function Underhollow.DrawOnMapFilledBox(pos, size)
	local half_size = math.floor(size / 2)
	local x, y = pos:GetX(), pos:GetY()
	local x_scaled, y_scaled = (x / map_size_x) * (map_w / 2), (y / map_size_y) * (map_h / 2)
	Renderer.DrawFilledRect(math.floor(map_x + map_w / 2 + x_scaled) - half_size, math.floor(map_y + map_h / 2 - y_scaled) - half_size, size, size)
end

return Underhollow