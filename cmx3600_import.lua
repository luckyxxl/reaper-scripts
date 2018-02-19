local print = function(s) reaper.ShowConsoleMsg(s .. "\n") end
local error = error

local filename = ""
local result, filename = reaper.GetUserFileNameForRead(filename, "Open CMX3600", "*.edl")

if not result then return end

local function parse_cmx3600(filename)
  local events = {}

  local function totimecode(string)
    local hs, ms, ss, fs = string:match("(%d+):(%d+):(%d+):(%d+)")
    local h, m, s, f = tonumber(hs), tonumber(ms), tonumber(ss), tonumber(fs)
    if not h or not m or not s or not f then error("invalid timecode " .. string) end
    return { h = h, m = m, s = s, f = f }
  end

  for line in io.lines(filename) do
    local first = line:match("%S+")
    local event_id = tonumber(first) -- can fail with nil

    if first == "TITLE:" then
    elseif event_id then
      local fields = {}
      for f in line:gmatch("%S+") do table.insert(fields, f) end

      local event = {}
      event.id = tonumber(fields[1])
      event.type = fields[3]
      if fields[4] == "K" then
        event.source_in = totimecode(fields[6])
        event.source_out = totimecode(fields[7])
        event.record_in = totimecode(fields[8])
        event.record_out = totimecode(fields[9])
      else
        event.source_in = totimecode(fields[5])
        event.source_out = totimecode(fields[6])
        event.record_in = totimecode(fields[7])
        event.record_out = totimecode(fields[8])
      end

      if fields[4] == "C" or (fields[4] == "K" and fields[5] == "B") then
        table.insert(events, event)
      end
    elseif first == "AUD" then
    elseif first == "*" then
      local clip_comment = "* FROM CLIP NAME: " -- TODO: don't depend on the space
      if line:sub(1, #clip_comment) == clip_comment then
        local clip = line:sub(#clip_comment + 1)
        events[#events].clip = clip
      end
    elseif first == "M2" then
    elseif first ~= nil then
      error("invalid line starting with " .. first)
    end
  end

  return events
end

events = parse_cmx3600(filename)
table.sort(events, function(a, b) return a.id < b.id end)

local function add_to_project(events)
  local track = reaper.GetSelectedTrack(0, 0)
  if not track then error("no track selected") end

  local function totime(tc)
    return tc.h * 60 * 60 + tc.m * 60 + tc.s + tc.f * 1/25
  end

  for _, event in ipairs(events) do
    local item = reaper.AddMediaItemToTrack(track)

    local record_in, record_out = totime(event.record_in), totime(event.record_out)

    reaper.SetMediaItemPosition(item, record_in, false)
    reaper.SetMediaItemLength(item, record_out - record_in, false)
    reaper.ULT_SetMediaItemNote(item, event.clip)
  end
end

add_to_project(events)

reaper.UpdateArrange()
