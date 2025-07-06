local addonName, addon = ...
Shouter = addon
_G.Shouter = addon  -- Make it globally accessible

-- Add debug logging method
function Shouter:DebugLog(message, category)
    return ShouterDebugLog(self, message, category)
end

local defaults = {
    enabled = true,
    range = 30,
    players = {},
    cooldown = 60,
    messageType = "YELL",
}

local lastYellTime = {}

function Shouter:OnInitialize()
    ShouterDB = ShouterDB or {}
    self.db = ShouterDB
    
    for k, v in pairs(defaults) do
        if self.db[k] == nil then
            self.db[k] = v
        end
    end
    
    self:RegisterSlashCommands()
    
    if self.db.enabled then
        self:Enable()
    end
    
    print("|cFF00FF00Shouter|r loaded. Type /shouter for help.")
    
    -- Initialize panels after a short delay
    C_Timer.After(0.5, function()
        self:InitializePanels()
    end)
end

function Shouter:InitializePanels()
    -- Load settings panel
    if not self.settingsPanel then
        print("|cFF00FF00Shouter:|r Loading settings panel...")
        local CreateSettingsPanel = _G.ShouterCreateSettingsPanel
        if CreateSettingsPanel then
            print("|cFF00FF00Shouter:|r Calling CreateSettingsPanel...")
            local success, result = pcall(CreateSettingsPanel)
            if success and result then
                self.settingsPanel = result
                print("|cFF00FF00Shouter:|r Settings panel loaded successfully!")
            else
                print("|cFF00FF00Shouter:|r Settings panel creation failed: " .. tostring(result))
                -- Try creating a simple test panel
                self:CreateSimpleSettingsPanel()
            end
        else
            print("|cFF00FF00Shouter:|r CreateSettingsPanel function not found!")
        end
    end
    
    -- Load debug panel
    if not self.debugPanel then
        local CreateDebugPanel = _G.ShouterCreateDebugPanel
        if CreateDebugPanel then
            local success, result = pcall(CreateDebugPanel)
            if success and result then
                self.debugPanel = result
                print("|cFF00FF00Shouter:|r Debug panel loaded successfully!")
                -- Hook debug functions
                local HookDebugFunctions = _G.ShouterHookDebugFunctions
                if HookDebugFunctions then
                    HookDebugFunctions()
                end
                self:DebugLog("Shouter addon loaded", "System")
            else
                print("|cFF00FF00Shouter:|r Debug panel creation failed: " .. tostring(result))
            end
        else
            print("|cFF00FF00Shouter:|r CreateDebugPanel function not found!")
        end
    end
end

function Shouter:CreateSimpleSettingsPanel()
    print("|cFF00FF00Shouter:|r Creating simple settings panel...")
    local panel = CreateFrame("Frame", "ShouterSimpleSettings", UIParent, "BackdropTemplate")
    panel:SetSize(400, 300)
    panel:SetPoint("CENTER")
    if panel.SetBackdrop then
        panel:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
    end
    panel:SetFrameStrata("DIALOG")
    panel:Hide()
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -20)
    title:SetText("Shouter Settings")
    
    -- Enable checkbox
    local enableCheckbox = CreateFrame("CheckButton", nil, panel, "ChatConfigCheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", 20, -50)
    enableCheckbox.Text:SetText("Enable Shouter")
    enableCheckbox:SetChecked(self.db.enabled)
    enableCheckbox:SetScript("OnClick", function(cb)
        if cb:GetChecked() then
            self:Enable()
        else
            self:Disable()
        end
    end)
    
    -- Message type buttons
    local yellButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    yellButton:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 0, -30)
    yellButton:SetSize(80, 22)
    yellButton:SetText("Use YELL")
    yellButton:SetScript("OnClick", function()
        self.db.messageType = "YELL"
        print("|cFF00FF00Shouter:|r Message type set to yell")
    end)
    
    local sayButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    sayButton:SetPoint("LEFT", yellButton, "RIGHT", 10, 0)
    sayButton:SetSize(80, 22)
    sayButton:SetText("Use SAY")
    sayButton:SetScript("OnClick", function()
        self.db.messageType = "SAY"
        print("|cFF00FF00Shouter:|r Message type set to say")
    end)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    closeButton:SetPoint("BOTTOM", 0, 20)
    closeButton:SetSize(80, 22)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function() panel:Hide() end)
    
    self.settingsPanel = panel
    print("|cFF00FF00Shouter:|r Simple settings panel created!")
    return panel
