local su = G.start_up
local function safe_str_unpack(str)
  local chunk, err = loadstring(str)
  if not chunk then
    print("[Talisman] Error loading string: " .. err)
    print(tostring(str))
    return nil
  end

  setfenv(chunk, {
    Big = Big,
    BigMeta = BigMeta,
    OmegaMeta = OmegaMeta,
    to_big = to_big,
    inf = 1.79769e308,
    uncompress_big =uncompress_big
  }) -- Use an empty environment to prevent access to potentially harmful functions

  local success, result = pcall(chunk)
  if not success then
    print("[Talisman] Error unpacking string: " .. result)
    print(tostring(str))
    return nil
  end

  return result
end

function G:start_up()
  STR_UNPACK = safe_str_unpack
  su(self)
  STR_UNPACK = safe_str_unpack
end

local function save_run_sanitize(obj, done)
  if done[obj] then return end
  done[obj] = true

  for k,v in pairs(obj) do
    local t = type(v)
    if t == "table" then
      save_run_sanitize(v, done)
    elseif Big and Big.is(v) then
      obj[k] = v:as_table()
    end
  end
end

local save_run_hook = save_run
function save_run()
  save_run_hook()
  save_run_sanitize(G.ARGS.save_run, {})
end

local function copy_table_internal(obj, reflist)
  if type(obj) ~= 'table' then return obj end
  if Big.is(obj) then return obj end
  if reflist[obj] then return reflist[obj] end

  local copy = {}
  reflist[obj] = copy
  for k, v in pairs(obj) do
      copy[copy_table_internal(k, reflist)] = copy_table_internal(v, reflist)
  end
  setmetatable(copy, copy_table_internal(getmetatable(obj), reflist))

  return copy
end

local copy_table_hook = copy_table
function copy_table(v)
  if not Talisman.config_file.enable_compat or not Big then return copy_table_hook(v) end
  return copy_table_internal(v, {})
end