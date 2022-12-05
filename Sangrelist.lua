local AceGUI = LibStub("AceGUI-3.0")

local ITEM_COLORS = {}

local instance_name = nil
local boss_index = nil
local db_data = {}
local raid_players_data = {}
local instance_options = {}
local boss_options = {}
local c_players_booking = {}
local importing_systems = false

local boss_frame = nil
local players_frame = nil
local bookings_frame = nil
local selected_item_frame = nil
local assign_item_frame = nil
local main_frame = nil
local import_frame = nil
local system_frame = nil
local system_header_config = {
    {
        ["key"] = "a",
        ["title"] = "Asist.\nPuntualidad",
        ["width"] = 80,
        ["enabled"] = false
    },
    {
        ["key"] = "e",
        ["title"] = "Encantamientos",
        ["width"] = 100,
        ["enabled"] = false
    },
    {
        ["key"] = "g",
        ["title"] = "Gemas",
        ["width"] = 50,
        ["enabled"] = false
    },
    {
        ["key"] = "r",
        ["title"] = "Reparación",
        ["width"] = 75,
        ["enabled"] = false
    },
    {
        ["key"] = "c",
        ["title"] = "Cons.\nExigidos",
        ["width"] = 60,
        ["enabled"] = false
    },
    {
        ["key"] = "bc",
        ["title"] = "Bonus\nConstancia",
        ["width"] = 80,
        ["enabled"] = false
    },
    {
        ["key"] = "cv",
        ["title"] = "Cons.\nVoluntarios",
        ["width"] = 80,
        ["enabled"] = false
    },
    {
        ["key"] = "bd",
        ["title"] = "BIS Despojado",
        ["width"] = 90,
        ["enabled"] = true
    },
    {
        ["key"] = "p",
        ["title"] = "Penalizaciones",
        ["width"] = 90,
        ["enabled"] = false
    },
    {
        ["key"] = "t",
        ["title"] = "Total",
        ["width"] = 100,
        ["enabled"] = true
    },
    {
        ["key"] = "acu",
        ["title"] = "Acumulado",
        ["width"] = 100,
        ["enabled"] = true
    },
    {
        ["key"] = "rt",
        ["title"] = "Real Time",
        ["width"] = 100,
        ["enabled"] = true
    },
}
local items = {}
local allowed_instances = { 533, 603, 615, 616, 624, 631, 649, 724 }

local function recalculatePlayer(player)
    local t = (raid_players_data[player]["a"] + raid_players_data[player]["e"] + raid_players_data[player]["g"] + raid_players_data[player]["r"] + raid_players_data[player]["c"] + raid_players_data[player]["bc"] + raid_players_data[player]["cv"]) / 550 * 100 + raid_players_data[player]["bd"] * (-200)
    local t_truncate = math.floor((t * 100) + 0.5) / 100
    raid_players_data[player]["t"] = t_truncate
    SangreAddon.db.char.raid_players_data[player]["t"] = t_truncate

    local rt = raid_players_data[player]["t"] * 0.3 + raid_players_data[player]["acu"] * 0.7 + raid_players_data[player]["p"] * (-0.2)
    local rt_truncate = math.floor((rt * 100) + 0.5) / 100
    raid_players_data[player]["rt"] = rt_truncate
    SangreAddon.db.char.raid_players_data[player]["rt"] = rt_truncate
end

local function updatePlayersBookings(player, item_id, action)
    if action == "add" then
        if c_players_booking[player] == nil then c_players_booking[player] = {} end
        tinsert(c_players_booking[player], item_id)
        SangreAddon.db.char.raid_players_data[player]["bd"] = SangreAddon.db.char.raid_players_data[player]["bd"] + 1
        raid_players_data = SangreAddon.db.char.raid_players_data
        assign_item_frame:ReleaseChildren()
        local doneLabel = AceGUI:Create("Label")
        doneLabel:SetFont("Fonts\\FRIZQT__.TTF", 14)
        doneLabel:SetColor(0.5, 1, 0.5)
        doneLabel:SetText("\"" .. items[item_id]:GetItemName() .. "\" correctamente asignado a " .. string.upper(player))
        assign_item_frame:AddChild(doneLabel)
        recalculatePlayer(player)
        local current_date = date("%d/%m/%Y")
        for k, v in ipairs(db_data[tostring(item_id)]["bookings"][1]) do
            if (v == player) then
                print(item_id, v, player, k, current_date)
                SangreAddon.db.char.bookings[tostring(item_id)]["bookings"][2][k] = current_date
            end
        end

        db_data = SangreAddon.db.char.bookings
        players_frame:ReleaseChildren()
        SangreAddon:updateBookingsList(item_id)
    end
