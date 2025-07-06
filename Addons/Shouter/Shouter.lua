local addonName, addon = ...
Shouter = addon

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

function Shouter:TestRange()
    print("|cFF00FF00Shouter:|r Testing range detection...")
    print("|cFF00FF00Shouter:|r Current settings: " .. self.db.range .. " yards, " .. string.lower(self.db.messageType) .. " messages")
    
    if #self.db.players == 0 then
        print("|cFF00FF00Shouter:|r No players are being tracked. Add some with /shouter add <name>")
        return
    end
    
    local foundPlayers = 0
    local nearbyPlayers = 0
    
    -- Check party members
    for i = 1, 4 do
        local unit = "party" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name then
                local distance = self:GetDistanceToUnit(unit)
                if distance then
                    nearbyPlayers = nearbyPlayers + 1
                    if self:IsPlayerTracked(name) then
                        foundPlayers = foundPlayers + 1
                        if distance <= self.db.range then
                            print("|cFFFF0000Shouter:|r WOULD ALERT: " .. name .. " is " .. string.format("%.1f", distance) .. " yards away!")
                        else
                            print("|cFFFFFF00Shouter:|r " .. name .. " is " .. string.format("%.1f", distance) .. " yards away (outside range)")
                        end
                    else
                        print("|cFF888888Shouter:|r " .. name .. " is " .. string.format("%.1f", distance) .. " yards away (not tracked)")
                    end
                else
                    if self:IsPlayerTracked(name) then
                        print("|cFFFFFF00Shouter:|r " .. name .. " is in party but distance unknown")
                    end
                end
            end
        end
    end
    
    -- Check raid members
    for i = 1, 40 do
        local unit = "raid" .. i
        if UnitExists(unit) then
            local name = UnitName(unit)
            if name then
                local distance = self:GetDistanceToUnit(unit)
                if distance then
                    nearbyPlayers = nearbyPlayers + 1
                    if self:IsPlayerTracked(name) then
                        foundPlayers = foundPlayers + 1
                        if distance <= self.db.range then
                            print("|cFFFF0000Shouter:|r WOULD ALERT: " .. name .. " is " .. string.format("%.1f", distance) .. " yards away!")
                        else
                            print("|cFFFFFF00Shouter:|r " .. name .. " is " .. string.format("%.1f", distance) .. " yards away (outside range)")
                        end
                    else
                        print("|cFF888888Shouter:|r " .. name .. " is " .. string.format("%.1f", distance) .. " yards away (not tracked)")
                    end
                else
                    if self:IsPlayerTracked(name) then
                        print("|cFFFFFF00Shouter:|r " .. name .. " is in raid but distance unknown")
                    end
                end
            end
        end
    end
    
    print("|cFF00FF00Shouter:|r Test complete. Found " .. nearbyPlayers .. " nearby players, " .. foundPlayers .. " are tracked.")
    
    if nearbyPlayers == 0 then
        print("|cFF00FF00Shouter:|r No party/raid members found. Make sure you're in a group to test!")
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
        elseif command == "test" then
            self:TestRange()
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
            print("  /shouter test - Test range detection (shows who's nearby)")
        end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        Shouter:OnInitialize()
    end
end)