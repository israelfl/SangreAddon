SangreAddon = LibStub("AceAddon-3.0"):NewAddon("Sangre-Loot")
--local AceAddon =

function addMapIcon()

    local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)
    if LDB then
        local PC_MinimapBtn = LDB:NewDataObject("SangreLoot", {
            type = "launcher",
			text = "SangreLoot",
            icon = "interface/icons/spell_shadow_lifedrain.blp",
            OnClick = function(_, button)
                if button == "LeftButton" then SangreAddon:createMainFrame() end
                if button == "RightButton" then SangreAddon:openConfigDialog() end
            end,
            OnTooltipShow = function(tt)
                tt:AddLine(SangreAddon.AddonNameAndVersion)
                tt:AddLine("|cffffff00Left click|r to open the BiS loot window")
                tt:AddLine("|cffffff00Right click|r to open addon configuration window")
            end,
        })
        if LDBIcon then
            LDBIcon:Register("SangreLoot", PC_MinimapBtn, SangreAddon.db.char) -- PC_MinimapPos is a SavedVariable which is set to 90 as default
        end
    end
end

function SangreAddon:OnInitialize()
    SangreAddon.AceAddonName = "Sangre-Loot"
    SangreAddon.AddonNameAndVersion = "Sangre-Loot v1.1"
    SangreAddon:initConfig()
    addMapIcon()
    SangreAddon:initSangrelists()
end
