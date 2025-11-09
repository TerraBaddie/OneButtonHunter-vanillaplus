local GT = GetTime

OBH = {}
OBH.t = CreateFrame("GameTooltip", "OBH_T", UIParent, "GameTooltipTemplate")
OBH.f = CreateFrame("Frame", "OBH_Events", UIParent)
OBH.f:RegisterEvent("START_AUTOREPEAT_SPELL")
OBH.f:RegisterEvent("STOP_AUTOREPEAT_SPELL")
OBH.auto = false
OBH.next = nil
OBH.debug = false -- toggle with /run OBH.debug = true or false

OBH.f:SetScript("OnEvent", function(self, event)
	if OBH.auto then
		OBH.auto = false
		OBH.next = nil
	else
		OBH.next = GT() + UnitRangedDamage("player")
		OBH.auto = true
	end
end)

OBH.f:SetScript("OnUpdate", function(self, elapsed)
	if OBH.auto then
		local time = GT()
		if OBH.next < time then
			OBH.next = time + UnitRangedDamage("player")
		end
	end
end)

-- Localization
if GetLocale() == "deDE" then
	OBH.name = {
		[1] = "Schnellfeuer",
		[2] = "Schnelle Schüsse",
		[3] = "Gezielter Schuss",
		[4] = "Mehrfachschuss",
		[5] = "Automatischer Schuss",
		[6] = "Anlegen: Erhöht das Distanzangriffstempo um (%d+)%%%."
	}
else
	OBH.name = {
		[1] = "Rapid Fire",
		[2] = "Quick Shots",
		[3] = "Aimed Shot",
		[4] = "Multi-Shot",
		[5] = "Auto Shot",
		[6] = "Equip: Increases ranged attack speed by (%d+)%%%."
	}
end

-- Quiver speed bonus
OBH.Quiver = nil
function OBH:GetQuiverSpeed()
	OBH_T:SetOwner(UIParent, "ANCHOR_NONE")
	OBH_T:ClearLines()
	OBH_T:SetInventoryItem("player", 23)
	local msg = OBH_TTextLeft4:GetText()
	if msg then
		for a in string.gfind(msg, self.name[6]) do
			self.Quiver = 1 + tonumber(a) / 100
		end
	end
	OBH_T:Hide()
end

-- Snapshot talent rank
function OBH:GetSnapshotRank()
	for tab = 1, GetNumTalentTabs() do
		for i = 1, GetNumTalents(tab) do
			local name, _, _, _, rank = GetTalentInfo(tab, i)
			if name == "Snapshot" then
				return rank or 0
			end
		end
	end
	return 0
end

-- Active buff check
function OBH:Active(a)
	for i = 0, 32 do
		OBH_T:SetOwner(UIParent, "ANCHOR_NONE")
		OBH_T:ClearLines()
		OBH_T:SetPlayerBuff(GetPlayerBuff(i, "HELPFUL"))
		local buff = OBH_TTextLeft1:GetText()
		OBH_T:Hide()
		if not buff then break end
		if string.find(buff, a) then
			return true
		end
	end
	return false
end

-- Find action slot (macro or spell)
function OBH:GetActionSlot(a)
	for i = 1, 100 do
		local macroName = GetActionText(i)
		if macroName and (macroName == a or string.find(macroName, a) or string.find(a, macroName)) then
			if self.debug then
				DEFAULT_CHAT_FRAME:AddMessage("OBH: Found '"..a.."' on macro slot "..i)
			end
			return i
		end

		OBH_T:SetOwner(UIParent, "ANCHOR_NONE")
		OBH_T:ClearLines()
		OBH_T:SetAction(i)
		local ab = OBH_TTextLeft1 and OBH_TTextLeft1:GetText()
		OBH_T:Hide()

		if ab and (ab == a or string.find(ab, a) or string.find(a, ab)) then
			if self.debug then
				DEFAULT_CHAT_FRAME:AddMessage("OBH: Found '"..a.."' on action slot "..i)
			end
			return i
		end
	end

	if self.debug then
		DEFAULT_CHAT_FRAME:AddMessage("OBH: WARNING - Could not find action for '"..a.."', defaulting to slot 2")
	end
	return 2