end

function Shouter:Enable()
    self.db.enabled = true
    self.scanFrame = CreateFrame("Frame")
    self.scanFrame:SetScript("OnUpdate", function(frame, elapsed)
        self:ScanForPlayers()
    end)
    print("|cFF00FF00Shouter|r enabled.")
end

function Shouter:Disable()
    self.db.enabled = false
    if self.scanFrame then
        self.scanFrame:SetScript("OnUpdate", nil)
    end
    print("|cFF00FF00Shouter|r disabled.")
end

function Shouter:ScanForPlayers()
    if not self.db.enabled then return end
    
    local currentTime = GetTime()
    
    for i = 1, 40 do
        local unit = "raid" .. i
        if not UnitExists(unit) then
            unit = "party" .. i
            if i > 4 or not UnitExists(unit) then
                break
            end
        end
        
        local name = UnitName(unit)
        if name and self:IsPlayerTracked(name) then
            local distance = self:GetDistanceToUnit(unit)
            if distance and distance <= self.db.range then
                if not lastYellTime[name] or (currentTime - lastYellTime[name]) >= self.db.cooldown then
                    self:YellForPlayer(name, distance)
                    lastYellTime[name] = currentTime
                end
            end
        end
    end
end

function Shouter:GetDistanceToUnit(unit)
    local y1, x1, _, instance1 = UnitPosition("player")
    local y2, x2, _, instance2 = UnitPosition(unit)
    
    if not (x1 and x2 and instance1 == instance2) then
        return nil
    end
    
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

function Shouter:IsPlayerTracked(name)
    for _, trackedName in ipairs(self.db.players) do
        if string.lower(trackedName) == string.lower(name) then
            return true
        end
    end
    return false
end

function Shouter:YellForPlayer(name, distance)
    local message = string.format("%s!", name)
    SendChatMessage(message, self.db.messageType)
    print(string.format("|cFF00FF00Shouter:|r %s (%.1f yards away) (%s)", message, distance, string.lower(self.db.messageType)))
end

function Shouter:AddPlayer(name)
    if self:IsPlayerTracked(name) then
        print("|cFF00FF00Shouter:|r " .. name .. " is already being tracked.")
        return
    end
    
    table.insert(self.db.players, name)
    print("|cFF00FF00Shouter:|r Now tracking " .. name)
end

function Shouter:RemovePlayer(name)
    for i, trackedName in ipairs(self.db.players) do
        if string.lower(trackedName) == string.lower(name) then
            table.remove(self.db.players, i)
            print("|cFF00FF00Shouter:|r No longer tracking " .. trackedName)
            return
        end
    end
    print("|cFF00FF00Shouter:|r " .. name .. " was not being tracked.")
end

function Shouter:ListPlayers()
    if #self.db.players == 0 then
        print("|cFF00FF00Shouter:|r No players are being tracked.")
        return
    end
    
    print("|cFF00FF00Shouter:|r Tracking the following players:")
    for i, name in ipairs(self.db.players) do
        print("  " .. i .. ". " .. name)
    end
end

