local _, ADDON = ...

ADDON.L = {}
local L = ADDON.L

L["Click to drag"] = "Click to drag";
L["Mouseover Portrai: Not possible in combat"] = "Mouseover Portrai: Not possible in combat";

-- Command-Line
L["Restores default position for Mouseover Portrai"] = "Restores default position for Mouseover Portrai";
L["Hides the draggable frame to change position of Mouseover Portrai"] = "Hides the draggable frame to change position of Mouseover Portrai";
L["Shows the draggable frame to change position of Mouseover Portrai"] = "Shows the draggable frame to change position of Mouseover Portrai";

local locale = GetLocale()
if locale == "deDE" then
    --@localization(locale="deDE", format="lua_additive_table", handle-unlocalized=comment)@
elseif locale == "frFR" then
    --@localization(locale="frFR", format="lua_additive_table", handle-unlocalized=comment)@
end