local function urlencodechar(char)
    return "%" .. string.format("%02X", string.byte(char))
end

function string.urlencode(input)
    -- convert line endings
    input = string.gsub(tostring(input), "\n", "\r\n")
    -- escape all characters but alphanumeric, '.' and '-'
    input = string.gsub(input, "([^%w%.%- ])", urlencodechar)
    -- convert spaces to "+" symbols
    return string.gsub(input, " ", "+")
end

local function checknumber(value, base)
    return tonumber(value, base) or 0
end

function string.urldecode(input)
    input = string.gsub (input, "+", " ")
    input = string.gsub (input, "%%(%x%x)", function(h) return string.char(checknumber(h, 16)) end)
    input = string.gsub (input, "\r\n", "\n")
    return input
end

function string.random_str(n)
    local str = ''
    for i=1,n do
        str = str.. string.char(math.random(48,57))
    end
    return str
end

function string:split(sep)
    local splits = {}
    
    if sep == nil then
        -- return table with whole str
        table.insert(splits, self)
    elseif sep == "" then
        -- return table with each single character
        local len = #self
        for i = 1, len do
            table.insert(splits, self:sub(i, i))
        end
    else
        -- normal split use gmatch
        local pattern = "[^" .. sep .. "]+"
        for str in string.gmatch(self, pattern) do
            table.insert(splits, str)
        end
    end
    
    return splits
end

-- 判断字符串里面时候有中文
function string.check_chinese(str)
    if str == nil then
        return false
    end

    local l = #string.gsub(str, "[^\128-\191]", "")
    return (l ~= 0)
end