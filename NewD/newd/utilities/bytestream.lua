local bytestream = {}
bytestream.__index = bytestream

function bytestream.new(bytecode)
    local self = setmetatable({}, bytestream)

    if type(bytecode) == "string" then
        local tmp = bytecode
        bytecode = {}
        for i = 1, #tmp do
            bytecode[i] = string.sub(tmp,i,i)
        end
    end

    self.readIndex = 0
    self.bytecode = bytecode

    return self
end

function bytestream:readBytelist(size)
    local bytes = {}
    for i = self.readIndex+1, self.readIndex+size do
        bytes[#bytes+1] = byte(self.bytecode[i])
        self.readIndex = self.readIndex + 1
    end
    return bytelist(unpack(bytes))
end

local function tableResize(tab)
    local t = {}
    for k,v in pairs(tab) do t[#t+1] = v end
    return t
end

function bytestream:readUsertype(unit, sizes)
    local readTypes = {}
    for key,type in pairs(unit.constructorTypes) do
        if type.type ~= 'bytelist' and not type.usertype then
            readTypes[#readTypes+1] = self:read(type, sizes)
        elseif type.type == 'bytelist' then
            readTypes[#readTypes+1] = self:readBytelist(sizes[1])
            table.remove(sizes, 1)
            sizes = tableResize(sizes)
        elseif type.usertype then
            local v,s = self:readUsertype(type, sizes)
            readTypes[#readTypes+1] = v
            sizes = s
        end
    end
    return unit(unpack(readTypes)), sizes, readTypes
end

function bytestream:read(unit, ...)
    local sizes = {...}
    if unit.type ~= 'bytelist' then
        if not unit.usertype then
            local bytes = {}
            for i = self.readIndex+1, self.readIndex+unit.size do
                bytes[#bytes+1] = byte(self.bytecode[i])
                self.readIndex = self.readIndex + 1
            end
            if unit.size == 1 then return bytes[1] end
            return unit(unpack(bytes))
        else
            local value, sizes, typesRead = self:readUsertype(unit, sizes)
            return value
        end
    else
        return self:readBytelist(sizes[1])
    end
end

return bytestream