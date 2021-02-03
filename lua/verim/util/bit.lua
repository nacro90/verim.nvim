local bit = {}

function bit.shr(num, level)
    level = level or 1
    local dropped_bits = {}
    for _ = 1, level do
        dropped_bits[#dropped_bits + 1] = num % 2
        num = math.floor(num / 2)
    end
    local dropped_num = 0
    for i = 1, #dropped_bits do
        local dropped_bit = dropped_bits[i]
        dropped_num = dropped_num + dropped_bit * (2 ^ (i - 1))
    end
    return num, dropped_num
end

return bit
