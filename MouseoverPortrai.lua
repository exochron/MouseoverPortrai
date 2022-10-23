local _, ADDON = ...
local L = ADDON.L

local DEFAULT_POSITION = { "TOPLEFT", nil, "TOPLEFT", 750, -4 }

MouseoverPortraiSettings = MouseoverPortraiSettings or {
    position = DEFAULT_POSITION,
}

local isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
local mouseoverFrame, moveableFrame

local function MakeClickThrough(frame)
    if frame then
        local width, height = frame:GetSize()
        frame:SetHitRectInsets(width, 0, height, 0)
    end
end
local function MakeAllClickThrough(frame)
    MakeClickThrough(frame)
    for _, child in ipairs({ frame:GetChildren() })  do
        MakeAllClickThrough(child)
    end
end

local function ClickThroughAuras(frame)
    if frame.auraPools then -- >= 10.0
        for aura in frame.auraPools:EnumerateActive() do
            MakeClickThrough(aura)
            aura:SetScript("OnEnter", function() end)
            aura:SetScript("OnLeave", function() end)
        end
    else
        for i = 1, MAX_TARGET_BUFFS do
            local aura = _G[frame:GetName() .. "Buff" .. i]
            MakeClickThrough(aura)
            if aura then
                aura:SetScript("OnEnter", function() end)
                aura:SetScript("OnLeave", function() end)
            end
        end

        for i = 1, frame.maxDebuffs or MAX_TARGET_DEBUFFS do
            local aura = _G[frame:GetName() .. "Debuff" .. i]
            MakeClickThrough(aura)
            if aura then
                aura:SetScript("OnEnter", function() end)
                aura:SetScript("OnLeave", function() end)
            end
        end
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
local function UpdateCasts(spellbar)
    local currentCast = { UnitCastingInfo("mouseover") }  -- https://wow.gamepedia.com/API_UnitCastingInfo
    local currentChannel = { UnitChannelInfo("mouseover") } -- https://wow.gamepedia.com/API_UnitChannelInfo

    if #currentCast > 0 and currentCast[indexCastID] == lastCast[indexCastID] and currentCast[indexEndTimeMS] > lastCast[indexEndTimeMS] then
        Target_Spellbar_OnEvent(spellbar, "UNIT_SPELLCAST_DELAYED", "mouseover")
    end

    if #currentChannel > 0 and currentChannel[indexChannelSpellId] == lastChannel[indexChannelSpellId] and currentChannel[indexEndTimeMS] > lastChannel[indexEndTimeMS] then
        Target_Spellbar_OnEvent(spellbar, "UNIT_SPELLCAST_CHANNEL_UPDATE", "mouseover")
    end

    if #currentCast > 0 and currentCast[indexCastingSpellId] == lastCast[indexCastingSpellId] and currentCast[indexCastingNotInterruptible] ~= lastCast[indexCastingNotInterruptible] then
        if currentCast[indexCastingNotInterruptible] then
            Target_Spellbar_OnEvent(spellbar, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "mouseover")
        else
            Target_Spellbar_OnEvent(spellbar, "UNIT_SPELLCAST_INTERRUPTIBLE", "mouseover")
        end
    end

    if #currentChannel > 0 and currentChannel[indexChannelSpellId] == lastChannel[indexChannelSpellId] and currentChannel[indexChannelNotInterruptible] ~= lastChannel[indexChannelNotInterruptible] then
        if currentChannel[indexChannelNotInterruptible] then
            Target_Spellbar_OnEvent(spellbar, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "mouseover")
        else
            Target_Spellbar_OnEvent(spellbar, "UNIT_SPELLCAST_INTERRUPTIBLE", "mouseover")
        end
    end

    if #currentCast == 0 then
        if #lastCast > 0 then
            -- GetTime() isn't precise. cast might show as interrupted, although it was finished
            local delta = 1000 -- 0.1s
            if lastCast[indexEndTimeMS] - delta <= (GetTime() * 1000) then
                Target_Spellbar_OnEvent(spellbar, "UNIT_SPELLCAST_STOP", "mouseover", lastCast[indexCastID])
            else
                Target_Spellbar_OnEvent(spellbar, "UNIT_SPELLCAST_INTERRUPTED", "mouseover", lastCast[indexCastID])
            end
            lastCast = { }
        end
    end

    if #currentChannel == 0 then
        if #lastChannel > 0 then
            Target_Spellbar_OnEvent(spellbar, "UNIT_SPELLCAST_CHANNEL_STOP", "mouseover")
            lastChannel = { }
        end
    end

    if #currentCast > 0 then
        if lastCast[indexCastID] ~= currentCast[indexCastID] then
            lastCast = currentCast
            lastChannel = { }
            Target_Spellbar_OnEvent(spellbar, "UNIT_SPELLCAST_START", "mouseover")
        end
    end

    if #currentChannel > 0 then
        if #lastChannel == 0 then
            lastChannel = currentChannel
            lastCast = { }
            Target_Spellbar_OnEvent(spellbar, "UNIT_SPELLCAST_CHANNEL_START", "mouseover")
        end
    end
