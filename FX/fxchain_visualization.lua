-- @description FXChain Visualization
-- @author luckyxxl
-- @version 1.0

--[[
Copyright (c) 2017 luckyxxl

This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.

Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.

    3. This notice may not be removed or altered from any source distribution.
]]

border = 20
fx_height = 50
bar_height = 10
pin_border = 4
pin_size = 6
theme =
{
  {0, 0, 0}, -- background
  {1, 0, 0}, -- channel bar
  {1, 1, 0}, -- pin
  {0, 0, 1}, -- fx box
  {0, 0, 0.25}, -- fx box (disabled)
  {1, 1, 1}, -- fx text
  {0, 1, 0}, -- connection
  {0, 0.25, 0}, -- pass-through connection
}

old_gfx_w, old_gfx_h = gfx.w, gfx.h

track = nil
data = nil

gfx.clear = (theme[1][1] * 255 << 0) + (theme[1][2] * 255 << 8) + (theme[1][3] * 255 << 16)
gfx.init("fxchain visualization",
  tonumber(reaper.GetExtState("fxchain_visualization", "wndw")) or 256,
  tonumber(reaper.GetExtState("fxchain_visualization", "wndh")) or 640,
  tonumber(reaper.GetExtState("fxchain_visualization", "dock")) or 0,
  tonumber(reaper.GetExtState("fxchain_visualization", "wndx")) or 0,
  tonumber(reaper.GetExtState("fxchain_visualization", "wndy")) or 0)

function quit()
  d, x, y, w, h = gfx.dock(-1, 0, 0, 0, 0)
  reaper.SetExtState("fxchain_visualization", "wndw", w, true)
  reaper.SetExtState("fxchain_visualization", "wndh", h, true)
  reaper.SetExtState("fxchain_visualization", "dock", d, true)
  reaper.SetExtState("fxchain_visualization", "wndx", x, true)
  reaper.SetExtState("fxchain_visualization", "wndy", y, true)
  gfx.quit()
end

reaper.atexit(quit)

-- TODO: is there a better way?
function first_bit_set(int)
  for i=0, 32 do
    if int & (1 << i) ~= 0 then return (i+1) end
  end
  return 0
end

function build_chain_data()
  data = nil
  if not track then return end
  
  local fx_count = reaper.TrackFX_GetCount(track)
  if fx_count == 0 then return end
  
  local channels = reaper.GetMediaTrackInfo_Value(track, "I_NCHAN")
  
  local fxs = {}
  for fx=0, fx_count-1 do
    local _, name = reaper.TrackFX_GetFXName(track, fx, "")
    
    local enabled = reaper.TrackFX_GetEnabled(track, fx)
    
    local _, in_pins, out_pins = reaper.TrackFX_GetIOSize(track, fx)
    
    local input = {}
    for pin=0, in_pins-1 do
      input[pin+1] = reaper.TrackFX_GetPinMappings(track, fx, 0, pin)
    end
    
    local output = {}
    for pin=0, out_pins-1 do
      output[pin+1] = reaper.TrackFX_GetPinMappings(track, fx, 1, pin)
    end
    
    local element = { name = name, enabled = enabled, input = input, output = output }
    fxs[fx+1] = element
  end
  
  data = { channels = channels, fxs = fxs }
end

