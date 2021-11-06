require("newd/utilities/logic")
textstream = require("newd/utilities/textstream")
bytestream = require("newd/utilities/bytestream")
byte = require("newd/data/byte")
bytelist = require("newd/data/bytelist")
int16 = require("newd/data/int16")
int32 = require("newd/data/int32")
int64 = require("newd/data/int64")
usertype = require("newd/data/usertype")

local newd = {}

newd.configuration = {
    ["lvm51"] = require("newd/configurations/lvm51")
}

function newd.bruteforce(bytecode)
    local selectedConfiguration = nil
    for key, configuration in pairs(newd.configuration) do
        if configuration:isSignaturePresent(bytecode) then
            print("[NEWD] - detected virtual machine signature " .. configuration.virtualMachineName)
            selectedConfiguration = configuration
            break
        end
    end
    if selectedConfiguration == nil then
        error("[NEWD] - could not find a possible configuration.")
    end
    local chunk = selectedConfiguration:deserialize(bytecode)
    selectedConfiguration:dump(chunk)
end

return newd