local _, ADDON = ...

SLASH_MOUSEOVERPORTRAI1, SLASH_MOUSEOVERPORTRAI2 = '/mouseoverportrai', '/mop'
function SlashCmdList.MOUSEOVERPORTRAI(msg, editBox)
    msg = msg:lower()

    if (msg == "default") then
        ADDON:SetDefaultPosition();
    elseif (msg == "lock") then
        ADDON:LockFrame();
    elseif (msg == "unlock") then
        ADDON:UnlockFrame();
    else
        print("Syntax:");
        print("/mop default - " .. ADDON.L["Restores default position for Mouseover Portrai"]);
        print("/mop lock - " .. ADDON.L["Hides the draggable frame to change position of Mouseover Portrai"]);
        print("/mop unlock - " .. ADDON.L["Shows the draggable frame to change position of Mouseover Portrai"]);
    end
end