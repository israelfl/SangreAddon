local AceGUI = LibStub("AceGUI-3.0")

local instance_name = nil
local instance_options = {}
local boss_options = {}
local boss_index = nil
local boss_frame = nil
local bookings_frame = nil
local main_frame = nil
local import_frame = nil
local ITEM_COLORS = {}
local items = {}


local function createItemNameFrame(item_id)
    if item_id < 0 then
        local f = AceGUI:Create("Label")
        return f
    end
    --GetItemQualityColor
    local item_name = AceGUI:Create("Label")
    item_name:SetFont("Fonts\\FRIZQT__.TTF", 14)
    item_name:SetText(ITEM_COLORS[items[item_id]:GetItemQuality() or 0]..items[item_id]:GetItemName())

    return item_name
end

local function createItemFrame(item_id, size)
    if item_id < 0 then
        local f = AceGUI:Create("Label")
        return f
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

local function drawBossItems(frame, text)
    frame:ReleaseChildren()

    for itemIndex, itemId in pairs(Sangre_instances[instance_name]["bosses"][boss_index]["items"]) do
        local itemsGroup = AceGUI:Create("SimpleGroup")

        itemsGroup:SetLayout("Table")
        itemsGroup:SetUserData("table", {
            columns = {50, 300},
            space = 1,
            align = "LEFT",
            alignV = "MIDDLE"
        })
        frame:AddChild(itemsGroup)

        items[itemId] = Item:CreateFromItemID(itemId)

        if (items[itemId]:GetItemID()) then
            items[itemId]:ContinueOnItemLoad(function()
                itemsGroup:AddChild(createItemFrame(itemId, 32))
                itemsGroup:AddChild(createItemNameFrame(itemId));
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
    drawBossItems(boss_frame, "Items")
end

local function drawBookingsData(itemId)
    saveData()
    bookings_frame:ReleaseChildren()
end

local function buildInstanceDict()
    for intIndex, instName in pairs(Sangre_instances) do
        instance_options[intIndex] = intIndex
    end
end

local function buildBossDict(instanceId)
    boss_options = {}
    for bossIndex, bossData in ipairs(Sangre_instances[instanceId]["bosses"]) do
        table.insert(boss_options, bossData.name)
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
    local dropDownGroup = AceGUI:Create("SimpleGroup")
    local instanceDropdown = AceGUI:Create("Dropdown")
    local bossDropdown = AceGUI:Create("Dropdown")
    local importButton = AceGUI:Create("Button")

    dropDownGroup:SetLayout("Table")
    dropDownGroup:SetUserData("table", {
        columns = {130, 110, 180, 70, 100},
        space = 1,
        align = "MIDDLE",
        alignV = "MIDDLE"
    })
    main_frame:AddChild(dropDownGroup)

    importButton:SetText("Importar")
    bossDropdown:SetDisabled(true)

    importButton:SetCallback("OnClick", function()
        SangreAddon:createImportFrame()
    end)

    instanceDropdown:SetCallback("OnValueChanged", function(_, _, key)
        bossDropdown:SetDisabled(false)
        buildBossDict(key)
        bossDropdown:SetList(boss_options)
        bossDropdown:SetValue(1)
        instance_name = key
        boss_index = 1
        drawBossData()
    end)

    bossDropdown:SetCallback("OnValueChanged", function(_, _, key)
        boss_index = key
        drawBossData()
    end)

    instanceDropdown:SetList(instance_options)
    bossDropdown:SetList(boss_options)

    dropDownGroup:AddChild(instanceDropdown)
    dropDownGroup:AddChild(bossDropdown)
    dropDownGroup:AddChild(importButton)

    local fillerFrame = AceGUI:Create("Label")
    fillerFrame:SetText(" ")
    main_frame:AddChild(fillerFrame)

    instanceDropdown:SetValue(instance_name)
    if (instance_name) then
        buildBossDict(instance_name)
        bossDropdown:SetList(boss_options)
        bossDropdown:SetDisabled(false)
    end
    bossDropdown:SetValue(boss_index)

end

local function drawImportTextarea()
    local textArea = AceGUI:Create("MultiLineEditBox")
    import_frame:AddChild(textArea)

    textArea:SetCallback("OnEnterPressed", function(_, _, text)
        loadstring('excelData = ' .. text)()
        if excelData then print(excelData['items'][39719]['enUS']) end
    end)

end

local function createBossFrame()
    local itemsContainer = AceGUI:Create("InlineGroup") -- "InlineGroup" is also good
    itemsContainer:SetFullWidth(true)
    itemsContainer:SetHeight(180)
    itemsContainer:SetLayout("Fill") -- important!
    itemsContainer:SetTitle('Items')
    itemsContainer:SetAutoAdjustHeight(true)

    main_frame:AddChild(itemsContainer)

    local bossFrame = AceGUI:Create("ScrollFrame")
    bossFrame:SetLayout("Table") -- probably?
    bossFrame:SetUserData("table", {
        columns = {
            {width = 425},
            {width = 425}
        },
        space = -5,
        align = "LEFT",
        alignV = "MIDDLE"
    })

    itemsContainer:AddChild(bossFrame)
    boss_frame = bossFrame
end

local function createBookingsFrame()
    local bookingsContainer = AceGUI:Create("InlineGroup") -- "InlineGroup" is also good
    bookingsContainer:SetFullWidth(true)
    bookingsContainer:SetHeight(180)
    bookingsContainer:SetLayout("Fill") -- important!
    bookingsContainer:SetTitle('Reservas')
    bookingsContainer:SetAutoAdjustHeight(true)

    main_frame:AddChild(bookingsContainer)


    local bookingsFrame = AceGUI:Create("ScrollFrame")
    bookingsFrame:SetFullWidth(true)
    bookingsFrame:SetLayout("Table") -- probably?
    bookingsFrame:SetUserData("table", {
        columns = {
            {width = 425}
        },
        space = -5,
        align = "LEFT",
        alignV = "MIDDLE"
    })

    local pp2 = AceGUI:Create("Label")
    pp2:SetFont("Fonts\\FRIZQT__.TTF", 14)
    pp2:SetText('Juan')
    bookingsFrame:AddChild(pp2)

    bookingsContainer:AddChild(bookingsFrame)

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
    createBossFrame()
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
