local CSV_URL = 'https://www8.cao.go.jp/chosei/shukujitsu/syukujitsu.csv'
local CSV_PATH = '/tmp/syukujitsu.csv'
local UTF8_CSV_PATH = '/tmp/syukujitsu_utf8.csv'

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
            year = year,
            month = month,
            day = d,
            wday = wday,
            is_holiday = false,
            name = '',
        }
        wday = (wday + 1) % 7
    end
    return days
end

local function set_holidays(days, holidays)
    for d = 1, #days do
        local ymd = days[d]['year'] .. '/' .. days[d]['month'] .. '/' .. days[d]['day']
        if holidays[ymd] ~= nil then
            days[d]['is_holiday'] = true
            days[d]['name'] = holidays[ymd]
        end
    end
    return days
end

local function format_calendar(days, now)
    local result = ''
    local holiday_names = ''

    for i = 1, days[1]['wday'] do
        result = result .. '   '
    end

    for d = 1, #days do
        if days[d]['year'] == now['year'] and days[d]['month'] == now['month'] and days[d]['day'] == now['day'] then -- 今日
            result = result .. string.format('\x1b[7;30m%2d \x1b[0m', d)
        elseif days[d]['wday'] == 0 then -- 日曜
            result = result .. string.format('\x1b[0;31m%2d \x1b[0m', d)
        elseif days[d]['wday'] == 6 then -- 土曜
            result = result .. string.format('\x1b[0;34m%2d \x1b[0m', d)
        elseif days[d]['is_holiday'] then -- 祝日
            result = result .. string.format('\x1b[0;31m%2d \x1b[0m', d)
        else
            result = result .. string.format('%2d ', d)
        end

        if days[d]['is_holiday'] then
            holiday_names = holiday_names .. string.format(' %d:%s', d, days[d]['name'])
        end

        if days[d]['wday'] == 6 then
            result = result .. holiday_names .. '\n'
            holiday_names = ''
        end
    end
    return result
end

local function print_calendar(year, month, holidays, now)
    print(string.format('     %d年 %d月', year, month))
    print('日 月 火 水 木 金 土')
    local days = generate_days(year, month)
    days = set_holidays(days, holidays)
    print(format_calendar(days, now))
end

local execute_cmd = function(cmd)
    local handle = io.popen(cmd)
    local result = handle:read('*a')
    handle:close()
    return result
end

local function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

local function download_csv_if_not_exist()
    if file_exists(UTF8_CSV_PATH) then
        return
    end

    local cmd = 'curl --silent ' .. CSV_URL .. ' -o ' .. CSV_PATH
    execute_cmd(cmd)

    local convert_cmd = 'iconv -f CP932 -t UTF-8 < ' .. CSV_PATH .. ' > ' .. UTF8_CSV_PATH
    execute_cmd(convert_cmd)
end

-- 文字列を分割
-- https://stackoverflow.com/questions/1426954/split-string-in-lua#comment73602874_7615129
local function split(inputstr, sep)
    sep = sep or '%s' -- %s is any whitespace
    local t = {}
    for field,s in string.gmatch(inputstr, "([^"..sep.."]*)("..sep.."?)") do
        table.insert(t,field)
        if s == "" then
            return t
        end
    end
end

local function load_csv()
    local holidays = {}

    local f = io.open(UTF8_CSV_PATH, 'r')
    local lnum = 0
    for line in f:lines() do
        lnum = lnum + 1
        if lnum ~= 1 then
            local cols = split(line, ',')
            holidays[cols[1]] = cols[2]
        end
    end
    f:close()

    return holidays
end

local function main()
    local now = os.date("*t", os.time())
    local month = arg[1] and tonumber(arg[1]) or now['month']
    local year = arg[2] and tonumber(arg[2]) or now['year']

    download_csv_if_not_exist()

    local holidays = load_csv();

    for i = 1, 2 do
        print_calendar(year, month, holidays, now)
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