function Shouter:RegisterSlashCommands()
    SLASH_SHOUTER1 = "/shouter"
    SLASH_SHOUTER2 = "/shout"
    
    SlashCmdList["SHOUTER"] = function(msg)
        local command, arg = msg:match("(%S+)%s*(.*)")
        command = command and command:lower() or ""
        
        if command == "add" and arg ~= "" then
            self:AddPlayer(arg)
        elseif command == "remove" and arg ~= "" then
            self:RemovePlayer(arg)
        elseif command == "list" then
            self:ListPlayers()
        elseif command == "range" and tonumber(arg) then
            self.db.range = tonumber(arg)
            print("|cFF00FF00Shouter:|r Range set to " .. self.db.range .. " yards")
        elseif command == "cooldown" and tonumber(arg) then
            self.db.cooldown = tonumber(arg)
            print("|cFF00FF00Shouter:|r Cooldown set to " .. self.db.cooldown .. " seconds")
        elseif command == "messagetype" and arg ~= "" then
            arg = arg:upper()
            if arg == "YELL" or arg == "SAY" then
                self.db.messageType = arg
                print("|cFF00FF00Shouter:|r Message type set to " .. arg:lower())
            else
                print("|cFF00FF00Shouter:|r Invalid message type. Use 'yell' or 'say'")
            end
        elseif command == "enable" then
            self:Enable()
        elseif command == "disable" then
            self:Disable()
        elseif command == "clear" then
            self.db.players = {}
            print("|cFF00FF00Shouter:|r Cleared all tracked players.")
        elseif command == "config" or command == "settings" then
            if self.settingsPanel then
                -- For Classic WoW, show the panel directly
                self.settingsPanel:Show()
                print("|cFF00FF00Shouter:|r Settings panel opened.")
            else
                print("|cFF00FF00Shouter:|r Settings panel not loaded yet. Try again in a moment.")
                -- Try to force load it
                self:InitializePanels()
            end
        elseif command == "show" then
            if self.settingsPanel then
                self.settingsPanel:Show()
                print("|cFF00FF00Shouter:|r Settings panel shown.")
            else
                print("|cFF00FF00Shouter:|r Settings panel not loaded.")
                self:InitializePanels()
            end
        elseif command == "debug" then
            print("|cFF00FF00Shouter:|r Debug info:")
            print("  - Addon loaded: " .. (self.db and "yes" or "no"))
            print("  - Settings panel: " .. (self.settingsPanel and "loaded" or "not loaded"))
            print("  - Debug panel: " .. (self.debugPanel and "loaded" or "not loaded"))
            print("  - Message type: " .. (self.db and self.db.messageType or "unknown"))
            print("  - CreateSettingsPanel function: " .. (_G.ShouterCreateSettingsPanel and "found" or "missing"))
            print("  - CreateDebugPanel function: " .. (_G.ShouterCreateDebugPanel and "found" or "missing"))
            if self.settingsPanel then
                print("  - Settings panel visible: " .. (self.settingsPanel:IsVisible() and "yes" or "no"))
                print("  - Settings panel type: " .. type(self.settingsPanel))
            end
        elseif command == "force" then
            if self.settingsPanel then
                print("|cFF00FF00Shouter:|r Force showing settings panel...")
                self.settingsPanel:SetAlpha(1)
                self.settingsPanel:Show()
                self.settingsPanel:Raise()
                print("|cFF00FF00Shouter:|r Panel should be visible now.")
            else
                print("|cFF00FF00Shouter:|r No settings panel to show.")
            end
        else
            print("|cFF00FF00Shouter|r Commands:")
            print("  /shouter add <name> - Add a player to track")
            print("  /shouter remove <name> - Remove a tracked player")
            print("  /shouter list - List all tracked players")
            print("  /shouter range <number> - Set detection range (default: 30 yards)")
            print("  /shouter cooldown <number> - Set yell cooldown (default: 60 seconds)")
            print("  /shouter messagetype <yell|say> - Set message type")
            print("  /shouter enable - Enable the addon")
            print("  /shouter disable - Disable the addon")
            print("  /shouter clear - Remove all tracked players")
            print("  /shouter config - Open settings panel")
            print("  /shouter show - Show settings panel directly")
            print("  /shouter force - Force show settings panel")
            print("  /shouter debug - Show debug information")
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        Shouter:OnInitialize()
    elseif event == "PLAYER_LOGIN" then
        -- Ensure settings are fully loaded after login
        C_Timer.After(1, function()
            if Shouter.settingsPanel and Shouter.settingsPanel.refresh then
                Shouter.settingsPanel.refresh()
            end
        end)
    end
end)