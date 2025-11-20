script_name("AdvancedFrequencyUpdater")
script_description("Automate Radio Frequency Updation with time-based hashing for private environments")
script_version("2.1.0")
script_author("Rajaneesh_Dev (Discord: rajaneeshr)")

require "lib.moonloader"
local inicfg = require 'inicfg'
local sampev = require 'lib.samp.events'
local imgui = require 'mimgui'
local encoding = require 'encoding'
local ffi = require 'ffi'
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- Config setup
local defaultIni = {settings={secretCode="", updateInterval=3600, autoEnabled=true, hideFreq=false, maskString="####"}}

local mainIni = inicfg.load(defaultIni, "AdvancedFrequencyUpdater.ini")
if not mainIni then
    mainIni = defaultIni
    inicfg.save(mainIni, "AdvancedFrequencyUpdater.ini")
end

-- Mimgui State Variables
local winState = imgui.new.bool(false)
local bufCode = imgui.new.char[256](mainIni.settings.secretCode)
local bufInterval = imgui.new.int(mainIni.settings.updateInterval)
local bufMask = imgui.new.char[50](mainIni.settings.maskString)
local bufAuto = imgui.new.bool(mainIni.settings.autoEnabled)
local bufHide = imgui.new.bool(mainIni.settings.hideFreq)
local showPassword = imgui.new.bool(false)

local updateThread = nil

local PREFIX = "{B2BEC3}[{D4AF37}AdvFreq{B2BEC3}]{FFFFFF} "
local COL_HIGHLIGHT = "{FAD02E}" -- Bright Gold for values
local COL_ERROR = "{FF7675}" -- Soft Red for warnings

imgui.OnInitialize(function()
    local style = imgui.GetStyle()
    style.WindowPadding = imgui.ImVec2(10, 10)
    style.FramePadding = imgui.ImVec2(6, 4)
    style.ItemSpacing = imgui.ImVec2(6, 6)
    style.ScrollbarSize = 12
    style.ScrollbarRounding = 8
    style.GrabRounding = 8
    style.WindowRounding = 8
    style.FrameRounding = 6

    local colors = style.Colors
    -- Backgrounds: Deep Carbon/Black
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.10, 0.09, 0.09, 1.00)
    colors[imgui.Col.FrameBg] = imgui.ImVec4(0.16, 0.14, 0.14, 1.00)

    -- Headers: Warm Grey
    colors[imgui.Col.Header] = imgui.ImVec4(0.22, 0.20, 0.20, 1.00)
    colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.28, 0.24, 0.24, 1.00)
    colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.32, 0.28, 0.28, 1.00)

    -- Buttons & Accents: Metallic Rose Gold (approx #B76E79)
    colors[imgui.Col.Button] = imgui.ImVec4(0.72, 0.43, 0.47, 0.60)
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.82, 0.53, 0.57, 1.00)
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.62, 0.33, 0.37, 1.00)

    -- Title & Checkmarks
    colors[imgui.Col.TitleBg] = imgui.ImVec4(0.10, 0.09, 0.09, 1.00)
    colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.45, 0.27, 0.30, 1.00) -- Active title glows rose
    colors[imgui.Col.CheckMark] = imgui.ImVec4(0.85, 0.55, 0.60, 1.00)
    -- Text Color: Slightly warm white
    colors[imgui.Col.Text] = imgui.ImVec4(0.95, 0.92, 0.92, 1.00)
end)

-- GUI Frame Layout
imgui.OnFrame(function()
    return winState[0]
end, function(player)
    imgui.SetNextWindowSize(imgui.ImVec2(360, 380), imgui.Cond.FirstUseEver)

    imgui.Begin(u8 "Advanced Frequency Updater v"..script.this.version, winState, imgui.WindowFlags.NoCollapse)

    imgui.TextDisabled(u8 "Configuration")
    imgui.Separator()
    imgui.Text(u8 "Secret Code:")
    imgui.PushItemWidth(-1)

    local flags = imgui.InputTextFlags.Password
    if showPassword[0] then
        flags = 0
    end

    imgui.InputText("##code", bufCode, 256, flags)
    imgui.PopItemWidth()

    imgui.Checkbox(u8 "Show Secret Code", showPassword)

    imgui.Spacing()
    imgui.Text(u8 "Update Interval (Seconds):")
    imgui.PushItemWidth(-1)
    imgui.InputInt("##interval", bufInterval)
    imgui.PopItemWidth()

    imgui.Spacing()
    imgui.Checkbox(u8 "Enable Automation", bufAuto)
    imgui.Checkbox(u8 "Hide Frequency Numbers in Chat", bufHide)

    -- Mask String (Only show if Hiding is enabled)
    if bufHide[0] then
        imgui.Indent()
        imgui.Text(u8 "Mask String:")
        imgui.PushItemWidth(150)
        imgui.InputText("##mask", bufMask, 50)
        imgui.PopItemWidth()
        imgui.Unindent()
    end

    imgui.Spacing()
    imgui.Separator()
    imgui.Spacing()

    -- Save Button
    if imgui.Button(u8 "SAVE SETTINGS", imgui.ImVec2(-1, 30)) then
        saveSettings()
    end

    -- Manual Update Button
    imgui.Spacing()
    if imgui.Button(u8 "Force Update Now", imgui.ImVec2(-1, 25)) then
        cmd_updatefreqnow()
    end

    imgui.End()
end)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then
        return
    end
    while not isSampAvailable() do
        wait(100)
    end

    sampRegisterChatCommand("advfreq", function()
        winState[0] = not winState[0]
    end)
    sampRegisterChatCommand("advfreqnow", cmd_updatefreqnow)

    sampAddChatMessage(PREFIX .. "Script Loaded. Type " .. COL_HIGHLIGHT .. "/advfreq{FFFFFF} to open the menu.", -1)

    if mainIni.settings.autoEnabled then
        if mainIni.settings.secretCode == "" then
            sampAddChatMessage(PREFIX .. COL_ERROR .. "Warning: No secret code set. Open /advfreq to configure.", -1)
        else
            startAutomation()
        end
    end

    wait(-1)
