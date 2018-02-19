local old_path = "C:\\old"
local new_path = "D:\\new"

local items = {}
for i = 0, reaper.CountMediaItems(0)-1 do
  table.insert(items, reaper.GetMediaItem(0, i))
end

for _, i in ipairs(items) do
  local _, state = reaper.GetItemStateChunk(i, "", false)
  local new_state = string.gsub(state, old_path, new_path)
  reaper.SetItemStateChunk(i, new_state, false)
end
