-- オブジェクトの文字列表現を返す
-- https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local function is_leap_year(year)
    return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

local function days_of_month(year, month)
    local days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    local result = days[month]
    if month == 2 and is_leap_year(year) then
        result = result + 1
    end
    return result
end

local function day_of_week(y, m, d)
    -- ツェラーの公式
    if m < 3 then
        y = y - 1
        m = m + 12
    end
    return (y + math.floor(y / 4) - math.floor(y / 100) + math.floor(y / 400) + math.floor((13 * m + 8) / 5) + d) % 7
end

local function generate_days(year, month)
    local days = {}
    local dom = days_of_month(year, month)
    local wday = day_of_week(year, month, 1)
    for d = 1, dom do
        days[d] = {
            day = d,
            wday = wday,
            is_holiday = false,
            name = '',
        }
        wday = (wday + 1) % 7
    end
    return days
end

local function format_calendar(days)
    local result = ''
    for i = 1, days[1]['wday'] do
        result = result .. '   '
    end
    for d = 1, #days do
        if days[d]['wday'] == 0 then
            result = result .. string.format('\x1b[0;31m%2d \x1b[0m', d)
        elseif days[d]['wday'] == 6 then
            result = result .. string.format('\x1b[0;34m%2d \x1b[0m', d)
        else
            result = result .. string.format('%2d ', d)
        end
        if days[d]['wday'] == 6 then
            result = result .. '\n'
        end
    end
    return result
end

local function print_calendar(year, month)
    print(string.format('     %d年 %d月', year, month))
    print('日 月 火 水 木 金 土')
    local days = generate_days(year, month)
    -- print(dump(days))
    print(format_calendar(days))
end

local function main()
    local now = os.date("*t", os.time())
    local month = arg[1] and tonumber(arg[1]) or now['month']
    local year = arg[2] and tonumber(arg[2]) or now['year']
    -- print(is_leap_year(year))
    -- print(days_of_month(year, month))
    -- print(day_of_week(year, month, 1))
    for i = 1, 2 do
        print_calendar(year, month)
        if i ~= 2 then
            print()
        end
        if month == 12 then
            year = year + 1
            month = 1
        else
            month = month + 1
        end
    end
end

main()