local _, ADDON = ...
local L = ADDON.L

local DEFAULT_POSITION = { "TOPLEFT", nil, "TOPLEFT", 750, -4 }

MouseoverPortraiSettings = MouseoverPortraiSettings or {
    position = DEFAULT_POSITION,
}

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
    local currentCast = { UnitCastingInfo("mouseover") }  -- https://warcraft.wiki.gg/wiki/API_UnitCastingInfo
    local currentChannel = { UnitChannelInfo("mouseover") } -- https://warcraft.wiki.gg/wiki/API_UnitChannelInfo

    local OnEvent = Target_Spellbar_OnEvent or spellbar.OnEvent

    if #currentCast > 0 and currentCast[indexCastID] == lastCast[indexCastID] and currentCast[indexEndTimeMS] > lastCast[indexEndTimeMS] then
        OnEvent(spellbar, "UNIT_SPELLCAST_DELAYED", "mouseover")
    end

    if #currentChannel > 0 and currentChannel[indexChannelSpellId] == lastChannel[indexChannelSpellId] and currentChannel[indexEndTimeMS] > lastChannel[indexEndTimeMS] then
        OnEvent(spellbar, "UNIT_SPELLCAST_CHANNEL_UPDATE", "mouseover")
    end

    if #currentCast > 0 and currentCast[indexCastingSpellId] == lastCast[indexCastingSpellId] and currentCast[indexCastingNotInterruptible] ~= lastCast[indexCastingNotInterruptible] then
        if currentCast[indexCastingNotInterruptible] then
            OnEvent(spellbar, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "mouseover")
        else
            OnEvent(spellbar, "UNIT_SPELLCAST_INTERRUPTIBLE", "mouseover")
        end
    end

    if #currentChannel > 0 and currentChannel[indexChannelSpellId] == lastChannel[indexChannelSpellId] and currentChannel[indexChannelNotInterruptible] ~= lastChannel[indexChannelNotInterruptible] then
        if currentChannel[indexChannelNotInterruptible] then
            OnEvent(spellbar, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "mouseover")
        else
            OnEvent(spellbar, "UNIT_SPELLCAST_INTERRUPTIBLE", "mouseover")
        end
    end

    if #currentCast == 0 then
        if #lastCast > 0 then
            -- GetTime() isn't precise. cast might show as interrupted, although it was finished
            local delta = 1000 -- 0.1s
            if lastCast[indexEndTimeMS] - delta <= (GetTime() * 1000) then
                OnEvent(spellbar, "UNIT_SPELLCAST_STOP", "mouseover", lastCast[indexCastID])
            else
                OnEvent(spellbar, "UNIT_SPELLCAST_INTERRUPTED", "mouseover", lastCast[indexCastID])
            end
            lastCast = { }
        end
    end

    if #currentChannel == 0 then
        if #lastChannel > 0 then
            OnEvent(spellbar, "UNIT_SPELLCAST_CHANNEL_STOP", "mouseover")
            lastChannel = { }
        end
    end

    if #currentCast > 0 then
        if lastCast[indexCastID] ~= currentCast[indexCastID] then
            lastCast = currentCast
            lastChannel = { }
            OnEvent(spellbar, "UNIT_SPELLCAST_START", "mouseover")
        end
    end

    if #currentChannel > 0 then
        if #lastChannel == 0 then
            lastChannel = currentChannel
            lastCast = { }
            OnEvent(spellbar, "UNIT_SPELLCAST_CHANNEL_START", "mouseover")
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
    end

    if currentGUID then
        if self.UpdateRaidTargetIcon then
            self:UpdateRaidTargetIcon(self)
        elseif TargetFrame_UpdateRaidTargetIcon then
            TargetFrame_UpdateRaidTargetIcon(self)
        end
        if self.UpdateAuras then -- >= 10.0
            self:UpdateAuras()
        elseif TargetFrame_UpdateAuras then
            TargetFrame_UpdateAuras(self)
        end
        ClickThroughAuras(self)

        UpdateCasts(self.spellbar)
    end

    lastGUID = currentGUID
end

local function InitMouseoverFrame()
    local frame = _G["MouseoverFrame"]

    frame:HookScript("OnUpdate", OnUpdate)
    frame:SetScript("OnEnter", function() end)
    frame:SetScript("OnLeave", function() end)
    frame:SetScript("OnClick", function() end)
    frame:SetScript("OnDragStart", function() end)
    frame:SetScript("OnDragStop", function() end)
    frame:SetScript("OnShow", function() end)
    frame:SetScript("OnHide", function() end)

    frame:ClearAllPoints()
    frame:SetPoint(unpack(MouseoverPortraiSettings.position))

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
        mouseoverFrame = InitMouseoverFrame()
        moveableFrame = CreateMoveableFrame(mouseoverFrame)

        -- CVarCallbackRegistry caches an therefore transports taint into the original TargetFrame
        hooksecurefunc(CVarCallbackRegistry, "GetCVarValue", function(self, cvar)
            if cvar == "showTargetOfTarget" and not issecurevariable(self.cvarValueCache, cvar) then
                if self.ClearCache then
                    self:ClearCache(cvar)
                else -- classic
                    local data = {textures = self.cvarValueCache}
                    TextureLoadingGroupMixin.RemoveTexture(data, cvar)
                end
            end
        end)
    elseif event == "PLAYER_REGEN_DISABLED" then
        ADDON:LockFrame()
    end
end)
