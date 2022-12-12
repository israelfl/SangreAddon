local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local db_defaults = {
    char = {
        instance_name = "",
        boss_index = 0,
        bookings = {},
        raid_players_data = {},
        constants = {
            bd = 0,
            p = 0,
            t = 0,
            t_perc = 0,
            acu = 0
        },
        loot_filter = false
    }
}

local configTable = {
    type = "group",
    args = {
        constant_bd = {
            name = "Filtro de loot",
            desc = "Activa o desactiva el filtro al lotear un boss (aún no implementado)",
            type = "toggle",
            disabled = true,
            set = function(info, val)
                SangreAddon.db.char.loot_filter = val
            end,
            get = function(info)
                return SangreAddon.db.char.loot_filter
            end
        },
        moreoptions = {
            name = "Constantes",
            type = "group",
            args = {
                constant_bd = {
                    name = "BIS Despojado",
                    desc = "Establece la constante para BIS Despojado",
                    type = "input",
                    set = function(info, val)
                        SangreAddon.db.char.constants.bd = tonumber(val)
                    end,
                    get = function(info)
                        return tostring(SangreAddon.db.char.constants.bd)
                    end
                },
                constant_p = {
                    name = "Penalizaciones",
                    desc = "Establece la constante para penalizaciones",
                    type = "input",
                    set = function(info, val)
                        SangreAddon.db.char.constants.p = tonumber(val)
                    end,
                    get = function(info)
                        return tostring(SangreAddon.db.char.constants.p)
                    end
                },
                constant_t = {
                    name = "Total",
                    desc = "Establece la constante para total",
                    type = "input",
                    set = function(info, val)
                        SangreAddon.db.char.constants.t = tonumber(val)
                    end,
                    get = function(info)
                        return tostring(SangreAddon.db.char.constants.t)
                    end
                },
                constant_t_perc = {
                    name = "Porcentaje Total",
                    desc = "Establece la constante para el porcentaje total",
                    type = "input",
                    set = function(info, val)
                        SangreAddon.db.char.constants.t_perc = tonumber(val)
                    end,
                    get = function(info)
                        return tostring(SangreAddon.db.char.constants.t_perc)
                    end
                },
                constant_acu = {
                    name = "Porcentaje Acumulado",
                    desc = "Establece la constante para el porcentaje acumulado",
                    type = "input",
                    set = function(info, val)
                        SangreAddon.db.char.constants.acu = tonumber(val)
                    end,
                    get = function(info)
                        return tostring(SangreAddon.db.char.constants.acu)
                    end
                }
            }
        }
    }
}


local function migrateAddonDB()
    if not SangreAddon.db.char["version"] then
        SangreAddon.db.char.instance_name = "Loot Naxx 25"
        SangreAddon.db.char.boss_index = 1
        SangreAddon.db.char.version = 1.1
        SangreAddon.db.char.bookings = {}
        SangreAddon.db.char.loot_filter = false
        SangreAddon.db.char.constants = {
            bd = -200,
            p = -20,
            t = 550,
            t_perc = 30,
            acu = 70
        }
    end
end

local config_shown = false
function SangreAddon:openConfigDialog()
    if config_shown then
        InterfaceOptionsFrame_Show()
    else
        InterfaceOptionsFrame_OpenToCategory(SangreAddon.AceAddonName)
        InterfaceOptionsFrame_OpenToCategory(SangreAddon.AceAddonName)
    end
    config_shown = not (config_shown)
end

function SangreAddon:initConfig()
    SangreAddon.db = LibStub("AceDB-3.0"):New("SangreAddonDB", db_defaults, true)

    migrateAddonDB()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(SangreAddon.AceAddonName, configTable)
    AceConfigDialog:AddToBlizOptions(SangreAddon.AceAddonName, SangreAddon.AceAddonName)
end
