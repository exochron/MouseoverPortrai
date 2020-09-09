local ADDON_NAME = ...;

local DEFAULT_POSITION = { "TOPLEFT", _G["UIParent"], "TOPLEFT", 750, -4 };

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
};

local L = CoreFramework:GetModule("Localization", "1.1"):GetLocalization(ADDON_NAME);

local initialState = {
    settings = {
        position = DEFAULT_POSITION,
    },
};
local private = CoreFramework:GetModule("Addon", "1.0"):NewAddon(ADDON_NAME, initialState);

private.MouseoverFrame = nil;
function private:CreateMouseoverFrame()
    local frame = CreateFrame("Button", "MouseoverFrame", UIParent, "TargetFrameTemplate");
    frame:SetScript("OnUpdate", function(this) self:UpdateUI(this); end);
    frame:ClearAllPoints();
    frame:SetPoint(unpack(self.settings.position));

    frame.Show = function() frame:SetAlpha(1.0); end
    frame.Hide = function() frame:SetAlpha(0.0); end
    frame.IsShown = function() return frame:GetAlpha() > 0; end

    frame.noTextPrefix = true;
    frame.showLevel = true;
    frame.showPVP = true;
    frame.showLeader = true;
    frame.showThreat = true;
    frame.showPortrait = true;
    frame.showClassification = true;
    frame.showAuraCount = true;

    TargetFrame_OnLoad(frame, "mouseover");
    TargetFrame_CreateSpellbar(frame, "UPDATE_MOUSEOVER_UNIT");
    TargetFrame_CreateTargetofTarget(frame, "mouseovertarget");

    MouseoverFrameToT:Show();
    MouseoverFrameToT.Show = function() MouseoverFrameToT:SetAlpha(1.0); end
    MouseoverFrameToT.Hide = function()
        MouseoverFrameToT:SetAlpha(0.0);
        for i = 1, 4 do
            local debuffFrame = _G[self.MouseoverFrame:GetName() .. "ToTDebuff" .. (i)];
            if (debuffFrame) then
                debuffFrame:Hide();
            end
        end
    end
    MouseoverFrameToT.IsShown = function() return MouseoverFrameToT:GetAlpha() > 0; end

    for _, name in pairs(FRAME_NAMES) do
        self:MakeUnclickable(name);
    end

    self.MouseoverFrame = frame;
end

private.moveableFrame = nil;
function private:CreateMoveableFrame()
    frame = CreateFrame("Frame", nil, UIParent);
    frame:SetFrameLevel(self.MouseoverFrame:GetFrameLevel() + 1);
    frame:SetSize(self.MouseoverFrame:GetSize());
    frame:ClearAllPoints();
    frame:SetPoint(self.MouseoverFrame:GetPoint());
    frame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", insets = { left = 0, right = 0, top = 0, bottom = 0 } });
    frame:SetBackdropColor(0, 0, 0, .5);
    frame:SetClampedToScreen(true);
    frame:EnableMouse(true);
    frame:SetMovable(true);
    frame:RegisterForDrag("LeftButton");
    frame:Hide();

    frame.label = frame:CreateFontString(nil, "BACKGROUND");
    frame.label:SetFontObject("GameFontHighlight");
    frame.label:SetText("Mouseover Portrai\n(" .. L["Click to drag"] .. ")");
    frame.label:SetPoint("CENTER", 0, 0);
    frame:SetScript("OnDragStart", function()
        if (InCombatLockdown()) then return; end

        self.moveableFrame:StartMoving();
    end);
    frame:SetScript("OnDragStop", function()
        if (InCombatLockdown()) then return; end

        self.moveableFrame:StopMovingOrSizing();
        self:SetPosition({ self.moveableFrame:GetPoint() });
    end);

    self.moveableFrame = frame;
end

function private:MakeUnclickable(name)
    local frame = _G[name];
    if (frame) then
        local width, height = frame:GetSize();
        frame:SetHitRectInsets(width, 0, height, 0);
    end
end

