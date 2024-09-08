local skynet = require "skynet"


local print = skynet.error

local function table_print( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => ".."{")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print("{")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
end

function dump( ... )
    for i,t in ipairs({...}) do
        if type(t) ~= 'table' then
            print(tostring(t))
        else
            table_print(t)
        end
    end
end


function dump_cards(cards)
    if type(cards) ~= "table" then
        return tostring(cards)
    end

    local s = " {"
    for i,c in ipairs(cards) do
        s = s .. string.format("%#x", c) .. ", "
    end
    s = s:sub(1, #s-2) .. "}"
    return s
end


function dump_tables(...)
    local list = {...}
    for i,t in ipairs(list) do
        list[i] = table.pretty(t)
    end
    return list
end