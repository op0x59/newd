local registerSignatures = {
    sig0 = {"sBx"},
    sig1 = {"A"},
    sig2 = {"A", "B"},
    sig3 = {"A", "Bx"},
    sig4 = {"A", "C"},
    sig5 = {"A", "sBx"},
    sig6 = {"A", "B", "C"}
}

return require("newd/vm/virtualmachine").new(function(self)
    self.virtualMachineName = "LuaQ VM"
    self.instructionLookup = {
        [0] = 'move', [1] = 'loadk', [2] = 'loadbool',
        [3] = 'loadnil', [4] = 'getupval', [5] = 'getglobal',
        [6] = 'gettable', [7] = 'setglobal', [8] = 'setupval',
        [9] = 'settable', [10] = 'newtable', [11] = 'self',
        [12] = 'add', [13] = 'sub', [14] = 'mul', [15] = 'div',
        [16] = 'mod', [17] = 'pow', [18] = 'unm', [19] = 'not',
        [20] = 'len', [21] = 'concat', [22] = 'jmp', [23] = 'eq',
        [24] = 'lt', [25] = 'le', [26] = 'test', [27] = 'testset',
        [28] = 'call', [29] = 'tailcall', [30] = 'return',
        [31] = 'forloop', [32] = 'forprep', [33] = 'tforloop',
        [34] = 'setlist', [35] = 'close', [36] = 'closure', 
        [37] = 'vararg'
    }
    self.instructionRegisterSignatures = {
        [0] = registerSignatures.sig2, [1] = registerSignatures.sig3, [2] = registerSignatures.sig6,
        [3] = registerSignatures.sig1, [4] = registerSignatures.sig1, [5] = registerSignatures.sig3,
        [6] = registerSignatures.sig5, [7] = registerSignatures.sig2, [8] = registerSignatures.sig1,
        [9] = registerSignatures.sig5, [10] = registerSignatures.sig5, [11] = registerSignatures.sig5,
        [12] = registerSignatures.sig5, [13] = registerSignatures.sig5, [14] = registerSignatures.sig5,
        [15] = registerSignatures.sig5, [16] = registerSignatures.sig5, [17] = registerSignatures.sig5,
        [18] = registerSignatures.sig1, [19] = registerSignatures.sig1, [20] = registerSignatures.sig1,
        [21] = registerSignatures.sig5, [22] = registerSignatures.sig0, [23] = registerSignatures.sig6,
        [24] = registerSignatures.sig5, [25] = registerSignatures.sig5, [26] = registerSignatures.sig3,
        [27] = registerSignatures.sig5, [28] = registerSignatures.sig6, [29] = registerSignatures.sig5,
        [30] = registerSignatures.sig2, [31] = registerSignatures.sig5, [32] = registerSignatures.sig4,
        [33] = registerSignatures.sig3, [34] = registerSignatures.sig5, [35] = registerSignatures.sig0,
        [36] = registerSignatures.sig3, [37] = registerSignatures.sig1
    }
    self.signature = {
        [1] = byte(27),  [2] = byte(76),
        [3] = byte(117), [4] = byte(97),
        [5] = byte(81)
    }

    function self:deserialize(bytecode)
        local stream = bytestream.new(bytecode)
        usertype("vheader", {bytelist, byte, byte, byte, byte, byte})
        usertype("instruction", {int32})
        usertype("constant", {byte, bytelist})
        
        local virtualHeader = vheader(
            stream:read(bytelist, 4),
            stream:read(byte),
            stream:read(byte),
            stream:read(byte),
            stream:read(byte),
            stream:read(byte)
        )

        assert(virtualHeader.values[1]:equals(bytelist(27, 76, 117, 97)), 
            "Something is wrong with signature scanning."
        )
        assert(virtualHeader.values[2]:equals(0x51), 
            "Something is wrong with signature scanning."
        )
        assert(stream:read(bytelist, 3):equals(bytelist(4, 8, 0)),
            "Something is wrong with bytelist reading."
        )

        if virtualHeader.values[5]:equals(8) then
            _G["lnumber"] = int64
        elseif virtualHeader.values[5]:equals(4) then
            _G["lnumber"] = int32
        end

        if virtualHeader.values[6]:equals(8) then
            usertype("sizet", {int64})
            usertype("lstring", {sizet, bytelist})
        elseif virtualHeader.values[6]:equals(4) then
            usertype("sizet", {int32})
            usertype("lstring", {sizet, bytelist})
        end

        if not lstring or not lnumber then 
            error("Something went very wrong with reading sizes.") 
        end

        usertype("pcinfo", {int32, int32})

        local function readString(len)
            if len == nil then len = stream:read(sizet) end
            local val = stream:read(bytelist, len.values[1].value)
            return lstring(len, val)
        end

        local function readFloat64()
            local a = stream:read(int32).value
			local b = stream:read(int32).value
			return (-2*logicalGetBits(b, 32)+1)*(2^(logicalGetBits(b, 21, 31)-1023))*
			       ((logicalGetBits(b, 1, 20)*(2^32) + a)/(2^52)+1)
        end

        local function deserializeChunk()
            local chunk = {
                instructions = {},
                constants    = {},
                prototypes   = {},
                debug        = {lines = {}, locals = {}, upvalues = {}}
            }

            chunk.startAddress = stream.readIndex
            chunk.name = readString()
            if chunk.name then 
                if chunk.name.values[2]:toString() ~= '' then
                    chunk.name = lstring(
                        chunk.name.values[1], 
                        chunk.name.values[2]:toString():sub(1, -2)
                    )
                else
                    chunk.name = lstring(
                        chunk.name.values[1], 
                        chunk.name.values[2]:toByteString()
                    )
                end
            end

            chunk.debug.firstLine = stream:read(lnumber).value
            chunk.debug.lastLine = stream:read(lnumber).value
            chunk.nups = stream:read(byte).value
            chunk.nargs = stream:read(byte).value
            chunk.varg = stream:read(byte).value
            chunk.stack = stream:read(byte).value

            -- deserialize instructions
            for i = 1, stream:read(lnumber).value do
                local instruction = {}
                instruction.start = stream.readIndex
                instruction.data = stream:read(int32)
                local i32 = instruction.data.value
                
                instruction.opcode = logicalGetBits(i32, 1, 6)
                instruction.A = logicalGetBits(i32, 7, 14)
                instruction.B = logicalGetBits(i32, 24, 32)
                instruction.C = logicalGetBits(i32, 15, 23)
                instruction.Bx = logicalGetBits(i32, 15, 32)
                instruction.sBx = logicalGetBits(i32, 15, 32) - 131071

                chunk.instructions[i] = instruction
            end

            -- deserialize constants
            for i = 1, stream:read(lnumber).value do
                local constant = {}
                constant.type = stream:read(byte)
                local ib = constant.type.value
                if ib == 1 then
                    constant.data = stream:read(byte).value ~= 0
                elseif ib == 3 then
                    constant.data = readFloat64()
                elseif ib == 4 then
                    constant.data = readString().values[2]:toString():sub(1, -2)
                end
                chunk.constants[i-1] = constant
            end

            -- deserialize prototypes
            for i = 1, stream:read(lnumber).value do
                chunk.prototypes[i-1] = deserializeChunk()
            end

            -- deserialize line info
            for i = 1, stream:read(lnumber).value do
                chunk.debug.lines[i] = stream:read(int32).value
            end
            
            -- deserialize local info
            for i = 1, stream:read(lnumber).value do
                local loc = {}
                loc.name = readString().values[2]:toString():sub(1, -2)
                loc.pcinfo = stream:read(pcinfo)
                chunk.debug.locals[i] = loc
            end

            -- deserialize upvalue info
            for i = 1, stream:read(lnumber).value do
                chunk.debug.upvalues[i] = readString().values[2]:toString()
            end

            return chunk
        end

        return deserializeChunk()
    end

    function self:applyJumpLines(stream, jumpFrom, jumpTo)
        local step = 1
        if jumpTo < jumpFrom then step = -1 end
        for i = jumpFrom, jumpTo, step do
            local jumpText = ""
            if i == jumpFrom then
                jumpText = '+---'
            elseif i == jumpTo then
                jumpText = 'o-->'
            else
                if step == -1 then
                    if i < jumpFrom and i > jumpTo then jumpText = '|' end
                else
                    if i > jumpFrom and i < jumpTo then jumpText = '|' end
                end
            end
            stream:changeColumn(i, 3, jumpText)
        end
    end

    function self:dump(chunk)
        local chunkInfo = textstream:new()
        local constantInfo = textstream:new()
        local instructionInfo = textstream:new()
        local localInfo = textstream:new()
        local debugInfo = textstream:new()
        constantInfo.columnMargin = 1
        
        chunkInfo:addToRow(1, 1, "func_" .. string.format("%4.8X", chunk.startAddress) .. '[nupv->' .. chunk.nups .. ', narg->' .. chunk.nargs .. '](' .. chunk.name.values[2]:toString() .. ')')
        
        for key, val in pairs(chunk.constants) do
            constantInfo:setColumnMargin(3, 2)
            constantInfo:addToRow(key+1, 1, '.constant')
            constantInfo:addToRow(key+1, 2, ({'boolean', '?', 'number', 'string'})[val.type.value])
            constantInfo:addToRow(key+1, 3, string.format('Cnst[%s]', key))
            constantInfo:addToRow(key+1, 4, tostring(val.data))
        end

        local a = 0
        instructionInfo:addToRow(1, 1, "address")
        instructionInfo:addToRow(1, 2, "opcode")
        instructionInfo:addToRow(1, 3, "jmp")
        instructionInfo:addToRow(1, 4, "opname")
        instructionInfo:addToRow(1, 10, "note")

        for key, instruction in pairs(chunk.instructions) do
            local opname = self.instructionLookup[instruction.opcode]
            instructionInfo:addToRow(key+1, 1, string.format("%4.6X", instruction.start))
            instructionInfo:addToRow(key+1, 2, '[' .. string.format("%2.3X", instruction.opcode) .. ']')
            instructionInfo:addToRow(key+1, 3, '')
            instructionInfo:addToRow(key+1, 4, opname)

            local regIdx = {['A'] = 1, ['B'] = 2, ['C'] = 3, ['Bx'] = 4, ['sBx'] = 5}
            for k,v in pairs(self.instructionRegisterSignatures[instruction.opcode]) do
                if instruction[v] > 255 then
                    if #self.instructionRegisterSignatures[instruction.opcode] == k then
                        instructionInfo:addToRow(key+1, 4+regIdx[v], tostring(instruction[v]-255))
                        instructionInfo:setColumnMargin(4+regIdx[v], 1)
                    else
                        instructionInfo:addToRow(key+1, 4+regIdx[v], tostring(instruction[v]-255) .. ',')
                        instructionInfo:setColumnMargin(4+regIdx[v], 1)
                    end
                else
                    if #self.instructionRegisterSignatures[instruction.opcode] == k then
                        instructionInfo:addToRow(key+1, 4+regIdx[v], tostring(instruction[v]))
                        instructionInfo:setColumnMargin(4+regIdx[v], 1)
                    else
                        instructionInfo:addToRow(key+1, 4+regIdx[v], tostring(instruction[v]) .. ',')
                        instructionInfo:setColumnMargin(4+regIdx[v], 1)
                    end
                end
            end

            for i = 5, 9 do
                if instructionInfo:getColumnText(key+1, i) == '' and a < 3 then
                    instructionInfo:changeColumn(key+1, i, '-')
                end
            end

            if opname == 'loadk' then
                if type(chunk.constants[instruction.Bx].data) == 'string' then
                    instructionInfo:addToRow(key+1, 10, string.format('; S[%s] := ([[%s]] <- Cnst[%s])', instruction.A, tostring(chunk.constants[instruction.Bx].data), instruction.Bx))
                else
                    instructionInfo:addToRow(key+1, 10, string.format('; S[%s] := (%s <- Cnst[%s])', instruction.A, tostring(chunk.constants[instruction.Bx].data), instruction.Bx))
                end
            elseif opname == 'getglobal' then
                instructionInfo:addToRow(key+1, 10, string.format('; S[%s] := (%s <- _G[Cnst[%s]])', instruction.A, tostring(chunk.constants[instruction.Bx].data), instruction.Bx))
            elseif opname == 'move' then
                instructionInfo:addToRow(key+1, 10, string.format('; S[%s] := S[%s]', instruction.A, instruction.B))
            elseif opname == 'jmp' then
                instructionInfo:addToRow(key+1, 10, string.format('; IP += %s', instruction.sBx))
                self:applyJumpLines(instructionInfo, (key+1), (key+1) + instruction.sBx + 1)
            elseif opname == 'eq' then
                local A = instruction.A
			    local B = instruction.B
			    local C = instruction.C
                local BTxt, CTxt = '', ''
                A = A ~= 0
                if B > 255 then BTxt = string.format('Cnst[%s]', B-256) else BTxt = string.format('S[%s]', B) end
                if C > 255 then CTxt = string.format('Cnst[%s]', C-256) else CTxt = string.format('S[%s]', C) end
                instructionInfo:addToRow(key+1, 10, string.format('; (%s == %s) ~= %s { IP += 1 }', BTxt, CTxt, tostring(A)))
            elseif opname == 'loadbool' then
                instructionInfo:addToRow(key+1, 10, string.format('; S[%s] := %s (%s ~= 0)', instruction.A, tostring(instruction.B ~= 0), instruction.B))
                if instruction.C ~= 0 then
                    self:applyJumpLines(instructionInfo, (key+1), (key+1) + 2)
                end
            elseif opname == 'closure' then
                instructionInfo:addToRow(key+1, 10, string.format('; S[%s] := func_%s', instruction.A, string.format("%4.8X", chunk.prototypes[instruction.Bx].startAddress)))
            end
        end

        print(chunkInfo:toString())
        if not constantInfo:empty() then
            print(constantInfo:toString())
        end
        print(instructionInfo:toString())

        for k,v in pairs(chunk.prototypes) do
            self:dump(v)
        end
    end

    return self
end)