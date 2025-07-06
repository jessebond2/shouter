local addonName, addon = ...
local Shouter = addon

-- Debug log storage
Shouter.debugLog = {}
Shouter.debugEnabled = false
local maxLogEntries = 500

function Shouter:DebugLog(message, category)
    if not self.debugEnabled then return end
    
    local timestamp = date("%H:%M:%S")
    local entry = {
        time = timestamp,
        category = category or "General",
        message = message
    }
    
    table.insert(self.debugLog, 1, entry)
    
    -- Limit log size
    while #self.debugLog > maxLogEntries do
        table.remove(self.debugLog)
    end
    
    -- Update debug panel if visible
    if self.debugPanel and self.debugPanel:IsVisible() then
        self.debugPanel:RefreshLog()
    end
end

local function CreateDebugPanel()
    local panel = CreateFrame("Frame", "ShouterDebugPanel", UIParent)
    panel.name = "Debug"
    panel.parent = "Shouter"
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Shouter Debug Panel")
    
    -- Enable debug checkbox
    local debugCheckbox = CreateFrame("CheckButton", "ShouterDebugCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    debugCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    debugCheckbox.Text:SetText("Enable Debug Logging")
    debugCheckbox:SetChecked(Shouter.debugEnabled)
    debugCheckbox:SetScript("OnClick", function(self)
        Shouter.debugEnabled = self:GetChecked()
        Shouter.db.debugEnabled = Shouter.debugEnabled
        if Shouter.debugEnabled then
            Shouter:DebugLog("Debug logging enabled", "System")
        end
    end)
    
    -- Clear log button
    local clearButton = CreateFrame("Button", "ShouterClearDebugButton", panel, "UIPanelButtonTemplate")
    clearButton:SetPoint("LEFT", debugCheckbox.Text, "RIGHT", 20, 0)
    clearButton:SetSize(80, 22)
    clearButton:SetText("Clear Log")
    clearButton:SetScript("OnClick", function()
        Shouter.debugLog = {}
        panel:RefreshLog()
        Shouter:DebugLog("Debug log cleared", "System")
    end)
    
    -- Export button
    local exportButton = CreateFrame("Button", "ShouterExportDebugButton", panel, "UIPanelButtonTemplate")
    exportButton:SetPoint("LEFT", clearButton, "RIGHT", 10, 0)
    exportButton:SetSize(80, 22)
    exportButton:SetText("Export Log")
    exportButton:SetScript("OnClick", function()
        panel:ShowExportDialog()
    end)
    
    -- Category filter
    local filterLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    filterLabel:SetPoint("TOPLEFT", debugCheckbox, "BOTTOMLEFT", 0, -20)
    filterLabel:SetText("Filter:")
    
    local filterDropdown = CreateFrame("Frame", "ShouterDebugFilterDropdown", panel, "UIDropDownMenuTemplate")
    filterDropdown:SetPoint("LEFT", filterLabel, "RIGHT", 0, -2)
    UIDropDownMenu_SetWidth(filterDropdown, 150)
    
    panel.currentFilter = "All"
    
    local function InitializeFilterDropdown()
        local categories = {"All", "System", "Scan", "Detection", "Command", "General"}
        
        local function OnFilterSelect(self)
            panel.currentFilter = self.value
            UIDropDownMenu_SetText(filterDropdown, self.value)
            panel:RefreshLog()
        end
        
        for _, category in ipairs(categories) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = category
            info.value = category
            info.func = OnFilterSelect
            UIDropDownMenu_AddButton(info)
        end
    end
    
    UIDropDownMenu_Initialize(filterDropdown, InitializeFilterDropdown)
    UIDropDownMenu_SetText(filterDropdown, "All")
    
    -- Log display
    local logFrame = CreateFrame("Frame", nil, panel)
    logFrame:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -30)
    logFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -30, 30)
    logFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    
    -- Scroll frame for log
    local scrollFrame = CreateFrame("ScrollFrame", "ShouterDebugScrollFrame", logFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    
    local logText = scrollChild:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    logText:SetPoint("TOPLEFT", 0, 0)
    logText:SetJustifyH("LEFT")
    logText:SetJustifyV("TOP")
    logText:SetWordWrap(true)
    
    -- Refresh log function
    function panel:RefreshLog()
        local text = ""
        local count = 0
        
        for _, entry in ipairs(Shouter.debugLog) do
            if self.currentFilter == "All" or entry.category == self.currentFilter then
                if count > 0 then
                    text = text .. "\n"
                end
                text = text .. string.format("|cFF888888%s|r [|cFF00FFFF%s|r] %s", 
                    entry.time, entry.category, entry.message)
                count = count + 1
            end
        end
        
        if text == "" then
            text = "No log entries"
        end
        
        logText:SetText(text)
        
        -- Update scroll child size
        local width = scrollFrame:GetWidth() - 20
        logText:SetWidth(width)
        local height = logText:GetStringHeight()
        scrollChild:SetSize(width, height)
    end
    
    -- Export dialog
    function panel:ShowExportDialog()
        if not panel.exportDialog then
            local dialog = CreateFrame("Frame", "ShouterExportDialog", UIParent)
            dialog:SetSize(400, 300)
            dialog:SetPoint("CENTER")
            dialog:SetFrameStrata("DIALOG")
            dialog:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 }
            })
            
            local title = dialog:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            title:SetPoint("TOP", 0, -20)
            title:SetText("Export Debug Log")
            
            local scrollFrame = CreateFrame("ScrollFrame", nil, dialog, "UIPanelScrollFrameTemplate")
            scrollFrame:SetPoint("TOPLEFT", 20, -50)
            scrollFrame:SetPoint("BOTTOMRIGHT", -40, 50)
            
            local editBox = CreateFrame("EditBox", nil, scrollFrame)
            editBox:SetMultiLine(true)
            editBox:SetFontObject(GameFontNormalSmall)
            editBox:SetWidth(340)
            editBox:SetScript("OnEscapePressed", function() dialog:Hide() end)
            scrollFrame:SetScrollChild(editBox)
            
            local closeButton = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
            closeButton:SetPoint("BOTTOM", 0, 20)
            closeButton:SetSize(80, 22)
            closeButton:SetText("Close")
            closeButton:SetScript("OnClick", function() dialog:Hide() end)
            
            panel.exportDialog = dialog
            panel.exportEditBox = editBox
        end
        
        -- Generate export text
        local exportText = "Shouter Debug Log Export\n"
        exportText = exportText .. "Generated: " .. date("%Y-%m-%d %H:%M:%S") .. "\n"
        exportText = exportText .. string.rep("-", 50) .. "\n\n"
        
        for _, entry in ipairs(Shouter.debugLog) do
            exportText = exportText .. string.format("%s [%s] %s\n", 
                entry.time, entry.category, entry.message)
        end
        
        panel.exportEditBox:SetText(exportText)
        panel.exportEditBox:HighlightText()
        panel.exportEditBox:SetFocus()
        panel.exportDialog:Show()
    end
    
    -- Refresh handler
    panel.refresh = function()
        debugCheckbox:SetChecked(Shouter.debugEnabled)
        panel:RefreshLog()
    end
    
    -- Add to Interface Options
    InterfaceOptions_AddCategory(panel)
    
    return panel