end

local function buildInstanceDict()
    for int_index, _ in pairs(Sangre_instances) do
        instance_options[int_index] = int_index
    end
end

local function buildBossDict(instanceId)
    boss_options = {}
    for _, boss_data in ipairs(Sangre_instances[instanceId]["bosses"]) do
        table.insert(boss_options, boss_data.name)
    end
end

local function loadData()
    instance_name = SangreAddon.db.char.instance_name
    boss_index = SangreAddon.db.char.boss_index
    db_data = SangreAddon.db.char.bookings
    raid_players_data = SangreAddon.db.char.raid_players_data
    if instance_name then
        buildBossDict(instance_name)
    end
end

local function saveData()
    SangreAddon.db.char.instance_name = instance_name
    SangreAddon.db.char.boss_index = boss_index
    SangreAddon.db.char.bookings = db_data
    SangreAddon.db.char.raid_players_data = raid_players_data
end

local function createItemNameFrame(item_id)
    if item_id < 0 then
        local empty_label = AceGUI:Create("Label")
        return empty_label
    end
    --GetItemQualityColor
    local item_name = AceGUI:Create("Label")

    item_name:SetFont("Fonts\\FRIZQT__.TTF", 13)
    item_name:SetText(ITEM_COLORS[items[item_id]:GetItemQuality() or 0] .. items[item_id]:GetItemName())

    return item_name
end

local function createItemFrame(item_id, size)
    if item_id < 0 then
        local empty_label = AceGUI:Create("Label")
        return empty_label
    end

    local item_frame = AceGUI:Create("Icon")
    item_frame:SetImageSize(size, size)
    item_frame:SetImage(items[item_id]:GetItemIcon())

    item_frame:SetCallback("OnClick", function(button)

        local _, item_to_show = SangreAddon:addItem(item_id)
        selected_item_frame:ReleaseChildren()
        assign_item_frame:ReleaseChildren()
        selected_item_frame:AddChild(item_to_show)
        players_frame:ReleaseChildren()
        if db_data[tostring(item_id)] then
            -- print("clickado", item_id, db_data[tostring(item_id)]["bookings"][1][1],
            --     db_data[tostring(item_id)]["bookings"][2][1])
            SangreAddon:updateBookingsList(item_id)
        end
        --SetItemRef(items[item_id]:GetItemLink(), items[item_id]:GetItemLink(), "LeftButton")
    end)

    -- Mostrar u ocultar el tooltip del objeto
    item_frame:SetCallback("OnEnter", function(widget)
        GameTooltip:SetOwner(item_frame.frame)
        GameTooltip:SetPoint("TOPRIGHT", item_frame.frame, "TOPRIGHT",
            220, -13)
        GameTooltip:SetHyperlink(items[item_id]:GetItemLink())
    end)

    item_frame:SetCallback("OnLeave", function(widget)
        GameTooltip:Hide()
    end)

    return item_frame
end

local function drawBossItems(frame)
    frame:ReleaseChildren()
    selected_item_frame:ReleaseChildren()
    assign_item_frame:ReleaseChildren()
    players_frame:ReleaseChildren()
    for _, item_id in pairs(Sangre_instances[instance_name]["bosses"][boss_index]["items"]) do
        SangreAddon:addItem(item_id, frame)
    end
end

local function drawBossData()
    saveData()
    drawBossItems(boss_frame)
end

local function drawBookingsData(item_id)
    saveData()
    --bookings_frame:ReleaseChildren()
end

