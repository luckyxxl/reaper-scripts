local items = {}
for i = 0, reaper.CountMediaItems(0)-1 do
  table.insert(items, reaper.GetMediaItem(0, i))
end

local project_path = reaper.GetProjectPath("")

for _, i in ipairs(items) do
  local _, state = reaper.GetItemStateChunk(i, "", false)
  for p in string.gmatch(state, "\nFILE \"([^\"]*)\"\n") do
    if string.sub(p, 1, #project_path) ~= project_path then
      reaper.ShowConsoleMsg(p .. "\n")
    end
  end
end