end

-- Hook into main addon functions for debugging
local function HookDebugFunctions()
    local originalScan = Shouter.ScanForPlayers
    Shouter.ScanForPlayers = function(self)
        self:DebugLog("Starting player scan", "Scan")
        originalScan(self)
    end
    
    local originalYell = Shouter.YellForPlayer
    Shouter.YellForPlayer = function(self, name, distance)
        self:DebugLog(string.format("Yelling for %s at %.1f yards", name, distance), "Detection")
        originalYell(self, name, distance)
    end
    
    local originalAdd = Shouter.AddPlayer
    Shouter.AddPlayer = function(self, name)
        self:DebugLog(string.format("Adding player: %s", name), "Command")
        originalAdd(self, name)
    end
    
    local originalRemove = Shouter.RemovePlayer
    Shouter.RemovePlayer = function(self, name)
        self:DebugLog(string.format("Removing player: %s", name), "Command")
        originalRemove(self, name)
    end
end

-- Initialize debug panel after addon loads
local debugFrame = CreateFrame("Frame")
debugFrame:RegisterEvent("ADDON_LOADED")
debugFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        print("|cFFFF0000[Shouter Debug]|r Addon loaded event fired")
        C_Timer.After(0.2, function()
            print("|cFFFF0000[Shouter Debug]|r Attempting to create debug panel...")
            -- Restore debug state
            if Shouter.db and Shouter.db.debugEnabled ~= nil then
                Shouter.debugEnabled = Shouter.db.debugEnabled
            end
            
            local panel = CreateDebugPanel()
            if panel then
                Shouter.debugPanel = panel
                HookDebugFunctions()
                print("|cFFFF0000[Shouter Debug]|r Debug panel created successfully!")
                Shouter:DebugLog("Shouter addon loaded", "System")
            else
                print("|cFFFF0000[Shouter Debug]|r Debug panel creation failed!")
            end
        end)
    end
end)