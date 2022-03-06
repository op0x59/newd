function reverse(t)
    local n = #t
    local i = 1
    while i < n do
        t[i],t[n] = t[n],t[i]
        i = i + 1
        n = n - 1
    end
    return t
end

logicalGetBits = function(input, n, n2)
    if n2 then
		local total = 0
		local digitn = 0
		for i = n, n2 do
			total = total + 2^digitn*logicalGetBits(input, i)
			digitn = digitn + 1
		end
		return total
	else
		local pn = 2^(n-1)
		return (input % (pn + pn) >= pn) and 1 or 0
	end
end

logicalLeftShift = function(left, right)
    return left * (2 ^ right)
end

logicalRightShift = function(left, right)
    return math.floor(left / (2 ^ right))
end

logicalXor = function(left, right)
    local remainder = 0
    for i = 0, 31 do
        local result = left / 2 + right / 2
        if result ~= math.floor(result) then
            remainder = remainder + 2^i
        end
        left = math.floor(left / 2)
        right = math.floor(right / 2)
    end
    return remainder
end

-- solution from: https://stackoverflow.com/questions/32387117/bitwise-and-in-lua
-- author: ryanpattison
logicalBand = function(left, right)
    local result = 0
    local bitval = 1
    while left > 0 and right > 0 do 
        if left % 2 == 1 and right % 2 == 1 then
            result = result + bitval
        end
        bitval = bitval * 2
        left = math.floor(left/2)
        right = math.floor(right/2)
    end
    return result
end

logicalBor = function(a1, a2, a3, ...)
    local result
    if a2 then
        a1 = a1 % 4294967296
        a2 = a2 % 4294967296
        result = 4294967296 - logicalBand(4294967296 - a1, 4294967296 - a2)
        if a3 then
            result = logicalBor(result,a3,...)
        end
        return result
    elseif a1 then
        return a1 % 4294967296
    else
        return 0
    end
end

getValueFromBytes = function(...)
    local bytes = {...}
    if _G.BIG_ENDIAN then bytes = reverse(bytes) end
    local value = bytes[1].value
    for i = 2, #bytes do
        value = value*256 + bytes[i].value
    end
    return value
end

getBytesFromValue = function(value, size)
    local bytes = {}
    for i = 1, size do
        bytes[i] = byte(logicalBand((logicalRightShift(value, (8*(i-1)))), 0xFF))
    end
    if not _G.BIG_ENDIAN then bytes = reverse(bytes) end
    return bytes
end
