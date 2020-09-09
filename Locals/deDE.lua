local ADDON_NAME, ADDON = ...

if (GetLocale() ~= "deDE") then
    return
end

local L = ADDON.L or {}

--@localization(locale="deDE", format="lua_additive_table", handle-unlocalized=comment)@