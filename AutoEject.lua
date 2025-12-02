script_name("Auto Eject")
script_author("Rajaneesh_Dev (Discord: rajaneeshr)")
script_version("2.0.0")
require "lib.moonloader"
require "lib.sampfuncs"
require "lib.vkeys"

function main()
    while not isSampLoaded() and not isSampAvailable() and not isSampfuncsLoaded() do
        wait(100)
    end
    pcall(function()
        while true do
            wait(1000)
            if wasKeyPressed(VK_J) then
                if isCharInAnyCar(PLAYER_PED) then
                    local Current_Car = storeCarCharIsInNoSave(PLAYER_PED)
                    local CAR_PLAYER_PED = getDriverOfCar(Current_Car)
                    if CAR_PLAYER_PED == PLAYER_PED then
                        local max_passengers = getMaximumNumberOfPassengers(Current_Car)
                        for seatId = 0, max_passengers - 1 do
                            wait(50)
                            if not isCarPassengerSeatFree(Current_Car, seatId) then
                                local PASSENGER_PED = getCharInCarPassengerSeat(Current_Car, seatId)
                                if doesCharExist(PASSENGER_PED) then
                                    local result, PASSENGER_ID = sampGetPlayerIdByCharHandle(PASSENGER_PED)
                                    if result then
                                        sampSendChat("/eject " .. PASSENGER_ID)
                                    end
                                end
                            end
                        end
                        taskLeaveCar(PLAYER_PED, Current_Car)
                    end
                end
            end
        end
    end)
end
