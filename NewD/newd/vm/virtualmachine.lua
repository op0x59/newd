__numberOfVirtualMachines = 0
local virtualMachine = {}
virtualMachine.__index = virtualMachine

function virtualMachine.new(constructor)
    __numberOfVirtualMachines = __numberOfVirtualMachines + 1
    local self = setmetatable({}, virtualMachine)

    self.signature = {};
    self.virtualMachineName = "unknown(" .. tostring(__numberOfVirtualMachines) .. ")"
    self = constructor(self)

    return self
end

function virtualMachine:isSignaturePresent(bytecode)
    local stream = bytestream.new(bytecode)
    for i = 1, #self.signature do
        local signature = self.signature[i]
        local unit = stream:read(_G[signature.type])
        if not unit:equals(signature.value) then 
            print(unit.value, signature.value)
            return false
        end
    end
    return true
end

return virtualMachine