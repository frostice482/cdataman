G.ARGS.str_unpack_env = {
  Big = Big,
  OmegaMeta = OmegaMeta,
  to_big = to_big,
  uncompress_big = uncompress_big,
  inf = 1.79769e308,
}

function STR_UNPACK(str)
  local chunk = assert(load(str, '=[temp:str_unpack]', 'bt', G.ARGS.str_unpack_env))
  setfenv(chunk, G.ARGS.str_unpack_env)
  return chunk()
end

function Talisman.sanitize(obj, done)
  if not done then done = {} end
  if done[obj] then return obj end
  done[obj] = true

  for k,v in pairs(obj) do
    local t = type(v)
    if t == "table" then
      Talisman.sanitize(v, done)
    elseif Big and Big.is(v) then
      obj[k] = v:as_table()
    end
  end

  return obj
end

function Talisman.copy_table(obj, reflist)
  if not reflist then reflist = {} end
  if type(obj) ~= 'table' then return obj end
  if Big.is(obj) then return obj end
  if reflist[obj] then return reflist[obj] end

  local copy = {}
  reflist[obj] = copy
  for k, v in pairs(obj) do
      copy[Talisman.copy_table(k, reflist)] = Talisman.copy_table(v, reflist)
  end
  setmetatable(copy, Talisman.copy_table(getmetatable(obj), reflist))

  return copy
end

local copy_table_hook = copy_table
function copy_table(v)
  if not Talisman.config_file.enable_compat or not Big then return copy_table_hook(v) end
  return Talisman.copy_table(v)
end