script_name("AutoGarbageTruck")
script_description("Automate the Garbage Truck Commands in Horizon Roleplay")
script_version("1.1.0")
script_author("Rajaneesh R (Discord: rajaneeshr)")

require "lib.moonloader"
local sampev = require "lib.samp.events"
local game_models = require "lib.game.models"

local garbageTruckHandle
local playerIsInGarbageTruck = false
local startedJob = false
local isPlayerMuted = false
function main()
    while true do
        wait(0)
        while isPlayerMuted do
            wait(10 * 1000)
        end
        if playerIsInGarbageTruck and not startedJob then
            startedJob = true
            done, result = pcall(function()
                while not isCharInCar(PLAYER_PED, garbageTruckHandle) do
                    wait(150)
                end
                sampSendChat("/pickuptrash")
            end)
        end
    end
end

function sampev.onServerMessage(color, message)
    if string.sub(message, 1, 48) == "You have been muted automatically for spamming. " then
        isPlayerMuted = true
        return false
    elseif message == "You are muted from submitting commands right now." then
        isPlayerMuted = true
    elseif startedJob and string.match(message, "Please ensure that your current checkpoint is destroyed first") then
        sampSendChat("/killcheckpoint")
        removeWaypoint()
        sampSendChat("/pickuptrash")
        return false
    elseif string.match(message, "Return the garbage truck to the department of sanitation") then
    elseif string.match(message, "You have been paid") and
        string.match(message, "for picking up garbage and returning the garbage truck") then
        playerIsInGarbageTruck = false
        startedJob = false
        removeWaypoint()
    elseif string.match(message, "All current checkpoints, trackers and accepted fares have been reset") then
        -- return false
    end

    return true
end

function sampev.onSendEnterVehicle(vehicleId, isPassenger)
    _, vehicleHandle = sampGetCarHandleBySampVehicleId(vehicleId)
    if vehicleHandle ~= nil and doesVehicleExist(vehicleHandle) then
        garbageTruckHandle = vehicleHandle
        local vehicleModel = getCarModel(vehicleHandle)
        if vehicleModel == game_models.TRASH then
            playerIsInGarbageTruck = true
        end
    end
end
function sampev.onSendExitVehicle(vehicleId)
    lua_thread.create(function()
        _, vehicleHandle = sampGetCarHandleBySampVehicleId(vehicleId)
        if vehicleHandle ~= nil and doesVehicleExist(vehicleHandle) then
            garbageTruckHandle = vehicleHandle
            local vehicleModel = getCarModel(vehicleHandle)
            if vehicleModel == game_models.TRASH and startedJob then
                wait(100)
                sampSendChat("/killcheckpoint")
                removeWaypoint()
                playerIsInGarbageTruck = false
                startedJob = false
            end
        end
    end)

end
function sampev.onSetCheckpoint(pos, radius)
    if playerIsInGarbageTruck and startedJob then
        -- print(pos.x, pos.y, pos.z, radius)
        placeWaypoint(pos.x, pos.y, pos.z)
        if math.abs(pos.x - 1423.8372802734) < 0.01 and math.abs(pos.y + 1318.9272460938) < 0.01 and
            math.abs(pos.z - 13.554699897766) < 0.01 and math.abs(radius - 5) < 0.01 then
            sampAddChatMessage(
                "{aaaaaa}[{33ccff}AGT{aaaaaa}] {ffffff}You will be picking up the trash from {4f5bae}Downtown Los Santos {aaaaaa}", -1)
            sampAddChatMessage("{aaaaaa}[{33ccff}AGT{aaaaaa}] {33ccff}Landmark{aaaaaa}: {4f5bae}Materials Pickup 1 {ffffff}Alley Way", -1)
            printStringNow("Go to ~b~~h~Downtown Los Santos", 5000)
        elseif math.abs(pos.x - 1142.04296875) < 0.01 and math.abs(pos.y + 1350.2926025391) < 0.01 and
            math.abs(pos.z - 13.677399635315) < 0.01 and math.abs(radius - 5) < 0.01 then
            sampAddChatMessage(
                "{aaaaaa}[{33ccff}AGT{aaaaaa}] {ffffff}You will be picking up the trash from Market {aaaaaa}", -1)
            sampAddChatMessage("{aaaaaa}[{33ccff}AGT{aaaaaa}] {33ccff}Landmark{aaaaaa}: {ffffff}(behind) {4f5bae}All Saints General Hospital.", -1)
            printStringNow("Go to ~b~~h~Market", 5000)
        elseif math.abs(pos.x - 1665.3306884766) < 0.01 and math.abs(pos.y + 1002.8746948242) < 0.01 and
            math.abs(pos.z - 24.05590057373) < 0.01 and math.abs(radius - 5) < 0.01 then
            sampAddChatMessage(
                "{aaaaaa}[{33ccff}AGT{aaaaaa}] {ffffff}You will be picking up the trash from {4f5bae}Mulholland Intersection {aaaaaa}", -1)
            sampAddChatMessage(
                "{aaaaaa}[{33ccff}AGT{aaaaaa}] {33ccff}Landmark{aaaaaa}: {ffffff}Parking Lot next to the {4f5bae}Bank of Los Santos {ffffff}under the bridge.", -1)
            printStringNow("Go to ~b~~h~Mulholland Intersection", 5000)
        elseif math.abs(pos.x - 2484.8706054688) < 0.01 and math.abs(pos.y + 2529.1831054688) < 0.01 and
            math.abs(pos.z - 13.543171882629) < 0.01 and math.abs(radius - 5) < 0.01 then
            sampAddChatMessage("{aaaaaa}[{33ccff}AGT{aaaaaa}] {ffffff}Return back to {4f5bae}Ocean Docks {aaaaaa}", -1)
            sampAddChatMessage("{aaaaaa}[{33ccff}AGT{aaaaaa}] {33ccff}Landmark{aaaaaa}: {4f5bae}Department of Sanitation", -1)
            printStringNow("Return to ~b~~h~Ocean Docks", 5000)

        end

    end

end
