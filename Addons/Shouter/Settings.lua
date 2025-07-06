local addonName, addon = ...
local Shouter = addon

function ShouterCreateSettingsPanel()
    -- Get the global Shouter reference
    local Shouter = _G.Shouter
    if not Shouter or not Shouter.db then
        print("|cFFFF0000[Shouter Settings]|r Error: Shouter not initialized")
        return nil
    end
    
    local panel = CreateFrame("Frame", "ShouterSettingsPanel", UIParent)
    panel.name = "Shouter"
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Shouter Settings")
    
    -- Enable checkbox
    local enableCheckbox = CreateFrame("CheckButton", "ShouterEnableCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    enableCheckbox.Text:SetText("Enable Shouter")
    enableCheckbox:SetChecked(Shouter.db.enabled)
    enableCheckbox:SetScript("OnClick", function(self)
        if self:GetChecked() then
            Shouter:Enable()
        else
            Shouter:Disable()
        end
    end)
    
    -- Range slider
    local rangeSlider = CreateFrame("Slider", "ShouterRangeSlider", panel, "OptionsSliderTemplate")
    rangeSlider:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -40)
    rangeSlider:SetWidth(200)
    rangeSlider:SetMinMaxValues(10, 100)
    rangeSlider:SetValue(Shouter.db.range)
    rangeSlider:SetValueStep(5)
    rangeSlider.Text:SetText("Detection Range")
    rangeSlider.Low:SetText("10")
    rangeSlider.High:SetText("100")
    
    local rangeValue = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    rangeValue:SetPoint("LEFT", rangeSlider, "RIGHT", 10, 0)
    rangeValue:SetText(Shouter.db.range .. " yards")
    
    rangeSlider:SetScript("OnValueChanged", function(self, value)
        Shouter.db.range = value
        rangeValue:SetText(value .. " yards")
    end)
    
    -- Cooldown slider
    local cooldownSlider = CreateFrame("Slider", "ShouterCooldownSlider", panel, "OptionsSliderTemplate")
    cooldownSlider:SetPoint("TOPLEFT", rangeSlider, "BOTTOMLEFT", 0, -40)
    cooldownSlider:SetWidth(200)
    cooldownSlider:SetMinMaxValues(10, 300)
    cooldownSlider:SetValue(Shouter.db.cooldown)
    cooldownSlider:SetValueStep(10)
    cooldownSlider.Text:SetText("Yell Cooldown")
    cooldownSlider.Low:SetText("10s")
    cooldownSlider.High:SetText("300s")
    
    local cooldownValue = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    cooldownValue:SetPoint("LEFT", cooldownSlider, "RIGHT", 10, 0)
    cooldownValue:SetText(Shouter.db.cooldown .. " seconds")
    
    cooldownSlider:SetScript("OnValueChanged", function(self, value)
        Shouter.db.cooldown = value
        cooldownValue:SetText(value .. " seconds")
    end)
    
    -- Message type dropdown
    local messageTypeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    messageTypeLabel:SetPoint("TOPLEFT", cooldownSlider, "BOTTOMLEFT", 0, -30)
    messageTypeLabel:SetText("Message Type:")
    
    local messageTypeDropdown = CreateFrame("Frame", "ShouterMessageTypeDropdown", panel, "UIDropDownMenuTemplate")
    messageTypeDropdown:SetPoint("LEFT", messageTypeLabel, "RIGHT", 0, -2)
    UIDropDownMenu_SetWidth(messageTypeDropdown, 100)
    
    local function InitializeMessageTypeDropdown()
        local function OnMessageTypeSelect(self)
            Shouter.db.messageType = self.value
            UIDropDownMenu_SetText(messageTypeDropdown, self.value == "YELL" and "Yell" or "Say")
            CloseDropDownMenus()
        end
        
        local info = UIDropDownMenu_CreateInfo()
        
        info.text = "Yell"
        info.value = "YELL"
        info.func = OnMessageTypeSelect
        info.checked = Shouter.db.messageType == "YELL"
        UIDropDownMenu_AddButton(info)
        
        info.text = "Say"
        info.value = "SAY"
        info.func = OnMessageTypeSelect
        info.checked = Shouter.db.messageType == "SAY"
        UIDropDownMenu_AddButton(info)
    end
    
    UIDropDownMenu_Initialize(messageTypeDropdown, InitializeMessageTypeDropdown)
    UIDropDownMenu_SetText(messageTypeDropdown, Shouter.db.messageType == "YELL" and "Yell" or "Say")
    
    -- Player list section
    local playerListTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    playerListTitle:SetPoint("TOPLEFT", messageTypeLabel, "BOTTOMLEFT", 0, -30)
    playerListTitle:SetText("Tracked Players")
    
    -- Add player input
    local addPlayerLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    addPlayerLabel:SetPoint("TOPLEFT", playerListTitle, "BOTTOMLEFT", 0, -10)
    addPlayerLabel:SetText("Add Player:")
    
    local addPlayerInput = CreateFrame("EditBox", "ShouterAddPlayerInput", panel, "InputBoxTemplate")
    addPlayerInput:SetPoint("LEFT", addPlayerLabel, "RIGHT", 10, 0)
    addPlayerInput:SetSize(120, 20)
    addPlayerInput:SetAutoFocus(false)
    
    local addButton = CreateFrame("Button", "ShouterAddButton", panel, "UIPanelButtonTemplate")
    addButton:SetPoint("LEFT", addPlayerInput, "RIGHT", 10, 0)
    addButton:SetSize(60, 22)
    addButton:SetText("Add")
    addButton:SetScript("OnClick", function()
        local name = addPlayerInput:GetText()
        if name and name ~= "" then
            Shouter:AddPlayer(name)
            addPlayerInput:SetText("")
            panel:RefreshPlayerList()
        end
    end)
    
    -- Player list scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "ShouterPlayerListScrollFrame", panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", addPlayerLabel, "BOTTOMLEFT", 0, -30)
    scrollFrame:SetSize(280, 150)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(280, 150)
    scrollFrame:SetScrollChild(scrollChild)
    
    panel.playerButtons = {}
    
    function panel:RefreshPlayerList()
        -- Clear existing buttons
        for _, button in ipairs(self.playerButtons) do
            button:Hide()
        end
        
        -- Create buttons for each player
        for i, playerName in ipairs(Shouter.db.players) do
            local button = self.playerButtons[i]
            if not button then
                button = CreateFrame("Frame", nil, scrollChild)
                button:SetSize(260, 20)
                
                button.text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                button.text:SetPoint("LEFT", 5, 0)
                
                button.removeBtn = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
                button.removeBtn:SetPoint("RIGHT", -5, 0)
                button.removeBtn:SetSize(60, 18)
                button.removeBtn:SetText("Remove")
                
                self.playerButtons[i] = button
            end
            
            button:SetPoint("TOPLEFT", 0, -(i-1) * 25)
            button.text:SetText(playerName)
            button.removeBtn:SetScript("OnClick", function()
                Shouter:RemovePlayer(playerName)
                panel:RefreshPlayerList()
            end)
            button:Show()
        end
        
        scrollChild:SetHeight(math.max(150, #Shouter.db.players * 25))
    end
    
    -- Refresh handler
    panel.refresh = function()
        enableCheckbox:SetChecked(Shouter.db.enabled)
        rangeSlider:SetValue(Shouter.db.range)
        cooldownSlider:SetValue(Shouter.db.cooldown)
        UIDropDownMenu_SetText(messageTypeDropdown, Shouter.db.messageType == "YELL" and "Yell" or "Say")
        panel:RefreshPlayerList()
    end
    
    -- Add to Interface Options
    InterfaceOptions_AddCategory(panel)
    
    return panel
end

-- Make the function globally accessible
_G.ShouterCreateSettingsPanel = ShouterCreateSettingsPanel