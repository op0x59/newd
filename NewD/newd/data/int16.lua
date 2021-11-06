-- int16(1)
-- int16('L')
-- int16(byte(1), byte(2))
-- int16(1, 2)
-- int16(byte(1), 2)

local int16 = {}
int16.size = 2
int16.type = 'int16'
setmetatable(int16, {
    __call = function(self, ...)
        local args = {...}
        if #args == 0 then error("Cannot create empty int16.") end
        local data = {bytes = {}, value = nil}
        if #args == int16.size then
            for _,value in pairs(args) do
                if type(value) == "number" then
                    value = byte(value)
                elseif type(value) ~= "table" then
                    error("Cannot create int16 with an unsupported byte type.")
                end
                data.bytes[#data.bytes+1] = value
            end
            data.value = getValueFromBytes(data.bytes[1], data.bytes[2])
            --print(data.value)
        else
            local value = args[1]
            if type(value) == "string" and #value == 1 then
                value = string.byte(value)
            elseif type(value) == "string" and #value > 1 then
                error("Value for int16 must be a character or a valid int16 integer.")
            elseif type(value) ~= "number" then
                error("Cannot create int16 for an unsupported type: " .. type(value) .. ".")
            end
    
            if not (value >= -32768 and value <= 32767) then
                error("Cannot create int16 from number: " .. tostring(value) .. ".")
            end

            data.bytes = getBytesFromValue(value, 2)
            --print(data.bytes[1].value, data.bytes[2].value)
            data.value = value
        end

        function data:getBytes() return data.bytes end

        function data:equals(otherUnit)
            if type(otherUnit) ~= "table" then
                if type(otherUnit) == "string" or type(otherUnit) == "number" then
                    otherUnit = int16(otherUnit)
                else
                    error("Cannot compare a int16 to an unsupported type: " .. type(otherUnit) .. ".")
                end
            end
            
            if otherUnit.size ~= int16.size then return false end
            for i = 1, int16.size do
                if not otherUnit.bytes[i]:equals(data.bytes[i]) then return false end
            end
            return true
        end
        data.size = 2
        data.type = 'int16'
        return data
    end
})

return int16