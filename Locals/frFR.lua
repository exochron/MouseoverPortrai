local _, ADDON = ...

if GetLocale() ~= "frFR" then
    return
end

local L = ADDON.L or {}

--@localization(locale="frFR", format="lua_additive_table", handle-unlocalized=comment)@