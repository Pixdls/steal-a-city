--!strict
local Format = {}
local suffixes = {"", "K", "M", "B", "T", "Qa"}
function Format.Number(value: number): string
 if value ~= value then return "0" end
 local sign = if value < 0 then "-" else ""
 local n = math.abs(value)
 local i = 1
 while n >= 1000 and i < #suffixes do n /= 1000; i += 1 end
 n = math.floor(n*10+0.5)/10
 if n >= 1000 and i < #suffixes then n /= 1000; i += 1 end
 local digits = if i == 1 then tostring(math.floor(n)) else string.gsub(string.format("%.1f",n),"%.0$","")
 return sign..digits..suffixes[i]
end
function Format.Cash(value: number): string return "$"..Format.Number(value) end
return Format
