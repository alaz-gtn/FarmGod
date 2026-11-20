local _, ns = ...
local L = ns.L

local ICON = "Interface\\AddOns\\FarmGod\\media\\icon"

local db
local button = CreateFrame("Button", "FarmGodMinimapButton", Minimap)
button:SetSize(31, 31)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:RegisterForDrag("LeftButton")
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
local background = button:CreateTexture(nil, "BACKGROUND")
background:SetSize(20, 20)
background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
background:SetPoint("TOPLEFT", 7, -5)
local icon = button:CreateTexture(nil, "ARTWORK")
icon:SetSize(20, 20)
icon:SetTexture(ICON)
icon:SetPoint("TOPLEFT", 7, -5)
local border = button:CreateTexture(nil, "OVERLAY")
border:SetSize(53, 53)
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetPoint("TOPLEFT")

local function Place()
	local angle = math.rad(db.angle)
	local radius = Minimap:GetWidth() / 2 + 10
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

-- Dragging moves the button around the edge of the minimap
local function FollowCursor()
	local mx, my = Minimap:GetCenter()
	local px, py = GetCursorPosition()
	local scale = Minimap:GetEffectiveScale()
	db.angle = math.deg(math.atan2(py / scale - my, px / scale - mx))
	Place()
end

button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", FollowCursor) end)
button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

-- Left: the session window; shift-left: start or pause; right: the options
button:SetScript("OnClick", function(_, mouse)
	if mouse == "RightButton" then
		if ns.ToggleOptions then ns.ToggleOptions() end
	elseif IsShiftKeyDown() then
		ns.ToggleSession()
	else
		ns.db.tracker.shown = not ns.db.tracker.shown
		ns.UpdateTracker()
	end
end)

-- The session at a glance
button:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:AddLine("FarmGod")
	local s = ns.char.current
	if s then
		local worth = ns.Appraise(s)
		local seconds = ns.Elapsed(s)
		local hour = ns.PerHour(worth.total, seconds)
		local state = ns.SessionState() == "running" and "" or "  (" .. L.STATE_PAUSED .. ")"
		GameTooltip:AddDoubleLine(L.TIP_TIME, ns.Clock(seconds) .. state, 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine(L.TIP_TOTAL, ns.Money(worth.total), 1, 1, 1, 1, 1, 1)
		if hour then GameTooltip:AddDoubleLine(L.TIP_HOUR, ns.Money(hour, true), 1, 1, 1, 1, 1, 1) end
		if ns.Kills(s) > 0 then GameTooltip:AddDoubleLine(L.TIP_KILLS, ns.Kills(s), 1, 1, 1, 1, 1, 1) end
	else
		GameTooltip:AddLine(L.NO_SESSION, 1, 1, 1)
	end
	local day = ns.Day and ns.Day()
	if day then
		local net = ns.DayNet(day)
		GameTooltip:AddDoubleLine(L.TIP_DAY, format("%s%s  (%s)", net > 0 and "+" or "", ns.Money(net), ns.Clock(ns.DayPlayed(day))),
			1, 1, 1, 1, 1, 1)
	end
	GameTooltip:AddLine(L.TIP_LEFT, 0.95, 0.76, 0.31)
	GameTooltip:AddLine(L.TIP_SHIFT, 0.95, 0.76, 0.31)
	GameTooltip:AddLine(L.TIP_RIGHT, 0.95, 0.76, 0.31)
	GameTooltip:AddLine(L.TIP_DRAG, 0.6, 0.6, 0.6)
	GameTooltip:Show()
end)
button:SetScript("OnLeave", GameTooltip_Hide)

function ns.UpdateMinimapButton()
	button:SetShown(not db.hide)
	Place()
end

local function ToggleButton()
	db.hide = not db.hide
	ns.UpdateMinimapButton()
end
ns.commands.button = ToggleButton
ns.commands.boton = ToggleButton
ns.commands["botón"] = ToggleButton

local events = CreateFrame("Frame")
ns.Listen(events, "PLAYER_LOGIN")
events:SetScript("OnEvent", function()
	db = ns.db.minimapButton
	ns.UpdateMinimapButton()
end)