end

function saveSettings()
    local newInterval = bufInterval[0]
    if newInterval < 15 then
        newInterval = 15
        bufInterval[0] = 15
        sampAddChatMessage(PREFIX .. COL_ERROR .. "Interval too low! Reset to 15s.", -1)
    end
    showPassword[0] = false

    mainIni.settings.secretCode = u8:decode(ffi.string(bufCode))
    mainIni.settings.updateInterval = newInterval
    mainIni.settings.autoEnabled = bufAuto[0]
    mainIni.settings.hideFreq = bufHide[0]
    mainIni.settings.maskString = u8:decode(ffi.string(bufMask))

    if inicfg.save(mainIni, "AdvancedFrequencyUpdater.ini") then
        sampAddChatMessage(PREFIX .. "Settings Saved successfully.", -1)

        if mainIni.settings.autoEnabled then
            startAutomation()
        else
            if updateThread then
                updateThread:terminate()
                updateThread = nil
            end
            sampAddChatMessage(PREFIX .. "Automation " .. COL_ERROR .. "STOPPED{FFFFFF}.", -1)
        end
    else
        sampAddChatMessage(PREFIX .. COL_ERROR .. "Failed to save settings.", -1)
    end
end

function startAutomation()
    if updateThread then
        updateThread:terminate()
    end
    updateThread = lua_thread.create(automationLoop)
    sampAddChatMessage(PREFIX .. "Automation " .. COL_HIGHLIGHT .. "STARTED{FFFFFF}.", -1)
end

function sampev.onServerMessage(color, message)
    if mainIni.settings.hideFreq then
        if message:match("**.Radio %(.+% kHz%).%**.+[a-zA-Z_]+%:") and color == 1845194239 then
            local replacement = "(" .. mainIni.settings.maskString .. " kHz)"
            message = message:gsub("%(.+% kHz%)", replacement, 1)
            sampAddChatMessage(message, 7207789)
            return false
        end

        if message:match("You have set the frequency of your portable radio to .+kHz") then
            return false
        end
    end
end

function cmd_updatefreqnow()
    if mainIni.settings.secretCode ~= "" then
        local interval = mainIni.settings.updateInterval
        local now = os.time()

        local currentSlot = math.floor(now / interval)

        local payload = mainIni.settings.secretCode .. tostring(currentSlot) ..
                            tostring(mainIni.settings.updateInterval)
        local hashedValue = simpleHash(payload) or 0

        sampSendChat(string.format("/setfreq %d", hashedValue))
        print(string.format("[AdvFreq] Synced Update: %d (Window: %d)", hashedValue, currentSlot))

        if mainIni.settings.hideFreq then
            sampAddChatMessage(PREFIX .. "Frequency updated (Masked).", -1)
        else
            sampAddChatMessage(string.format("%sFrequency updated to " .. COL_HIGHLIGHT .. "%d{FFFFFF}.", PREFIX,
                hashedValue), -1)
        end
    else
        sampAddChatMessage(PREFIX .. COL_ERROR .. "No Code set. Open /advfreq to configure.", -1)
    end
end

function automationLoop()
    while mainIni.settings.autoEnabled do
        if mainIni.settings.secretCode ~= "" then
            local interval = mainIni.settings.updateInterval
            local now = os.time()

            local currentSlot = math.floor(now / interval)

            local payload = mainIni.settings.secretCode .. tostring(currentSlot) ..
                                tostring(mainIni.settings.updateInterval)
            local hashedValue = simpleHash(payload) or 0

            sampSendChat(string.format("/setfreq %d", hashedValue))
            print(string.format("[AdvFreq] Synced Update: %d (Window: %d)", hashedValue, currentSlot))

            if mainIni.settings.hideFreq then
                sampAddChatMessage(PREFIX .. "Frequency updated (Masked).", -1)
            else
                sampAddChatMessage(string.format("%sFrequency updated to " .. COL_HIGHLIGHT .. "%d{FFFFFF}.", PREFIX,
                    hashedValue), -1)
            end

            local nextSlotTime = (currentSlot + 1) * interval
            local waitSeconds = nextSlotTime - os.time()

            if waitSeconds < 1 then
                waitSeconds = 1
            end

            wait(waitSeconds * 1000)
        else
            wait(1000)
        end
    end
end

function simpleHash(str)
    local hash = 5381
    for i = 1, #str do
        local char = string.byte(str, i)
        hash = ((hash * 33) + char) % 4294967296
    end
    local result = math.floor((hash % 19999999) - 9999999)

    if result == 0 then
        return 1
    end
    if result == -1 then
        return -2
    end

    return result
end
