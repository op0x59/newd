-- int32(100)
-- int32('L')
-- int32(byte(0), byte(0), byte(0), byte(10))
-- int32(1, 2, 4, 5)
-- int32(byte(1), 2, 4, 5)

local int32 = {}
int32.size = 4
int32.type = 'int32'
setmetatable(int32, {
    __call = function(self, ...)
        local args = {...}
        if #args == 0 then error("Cannot create empty int32.") end
        local data = {bytes = {}, value = nil}
        if #args == int32.size then
            for _,value in pairs(args) do
                if type(value) == "number" then
                    value = byte(value)
                elseif type(value) ~= "table" then
                    error("Cannot create int32 with an unsupported byte type.")
                end
                data.bytes[#data.bytes+1] = value
            end
            data.value = getValueFromBytes(data.bytes[1], data.bytes[2], data.bytes[3], data.bytes[4])
            --print(data.value)
        else
            local value = args[1]
            if type(value) == "string" and #value == 1 then
                value = string.byte(value)
            elseif type(value) == "string" and #value > 1 then
                error("Value for int32 must be a character or a valid int32 integer.")
            elseif type(value) ~= "number" then
                error("Cannot create int32 for an unsupported type: " .. type(value) .. ".")
            end
    
            if not (value >= -2147483648 and value <= 2147483647) then
                error("Cannot create int32 from number: " .. tostring(value) .. ".")
            end

            data.bytes = getBytesFromValue(value, 4)
            --print(data.bytes[1].value, data.bytes[2].value, data.bytes[3].value, data.bytes[4].value)
            data.value = value
        end

        function data:getBytes() return data.bytes end

        function data:equals(otherUnit)
            if type(otherUnit) ~= "table" then
                if type(otherUnit) == "string" or type(otherUnit) == "number" then
                    otherUnit = int32(otherUnit)
                else
                    error("Cannot compare a int32 to an unsupported type: " .. type(otherUnit) .. ".")
                end
            end
            
            if otherUnit.size ~= int32.size then return false end
            for i = 1, int32.size do
                if not otherUnit.bytes[i]:equals(data.bytes[i]) then return false end
            end
            return true
        end
        data.size = 4
        data.type = 'int32'
        return data
    end
})

return int32