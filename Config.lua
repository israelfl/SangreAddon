local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local db_defaults = {
    char = {
        instance_name = "",
        boss_index = 0,
        -- class_index = 1,
        -- spec_index = 1,
        -- phase_index = 1,
        -- filter_specs = {},
        -- highlight_spec = {}
    }
}

local configTable = {
    type = "group",
    args = {
        filter_class_names = {
            name = "Filter class names",
            desc = "Removes class name separators from item tooltips",
            type = "toggle",
            set = function(info, val)
                SangreAddon.db.char.filter_class_names = val
            end,
            get = function(info)
                return SangreAddon.db.char.filter_class_names
            end
        },
        filter_specs = {
            name = "Filter specs",
            desc = "Removes unselected specs from item tooltips",
            type = "multiselect",
            values = nil,
            set = function(info, key, val)
                local ci, si = strsplit(":", key)
                ci = tonumber(ci)
                si = tonumber(si)
                local class_name = Sangre_classes[ci].name
                local spec_name = Sangre_classes[ci].specs[si]
                SangreAddon.db.char.filter_specs[class_name][spec_name] = val
            end,
            get = function(info, key)
                local ci, si = strsplit(":", key)
                ci = tonumber(ci)
                si = tonumber(si)
                local class_name = Sangre_classes[ci].name
                local spec_name = Sangre_classes[ci].specs[si]
                if (not SangreAddon.db.char.filter_specs[class_name]) then
                    SangreAddon.db.char.filter_specs[class_name] = {}
                end
                if (SangreAddon.db.char.filter_specs[class_name][spec_name] == nil) then
                    SangreAddon.db.char.filter_specs[class_name][spec_name] = true
                end
                return SangreAddon.db.char.filter_specs[class_name][spec_name]
            end
        },
        highlight_spec = {
            name = "Highlight spec",
            desc = "Highlights selected spec in item tooltips",
            type = "multiselect",
            values = nil,
            set = function(info, key, val)
                if val then
                    local ci, si = strsplit(":", key)
                    ci = tonumber(ci)
                    si = tonumber(si)
                    local class_name = Sangre_classes[ci].name
                    local spec_name = Sangre_classes[ci].specs[si]
                    SangreAddon.db.char.highlight_spec = {
                        key = key,
                        class_name = class_name,
                        spec_name = spec_name
                    }
                else
                    SangreAddon.db.char.highlight_spec = {
                    }
                end
            end,
            get = function(info, key)
                return SangreAddon.db.char.highlight_spec.key == key
            end
        }
    }
}

local function buildFilterSpecOptions()
    local filter_specs_options = {}
    for ci, class in ipairs(Sangre_classes) do
        for si, spec in ipairs(Sangre_classes[ci].specs) do
            local option_val = "|T" .. Sangre_spec_icons[class.name][spec] .. ":16|t " .. class.name .. " " .. spec
            local option_key = ci .. ":" .. si
            filter_specs_options[option_key] = option_val
        end
    end
    configTable.args.filter_specs.values = filter_specs_options
    configTable.args.highlight_spec.values = filter_specs_options
end

local function migrateAddonDB()
    if not SangreAddon.db.char["version"] then
        SangreAddon.db.char.instance_name = "Loot Naxx 25"
        SangreAddon.db.char.boss_index = 1
        SangreAddon.db.char.version = 1.1
        -- SangreAddon.db.char.highlight_spec = {}
        -- SangreAddon.db.char.filter_specs = {}
        -- SangreAddon.db.char.class_index = 1
        -- SangreAddon.db.char.spec_index = 1
        -- SangreAddon.db.char.phase_index = 1
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

    buildFilterSpecOptions()
    LibStub("AceConfig-3.0"):RegisterOptionsTable(SangreAddon.AceAddonName, configTable)
    AceConfigDialog:AddToBlizOptions(SangreAddon.AceAddonName, SangreAddon.AceAddonName)
    migrateAddonDB()
end