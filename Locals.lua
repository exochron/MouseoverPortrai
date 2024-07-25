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
elseif locale == "esES" then
    --@localization(locale="esES", format="lua_additive_table", handle-unlocalized=comment)@
elseif locale == "esMX" then
    --@localization(locale="esMX", format="lua_additive_table", handle-unlocalized=comment)@
elseif locale == "frFR" then
    --@localization(locale="frFR", format="lua_additive_table", handle-unlocalized=comment)@
elseif locale == "itIT" then
    --@localization(locale="itIT", format="lua_additive_table", handle-unlocalized=comment)@
elseif locale == "koKR" then
    --@localization(locale="koKR", format="lua_additive_table", handle-unlocalized=comment)@
elseif locale == "ptBR" then
    --@localization(locale="ptBR", format="lua_additive_table", handle-unlocalized=comment)@
elseif locale == "ruRU" then
    --@localization(locale="ruRU", format="lua_additive_table", handle-unlocalized=comment)@
elseif locale == "zhCN" then
    --@localization(locale="zhCN", format="lua_additive_table", handle-unlocalized=comment)@
elseif locale == "zhTW" then
    --@localization(locale="zhTW", format="lua_additive_table", handle-unlocalized=comment)@
end