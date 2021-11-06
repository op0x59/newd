local bytelist = {}
bytelist.type = 'bytelist'
setmetatable(bytelist, {
    __call = function(self, ...)
        local data = {}
        data.type = 'bytelist'
        data.bytes = {}
        data.size  = #data.bytes

        function data:add(...)
            local args = {...}
            local argsFilteredBytes = {}
            for _,value in pairs(args) do
                if type(value) == "string"  then
                    for i = 1, #value do
                        argsFilteredBytes[#argsFilteredBytes+1] = byte(value:sub(i,i))
                    end
                elseif type(value) == "table" then
                    if value.size ~= 1 then 
                        for k,b in pairs(value:getBytes()) do
                            argsFilteredBytes[#argsFilteredBytes+1] = b
                        end
                    else
                        argsFilteredBytes[#argsFilteredBytes+1] = value
                    end
                elseif type(value) == "number" then
                    if value > -1 and value <= 256 then
                        argsFilteredBytes[#argsFilteredBytes+1] = byte(value)
                    elseif value >= -32768 and value <= 32767 then
                        -- TODO: Implement getBytes across ALL types including usertype's
                        for k,b in pairs(int16(value):getBytes()) do
                            argsFilteredBytes[#argsFilteredBytes+1] = b
                        end
                    elseif value >= -2147483648 and value <= 2147483647 then
                        for k,b in pairs(int32(value):getBytes()) do
                            argsFilteredBytes[#argsFilteredBytes+1] = b
                        end
                    end
                end
            end

            for k,b in pairs(argsFilteredBytes) do
                self.bytes[#self.bytes+1] = b
            end
            self.size = #self.bytes
            --table.foreach(self.bytes, print)
        end

        function data:toString()
            local s = ''
            for k,v in pairs(self.bytes) do
                s = s .. string.char(v.value)
            end
            return s
        end
        function data:toByteString()
            local s = '['
            for k,v in pairs(self.bytes) do
                s = s .. string.format('%4.4X', v)
            end
            s = s .. ']'
            return s
        end
        function data:getBytes() return self.bytes end
        function data:equals(...)
            local args = {...}
            local value
            if #args == 1 then value = args[1] else value = bytelist(args) end
            if #value.bytes ~= #self.bytes then return false end
            for i = 1, #self.bytes do
                if not value.bytes[i]:equals(self.bytes[i]) then return false end
            end
            return true
        end

        data:add(...)

        return data
    end
})
return bytelist