local function drawDropdowns()
    local dropdown_group = AceGUI:Create("SimpleGroup")
    local instance_dropdown = AceGUI:Create("Dropdown")
    local boss_dropdown = AceGUI:Create("Dropdown")
    local import_button = AceGUI:Create("Button")
    local system_button = AceGUI:Create("Button")

    dropdown_group:SetLayout("Table")
    dropdown_group:SetUserData("table", {
        columns = { 130, 180, 100, 110 },
        space = 10,
        align = "MIDDLE",
        alignV = "MIDDLE"
    })
    main_frame:AddChild(dropdown_group)

    import_button:SetText("Importar")
    system_button:SetText("Ver Sistema")
    boss_dropdown:SetDisabled(true)

    import_button:SetCallback("OnClick", function()
        SangreAddon:createImportFrame()
    end)

    system_button:SetCallback("OnClick", function()
        SangreAddon:createSystemFrame()
    end)

    instance_dropdown:SetCallback("OnValueChanged", function(_, _, key)
        boss_dropdown:SetDisabled(false)
        buildBossDict(key)
        boss_dropdown:SetList(boss_options)
        boss_dropdown:SetValue(1)
        instance_name = key
        boss_index = 1
        drawBossData()
    end)

    boss_dropdown:SetCallback("OnValueChanged", function(_, _, key)
        boss_index = key
        drawBossData()
    end)

    instance_dropdown:SetList(instance_options)
    boss_dropdown:SetList(boss_options)

    dropdown_group:AddChild(instance_dropdown)
    dropdown_group:AddChild(boss_dropdown)
    dropdown_group:AddChild(import_button)
    dropdown_group:AddChild(system_button)

    local filler_frame = AceGUI:Create("Label")
    filler_frame:SetText(" ")
    main_frame:AddChild(filler_frame)

    instance_dropdown:SetValue(instance_name)
    if (instance_name) then
        buildBossDict(instance_name)
        boss_dropdown:SetList(boss_options)
        boss_dropdown:SetDisabled(false)
    end
    boss_dropdown:SetValue(boss_index)
end

local function drawImportContent()
    importing_systems = false

    local import_checkbox = AceGUI:Create("CheckBox")
    import_checkbox:SetLabel("Importando Sistema")

    import_checkbox:SetCallback("OnValueChanged", function(_, _, value)
        importing_systems = value
    end)
    import_frame:AddChild(import_checkbox)

    local import_text_area = AceGUI:Create("MultiLineEditBox")
    import_text_area:SetFullWidth(true)
    import_text_area:SetFullHeight(true)
    import_frame:AddChild(import_text_area)

    import_text_area:SetCallback("OnEnterPressed", function(_, _, text)
        loadstring("parsed_data = " .. text:gsub('("[^"]-"):', '[%1]='))()
        if parsed_data then
            if importing_systems then raid_players_data = parsed_data
            else db_data = parsed_data end
            saveData()
        end
    end)
end

local function drawSystemHeaders(frame)
    local f = AceGUI:Create("Label")
    f:SetText("Nombre")
    f:SetFont("Fonts\\FRIZQT__.TTF", 14)
    local color = 0.8
    f:SetColor(color, color, color)
    frame:AddChild(f)
    for _, v in ipairs(system_header_config) do
        if v["enabled"] then
            f = AceGUI:Create("Label")
            f:SetText(v["title"])
            f:SetColor(color, color, color)
            frame:AddChild(f)
        end
    end
end

local function drawSystemContent(frame)
    main_frame:SetStatusText("Cargando Sistema. Por favor espere...")

    for k, v in pairs(raid_players_data) do
        local f = AceGUI:Create("Label", k)
        f:SetText(k)
        frame:AddChild(f)
        for _, v_sort in ipairs(system_header_config) do
            if v_sort["enabled"] then
                local f = AceGUI:Create("Label")
                f:SetText(v[v_sort["key"]])
                frame:AddChild(f)
            end
        end
    end
    main_frame:SetStatusText("")
end

