# newd
newd (new disassembler) lol i couldn't figure a good name so.
the point of this project was simply a POC (proof of concept) on typed deserialization methods 
along with configurable disassemblers.

# output
```lua
if true then
    print(true and false)
    print(true or false)
else
    print('aaaaa')
    for i = 1, 100 do
        local function add() return false end
    end
end
```

when feeding newd the bytecode of the previous code snippet you will be greeted with the following disassembly view
```asm
[NEWD] - detected virtual machine signature LuaQ VM
func_0000000C[nupv->0, narg->0](@main.lua)

.constant string Cnst[0]  print
.constant string Cnst[1]  aaaaa
.constant number Cnst[2]  1
.constant number Cnst[3]  100

address    opcode    jmp     opname                    note
00002E     [005]             getglobal    0, -  - 0 -  ; S[0] := (print <- _G[Cnst[0]])     
000032     [002]             loadbool     1, 0, 0 - -  ; S[1] := false (0 ~= 0)
000036     [01C]             call         0, 2, 1 - -
00003A     [005]             getglobal    0, -  - 0 -  ; S[0] := (print <- _G[Cnst[0]])     
00003E     [002]             loadbool     1, 1, 0 - -  ; S[1] := true (1 ~= 0)
000042     [01A]             test         1, -  - 1 -
000046     [016]     +---    jmp          -  -  - - 1  ; IP += 1
00004A     [002]     |       loadbool     1, 0, 0 - -  ; S[1] := false (0 ~= 0)
00004E     [01C]     o-->    call         0, 2, 1 - -
000052     [016]     +---    jmp          -  -  - - 9  ; IP += 9
000056     [005]     |       getglobal    0, -  - 0 -  ; S[0] := (print <- _G[Cnst[0]])     
00005A     [001]     |       loadk        1, -  - 1 -  ; S[1] := ([[aaaaa]] <- Cnst[1])     
00005E     [01C]     |       call         0, 2, 1 - -
000062     [001]     |       loadk        0, -  - 2 -  ; S[0] := (1 <- Cnst[2])
000066     [001]     |       loadk        1, -  - 3 -  ; S[1] := (100 <- Cnst[3])
00006A     [001]     |       loadk        2, -  - 2 -  ; S[2] := (1 <- Cnst[2])
00006E     [020]     |       forprep      0, -  0 - -
000072     [024]     |       closure      4, -  - 0 -  ; S[4] := func_000000B6
000076     [01F]     |       forloop      0, -  - - -2
00007A     [01E]     o-->    return       0, 1  - - -

func_000000B6[nupv->0, narg->0]([])

address    opcode    jmp    opname                        note
0000CE     [002]            loadbool    0, 0, 0 -    -    ; S[0] := false (0 ~= 0)
0000D2     [01E]            return      0, 2  - -    -
0000D6     [01E]            return      0, 1  - -    -
```

# how to use
once you have downloaded the src for newd you can simply go to the main.lua file and feed newd.bruteforce function with a bytecode string.

# creating your own deserialization configuration
there isn't very good support for this yet but I plan on making some updates in the future to make this process a lot easier.
here is the template configuration file for newd:

```lua
return require("newd/vm/virtualmachine").new(function(self)
    self.virtualMachineName = "LuaQ VM"
    self.signature = {}
    function self:deserialize(bytecode) end
    function self:dump(chunk) end
end
```

# the base type system
the newd library currently only contains a select few datatypes being ``byte``, ``bytelist``, ``int16``, ``int32``, ``int64``, and ``usertype``
these types act as constructors for an object of the specified type; calling ``byte(10)`` creates a byte type with the value of 10 as it's only byte.
byte can also be constructed with a string parameter however it is limited to one character ``byte('A')``

here is a quick overview for each type
* byte
    * this data type is the basic building block for all other types if the other types cannot construct a byte out of anything you are sending it; it will error.
    * this data type can be constructed in two ways; ``byte(1)`` && ``byte('A')``
* bytelist
    * this data type was a pain in the ass to implement because it adds a whole new layer of complexity on top of the data type system. a bytelist is an undetermined size therefore it is dynamic and when things are dynamic it is hard to read them unless you supply a length (which i had to enforce for the bytestream utility)
    * while the bytelist is useful it makes usertypes that utilize the bytelist impossibly hard to read without supplying a length.
    * a bytelist can be constructed in many ways; ``bytelist(1, 2, 3)``, ``bytelist(1, 'A', 2)``, ``bytelist('Hello, World!')``, and ``bytelist(byte(1), int32(100000))``
* int16
    * this data type holds two bytes which store the overall value for the type.
    * this data type can be constructed in a few ways ``int16(279)``, ``int16(1, 2)``, ``int16(byte('X'), byte('D'))``, ``int16('H')``
* int32
    * this data type holds four bytes which store the overall value for the type.
    * this data type can be constructed in a few ways ``int32(279000)``, ``int32(1, 2, 9, 10)``, ``int32(byte('X'), byte('D'), int16('A'))``, ``int32('H')``
* int64
    * this data type holds eight bytes which store the overall value for the type. (wow do you see a pattern yet?)
    * this data type is in the works as currently it is not working but it's not used atm either.

## the usertype
this type honestly deserves its own section because in order to make this it was an actual living hell.
example one:
```lua
usertype("sizet", {int32})
local s = sizet(1000000)
print(s.values[1].value) --> 1000000
```

example two:
```lua
usertype("vheader", {byte, byte, byte, byte, byte, int32})
local header = stream:read(vheader) --> assuming there was enough bytes to construct all the inside types of the usertype 'vheader' it will return the type
```
```
