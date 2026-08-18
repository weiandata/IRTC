-- Table and inline-code polish for the designed manual PDF.
--
-- 1. Header cells get the manual's heading colour and weight.
-- 2. Every cell starts with a \strut so that cells set in the monospace
--    font (whose ascent differs from the CJK body font) share one baseline
--    with the rest of the row.
-- 3. Long slash-separated runs such as `"none"`/`"squarem"`/`"Ramsay"` get a
--    break opportunity after each slash, so they wrap inside narrow columns
--    instead of overflowing into the next one.

local function first_block(cell)
  for _, blk in ipairs(cell.contents) do
    if blk.t == "Plain" or blk.t == "Para" then
      return blk
    end
  end
  return nil
end

local function strut(cell)
  local blk = first_block(cell)
  if blk then
    blk.content:insert(1, pandoc.RawInline("latex", "\\strut "))
  end
end

local function emphasise(cell)
  local blk = first_block(cell)
  if blk then
    blk.content:insert(1, pandoc.RawInline("latex", "\\textcolor{IRTCink}{\\bfseries "))
    blk.content:insert(pandoc.RawInline("latex", "}"))
  end
end

function Table(tbl)
  if tbl.head and tbl.head.rows then
    for _, row in ipairs(tbl.head.rows) do
      for _, cell in ipairs(row.cells) do
        emphasise(cell)
        strut(cell)
      end
    end
  end
  for _, body in ipairs(tbl.bodies or {}) do
    for _, row in ipairs(body.body or {}) do
      for _, cell in ipairs(row.cells) do
        strut(cell)
      end
    end
  end
  return tbl
end

-- Long inline code (file paths, calls) cannot break, which forces the CJK
-- text around it to stretch. Offer break points after the usual separators;
-- each fragment is still typeset in the same monospace run.
local BREAK_AFTER = {["."] = true, ["("] = true, ["/"] = true,
                     [","] = true, ["_"] = true, ["="] = true}

function Code(el)
  if utf8.len(el.text) == nil or utf8.len(el.text) < 14 then return nil end
  local out, buf = {}, ""
  for _, cp in utf8.codes(el.text) do
    local ch = utf8.char(cp)
    buf = buf .. ch
    if BREAK_AFTER[ch] and utf8.len(buf) > 2 then
      table.insert(out, pandoc.Code(buf))
      table.insert(out, pandoc.RawInline("latex", "\\allowbreak{}"))
      buf = ""
    end
  end
  if buf ~= "" then table.insert(out, pandoc.Code(buf)) end
  if #out > 1 then return out end
end

-- Allow a line break after slashes that separate short code fragments.
function Str(el)
  if el.text:find("/", 1, true) then
    local out = {}
    for piece, slash in el.text:gmatch("([^/]*)(/?)") do
      if piece ~= "" then table.insert(out, pandoc.Str(piece)) end
      if slash == "/" then
        table.insert(out, pandoc.Str("/"))
        table.insert(out, pandoc.RawInline("latex", "\\allowbreak{}"))
      end
    end
    if #out > 0 then return out end
  end
end
