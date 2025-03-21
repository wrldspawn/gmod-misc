--[[
 * The following only applies to this one function
 *
 * Copyright (c) 2015-2020 Iryont <https://github.com/iryont/lua-struct>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
]]

local unpack = table.unpack or unpack

local function struct_unpack(format, stream, pos)
  local vars = {}
  local iterator = pos or 1
  local endianness = true

  for i = 1, format:len() do
    local opt = format:sub(i, i)

    if opt == "<" then
      endianness = true
    elseif opt == ">" then
      endianness = false
    elseif opt:find("[bBhHiIlL]") then
      local n = opt:find("[hH]") and 2 or opt:find("[iI]") and 4 or opt:find("[lL]") and 8 or 1
      local signed = opt:lower() == opt

      local val = 0
      for j = 1, n do
        local byte = string.byte(stream:sub(iterator, iterator))
        byte = byte or 0
        if endianness then
          val = val + byte * (2 ^ ((j - 1) * 8))
        else
          val = val + byte * (2 ^ ((n - j) * 8))
        end
        iterator = iterator + 1
      end

      if signed and val >= 2 ^ (n * 8 - 1) then
        val = val - 2 ^ (n * 8)
      end

      table.insert(vars, math.floor(val))
    elseif opt:find("[fd]") then
      local n = (opt == "d") and 8 or 4
      local x = stream:sub(iterator, iterator + n - 1)
      iterator = iterator + n

      if not endianness then
        x = string.reverse(x)
      end

      local sign = 1
      local mantissa = string.byte(x, (opt == "d") and 7 or 3) % ((opt == "d") and 16 or 128)
      for j = n - 2, 1, -1 do
        mantissa = mantissa * (2 ^ 8) + string.byte(x, j)
      end

      if string.byte(x, n) > 127 then
        sign = -1
      end

      local exponent = (string.byte(x, n) % 128) * ((opt == "d") and 16 or 2) +
      math.floor(string.byte(x, n - 1) / ((opt == "d") and 16 or 128))
      if exponent == 0 then
        table.insert(vars, 0.0)
      else
        mantissa = (math.ldexp(mantissa, (opt == "d") and -52 or -23) + 1) * sign
        table.insert(vars, math.ldexp(mantissa, exponent - ((opt == "d") and 1023 or 127)))
      end
    elseif opt == "s" then
      local bytes = {}
      for j = iterator, stream:len() do
        if stream:sub(j, j) == string.char(0) then
          break
        end

        table.insert(bytes, stream:sub(j, j))
      end

      local str = table.concat(bytes)
      iterator = iterator + str:len() + 1
      table.insert(vars, str)
    elseif opt == "c" then
      local n = format:sub(i + 1):match("%d+")
      table.insert(vars, stream:sub(iterator, iterator + tonumber(n) - 1))
      iterator = iterator + tonumber(n)
      i = i + n:len()
    end
  end

  return unpack(vars)
end

local meta = {
  data = "",
  offset = 1,
  Int8 = function(self)
    local out = struct_unpack("<b", self.data, self.offset)
    self.offset = self.offset + 1
    return out
  end,
  Int16 = function(self)
    local out = struct_unpack("<i2", self.data:sub(self.offset, self.offset + 1))
    self.offset = self.offset + 2
    return out
  end,
  Int32 = function(self)
    local out = struct_unpack("<i4", self.data:sub(self.offset, self.offset + 3))
    self.offset = self.offset + 4
    return out
  end,
  UInt8 = function(self)
    local out = struct_unpack("<B", self.data, self.offset)
    self.offset = self.offset + 1
    return out
  end,
  UInt16 = function(self)
    local out = struct_unpack("<I2", self.data:sub(self.offset, self.offset + 1))
    self.offset = self.offset + 2
    return out
  end,
  UInt32 = function(self)
    local out = struct_unpack("<I4", self.data:sub(self.offset, self.offset + 4))
    self.offset = self.offset + 4
    return out
  end,
  String = function(self, length)
    length = tonumber(length)
    local out = struct_unpack("<c" .. length, self.data, self.offset)
    self.offset = self.offset + length
    return out
  end,
  Seek = function(self, ofs)
    self.offset = self.offset + ofs
  end,
  SeekTo = function(self, ofs)
    self.offset = ofs + 1
  end,
}
meta.__index = meta

local function DataView(data)
  local tbl = setmetatable({}, meta)
  tbl.data = data

  return tbl
end

return DataView

