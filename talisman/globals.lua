--- @meta

BigC = copy_table(require('big-num.constants'))

function is_big(x)
  return Big and Big.is(x)
end

function is_number(x)
  if type(x) == 'number' then return true end
  if is_big(x) then return true end
  return false
end

--- @return t.Omega | number
function to_big(x, y)
  if type(x) == 'string' and x == "0" then --hack for when 0 is asked to be a bignumber need to really figure out the fix
    return 0
  elseif Big then
    local result = Big:create(x)
    if y then result.sign = y end
    return result
  elseif is_number(x) then
    return x * 10^(y or 0)

  elseif type(x) == "nil" then
    return 0
  else
    if ((#x>=2) and ((x[2]>=2) or (x[2]==1) and (x[1]>308))) then
      return 1e309
    end
    if (x[2]==1) then
      return math.pow(10,x[1])
    end
    return x[1]*(y or 1);
  end
end

function to_number(x)
  if Big and Big.is(x) then
    return x:to_number()
  else
    return x
  end
end

function uncompress_big(str, sign)
    local curr = 1
    local array = {}
    for i, v in pairs(str) do
        for i2 = 1, v[2] do
            array[curr] = v[1]
            curr = curr + 1
        end
    end
    return to_big(array, y)
end

function lenient_bignum(x)
    return x
end