local function createSelectedItemFrame()

    local middle_group = AceGUI:Create("SimpleGroup")
    middle_group:SetHeight(80)
    middle_group:SetFullWidth(true)
    middle_group:SetLayout("Fill")
    main_frame:AddChild(middle_group)

    local b_container = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
    b_container:SetFullWidth(true)
    b_container:SetHeight(1)
    b_container:SetAutoAdjustHeight(false)
    b_container:SetLayout("Table")
    b_container:SetUserData("table", {
        columns = {
            { width = 0.5 },
            { width = 0.5 }
        },
        space = 0,
        align = "LEFT",
        alignV = "TOP"
    })
    middle_group:AddChild(b_container)

    local big_item_group = AceGUI:Create("InlineGroup")
    big_item_group:SetFullWidth(true)
    --big_item_group:SetWidth(280)
    big_item_group:SetHeight(80)
    big_item_group:SetTitle("Opciones")
    big_item_group:SetLayout("Fill")
    assign_item_frame = big_item_group

    b_container:AddChild(assign_item_frame)

    local big_item_group = AceGUI:Create("InlineGroup")
    big_item_group:SetFullWidth(true)
    --big_item_group:SetWidth(280)
    big_item_group:SetHeight(80)
    big_item_group:SetTitle("Item Seleccionado")
    big_item_group:SetLayout("Fill")
    selected_item_frame = big_item_group

    b_container:AddChild(selected_item_frame)

end

local function createBossFrame()
    local items_container = AceGUI:Create("InlineGroup") -- "InlineGroup" is also good
    items_container:SetFullWidth(true)
    items_container:SetHeight(180)
    items_container:SetLayout("Fill")
    items_container:SetTitle("Items")
    items_container:SetAutoAdjustHeight(true)

    main_frame:AddChild(items_container)

    local boss_frame = AceGUI:Create("ScrollFrame")
    boss_frame:SetLayout("Table") -- probably?
    boss_frame:SetUserData("table", {
        columns = {
            { width = 250 },
            { width = 250 },
            { width = 250 }
        },
        space = -5,
        align = "LEFT",
        alignV = "MIDDLE"
    })

    items_container:AddChild(boss_frame)
    return boss_frame
end

local function createBookingsFrame()
    local groups_height = 235
    local b_container = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
    b_container:SetFullWidth(true)
    b_container:SetHeight(1)
    b_container:SetAutoAdjustHeight(false)
    b_container:SetLayout("Table")
    b_container:SetUserData("table", {
        columns = {
            { width = 0.5 },
            { width = 0.5 }
        },
        space = 0,
        align = "LEFT",
        alignV = "TOP"
    })
    main_frame:AddChild(b_container)

    local b_players_grp = AceGUI:Create("InlineGroup")
    b_players_grp:SetFullWidth(true)
    b_players_grp:SetHeight(groups_height)
    b_players_grp:SetLayout("Fill") -- important!
    b_players_grp:SetTitle("Players")
    b_container:AddChild(b_players_grp)

    local b_players_table = AceGUI:Create("ScrollFrame")
    b_players_table:SetLayout("Table")
    b_players_table:SetUserData("table", {
        columns = {
            { width = 0.99 }
        },
        space = 0,
        align = "LEFT",
        alignV = "TOP"
    })

    b_players_grp:AddChild(b_players_table)

    players_frame = b_players_table

    local b_reserves_grp = AceGUI:Create("InlineGroup")
    b_reserves_grp:SetFullWidth(true)
    b_reserves_grp:SetHeight(groups_height)
    b_reserves_grp:SetLayout("Fill") -- important!
    b_reserves_grp:SetTitle("Reservas")
    b_container:AddChild(b_reserves_grp)

    local b_reserves_table = AceGUI:Create("ScrollFrame")
    b_reserves_table:SetLayout("Table")
    b_reserves_table:SetUserData("table", {
        columns = {
            { width = 0.99 }
        },
        space = 0,
        align = "LEFT",
        alignV = "TOP"
    })

    for i = 1, 20 do
        local label2 = AceGUI:Create("Label")
        label2:SetFont("Fonts\\FRIZQT__.TTF", 12)
        --label2:SetText("Manolo")
        b_reserves_table:AddChild(label2)
    end

    b_reserves_grp:AddChild(b_reserves_table)

    bookings_frame = bookingsFrame
end

