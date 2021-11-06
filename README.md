# newd
newd (new disassembler) lol i couldn't figure a good name so.

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
