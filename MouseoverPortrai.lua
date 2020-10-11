local _, ADDON = ...
local L = ADDON.L

local DEFAULT_POSITION = { "TOPLEFT", nil, "TOPLEFT", 750, -4 }

MouseoverPortraiSettings = MouseoverPortraiSettings or {
    position = DEFAULT_POSITION,
}

local FRAME_NAMES = {
    "MouseoverFrame",
    "MouseoverFrameTextureFrame",
    "MouseoverFrameHealthBar",
    "MouseoverFrameManaBar",
    "MouseoverFrameBuffs",
    "MouseoverFrameDebuffs",
    "MouseoverFrameNumericalThreat",
    "MouseoverFrameSpellBar",
    "MouseoverFrameToT",
    "MouseoverFrameToTTextureFrame",
    "MouseoverFrameToTHealthBar",
    "MouseoverFrameToTManaBar",
    "MouseoverFrameToTDebuff1",
    "MouseoverFrameToTDebuff2",
    "MouseoverFrameToTDebuff3",
    "MouseoverFrameToTDebuff4",
}

local isClassic = (select(4, GetBuildInfo())) < 20000
local mouseoverFrame, moveableFrame

local function MakeClickThrough(name)
    local frame = _G[name]
    if frame then
        local width, height = frame:GetSize()
        frame:SetHitRectInsets(width, 0, height, 0)
    end
end

local function ClickThroughAuras(frame)
    for i = 1, MAX_TARGET_BUFFS do
        MakeClickThrough(frame:GetName() .. "Buff" .. i)
    end

    for i = 1, frame.maxDebuffs or MAX_TARGET_DEBUFFS do
        MakeClickThrough(frame:GetName() .. "Debuff" .. i)
    end
end

local indexEndTimeMS = 5
local indexCastID = 7
local indexCastingNotInterruptible = 8
local indexCastingSpellId = 9
local indexChannelNotInterruptible = 7
local indexChannelSpellId = 8

local lastCast = { }
local lastChannel = { }
local function UpdateCasts()
    local currentCast = { UnitCastingInfo("mouseover") }  -- https://wow.gamepedia.com/API_UnitCastingInfo
    local currentChannel = { UnitChannelInfo("mouseover") } -- https://wow.gamepedia.com/API_UnitChannelInfo

    if #currentCast > 0 and currentCast[indexCastID] == lastCast[indexCastID] and currentCast[indexEndTimeMS] > lastCast[indexEndTimeMS] then
        CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_DELAYED", "mouseover")
    end

    if #currentChannel > 0 and currentChannel[indexChannelSpellId] == lastChannel[indexChannelSpellId] and currentChannel[indexEndTimeMS] > lastChannel[indexEndTimeMS] then
        CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_CHANNEL_UPDATE", "mouseover")
    end

    if #currentCast > 0 and currentCast[indexCastingSpellId] == lastCast[indexCastingSpellId] and currentCast[indexCastingNotInterruptible] ~= lastCast[indexCastingNotInterruptible] then
        if currentCast[indexCastingNotInterruptible] then
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "mouseover")
        else
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_INTERRUPTIBLE", "mouseover")
        end
    end

    if #currentChannel > 0 and currentChannel[indexChannelSpellId] == lastChannel[indexChannelSpellId] and currentChannel[indexChannelNotInterruptible] ~= lastChannel[indexChannelNotInterruptible] then
        if currentChannel[indexChannelNotInterruptible] then
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "mouseover")
        else
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_INTERRUPTIBLE", "mouseover")
        end
    end

    if #currentCast == 0 then
        if #lastCast > 0 then
            if lastCast[indexEndTimeMS] <= (GetTime() * 1000) then
                CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_STOP", "mouseover", lastCast[indexCastID])
            else
                CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_INTERRUPTED", "mouseover", lastCast[indexCastID])
            end
            lastCast = { }
        end
    end

    if #currentChannel == 0 then
        if #lastChannel > 0 then
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_CHANNEL_STOP", "mouseover")
            lastChannel = { }
        end
    end

    if #currentCast > 0 then
        if lastCast[indexCastID] ~= currentCast[indexCastID] then
            lastCast = currentCast
            lastChannel = { }
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_START", "mouseover")
        end
    end

    if #currentChannel > 0 then
        if #lastChannel == 0 then
            lastChannel = currentChannel
            lastCast = { }
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_CHANNEL_START", "mouseover")
        end
    end
