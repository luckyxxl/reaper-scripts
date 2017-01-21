function process_take(take)
  if not reaper.TakeIsMIDI(take) then return end
  
  local _, num_notes = reaper.MIDI_CountEvts(take)
  local notes = {}
  for i=0, num_notes-1 do
    table.insert(notes, table.pack(reaper.MIDI_GetNote(take, i)))
  end
  for i=0, num_notes-1 do
    reaper.MIDI_DeleteNote(take, 0)
  end
  for _,note in ipairs(notes) do
    note[4] = note[4]*2
    note[5] = note[5]*2
    table.insert(note, false)
    reaper.MIDI_InsertNote(take, table.unpack(note, 2))
  end
  reaper.MIDI_Sort(take)
end

for i=0, reaper.CountSelectedMediaItems(0)-1 do
  local item = reaper.GetSelectedMediaItem(0, i)
  
  local pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", pos*2)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", len*2)
  
  process_take(reaper.GetTake(item, 0))
end
