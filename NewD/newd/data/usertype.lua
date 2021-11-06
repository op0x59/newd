return function(name, struct)
    local newtype = {}
    newtype.type = name
    newtype.usertype = true
    newtype.constructorTypes = struct

    setmetatable(newtype, {
        __call = function(self, ...)
            local args = {...}
            if #args ~= #struct then error("Cannot instantiate type " .. name .. " invalid # of arguments.") end
            for _,value in pairs(args) do
                if type(value) ~= 'table' then
                    if type(value) == "string"  then
                        if #value > 1 then
                            value = bytelist(value)
                        else
                            value = byte(value:byte())
                        end
                    elseif type(value) == "number" then
                        value = _G[struct[_].type](value)
                    end
                end
                if value.type ~= struct[_].type then
                    error("Type mismatch for " .. name .. " of " .. value.type .. ":" .. struct[_].type)
                end
                args[_] = value
            end

            local data = {}
            data.type = name
            data.values = args

            function data:getBytes()
                local bytes = {}
                for k,value in pairs(data.values) do
                    if value.size ~= 1 then
                        for k,b in pairs(value:getBytes()) do
                            bytes[#bytes+1] = b
                        end
                    else
                        bytes[#bytes+1] = b 
                    end
                end
                return bytes
            end

            function data:equals(otherUnit)
                if type(otherUnit) ~= 'table' then return false end
                if otherUnit.type ~= self.type then return false end
                for key,value in pairs(otherUnit.values) do
                    if not self.values[key]:equals(value) then 
                        print('doesnt equal')
                        return false 
                    end
                end
                return true
            end
            return data
        end
    })

    _G[name] = newtype
    return newtype
end