local function drawAssignButton(player_name, item_id)
    assign_item_frame:ReleaseChildren()

    local assign_button = AceGUI:Create("Button")
    assign_button:SetText("(" .. string.upper(player_name) .. ') Asignar "' .. items[item_id]:GetItemName() .. '"')
    assign_button:SetCallback("OnClick", function()
        print("click:", item_id, player_name)
        updatePlayersBookings(player_name, item_id, "add")
    end)

    assign_item_frame:AddChild(assign_button)
end

function SangreAddon:createMainFrame()
    if main_frame then
        AceGUI:Release(main_frame)
        return
    end
    main_frame = AceGUI:Create("Frame")
    main_frame:SetWidth(850)
    main_frame:SetHeight(600)
    main_frame:EnableResize(false)
    main_frame:SetCallback("OnClose", function(widget)
        if system_frame ~= nil then
            AceGUI:Release(system_frame)
            system_frame = nil
        end
        if import_frame ~= nil then
            AceGUI:Release(import_frame)
            import_frame = nil
        end
        boss_frame = nil
        bookings_frame = nil
        players_frame = nil
        selected_item_frame = nil
        assign_item_frame = nil
        main_frame = nil

        AceGUI:Release(widget)
        main_frame = nil
    end)

    local instance_info = (select(8, GetInstanceInfo()))
    if SangreAddon:inArray(allowed_instances, instance_info) then
        main_frame.frame:RegisterEvent("LOOT_OPENED")
        main_frame.frame:SetScript("OnEvent", function(frame, event)
            local count = GetNumLootItems()
            print("Total:", count)
            if count > 0 then
                SangreAddon:createMainFrame()
                for i = 1, count do
                    local itemLink = GetLootSlotLink(i)
                    local itemId = tonumber(itemLink:match("item:(%d+):"))
                    print(itemLink, itemId)
                    boss_frame:ReleaseChildren()
                    items = {}
                    SangreAddon:addItem(itemId, boss_frame)
                end
            end
            print(boss_frame)

        end)
    end

    -- eventData = [[
    --     naxx25 = {
    --         ["name"] = "Anub'Rekhan",
    --         ["items"] = {
    --             [39719] = {
    --                 ["sheetRow"] = 5,
    --                 ["enUS"] = "Manto de las langostas",
    --                 ["esES"] = "Mantle of the Locusts",
    --                 ["reserves"] = {}
    --             }
    --         }
    --     }
    -- ]]

    -- loadstring(eventData)()
    -- if naxx25 then print(naxx25["items"][39719]["enUS"]) end

    main_frame:SetLayout("List")
    main_frame:SetTitle(SangreAddon.AddonNameAndVersion)
    main_frame:SetStatusText("")

    drawDropdowns()
    boss_frame = createBossFrame()
    createSelectedItemFrame()
    createBookingsFrame()
    drawBossData()
    drawBookingsData()
end

function SangreAddon:createImportFrame()
    if import_frame then
        AceGUI:Release(import_frame)
        return
    end
    import_frame = AceGUI:Create("Frame")
    import_frame:SetWidth(450)
    import_frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        import_frame = nil
    end)

    import_frame:SetLayout("Flow")
    import_frame:SetTitle("Import Data")
    import_frame:SetStatusText("")
    drawImportContent()
end

function SangreAddon:createSystemFrame()
    if system_frame then
        AceGUI:Release(system_frame)
        return
    end
    local frame_width = 100
    local tableWidths = { { width = 100 } }
    for _, v in ipairs(system_header_config) do
        if v["enabled"] then
            table.insert(tableWidths, { width = v["width"] })
            frame_width = frame_width + tonumber(v["width"])
        end
    end

    system_frame = AceGUI:Create("Frame")
    system_frame:SetWidth(frame_width + 25)
    system_frame:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        system_frame = nil
    end)

    system_frame:SetLayout("Flow")
    system_frame:SetTitle("Pestaña Sistema")

    local frame = AceGUI:Create("ScrollFrame")
    frame:SetLayout("Table")
    frame:SetUserData("table", {
        columns = tableWidths,
        space = 2,
        align = "MIDDLE",
        alignV = "MIDDLE"
    })
    frame:SetFullWidth(true)
    frame:SetHeight(0)
    frame:SetAutoAdjustHeight(false)
    system_frame:AddChild(frame)

    drawSystemHeaders(frame)
    drawSystemContent(frame)