end

local lastGUID
local function OnUpdate(self)
    local currentGUID = UnitGUID("mouseover")

    if currentGUID ~= lastGUID then
        if self.Update then -- >= 10.0
            self:Update()
        elseif TargetFrame_Update then
            TargetFrame_Update(self)
        end
        if currentGUID and TargetFrame_UpdateRaidTargetIcon then
            TargetFrame_UpdateRaidTargetIcon(self)
        end
    end

    if currentGUID then
        if self.UpdateAuras then -- >= 10.0
            self:UpdateAuras()
        elseif TargetFrame_UpdateAuras then
            TargetFrame_UpdateAuras(self)
        end
        ClickThroughAuras(self)

        -- classic unit frames don't have cast bars
        if not isClassic then
            UpdateCasts(self.spellbar)
        end
    end

    lastGUID = currentGUID
end

local function CreateMouseoverFrame()
    local frame = CreateFrame("Button", "MouseoverFrame", UIParent, "TargetFrameTemplate")
    if TargetFrameMixin then -- >= 10.0
        frame = Mixin(frame, TargetFrameMixin)
    end

    frame:HookScript("OnUpdate", OnUpdate)
    frame:SetScript("OnEnter", function() end)
    frame:SetScript("OnLeave", function() end)

    frame:ClearAllPoints()
    frame:SetPoint(unpack(MouseoverPortraiSettings.position))

    -- overwrite show/hide to be usable while in combat
    frame.Show = function()
        frame:SetAlpha(1.0)
    end
    frame.Hide = function()
        frame:SetAlpha(0.0)
    end
    frame.IsShown = function()
        return frame:GetAlpha() > 0
    end

    frame.frameType = "Target" -- for TargetFrameMixin
    frame.noTextPrefix = true
    frame.showLevel = true
    frame.showPVP = true
    frame.showLeader = true
    frame.showThreat = true
    frame.showPortrait = true
    frame.showClassification = true
    frame.showAuraCount = true

    if TargetFrame_OnLoad then
        -- <10.0
        TargetFrame_OnLoad(frame, "mouseover")
        TargetFrame_CreateSpellbar(frame, "UPDATE_MOUSEOVER_UNIT")
        TargetFrame_CreateTargetofTarget(frame, "mouseovertarget")

        UnitFrameManaBar_Initialize("mouseover", _G["MouseoverFrameManaBar"], _G["MouseoverFrameTextureFrameManaBarText"], true)

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
    elseif frame.OnLoad then
        -- >= 10.0
        frame:OnLoad("mouseover");

        UnitFrameManaBar_Initialize("mouseover", frame.manabar, frame.manabar.ManaBarText, true)

        frame:CreateSpellbar("UPDATE_MOUSEOVER_UNIT");
        frame:CreateTargetofTarget("mouseovertarget");
        frame:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
        frame.threatNumericIndicator:SetScript("OnShow", function() frame:UpdateAuras() end);
        frame.threatNumericIndicator:SetScript("OnHide", function() frame:UpdateAuras() end);

        frame:HookScript("OnEvent", function(self, event, ...)
            if event == "UPDATE_MOUSEOVER_UNIT" then
                self:Update()
                self:UpdateRaidTargetIcon(self)
                self:UpdateAuras()
            end
        end)
    end

    MakeAllClickThrough(frame)

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
