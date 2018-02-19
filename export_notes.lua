local print = function(s) reaper.ShowConsoleMsg(s .. "\n") end
local error = error

local filename = ""
local result, filename = reaper.GetUserFileNameForRead(filename, "Export Notes", "*.txt")

if not result then return end

lines = {}
for l in io.lines(filename) do table.insert(lines, l) end

local track = reaper.GetSelectedTrack(0, 0)

if not track then return end

for i = 0, reaper.GetTrackNumMediaItems(track)-1 do
  local item = reaper.GetTrackMediaItem(track, i)
  local text = reaper.ULT_GetMediaItemNote(item)
  for t in text:gmatch("[^%\n]*") do
    if #t > 0 then
      local insert = true
      for _, l in ipairs(lines) do
        if l == t then insert = false break end
      end
      if insert then table.insert(lines, t) end
    end
  end
end

local out = io.open(filename, "w")
out:write(table.concat(lines, "\n"))
out:close()