private.lastCast = { };
private.lastChannel = { };
function private:UpdateUI(frame)
    local currentTime = GetTime() * 1000;
    TargetFrame_UpdateAuras(frame);
    TargetFrame_Update(frame);
    TargetFrame_UpdateRaidTargetIcon(frame);

    for i = 1, MAX_TARGET_BUFFS do
        self:MakeUnclickable(self.MouseoverFrame:GetName() .. "Buff" .. (i));
    end

    for i = 1, frame.maxDebuffs or MAX_TARGET_DEBUFFS do
        self:MakeUnclickable(self.MouseoverFrame:GetName() .. "Debuff" .. (i));
    end

    local currentCast = { UnitCastingInfo("mouseover") };
    local currentChannel = { UnitChannelInfo("mouseover") };

    if (#currentCast > 0 and currentCast[8] == self.lastCast[8] and currentCast[6] > self.lastCast[6]) then
        CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_DELAYED", "mouseover");
    end

    if (#currentChannel > 0 and currentChannel[1] == self.lastChannel[1] and currentChannel[6] > self.lastChannel[6]) then
        CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_CHANNEL_UPDATE", "mouseover");
    end

    if (#currentCast > 0 and currentCast[1] == self.lastCast[1] and currentCast[9] ~= self.lastCast[9]) then
        if (currentCast[9]) then
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_INTERRUPTIBLE", "mouseover");
        else
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "mouseover");
        end
    end

    if (#currentChannel > 0 and currentChannel[1] == self.lastChannel[1] and currentChannel[8] ~= self.lastChannel[8]) then
        if (currentChannel[8]) then
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_INTERRUPTIBLE", "mouseover");
        else
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "mouseover");
        end
    end

    if (#currentCast == 0) then
        if (#self.lastCast > 0) then
            if (self.lastCast[6] <= currentTime) then
                CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_STOP", "mouseover", _, _, self.lastCast[8]);
            else
                CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_INTERRUPTED", "mouseover", _, _, self.lastCast[8]);
            end
            self.lastCast = { };
        end
    end

    if (#currentChannel == 0) then
        if (#self.lastChannel > 0) then
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_CHANNEL_STOP", "mouseover");
            self.lastChannel = { };
        end
    end

    if (#currentCast > 0) then
        if (self.lastCast[8] ~= currentCast[8]) then
            self.lastCast = currentCast;
            self.lastChannel = { };
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_START", "mouseover");
        end
    end

    if (#currentChannel > 0) then
        if (#self.lastChannel == 0) then
            self.lastChannel = currentChannel;
            self.lastCast = { };
            CastingBarFrame_OnEvent(MouseoverFrameSpellBar, "UNIT_SPELLCAST_CHANNEL_START", "mouseover");
        end
    end
end

function private:SetPosition(position)
    if (InCombatLockdown()) then return; end

    self.settings.position = position;
    self.MouseoverFrame:ClearAllPoints();
    self.MouseoverFrame:SetPoint(unpack(self.settings.position));

    self.moveableFrame:ClearAllPoints();
    self.moveableFrame:SetPoint(unpack(self.settings.position));
end

function private:SetDefaultPosition()
    if (InCombatLockdown()) then
        print(L["Mouseover Portrai: Not possible in combat"]);
        return;
    end

    self:SetPosition(DEFAULT_POSITION);
end

function private:LockFrame()
    self.moveableFrame:Hide();
end

function private:UnlockFrame()
    if (InCombatLockdown()) then
        print(L["Mouseover Portrai: Not possible in combat"]);
        return;
    end

    self.moveableFrame:Show();
end

function private:Load()
    self:CreateMouseoverFrame();
    self:CreateMoveableFrame();

    self:AddEventHandler("PLAYER_REGEN_DISABLED", function() self:LockFrame(); end);

    self:AddSlashCommand("MOUSEOVERPORTRAI", function(...) private:OnSlashCommand(...) end, 'mouseoverportrai', 'mop');
end

function private:OnSlashCommand(command, parameter1, parameter2)
    if (command == "default") then
        self:SetDefaultPosition();
        return;
    end

    if (command == "lock") then
        self:LockFrame();
        return;
    end

    if (command == "unlock") then
        self:UnlockFrame();
        return;
    end

    print("Syntax:");
    print("/mop default - " .. L["Restores default position for Mouseover Portrai"]);
    print("/mop lock - " .. L["Hides the draggable frame to change position of Mouseover Portrai"]);
    print("/mop unlock - " .. L["Shows the draggable frame to change position of Mouseover Portrai"]);
end