function draw_chain_visualization()
  local vpx, vpy = border, border
  local vpw, vph = gfx.w - 2 * border, gfx.h - 2 * border
  
  if not data then
    -- clear the screen
    gfx.setpixel(table.unpack(theme[1]))
    return
  end
  
  local function fx_offset(fdata)
    local result = data.channels
    for pi = 1, #fdata.output do
      local pin = fdata.output[pi]
      for ci = 1, data.channels do
        if pin & (1 << (ci-1)) ~= 0 then
          result = math.min(result, (ci - 1) - (pi - 1))
        end
      end
    end
    return math.max(result, 0)
  end
  
  local pins = data.channels
  for _, fdata in ipairs(data.fxs) do
    pins = math.max(pins, --[[math.max(#fdata.input, #fdata.output) + ]]fx_offset(fdata))
  end
  
  local _bdy = (vph - bar_height) / #data.fxs
  
  local function by(i)
    return vpy + (i-1) * _bdy
  end
  
  local _px = vpx + pin_border + pin_size // 2
  local _pdx = (vpw - 2 * pin_border - pin_size) / (pins-1)
  
  local function px(i)
    return _px + _pdx * (i-1)
  end
  
  local function pinrow(y, x1, x2)
    if not x2 then x1, x2 = 0, x1 end
    
    local py = y - pin_size // 2
    
    gfx.set(table.unpack(theme[3]))
    for i=x1, x2 do gfx.rect(px(i) - pin_size // 2, py, pin_size, pin_size) end
  end
  
  -- fxs
  do
    local gridh = (vph - 2 * bar_height / 2) / (#data.fxs*3)
    
    for fi, fdata in ipairs(data.fxs) do
      local offset = fx_offset(fdata)
      local fx, fy = px(1 + offset) - pin_size // 2 - pin_border, vpy + gridh + (fi-1) * 3 * gridh
      local fw, fh = px(math.max(#fdata.input, #fdata.output) + offset) + pin_size // 2 + pin_border - fx, gridh
      
      -- pass-through connections
      do
        gfx.set(table.unpack(theme[8]))
        for ci=1, data.channels do
          local is_pass_through = true
          
          if fdata.enabled then
            for pi=1, #fdata.output do
              local pin = fdata.output[pi]
              if pin & (1 << (ci-1)) ~= 0 then is_pass_through = false break end
            end
          end
          
          if is_pass_through then
            local x1, y1 = px(ci), by(fi) + bar_height
            local x2, y2 = px(ci), by(fi+1)
            gfx.line(x1, y1, x2, y2)
          end
        end
      end
      
      if fdata.enabled then
        gfx.set(table.unpack(theme[7]))
        
        -- input connections
        for ci=1, data.channels do
          for pi=1, #fdata.input do
            local pin = fdata.input[pi]
            if pin & (1 << (ci-1)) ~= 0 then
              local x1, y1 = px(ci), by(fi) + bar_height
              local x2, y2 = px(pi + offset), fy
              gfx.line(x1, y1, x2, y2)
            end
          end
        end
        
        -- output connections
        for ci=1, data.channels do
          for pi=1, #fdata.output do
            local pin = fdata.output[pi]
            if pin & (1 << (ci-1)) ~= 0 then
              local x1, y1 = px(pi + offset), fy + fh
              local x2, y2 = px(ci), by(fi+1)
              gfx.line(x1, y1, x2, y2)
            end
          end
        end
      end
      
      -- box
      do
        gfx.set(table.unpack(theme[fdata.enabled and 4 or 5]))
        gfx.rect(fx, fy, fw, fh)
        
        gfx.set(table.unpack(theme[6]))
        gfx.x, gfx.y = vpx + 5, fy + fh / 2 - gfx.texth / 2
        gfx.drawstr(fdata.name)
        
        pinrow(fy,    1 + offset, #fdata.input  + offset)
        pinrow(fy+fh, 1 + offset, #fdata.output + offset)
      end
    end
  end
  
  -- channel bars
    do
      for bi=1, #data.fxs+1 do
        local bx, by = vpx, by(bi)
        local bw, bh = vpw, bar_height
      
        gfx.set(table.unpack(theme[2]))
        gfx.rect(bx, by, bw, bh)
        
        if bi ~= 1           then pinrow(by, 1, data.channels) end
        if bi ~= #data.fxs+1 then pinrow(by+bh, 1, data.channels) end
      end
    end
end

function runloop()
  local key = gfx.getchar()
  
  local reload = key == string.byte("r")
  
  local selected_track = reaper.GetSelectedTrack(0, 0)
  if selected_track ~= track then
    track = selected_track
    reload = true
  end
  
  if reload then
    build_chain_data()
  end
  
  local redraw = reload
  
  gfx.update()
  
  if gfx.w ~= old_gfx_w or gfx.h ~= old_gfx_h then
    old_gfx_w, old_gfx_h = gfx.w, gfx.h
    redraw = true
  end
  
  if redraw then
    draw_chain_visualization()
  end

  if key ~= -1 then
    reaper.runloop(runloop)
  end
end

runloop()