end

local lastGUID
local function OnUpdate(self, elapsed)
    local currentGUID = UnitGUID("mouseover")

    if currentGUID ~= lastGUID then
        TargetFrame_Update(self)
        if currentGUID then
            TargetFrame_UpdateRaidTargetIcon(self)
            ClickThroughAuras(self)
        end
    elseif currentGUID then
        TargetFrame_UpdateAuras(self)
        ClickThroughAuras(self)
    end

    -- classic unit frames don't have cast bars
    if currentGUID and not isClassic then
        UpdateCasts()
    end

    lastGUID = currentGUID
end

local function CreateMouseoverFrame()
    local frame = CreateFrame("Button", "MouseoverFrame", UIParent, "TargetFrameTemplate")
    frame:HookScript("OnUpdate", OnUpdate)
    frame:ClearAllPoints()
    frame:SetPoint(unpack(MouseoverPortraiSettings.position))

    frame.Show = function()
        frame:SetAlpha(1.0)
    end
    frame.Hide = function()
        frame:SetAlpha(0.0)
    end
    frame.IsShown = function()
        return frame:GetAlpha() > 0
    end

    frame.noTextPrefix = true
    frame.showLevel = true
    frame.showPVP = true
    frame.showLeader = true
    frame.showThreat = true
    frame.showPortrait = true
    frame.showClassification = true
    frame.showAuraCount = true

    TargetFrame_OnLoad(frame, "mouseover")
    TargetFrame_CreateSpellbar(frame, "UPDATE_MOUSEOVER_UNIT")
    TargetFrame_CreateTargetofTarget(frame, "mouseovertarget")

    MouseoverFrameToT:Show()
    MouseoverFrameToT.Show = function()
        MouseoverFrameToT:SetAlpha(1.0)
    end
    MouseoverFrameToT.Hide = function()
        MouseoverFrameToT:SetAlpha(0.0)
        for i = 1, 4 do
            local debuffFrame = _G[frame:GetName() .. "ToTDebuff" .. i]
            if debuffFrame then
                debuffFrame:Hide()
            end
        end
    end
    MouseoverFrameToT.IsShown = function()
        return MouseoverFrameToT:GetAlpha() > 0
    end

    for _, name in pairs(FRAME_NAMES) do
        MakeClickThrough(name)
    end

    return frame
end

local function CreateMoveableFrame(referenceFrame)
    local frame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
    frame:SetFrameLevel(referenceFrame:GetFrameLevel() + 1)
    frame:SetSize(referenceFrame:GetSize())
    frame:ClearAllPoints()
    frame:SetPoint(referenceFrame:GetPoint())
    frame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    frame:SetBackdropColor(0, 0, 0, .5)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:Hide()

    frame.label = frame:CreateFontString(nil, "BACKGROUND")
    frame.label:SetFontObject("GameFontHighlight")
    frame.label:SetText("Mouseover Portrai\n(" .. L["Click to drag"] .. ")")
    frame.label:SetPoint("CENTER", 0, 0)
    frame:SetScript("OnDragStart", function()
        if (InCombatLockdown()) then
            return
        end

        frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        if (InCombatLockdown()) then
            return
        end

        frame:StopMovingOrSizing()
        ADDON:SetPosition({ frame:GetPoint() })
    end)

    return frame
end

function ADDON:SetPosition(position)
    if (InCombatLockdown()) then
        return
    end

    MouseoverPortraiSettings.position = position
    mouseoverFrame:ClearAllPoints()
    mouseoverFrame:SetPoint(unpack(position))

    moveableFrame:ClearAllPoints()
    moveableFrame:SetPoint(unpack(position))
end

function ADDON:SetDefaultPosition()
    if (InCombatLockdown()) then
        print(L["Mouseover Portrai: Not possible in combat"])
        return
    end

    ADDON:SetPosition(DEFAULT_POSITION)
end

function ADDON:LockFrame()
    moveableFrame:Hide()
end

function ADDON:UnlockFrame()
    if (InCombatLockdown()) then
        print(L["Mouseover Portrai: Not possible in combat"])
        return
    end

    moveableFrame:Show()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        mouseoverFrame = CreateMouseoverFrame()
        moveableFrame = CreateMoveableFrame(mouseoverFrame)
    elseif event == "PLAYER_REGEN_DISABLED" then
        ADDON:LockFrame()
    end
end)