end

-- Core runtime variables
OBH.rf = 1
OBH.qs = 1
OBH.as = 3
OBH.autoSlot = nil
OBH.asSlot = nil

-- Main rotation logic
function OBH:Run()
	if not self.autoSlot then self.autoSlot = self:GetActionSlot(self.name[5]) end
	if not self.asSlot then self.asSlot = self:GetActionSlot(self.name[3]) end

	if self.next then
		-- Buff multipliers
		self.rf = self:Active(self.name[1]) and 1.3 or 1
		self.qs = self:Active(self.name[2]) and 1.3 or 1

		-- Get Quiver (affects Auto Shot only)
		if not self.Quiver then self:GetQuiverSpeed() end

		-- Snapshot modifies Aimed Shot base cast time
		local snapshotRank = self:GetSnapshotRank() or 0
		local aimedBase = 3.0 - 0.2 * snapshotRank
		self.as = aimedBase / ((self.rf or 1) * (self.qs or 1))

		local time = GT()
		local timeUntilAuto = (self.next or 0) - time

		-- Debug output
		if self.debug then
			DEFAULT_CHAT_FRAME:AddMessage(string.format(
				"OBH Debug -> AimedBase: %.2f | Snapshot: %d | RF: %.2f | QS: %.2f | Quiver: %.2f | AS: %.3f | NextAuto: %.2f",
				aimedBase, snapshotRank, self.rf or 1, self.qs or 1, self.Quiver or 1, self.as or 0, timeUntilAuto
			))
		end

		-- Decision: safe to cast Aimed Shot?
		if timeUntilAuto > self.as and GetActionCooldown(self.asSlot) == 0 then
			CastSpellByName(self.name[3]) -- Aimed Shot
			if self.debug then
				DEFAULT_CHAT_FRAME:AddMessage(string.format(
					"OBH: Casting Aimed Shot (%.2fs before next Auto)", timeUntilAuto
				))
			end
			return
		else
			if self.debug then
				DEFAULT_CHAT_FRAME:AddMessage(string.format(
					"OBH: Skipping Aimed Shot to avoid clipping (%.2fs left, need > %.2fs)",
					timeUntilAuto, self.as
				))
			end
		end

		-- Try Multi-Shot if ready
		local multiSlot = self:GetActionSlot(self.name[4])
		if GetActionCooldown(multiSlot) == 0 then
			CastSpellByName(self.name[4])
			if self.debug then
				DEFAULT_CHAT_FRAME:AddMessage("OBH: Casting Multi-Shot")
			end
		end

	else
		-- Toggle Auto Shot on if inactive
		if not IsCurrentAction(self.autoSlot) then
			UseAction(self.autoSlot)
			if self.debug then
				DEFAULT_CHAT_FRAME:AddMessage("OBH: Starting Auto Shot")
			end
		end
	end
end

-- Slash command handler for OBH debug control
SLASH_OBH1 = "/obh"
SlashCmdList["OBH"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "on" or msg == "1" or msg == "true" then
        OBH.debug = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00OBH Debugging Enabled|r")
    elseif msg == "off" or msg == "0" or msg == "false" then
        OBH.debug = false
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000OBH Debugging Disabled|r")
    elseif msg == "help" or msg == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00OneButtonHunter Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/obh on|r  - Enable debug output")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00/obh off|r - Disable debug output")
        DEFAULT_CHAT_FRAME:AddMessage("Current state: "..(OBH.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Unknown command.|r Type |cff00ff00/obh help|r for options.")
    end
end

SLASH_OBHDEBUG1 = "/obhdebug"
SlashCmdList["OBHDEBUG"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "on" or msg == "1" or msg == "true" then
        OBH.debug = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00OBH Debugging Enabled|r")
    elseif msg == "off" or msg == "0" or msg == "false" then
        OBH.debug = false
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000OBH Debugging Disabled|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00Usage: /obhdebug on|off|r")
        DEFAULT_CHAT_FRAME:AddMessage("Current state: "..(OBH.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    end
end
