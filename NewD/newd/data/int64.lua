-- int64(100)
-- int64('L')
-- int64(byte(0), byte(0), byte(0), byte(10))
-- int64(1, 2, 4, 5)
-- int64(byte(1), 2, 4, 5)

local int64 = {}
int64.size = 8
int64.type = 'int64'
setmetatable(int64, {
    __call = function(self, ...)
        local args = {...}
        if #args == 0 then error("Cannot create empty int64.") end
        local data = {bytes = {}, value = nil}
        if #args == int64.size then
            for _,value in pairs(args) do
                if type(value) == "number" then
                    value = byte(value)
                elseif type(value) ~= "table" then
                    error("Cannot create int64 with an unsupported byte type.")
                end
                data.bytes[#data.bytes+1] = value
            end
            data.value = getValueFromBytes(unpack(data.bytes))
            --print(data.value)
        else
            local value = args[1]
            if type(value) == "string" and #value == 1 then
                value = string.byte(value)
            elseif type(value) == "string" and #value > 1 then
                error("Value for int64 must be a character or a valid int64 integer.")
            elseif type(value) ~= "number" then
                error("Cannot create int64 for an unsupported type: " .. type(value) .. ".")
            end
    
            if not (value >= -9223372036854775808 and value <= 9223372036854775807) then
                error("Cannot create int64 from number: " .. tostring(value) .. ".")
            end

            data.bytes = getBytesFromValue(value, 8)
            --print(data.bytes[1].value, data.bytes[2].value, data.bytes[3].value, data.bytes[4].value)
            data.value = value
        end

        function data:getBytes() return data.bytes end

        function data:equals(otherUnit)
            if type(otherUnit) ~= "table" then
                if type(otherUnit) == "string" or type(otherUnit) == "number" then
                    otherUnit = int64(otherUnit)
                else
                    error("Cannot compare a int64 to an unsupported type: " .. type(otherUnit) .. ".")
                end
            end
            
            if otherUnit.size ~= int64.size then return false end
            for i = 1, int64.size do
                if not otherUnit.bytes[i]:equals(data.bytes[i]) then return false end
            end
            return true
        end
        data.size = 8
        data.type = 'int64'
        return data
    end
})

return int64
