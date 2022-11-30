local AceGUI = LibStub("AceGUI-3.0")

local ITEM_COLORS = {}

local instance_name = nil
local instance_options = {}
local boss_options = {}
local boss_index = nil
local boss_frame = nil
local bookings_frame = nil
local main_frame = nil
local import_frame = nil
local items = {}

local function createItemNameFrame(item_id)
    if item_id < 0 then
        local empty_label = AceGUI:Create("Label")
        return empty_label
    end
    --GetItemQualityColor
    local item_name = AceGUI:Create("Label")

    item_name:SetFont("Fonts\\FRIZQT__.TTF", 13)
    item_name:SetText(ITEM_COLORS[items[item_id]:GetItemQuality() or 0]..items[item_id]:GetItemName())

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
        print('clickado', item_id, items[item_id]:GetItemName())
        --SetItemRef(items[item_id]:GetItemLink(), items[item_id]:GetItemLink(), "LeftButton")
    end)

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

    for _, itemId in pairs(Sangre_instances[instance_name]["bosses"][boss_index]["items"]) do
        local items_group = AceGUI:Create("SimpleGroup")

        items_group:SetLayout("Table")
        items_group:SetUserData("table", {
            columns = {50, 425},
            space = 1,
            align = "LEFT",
            alignV = "MIDDLE"
        })

        items[itemId] = Item:CreateFromItemID(itemId)

        if (items[itemId]:GetItemID()) then
            items[itemId]:ContinueOnItemLoad(function()
                items_group:AddChild(createItemFrame(itemId, 32))
                items_group:AddChild(createItemNameFrame(itemId));
                frame:AddChild(items_group)
            end)
        end
    end
end

local function saveData()
    SangreAddon.db.char.instance_name = instance_name
    SangreAddon.db.char.boss_index = boss_index
end

local function drawBossData()
    saveData()
    drawBossItems(boss_frame)
end

local function drawBookingsData(itemId)
    saveData()
    --bookings_frame:ReleaseChildren()
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

    if instance_name then
        buildBossDict(instance_name)
    end
end

local function drawDropdowns()
    local dropdown_group = AceGUI:Create("SimpleGroup")
    local instance_dropdown = AceGUI:Create("Dropdown")
    local boss_dropdown = AceGUI:Create("Dropdown")
    local import_button = AceGUI:Create("Button")

    dropdown_group:SetLayout("Table")
    dropdown_group:SetUserData("table", {
        columns = {130, 180, 240},
        space = 10,
        align = "MIDDLE",
        alignV = "MIDDLE"
    })
    main_frame:AddChild(dropdown_group)

    import_button:SetText("Importar")
    boss_dropdown:SetDisabled(true)

    import_button:SetCallback("OnClick", function()
        SangreAddon:createImportFrame()
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

local function drawImportTextarea()
    local import_text_area = AceGUI:Create("MultiLineEditBox")
    import_frame:AddChild(import_text_area)

    import_text_area:SetCallback("OnEnterPressed", function(_, _, text)
        local import_excel_data = {};
        loadstring('import_excel_data = ' .. text)()
        if import_excel_data then print(import_excel_data['items'][39719]['enUS']) end
    end)

end

local function createBossFrame()
    local items_container = AceGUI:Create("InlineGroup") -- "InlineGroup" is also good
    items_container:SetFullWidth(true)
    items_container:SetHeight(180)
    items_container:SetLayout("Fill")
    items_container:SetTitle('Items')
    items_container:SetAutoAdjustHeight(true)

    main_frame:AddChild(items_container)

    local boss_frame = AceGUI:Create("ScrollFrame")
    boss_frame:SetLayout("Table") -- probably?
    boss_frame:SetUserData("table", {
        columns = {
            {width = 425},
            {width = 425}
        },
        space = -5,
        align = "LEFT",
        alignV = "MIDDLE"
    })

    items_container:AddChild(boss_frame)
    return boss_frame
end

local function createBookingsFrame()
    local groups_height = 215
    local b_container = AceGUI:Create("SimpleGroup") -- "InlineGroup" is also good
    b_container:SetFullWidth(true)
    b_container:SetHeight(0)
    b_container:SetAutoAdjustHeight(false)
    b_container:SetLayout("Table")
    b_container:SetUserData("table", {
        columns = {
            {width = 0.5},
            {width = 0.5}
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
    b_players_grp:SetTitle('Players')
    b_container:AddChild(b_players_grp)

    local b_players_table = AceGUI:Create("ScrollFrame")
    b_players_table:SetLayout("Table")
    b_players_table:SetUserData("table", {
        columns = {
            {width = 0.99}
        },
        space = 0,
        align = "LEFT",
        alignV = "TOP"
    })

    for _ = 1, 20 do
        local label2 = AceGUI:Create("Label")
        label2:SetFont("Fonts\\FRIZQT__.TTF", 12)
        label2:SetText('Players')
        b_players_table:AddChild(label2)
    end

    b_players_grp:AddChild(b_players_table)

    local b_reserves_grp = AceGUI:Create("InlineGroup")
    b_reserves_grp:SetFullWidth(true)
    b_reserves_grp:SetHeight(groups_height)
    b_reserves_grp:SetLayout("Fill") -- important!
    b_reserves_grp:SetTitle('Reservas')
    b_container:AddChild(b_reserves_grp)

    local b_reserves_table = AceGUI:Create("ScrollFrame")
    b_reserves_table:SetLayout("Table")
    b_reserves_table:SetUserData("table", {
        columns = {
            {width = 0.99}
        },
        space = 0,
        align = "LEFT",
        alignV = "TOP"
    })

    for i = 1, 20 do
        local label2 = AceGUI:Create("Label")
        label2:SetFont("Fonts\\FRIZQT__.TTF", 12)
        label2:SetText('Manolo')
        b_reserves_table:AddChild(label2)
    end

    b_reserves_grp:AddChild(b_reserves_table)

    bookings_frame = bookingsFrame
end

function SangreAddon:createMainFrame()
    if main_frame then
        AceGUI:Release(main_frame)
        return
    end
    main_frame = AceGUI:Create("Frame")
    main_frame:SetWidth(850)
    main_frame:SetCallback("OnClose", function(widget)
        boss_frame = nil
        bookings_frame = nil
        AceGUI:Release(widget)
        main_frame = nil
    end)

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
    -- if naxx25 then print(naxx25['items'][39719]['enUS']) end

    main_frame:SetLayout("List")
    main_frame:SetTitle(SangreAddon.AddonNameAndVersion)
    main_frame:SetStatusText("AceGUI-3.0")

    drawDropdowns()
    boss_frame = createBossFrame()
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

    import_frame:SetLayout("Fill")
    import_frame:SetTitle('Import Data')
    import_frame:SetStatusText("AceGUI-3.0")
    drawImportTextarea()
end

function SangreAddon:initSangrelists()
    -- create item colors
    for i = 0, 7 do
        local _, _, _, itemQuality = GetItemQualityColor(i)
        ITEM_COLORS[i] = "|c"..itemQuality
    end

    loadData()
    LibStub("AceConsole-3.0"):RegisterChatCommand("SangreAddon", function()
        SangreAddon:createMainFrame()
    end, persist)
end

buildInstanceDict()
