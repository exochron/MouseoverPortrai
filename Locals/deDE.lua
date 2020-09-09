local ADDON_NAME = ...;

L = CoreFramework:GetModule("Localization", "1.1"):NewLocalization(ADDON_NAME, "deDE");

L["Click to drag"] = "Klicken zum Verschieben";
L["Mouseover Portrai: Not possible in combat"] = "Mouseover Portrai: Im Kampf nicht möglich";

-- Command-Line
L["Restores default position for Mouseover Portrai"] = "Stellt die Standardposition von Mouseover Portrai wieder her";
L["Hides the draggable frame to change position of Mouseover Portrai"] = "Blendet die verschiebare Frame zur Positionierung von Mouseover Portrai aus";
L["Shows the draggable frame to change position of Mouseover Portrai"] = "Zeigt die verschiebare Frame zur Positionierung von Mouseover Portrai an";