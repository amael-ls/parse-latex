--- parse-latex.lua – parse and replace raw LaTeX snippets
---
--- Copyright: © 2021–2022 Albert Krewinkel
--- License: MIT – see LICENSE for details

--- Amael Le Squin: Added the possibility to ignore some environments

-- Makes sure users know if their pandoc version is too old for this
-- filter.
PANDOC_VERSION:must_be_at_least '2.9'

-- Return an empty filter if the target format is LaTeX: the snippets will be
-- passed through unchanged.
if FORMAT:match 'latex' then
  return {}
end

-- Function to read environments that should NOT be treated
local neglectEnv = pandoc.MetaMap({})
local beginEnvIgnore = {}
local backslashEnvIgnore = {}

function Meta(meta)
  for key, value in pairs(meta["parse-latex"]) do
    neglectEnv[key] = value
    if pandoc.utils.stringify(value) == "begin" then
      beginEnvIgnore[#beginEnvIgnore + 1] = tostring(key)
    end
    if pandoc.utils.stringify(value) == "backslash" then
      backslashEnvIgnore[#backslashEnvIgnore + 1] = tostring(key)
    end
  end
end

-- Helper to check if an environment is listed in toIgnore
local function ignore(env)
  for _, value in ipairs(beginEnvIgnore) do
    value = "\\begin{" .. value .. "}"
    if string.match(env, value) then
      return true
    end
  end

  for _, value in ipairs(backslashEnvIgnore) do
    value = "\\" .. value .. "{"
    if string.match(env, value) then
      return true
    end
  end

  return false
end

-- Parse and replace raw TeX blocks, leave all other raw blocks
-- alone.
function RawBlock (raw)
  if raw.format:match 'tex' then
    return pandoc.read(raw.text, 'latex').blocks
  end
end

-- Parse and replace raw TeX inlines, leave other raw inline
-- elements alone.
function RawInline(raw)
  if raw.format:match 'tex' then
    if ignore(raw.text) then
      return raw
    end
    return pandoc.utils.blocks_to_inlines(
      pandoc.read(raw.text, 'latex').blocks
    )
  end
end

return {
  { Meta = Meta },
  { RawBlock = RawBlock },
  { RawInline = RawInline }
}