end

function SangreAddon:addItem(item_id, frame)
    local item_group = AceGUI:Create("SimpleGroup")

    item_group:SetLayout("Table")
    item_group:SetUserData("table", {
        columns = { 50, 425 },
        space = 1,
        align = "LEFT",
        alignV = "MIDDLE"
    })

    items[item_id] = Item:CreateFromItemID(item_id)

    if (items[item_id]:GetItemID()) then
        items[item_id]:ContinueOnItemLoad(function()
            item_group:AddChild(createItemFrame(item_id, 32))
            item_group:AddChild(createItemNameFrame(item_id));
            if frame then frame:AddChild(item_group) end
        end)
    end

    return items[item_id], item_group
end

function SangreAddon:updateBookingsList(item_id)
    local s_item_id = tostring(item_id)
    if db_data[s_item_id] then

        local sorTable = function(aTable, direction)
            local keys = {}

            for k, v in pairs(aTable) do keys[#keys + 1] = k end
            if (direction == "desc") then
                table.sort(keys, function(a, b) return a > b end)
            else
                table.sort(keys, function(a, b) return a < b end)
            end
            local n = 0

            return function()
                n = n + 1
                return keys[n], aTable[keys[n]]
            end
        end

        local table_to_view = {
            ["with_numbers"] = {},
            ["rest"] = {}
        }
        for p_indice, p_valor in pairs(db_data[s_item_id]["bookings"][2]) do
            --if (type(p_valor) == "number") then table_to_view["with_numbers"][p_valor] = db_data[s_item_id]["bookings"][1][p_indice]
            if (p_valor == "getTable") then table_to_view["with_numbers"][
                    raid_players_data[db_data[s_item_id]["bookings"][1][p_indice]]["rt"]] = db_data[s_item_id][
                    "bookings"][1][p_indice]
            else table_to_view["rest"][p_valor] = db_data[s_item_id]["bookings"][1][p_indice] end
        end

        local finalResult = sorTable(table_to_view["with_numbers"], "desc")
        local first = true
        for p_index, p_name in finalResult do
            local label = AceGUI:Create("InteractiveLabel")
            if first then label:SetColor(0.5, 1, 0.5) end
            label:SetFont("Fonts\\FRIZQT__.TTF", 12)
            label:SetText(p_index .. " - " .. p_name)
            label:SetCallback("OnClick", function(self)
                local text = self.label:GetText()
                local _, j = string.find(text, " - ")
                local player_name = string.sub(text, j + 3, string.len(text))
                print("label pulsado", player_name, raid_players_data[string.sub(text, j + 3, string.len(text))]["rt"])
                drawAssignButton(player_name, item_id)
            end)
            players_frame:AddChild(label)
            first = false
        end

        local label_line = AceGUI:Create("InteractiveLabel")
        label_line:SetColor(1, 1, 0)
        label_line:SetFont("Fonts\\FRIZQT__.TTF", 14)
        label_line:SetText("---")
        players_frame:AddChild(label_line)

        for p_index, p_name in pairs(table_to_view["rest"]) do
            local label = AceGUI:Create("Label")
            label:SetColor(0.7, 0.7, 0.7)
            label:SetFont("Fonts\\FRIZQT__.TTF", 12)
            label:SetText(p_name .. " (" .. p_index .. ")")
            players_frame:AddChild(label)
            first = false
        end
    end
end

function SangreAddon:initSangrelists()
    -- create item colors
    for i = 0, 7 do
        local _, _, _, itemQuality = GetItemQualityColor(i)
        ITEM_COLORS[i] = "|c" .. itemQuality
    end

    loadData()
    LibStub("AceConsole-3.0"):RegisterChatCommand("SangreAddon", function()
        SangreAddon:createMainFrame()
    end, persist)
end

function SangreAddon:dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then k = '"' .. k .. '"' end
            s = s .. "[" .. k .. "] = " .. SangreAddon:dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

function SangreAddon:inArray(tab, val)
    for _, value in ipairs(tab) do if value == val then return true end end

    return false
end

buildInstanceDict()
