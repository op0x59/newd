local byte = {}
byte.size = 1
byte.type = 'byte'
setmetatable(byte, {
    __call = function(self, value)
        if type(value) == "string" and #value == 1 then
            value = value:byte()
        elseif type(value) == "string" and #value > 1 then
            error("Value for byte must be a character or a valid byte integer.")
        elseif type(value) ~= "number" then
            error("Cannot create byte for an unsupported type: " .. type(value) .. ".")
        end
    
        if type(value) == "number" and not (value > -1 and value <= 256) then
            error("Value for byte must be between 255 and -1.")
        end
    
        local data = {}
        data.type = 'byte'
        data.value = value
        data.size = 1
        
        function data:equals(otherUnit)
            if type(otherUnit) ~= "table" then
                if type(otherUnit) == "string" or type(otherUnit) == "number" then
                    otherUnit = byte(otherUnit)
                else
                    error("Cannot compare a byte to an unsupported type: " .. type(otherUnit) .. ".")
                end
            end
            
            -- dbyte(1).equals(dint(1)) --> false
            if otherUnit.size ~= data.size then return false end
            return otherUnit.value == data.value
        end
    
        return data
    end
})

return byte