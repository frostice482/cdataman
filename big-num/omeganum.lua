local ffi = require("ffi")
local R = require("big-num.constants")

ffi.cdef[[ struct TalismanOmega {}; ]]
local TalismanOmega = ffi.typeof("struct TalismanOmega")

--OmegaNum port by Mathguy

local bigs = {}
setmetatable(bigs, { __mode = 'k' })

--- @alias t.Omega.Parsable string | number | t.Omega

--- @class t.Omega: t.Omega.Proto
--- @operator add(t.Omega|number): t.Omega
--- @operator sub(t.Omega|number): t.Omega
--- @operator mul(t.Omega|number): t.Omega
--- @operator div(t.Omega|number): t.Omega
--- @operator mod(t.Omega|number): t.Omega
--- @operator pow(t.Omega|number): t.Omega
--- @operator unm(): t.Omega

--- @class t.Omega.Low: t.Omega.Proto
--- @field array number[]
--- @field sign number

--- @class t.Omega.Proto
--- @field protected array nil
--- @field unwrapped? boolean
local Big = {
    array = {},
}
local BigMetaSimple = { __index = Big }
OmegaMeta = {
    __index = {
        m = false,
        e = false
    }
}

local MAX_SAFE_INTEGER = 9007199254740991
local MAX_E = math.log(MAX_SAFE_INTEGER, 10)
local LONG_STRING_MIN_LENGTH = 17

-- this will be populated with bignum equivalents of R's values at the end of the file
--- @type table<string, t.Omega>
B = {}

--------------make the numbers look good----------------------


local function AThousandNotation(n, places)
    local raw = string.format("%." .. places .."f", n)
    local result = ""
    local comma = string.find(raw, "%.")

    if comma == nil then
        comma = #raw
    else
        comma = comma - 1
    end

    for i = 1, #raw do
        result = result .. string.sub(raw, i, i)
        if (comma - i) % 3 == 0 and i < comma then
            result = result .. ","
        end
    end
    return result
end

------------------------------------------------------

function Big.is(instance)
    return type(instance) == "cdata" and ffi.istype(instance, TalismanOmega)
end

function Big:assertUnwrapped()
    assert(self.unwrapped, "Object must be unwrapped with as_table()")
end

function Big:arraySize()
    local total = 0
    for i, v in pairs(self:get_array()) do
        if type(i) == "number" and v ~= 0 then
            total = i
        end
    end
    return total
end

--- @return t.Omega
function Big:new(arr)
    local obj = TalismanOmega()
    bigs[obj] = setmetatable({
        array = arr,
        sign = 1
    }, BigMetaSimple)
    Big.normalize(bigs[obj])
    return obj --- @diagnostic disable-line
end

function Big:isNaN()
    self = self:as_table()
    return self.array[1] ~= self.array[1]
end

function Big:isInfinite()
    self = self:as_table()
    return (self.array[1] == R.POSITIVE_INFINITY) or (self.array[1] == R.NEGATIVE_INFINITY)
end

function Big:isFinite()
    return (not self:isInfinite() and not self:isNaN())
end

--- @param self t.Omega
function Big:isint()
    if (self:get_sign()==-1) then
        return self:abs():isint()
    end
    if (self:gt(B.MAX_SAFE_INTEGER)) then
        return true;
    end
    local num = self:to_number()
    if (math.floor(num) == num) then
        return true
    end
    return Big:create(math.floor(self:to_number())) == self;
end

--- @param other t.Omega.Parsable
function Big:compareTo(other)
    self = self:as_table()
    local other = Big:ensureBig(other):as_table()
    local other_array_size = other:arraySize()
    local self_array_size = self:arraySize()
    if ((self.array[1] ~= self.array[1]) or (other.array[1] ~= other.array[1])) then
        return R.NaN;
    end
    if ((self.array[1]==R.POSITIVE_INFINITY) and (other.array[1]~=R.POSITIVE_INFINITY)) then
        return self.sign
    end
    if ((self.array[1]~=R.POSITIVE_INFINITY) and (other.array[1]==R.POSITIVE_INFINITY)) then
        return other.sign
    end
    if ((self_array_size==1) and (self.array[1]==other.array[1]) and (other_array_size==1)) then
        --return 0
    end
    if (self.sign~=other.sign) then
        return self.sign
    end
    local m = self.sign;
    local r = nil;
    if (self_array_size>other_array_size) then
        r = 1;
    elseif (self_array_size<other_array_size) then
        r = -1;
    else
        if self_array_size == 1 then
            if self.array[1] > other.array[1]  then
                return 1 * m
            elseif self.array[1] < other.array[1] then
                return -1 * m
            else
                return 0
            end
        end
        local barray = {}
        for i, v in pairs(self.array) do
            barray[#barray+1]=i
        end
        --make sure to include both sets of indeces so that it actually checks every non 0 value
        for i, v in pairs(other.array) do
            barray[#barray+1]=i
        end
        table.sort(barray, function(a,b) return a > b end)
        for i, v in pairs(barray) do
            if ((self.array[v] or 0)>(other.array[v] or 0)) then
                r = 1;
                break;
            elseif ((self.array[v] or 0)<(other.array[v] or 0)) then
                r = -1
                break
            end
            r = r or 0;
        end
    end
    return r * m;
end

--- @param other t.Omega.Parsable
function Big:lt(other)
    return self:compareTo(other) < 0
end

--- @param other t.Omega.Parsable
function Big:gt(other)
    return self:compareTo(other) > 0
end

--- @param other t.Omega.Parsable
function Big:lte(other)
    return self:compareTo(other) <= 0
end

--- @param other t.Omega.Parsable
function Big:gte(other)
    return self:compareTo(other) >= 0
end

--- @param other t.Omega.Parsable
function Big:eq(other)
    return self:compareTo(other) == 0
end

--- @return t.Omega
function Big:neg()
    local x = self:clone();
    local w = x:as_table()
    w.sign = w.sign * -1;
    return x;
end

--- @param self t.Omega
--- @return t.Omega
function Big:abs()
    if self:get_sign() == 1 then return self end

    local x = self:clone();
    x:as_table().sign = 1;
    return x;
end

--- @param self t.Omega
--- @param other t.Omega.Parsable
--- @return t.Omega
function Big:min(other)
    if (self:lt(other)) then
        return self
    else
        return Big:ensureBig(other)
    end
end

--- @param self t.Omega
--- @param other t.Omega.Parsable
--- @return t.Omega
function Big:max(other)
    if (self:gt(other)) then
        return self
    else
        return Big:ensureBig(other)
    end
end

--- @param self t.Omega
--- @return t.Omega
function Big:normalize()
    local b = nil
    local x = self:as_table()
    if ((x.array == nil) or (type(x.array) ~= "table") or (Big.arraySize(x) == 0)) then
        x.array = {0}
    end
    if (Big.arraySize(x) == 1) and (x.array[1] == 0) then
        x.sign = 1
        return self
    end
    if (Big.arraySize(x) == 1) and (x.array[1] < 0) then
        x.sign = -1
        x.array[1] = -x.array[1]
    end
    if ((x.sign~=1) and (x.sign~=-1)) then
    --   if (typeof x.sign!="number") x.sign=Number(x.sign);
        if (x.sign < 0) then
            x.sign = -1;
        else
            x.sign = 1;
        end
    end
    for i, v in pairs(x.array) do
        local e = x.array[i] or 0;
        if (e ~= e) then
            x.array={R.NaN};
            return self
        end
        if (e == R.POSITIVE_INFINITY) or (e == R.NEGATIVE_INFINITY) then
            x.array = {R.POSITIVE_INFINITY};
            return self
        end
        if (i ~= 1) then
            x.array[i]=math.floor(e)
        end
        --first 3 values kept because they are hardcoded in a few places
        --it also doesnt hurt memory that much to keep them anyway
        if ((e == 0)) and i > 3 then
            x.array[i] = nil
        end
    end
    local doOnce = true
    while (doOnce or b) do
    --   if (OmegaNum.debug>=OmegaNum.ALL) console.log(x.toString());
        b=false;
        while ((Big.arraySize(x) ~= 0) and (x.array[Big.arraySize(x)]==0)) do
            x.array[Big.arraySize(x)] = nil;
            b=true;
        end
        if ((x.array[1] or 0) > R.MAX_DISP_INTEGER) then --modified, should make printed values easier to display
            x.array[2]=(x.array[2] or 0) + 1;
            x.array[1]= math.log(x.array[1], 10);
            b=true;
        end
        while (((x.array[1] or 0) < math.log(R.MAX_DISP_INTEGER,10)) and ((x.array[2] ~= nil) and (x.array[2] ~= 0))) do
            x.array[1] = math.pow(10,x.array[1]);
            x.array[2] = x.array[2] - 1
            b=true;
        end
        -- if ((x:arraySize()>2) and ((x.array[2] == nil) or (x.array[2] == 0))) then
        --     local i = 3
        --     while (x.array[i] == nil) or (x.array[i] == 0) do
        --         i = i + 1
        --     end
        --     x.array[i-1]=x.array[1];
        --     x.array[1]=1;
        --     x.array[i] = x.array[i] - 1
        --     b=true;
        -- end
        doOnce = false;
        --l = x:arraySize()
        for i, v in pairs(x.array) do
            if type(i) == "number" then
                if ((x.array[i] or 0)>R.MAX_SAFE_INTEGER) then
                    x.array[i+1]=(x.array[i+1] or 0)+1;
                    x.array[1]=x.array[i]+1;
                    for j=2,i do
                        x.array[j]=0;
                    end
                    b=true;
                end
            end
        end
    end
    if (Big.arraySize(x) == 0) and #x.array ~= 1 then
        x.array = {0}
    end
    return self
end

--- @return string
function Big:toString()
    self = self:as_table()
    if (self.sign==-1) then
        return "-" .. self:abs():toString()
    end
    if (self.array[1] ~= self.array[1]) then
        return "NaN"
    end
    -- if (!isFinite(this.array[0])) return "Infinity";
    local s = "";
    if (self:arraySize()>=2) then
        for i=self:arraySize(),3,-1 do
            local q = nil
            if (i >= 6) then
                q = "{"..(i-1).."}"
            else
                q = string.rep("^", i-1)
            end
            if (self.array[i]>1) then
                s = s .."(10" .. q .. ")^" .. AThousandNotation(self.array[i], 0) .. " "
            elseif (self.array[i]==1) then
                s= s .."10" .. q;
            end
        end
    end
    if (self.array[2] == nil) or (self.array[2] == 0) then
        if (self.array[1] <= 9e9) then
            s = s .. AThousandNotation(self.array[1], 2)
        else
            local exponent = math.floor(math.log(self.array[1], 10))
            local mantissa = math.floor((self.array[1] / (10^exponent))*100)/100
            s = s .. AThousandNotation(mantissa, 2) .. "e" .. AThousandNotation(exponent, 0)
        end
    elseif (self.array[2]<3) then
        s = s .. string.rep("e", self.array[2]-1) .. AThousandNotation(math.pow(10,self.array[1]-math.floor(self.array[1])), 2) .. "e" .. AThousandNotation(math.floor(self.array[1]), 0);
    elseif (self.array[2]<8) then
        s = s .. string.rep("e", self.array[2]) .. AThousandNotation(self.array[1], 0)
    else
        s = s .. "(10^)^" .. AThousandNotation(self.array[2], 0) .. " " .. AThousandNotation(self.array[1],0)
    end
    return s
end

function log10LongString(str)
    return math.log(tonumber(string.sub(str, 1, LONG_STRING_MIN_LENGTH)), 10)+(string.len(str)- LONG_STRING_MIN_LENGTH);
end

--- @return t.Omega
function Big:parse(input)
    -- if (typeof input!="string") throw Error(invalidArgument+"Expected String");
    -- var isJSON=false;
    -- if (typeof input=="string"&&(input[0]=="["||input[0]=="{")){
    --   try {
    --     JSON.parse(input);
    --   }finally{
    --     isJSON=true;
    --   }
    -- }
    -- if (isJSON){
    --   return OmegaNum.fromJSON(input);
    -- }
    local t = Big:new({0})
    local x = t:as_table()
    -- if (!isOmegaNum.test(input)){
    --   console.warn(omegaNumError+"Malformed input: "+input);
    --   x.array=[NaN];
    --   return x;
    -- }
    local negateIt = false
    while ((string.sub(input, 1, 1)=="-") or (string.sub(input, 1, 1)=="+")) do
        if (string.sub(input, 1, 1)=="-") then
            negateIt = not negateIt
        end
        input = string.sub(input, 2);
    end
    if (input=="NaN") or (input=="nan") then
        x.array = {R.NaN}
    elseif (input=="Infinity") or (input=="inf") then
        x.array = {R.POSITIVE_INFINITY}
    else
        --- @type number | number[]
        local a = 0
        --- @type number | number[]
        local b = 0
        local c = 0
        local d = 0
        local i = 0
        while (string.len(input) > 0) do
            local passTest = false
            if true then
                local j = 1
                if string.sub(input, 1, 1) == "(" then
                    j = j + 1
                end
                if (string.sub(input, j, j+1) == "10") and ((string.sub(input, j+2, j+2) == "^") or (string.sub(input, j+2, j+2) == "{")) then
                    passTest = true
                end
            end
            if (passTest) then
                if (string.sub(input, 1, 1) == "(") then
                input = string.sub(input, 2);
                end
                local arrows = -1;
                if (string.sub(input, 3, 3)=="^") then
                    arrows = 3
                    while (string.sub(input, arrows, arrows) == "^") do
                        arrows = arrows + 1
                    end
                    arrows = arrows - 3
                    a = arrows
                    b = arrows + 2;
                else
                    a = 1
                    while (string.sub(input, a, a) ~= "}") do
                        a = a + 1
                    end
                    arrows=tonumber(string.sub(input, 4, a - 1))+1;
                    b = a + 1
                end
                --[[if (arrows >= maxArrow) then
                -- console.warn("Number too large to reasonably handle it: tried to "+arrows.add(2)+"-ate.");
                    x.array = {R.POSITIVE_INFINITY};
                    break;
                end--]]
                input = string.sub(input, b + 1);
                if (string.sub(input, 1, 1) == ")") then
                    a = 1
                    while (string.sub(input, a, a) ~= " ") do
                        a = a + 1
                    end
                    c = tonumber(string.sub(input, 3, a - 1)) or 0;
                    input = string.sub(input, a+1);
                else
                    c = 1
                end
                if (arrows==1) then
                    x.array[2] = (x.array[2] or 0) + c;
                elseif (arrows==2) then
                    a = x.array[2] or 0;
                    b = x.array[1] or 0;
                    if (b>=1e10) then
                        a = a + 1
                    end
                    if (b>=10) then
                        a = a + 1
                    end
                    x.array[1]=a;
                    x.array[2]=0;
                    x.array[3]=(x.array[3] or 0)+c;
                else
                    a=x.array[arrows] or 0;
                    b=x.array[arrows-1] or 0;
                    if (b>=10) then
                        a = a + 1
                    end
                    for i=1, arrows do
                        x.array[i] = 0;
                    end
                    x.array[1]=a;
                    x.array[arrows+1] = (x.array[arrows+1] or 0) + c;
                end
            else
                break
            end
        end
        a = {""} --- @diagnostic disable-line
        while (string.len(input) > 0) do
            if ((string.sub(input, 1, 1) == "e") or (string.sub(input, 1, 1) == "E")) then
                a[#a + 1] = ""
            else
                a[#a] = a[#a] .. string.sub(input, 1, 1)
            end
            input = string.sub(input, 2);
        end
        if a[#a] == "" then
            a[#a] = nil
        end
        b={x.array[1],0};
        c=1;
        for i=#a, 1, -1 do
            if ((b[1] < MAX_E) and (b[2]==0)) then
                b[1] = math.pow(10,c*b[1]);
            elseif (c==-1) then
                if (b[2]==0) then
                    b[1]=math.pow(10,c*b[1]);
                elseif ((b[2]==1) and (b[1]<=308)) then
                    b[1] = math.pow(10,c*math.pow(10,b[1]));
                else
                    b[1]=0;
                end
                b[2]=0;
            else
                b[2] = b[2] + 1;
            end
            local decimalPointPos = 1;
            while ((string.sub(a[i], decimalPointPos, decimalPointPos) ~= ".") and (decimalPointPos <= #a[i])) do
                decimalPointPos = decimalPointPos + 1
            end
            if decimalPointPos == #a[i] + 1 then
                decimalPointPos = -1
            end
            local intPartLen = -1
            if (decimalPointPos == -1) then
                intPartLen = #a[i] + 1
            else
                intPartLen = decimalPointPos
            end
            if (b[2] == 0) then
                if (intPartLen - 1 >= LONG_STRING_MIN_LENGTH) then
                    b[1] = math.log10(b[1]) + log10LongString(string.sub(a[i], 1, intPartLen - 1))
                    b[2] = 1;
                elseif ((a[i] ~= nil) and (a[i] ~= "") and (tonumber(a[i]) ~= nil)) then
                    b[1] = b[1] * tonumber(a[i]);
                end
            else
                d=-1
                if (intPartLen - 1 >= LONG_STRING_MIN_LENGTH) then
                    d = log10LongString(string.sub(a[i], 1,intPartLen - 1))
                else
                    if (a[i] ~= nil) and (a[i] ~= "") and (tonumber(a[i]) ~= nil) then
                        d = math.log(tonumber(a[i]), 10)
                    else
                        d = 0
                    end
                end
                if (b[2]==1) then
                    b[1] = b[1] + d;
                elseif ((b[2]==2) and (b[1]<MAX_E+math.log(d, 10))) then
                    b[1] = b[1] + math.log(1+math.pow(10,math.log10(d)-b[0]), 10);
                end
            end
            if ((b[1]<MAX_E) and (b[2] ~= 0) and (b[2] ~= nil)) then
                b[1]=math.pow(10,b[1]);
                b[2] = b[2] - 1;
            elseif (b[1]>MAX_SAFE_INTEGER) then
                b[1] = math.log(b[1], 10);
                b[2] = b[2] + 1;
            end
        end
        x.array[1]= b[1];
        x.array[2]= (x.array[2] or 0) + b[2];
    end
    if (negateIt) then
        x.sign = x.sign * -1
    end
    t:normalize();
    return t;
end

--- @return number
function Big:to_number()
    self = self:as_table()
    -- //console.log(this.array);
    if (self.sign==-1) then
        return -1*(self:neg():to_number());
    end
    if not self.array[1] then return 0 end
    if self.array[2] == nil then self.array[2] = 0 end
    if ((self:arraySize()>=2) and ((self.array[2]>=2) or (self.array[2]==1) and (self.array[1]>308))) then
        return R.POSITIVE_INFINITY;
    end
    if (self:arraySize() >= 3) and ((self.array[1] >= 3) or (self.array[2] >= 1) or (self.array[3] >= 1)) then
        return R.POSITIVE_INFINITY;
    end
    if (self:arraySize() >= 4) and ((self.array[1] > 1) or (self.array[2] >= 1) or (self.array[3] >= 1)) then
        for i, v in pairs(self.array) do
            if self.array[i] > 0 and i > 4 then
                return R.POSITIVE_INFINITY;
            end
        end
    end
    if (Big.is(self.array[1])) then
        self.array[1] = self.array[1]:to_number() --- @diagnostic disable-line
    end
    if (self.array[2]==1) then
        return math.pow(10,self.array[1]);
    end
    return self.array[1];
end

--- @param self t.Omega
--- @return t.Omega
function Big:floor()
    if (self:isint()) then
        return self
    end
    return Big:create(math.floor(self:to_number()));
end

--- @param self t.Omega
--- @return t.Omega
function Big:ceil()
    if (self:isint()) then
        return self
    end
    return Big:create(math.ceil(self:to_number()));
end

--- @return t.Omega
function Big:clone()
    self = self:as_table()
    local newArr = {}
    for i, j in pairs(self.array) do
        newArr[i] = j
    end
    local result = Big:new(newArr)
    result:as_table().sign = self.sign
    return result
end

--- @return t.Omega
function Big:create(input)
    if ((type(input) == "number")) then
        return Big:new({input})
    elseif ((type(input) == "string")) then
        return Big:parse(input)
    elseif Big.is(input) then
        return input
    else
        return Big:new(input)
    end
end

--- @return t.Omega
function Big:ensureBig(input)
    if Big.is(input) then
        return input
    else
        return Big:create(input)
    end
end

--- @param self t.Omega
--- @return t.Omega
function Big:add(other)
    local x = self:as_table()
    local other_m = Big:ensureBig(other)
    other = other_m:as_table()
    -- if (OmegaNum.debug>=OmegaNum.NORMAL){
    --   console.log(this+"+"+other);
    --   if (!debugMessageSent) console.warn(omegaNumError+"Debug output via 'debug' is being deprecated and will be removed in the future!"),debugMessageSent=true;
    -- }
    if (x.sign==-1) then
        return x:neg():add(other:neg()):neg()
    end
    if (other.sign==-1) then
        return self:sub(other:neg());
    end
    if (x:eq(B.ZERO)) then
        return other_m
    end
    if (other:eq(B.ZERO)) then
        return self
    end
    if (x:isNaN() or other:isNaN() or (x:isInfinite() and other:isInfinite() and x:eq(other:neg()))) then
        return B.NaN;
    end
    if (x:isInfinite()) then
        return self
    end
    if (other:isInfinite()) then
        return other_m
    end
    local pw=self:min(other_m);
    local p=x:as_table();
    local qw=self:max(other_m);
    local q=x:as_table();
    local t = B.NEG_ONE;
    if (p.array[2] == 2) and not p:gt(B.E_MAX_SAFE_INTEGER) then
        p.array[2] = 1
        p.array[1] = 10 ^ p.array[1]
    end
    if (q.array[2] == 2) and not q:gt(B.E_MAX_SAFE_INTEGER) then
        q.array[2] = 1
        q.array[1] = 10 ^ q.array[1]
    end
    if (q:gt(B.E_MAX_SAFE_INTEGER) or qw:div(p):gt(B.MAX_SAFE_INTEGER)) then
        t = qw;
    elseif (q.array[2] == nil) or (q.array[2] == 0) then
        t= Big:create(x:to_number()+other:to_number());
    elseif (q.array[2]==1) then
        local a
        if (p.array[2] ~= nil) and (p.array[2] ~= 0) then
            a = p.array[1]
        else
            a = math.log(p.array[1], 10)
        end
        t = Big:new({a+math.log(math.pow(10,q.array[1]-a)+1, 10),1});
    end
    return t;
end

--- @param self t.Omega
--- @param other t.Omega.Parsable
--- @return t.Omega
function Big:sub(other)
    local x = self
    other = Big:ensureBig(other)
    -- if (OmegaNum.debug>=OmegaNum.NORMAL) console.log(x+"-"+other);
    if (x:get_sign() ==-1) then
        return x:neg():sub(other:neg()):neg()
    end
    if (other:get_sign() ==-1) then
        return x:add(other:neg())
    end
    if (x:eq(other)) then
        return B.ZERO
    end
    if (other:eq(B.ZERO)) then
        return x
    end
    if (x:isNaN() or other:isNaN() or (x:isInfinite() and other:isInfinite() and x:eq(other:neg()))) then
        return B.NaN
    end
    if (x:isInfinite()) then
        return x
    end
    if (other:isInfinite()) then
        return other:neg()
    end
    local pw=x:min(other);
    local p=x:as_table();
    local qw=x:max(other);
    local q=x:as_table();
    local n = other:gt(x);
    local t = B.NEG_ONE;
    if (p.array[2] == 2) and not p:gt(B.E_MAX_SAFE_INTEGER) then
        p.array[2] = 1
        p.array[1] = 10 ^ p.array[1]
    end
    if (q.array[2] == 2) and not q:gt(B.E_MAX_SAFE_INTEGER) then
        q.array[2] = 1
        q.array[1] = 10 ^ q.array[1]
    end
    if (q:gt(B.E_MAX_SAFE_INTEGER) or qw:div(p):gt(B.MAX_SAFE_INTEGER)) then
        t = qw;
        if n then
            t = t:neg()
        else
            t = t
        end
    elseif (q.array[2] == nil) or (q.array[2] == 0) then
        t = Big:create(x:to_number()-other:to_number());
    elseif (q.array[2]==1) then
        local a
        if (p.array[2] ~= nil) and (p.array[2] ~= 0) then
            a = p.array[1]
        else
            a = math.log(p.array[1], 10)
        end

        t = Big:new({a+math.log(math.pow(10,q.array[1]-a)-1, 10),1});
        if n then
            t = t:neg()
        else
            t = t
        end
    end
    return t;
end

--- @param self t.Omega
--- @return t.Omega
function Big:div(other)
    local x = self;
    other = Big:ensureBig(other);
    if (x:get_sign()*other:get_sign()==-1) then
        return x:abs():div(other:abs()):neg()
    end
    if (x:get_sign()==-1) then
        return x:abs():div(other:abs())
    end
    if (x:isNaN() or other:isNaN() or (x:isInfinite() and other:isInfinite() and x:eq(other:neg()))) then
        return B.NaN
    end
    if (other:eq(B.ZERO)) then
        return B.POSITIVE_INFINITY
    end
    if (other:eq(B.ONE)) then
        return x
    end
    if (x:eq(other)) then
        return B.ONE
    end
    if (x:isInfinite()) then
        return x
    end
    if (other:isInfinite()) then
        return B.ZERO
    end
    if (x:max(other):gt(B.EE_MAX_SAFE_INTEGER)) then
        if x:gt(other) then
            return x
        else
            return B.ZERO
        end
    end
    local n = x:to_number()/other:to_number();
    if (n<=MAX_SAFE_INTEGER) then
        return Big:create(n)
    end
    local pw = B.TEN:pow(x:log10():sub(other:log10()))
    local fp = pw:floor()
    if (pw:sub(fp):lt(Big:create(1e-9))) then
        return fp
    end
    return pw
end

--- @return t.Omega
function Big:mul(other)
    local x = Big:ensureBig(self);
    other = Big:ensureBig(other);
    -- if (OmegaNum.debug>=OmegaNum.NORMAL) console.log(x+"*"+other);
    if (x:get_sign()*other:get_sign()==-1) then
        return x:abs():mul(other:abs()):neg()
    end
    if (x:get_sign()==-1) then
        return x:abs():mul(other:abs())
    end
    if (x:isNaN() or other:isNaN() or (x:isInfinite() and other:isInfinite() and x:eq(other:neg()))) then
        return B.NaN
    end
    if (other:eq(B.ZERO)) or x:eq(B.ZERO) then
        return B.ZERO
    end
    if (other:eq(B.ONE)) then
        return x
    end
    if (x:eq(B.ONE)) then
        return other
    end
    if (x:isInfinite()) then
        return x
    end
    if (other:isInfinite()) then
        return other
    end
    if (x:max(other):gt(B.EE_MAX_SAFE_INTEGER)) then
        return x:max(other)
    end
    local n = x:to_number()*other:to_number()
    if (n<=MAX_SAFE_INTEGER) then
        return Big:create(n)
    end
    return B.TEN:pow(x:log10():add(other:log10()));
end

--- @param self t.Omega
--- @return t.Omega
function Big:rec()
    if (self:isNaN() or self:eq(B.ZERO)) then
        return B.NaN
    end
    if (self:abs():gt("2e323")) then
        return B.ZERO
    end
    return B.ONE:div(self)
end

--- @param self t.Omega
--- @return t.Omega
function Big:logBase(base)
    return self:log10():div(base:log10())
end

Big.log = Big.logBase

--- @param self t.Omega
--- @return t.Omega
function Big:log10()
    local x = self;
    -- if (OmegaNum.debug>=OmegaNum.NORMAL) console.log("log"+this);
    if (x:lt(B.ZERO)) then
        return B.NaN
    end
    if (x:eq(B.ZERO)) then
        return B.NEGATIVE_INFINITY
    end
    if (x:lte(B.MAX_SAFE_INTEGER)) then
        return Big:create(math.log(x:to_number(), 10))
    end
    if (not x:isFinite()) then
        return x
    end
    if (x:gt(B.TETRATED_MAX_SAFE_INTEGER)) then
        return x
    end
    x = x:clone()
    local w = x:get_array()
    w[2] = (w[2] or 0) - 1;
    return x:normalize()
end

--- @param self t.Omega
--- @return t.Omega
function Big:ln()
    return self:log10():div(B.E_LOG)
end

--- @param self t.Omega
--- @return t.Omega
function Big:pow(other)
    other = Big:ensureBig(other);
    -- if (OmegaNum.debug>=OmegaNum.NORMAL) console.log(this+"^"+other);
    if (other:eq(B.ZERO)) then
        return B.ONE
    end
    if (other:eq(B.ONE)) then
        return self
    end
    if (other:lt(B.ZERO)) then
        return self:pow(other:neg()):rec()
    end
    if (self:lt(B.ZERO) and other:isint()) then
        if (other:mod(2):lt(B.ONE)) then
            return self:abs():pow(other)
        end
        return self:abs():pow(other):neg()
    end
    if (self:lt(B.ZERO)) then
        --return B.NaN
        --Override this interaction to always make positive numbers
        return self:abs():pow(other)
    end
    if (self:eq(B.ONE)) then
        return B.ONE
    end
    if (self:eq(B.ZERO)) then
        return B.ZERO
    end
    if (self:max(other):gt(B.TETRATED_MAX_SAFE_INTEGER)) then
        return self:max(other);
    end
    if (self:eq(10)) then
        if (other:gt(B.ZERO)) then
            other = other:clone();
            local w = other:get_array()
            w[2] = (w[2] or 0) + 1;
            other:normalize();
            return other;
        else
            return Big:create(math.pow(10,other:to_number()));
        end
    end
    if (other:lt(B.ONE)) then
        return self:root(other:rec())
    end
    local n = math.pow(self:to_number(),other:to_number())
    if (n<=MAX_SAFE_INTEGER) then
        return Big:create(n);
    end
    return B.TEN:pow(self:log10():mul(other));
end

--- @return t.Omega
function Big:exp()
    return B.E:pow(self)
end

--- @param self t.Omega
--- @return t.Omega
function Big:root(other)
    other = Big:ensureBig(other)
    -- if (OmegaNum.debug>=OmegaNum.NORMAL) console.log(this+"root"+other);
    if (other:eq(B.ONE)) then
        return self
    end
    if (other:lt(B.ZERO)) then
        return self:root(other:neg()):rec()
    end
    if (other:lt(B.ONE)) then
        return self:pow(other:rec())
    end
    if (self:lt(B.ZERO) and other:isint() and other:mod(2):eq(B.ONE)) then
        return self:neg():root(other):neg()
    end
    if (self:lt(B.ZERO)) then
        return B.NaN
    end
    if (self:eq(B.ONE)) then
        return B.ONE
    end
    if (self:eq(B.ZERO)) then
        return B.ZERO
    end
    if (self:max(other):gt(B.TETRATED_MAX_SAFE_INTEGER)) then
        if self:gt(other) then
            return self
        else
            return B.ZERO
        end
    end
    return B.TEN:pow(self:log10():div(other));
end

--- @param self t.Omega
--- @return t.Omega
function Big:slog(base)
    if base == nil then
        base = 10
    end
    local x = self
    base = Big:ensureBig(base)
    if (x:isNaN() or base:isNaN() or (x:isInfinite() and base:isInfinite())) then
        return B.NaN
    end
    if (x:isInfinite()) then
        return x
    end
    if (base:isInfinite()) then
        return B.ZERO
    end
    if (x:lt(B.ZERO)) then
        return Big:create(-R.ONE)
    end
    if (x:lt(B.ONE)) then
        return B.ZERO
    end
    if (x:eq(base)) then
        return B.ONE
    end
    if (base:lt(math.exp(1/R.E))) then
        local a = base:tetrate(1/0)
        if (x:eq(a)) then
            return B.POSITIVE_INFINITY
        end
        if (x:gt(a)) then
            return B.NaN
        end
    end
    if (x:max(base):gt("10^^^" .. R.MAX_SAFE_INTEGER)) then
        if (x:gt(base)) then
            return x;
        end
        return B.ZERO
    end
    if (x:max(base):gt(B.TETRATED_MAX_SAFE_INTEGER)) then
        if x:gt(base) then
            x = x:clone()
            local w = x:get_array()
            w[3] = (w[3] or 0) - 1
            x:normalize()
            return x:sub(w[2])
        end
        return B.ZERO
    end
    x = x:clone()
    local w = x:get_array()
    local r = 0
    local t = (w[2] or 0) - (base:get_array()[2] or 0)
    if (t > 3) then
        local l = t - 3
        r = r + l
        w[2] = w[2] - l
    end
    for i = 0, 99 do
        if x:lt(B.ZERO) then
            x = base:pow(x)
            r = r - 1
        elseif (x:lte(B.ONE)) then
            return Big:create(r + x:to_number() - 1)
        else
            r = r + 1
            x = x:logBase(base)
        end
    end
    if (x:gt(10)) then
        return Big:create(r)
    end
    error('?')
end

--- @param self t.Omega
--- @return t.Omega
function Big:tetrate(other)
    local t = self
    if other == 1 then return Big:create(self) end
    other = Big:ensureBig(other)
    local negln = nil
    if (t:isNaN() or other:isNaN()) then
        return B.NaN
    end
    if (other:isInfinite() and other:get_sign() > 0) then
        negln = t:ln():neg()
        return negln:lambertw():div(negln)
    end
    if (other:lte(-2)) then
        return B.NaN
    end
    if (t:eq(B.ZERO)) then
        if (other:eq(B.ZERO)) then
            return B.NaN
        end
        if (other:mod(2):eq(B.ZERO)) then
            return B.ZERO
        end
        return B.ONE
    end
    if (t:eq(B.ONE)) then
        if (other:eq(-1)) then
            return B.NaN
        end
        return B.ONE
    end
    if (other:eq(-1)) then
        return B.ZERO
    end
    if other:eq(B.ZERO) then
        return B.ONE
    end
    if other:eq(B.ONE) then
        return t
    end
    if other:eq(2) then
        return t:pow(t)
    end
    if t:eq(2) then
        if other:eq(3) then
            return Big:create({16})
        end
        if other:eq(4) then
            return Big:create({65536})
        end
    end
    local m = t:max(other)
    if (m:gt(Big:create("10^^^" .. tostring(R.MAX_SAFE_INTEGER)))) then
        return m
    end
    if (m:gt(B.TETRATED_MAX_SAFE_INTEGER) or other:gt(R.MAX_SAFE_INTEGER)) then
        if (t:lt(math.exp(1/R.E))) then
            negln = t:ln():neg()
            return negln:lambertw():div(negln)
        end
        local j = t:slog(10):add(other)
        local w = j:get_array()
        w[3]=(w[3] or 0) + 1
        j:normalize()
        return j
    end
    local y = other:to_number()
    local f = math.floor(y)
    local r = t:pow(y-f)
    local l = B.NaN
    local i = 0
    local m = B.E_MAX_SAFE_INTEGER
    while ((f ~= 0) and r:lt(m) and (i < 100)) do
        if (f > 0) then
            r = t:pow(r)
            if (l:eq(r)) then
                f = 0
                break
            end
            l = r
            f = f - 1
        else
            r = r:logBase(t)
            if (l:eq(r)) then
                f = 0
                break
            end
            l = r
            f = f + 1
        end
    end
    if ((i == 100) or t:lt(math.exp(1/R.E))) then
        f = 0
    end
    local w = r:get_array()
    w[2] = (w[2] or 0) + f
    r:normalize()
    return r;
end

--- @return t.Omega
function Big:max_for_op(arrows)
    if Big.is(arrows) then
        arrows = arrows:to_number()
    end
    if arrows < 1 or arrows ~= arrows or arrows == R.POSITIVE_INFINITY then
        return B.NaN
    end
    if arrows == 1 then
        return B.E_MAX_SAFE_INTEGER
    end
    if arrows == 2 then
        return B.TETRATED_MAX_SAFE_INTEGER
    end

    local arr = {}
    arr[1] = 10e9
    arr[arrows] = R.MAX_SAFE_INTEGER - 2
    for i = 2, math.min(arrows - 1, 1e6) do
        arr[i] = 8
    end
    if arrows > 1e6 then
        local limit = math.floor(math.log(arrows, 10))
        for i = 6, limit do
            arr[10^i] = 8
        end
    end
    arr[arrows - 1] = 8

    local res = Big:new({0})
    res.array = arr
    return res
end

--- @return t.Omega
function Big:arrow(arrows, other)
    local t = self:clone()
    if arrows > 1e308 then --if too big return infinity
        return Big:create(R.POSITIVE_INFINITY)
    end
    local oldarrows = to_number(arrows)
    arrows = Big:ensureBig(arrows)
    if oldarrows >= 1e6 then --needed to stop "Infinity"
        arrows = arrows:floor()
    end
    if oldarrows == 1 then
        return Big:create(self)
    end
    if self:eq(B.ONE) then return B.ONE end
    if self:eq(B.ZERO) then return B.ZERO end
    --idk why but arrows above 1e6 just sometimes randomly get treated as non ints even though they are
    --this is technically inaccurate now but i think 1e7 +0.1 counting as an integer amount of arrow here is fine
    if (not arrows:isint() or arrows:lt(B.ZERO)) and arrows:lt(1e6) then
        return B.NaN
    end
    if type(oldarrows) == "number" and oldarrows ~= math.floor(oldarrows) and oldarrows < 1e6 then
        return B.NaN
    end
    if arrows:eq(B.ZERO) then
        return t:mul(other)
    end
    if arrows:eq(B.ONE) or oldarrows == 1 then
        return t ^ other--t:pow(other) idk why this was causing issues but it was so now theres this
    end
    if arrows:eq(2) or oldarrows == 2 then
        return t:tetrate(other)
    end
    other = Big:create(other)
    if (other:lt(B.ZERO)) then
        return B.NaN
    end
    if (other:eq(B.ZERO)) then
        return B.ONE
    end
    if (other:eq(B.ONE)) then
        return t
    end
    if self:eq(2) and other:eq(2) then
        -- handle infinite arrows
        if arrows:isInfinite() then return Big:create(R.POSITIVE_INFINITY) end

        return Big:create(4)
    end
    --[[if (arrows:gte(maxArrow)) then
        return B.POSITIVE_INFINITY
    end--]]

    --remove potential error from before
    local arrowsNum = math.floor(oldarrows)
    if (other:eq(2)) then
        return t:arrow(arrowsNum - 1, t)
    end
    local limit_plus = Big:max_for_op(arrowsNum+1)
    local limit = Big:max_for_op(arrowsNum)
    local limit_minus = Big:max_for_op(arrowsNum-1)
    if (t:max(other):gt(limit_plus)) then
        return t:max(other)
    end
    local r = nil
    -- if arrows >= Big:ensureBig(3500) then
    --     if self:arrow(100, self) > other then
    --         return Big:new({
    --             [1] = math.min(to_number(math.log(other, 10)), 1e300),
    --             [2] = 0,
    --             [3] = 0,
    --             [to_number(arrows)+1] = 1
    --         })
    --     end
    -- end
    if (t:gt(limit) or other:gt(B.MAX_SAFE_INTEGER)) or arrows >= Big:ensureBig(350) then --just kinda chosen randomly
        if (t:gt(limit)) then
            r = t:clone()
            local w = r:get_array()
            w[arrowsNum + 1] = w[arrowsNum + 1] - 1
            if arrowsNum < 25000 then --arbitrary, normalisation is just extra steps when you get high enough
                r:normalize()
            end
        elseif (t:gt(limit_minus)) then
            r = Big:create(t:get_array()[arrowsNum])
        else
            r = B.ZERO
        end
        local j = r:add(other)
        local w = j:get_array()
        w[arrowsNum+1] = (w[arrowsNum+1] or 0) + 1
        j:normalize()
        return j
    end
    local y = other:to_number()
    local f = math.floor(y)
    local arrows_m1 = arrows:sub(B.ONE)
    local i = 0
    local m = limit_minus
    r = t:arrow(arrows_m1, y-f)
    while (f ~= 0) and r:lt(m) and (i<100) do
        if (f > 0) then
            r = t:arrow(arrows_m1, r)
            f = f - 1
        end
        i = i + 1
    end
    if (i == 100) then
        f = 0
    end
    local w = r:get_array()
    w[arrowsNum] = (w[arrowsNum] or 0) + f
    r:normalize()
    return r
end

--- @param self t.Omega
--- @return t.Omega
function Big:mod(other)
    local x = self:as_table()
    other = Big:ensureBig(other)
    if (other:eq(B.ZERO)) then
        return B.NaN
    end
    if (x.sign*other:get_sign() == -1) then
        return self:abs():mod(other:abs()):neg()
    end
    if (x.sign==-1) then
        return self:abs():mod(other:abs())
    end
    return self:sub(self:div(other):floor():mul(other))
end

--- @param self t.Omega
--- @return t.Omega
function Big:lambertw()
    local x = self:as_table()
    if (x:isNaN()) then
        return self
    end
    if (x:lt(-0.3678794411710499)) then
        error("lambertw is unimplemented for results less than -1, sorry!")
    end
    if (x:gt(B.TETRATED_MAX_SAFE_INTEGER)) then
        return self
    end
    if (x:gt(B.EE_MAX_SAFE_INTEGER)) then
        x.array[1] = x.array[1] - 1
        return self
    end
    if (x:gt(B.E_MAX_SAFE_INTEGER)) then
        return Big:d_lambertw(x)
    else
        return Big:create(Big:f_lambertw(x.sign*x.array[1]))
    end
end

--- @return t.Omega
function Big:f_lambertw(z)
    local tol = 1e-10
    local w = nil
    local wn = nil
    if (not Big:ensureBig(z):isFinite()) then
        return z;
    end
    if z == 0 then
        return B.ZERO;
    end
    if z == 1 then
        return B.LOMEGA
    end
    if (z < 10) then
        w = 0
    else
        w = math.log(z) - math.log(math.log(z))
    end
    for i=0,99 do
        wn = (z*math.exp(-w)+w*w)/(w+1)
        if (math.abs(wn-w)<tol*math.abs(wn)) then
            return wn
        end
        w=wn
    end
    error("Iteration failed to converge: "+z)
end

--- @return t.Omega
function Big:d_lambertw(z)
    local tol = 1e-10
    z = Big:ensureBig(z)
    local w = nil
    local ew = nil
    local wewz = nil
    local wn = nil
    if (not z:isFinite()) then
        return z
    end
    if (z == 0) then
        return B.ZERO
    end
    if (z == 1) then
        return B.LOMEGA
    end
    w = z:ln()
    for i=0, 99 do
        ew = w:neg():exp()
        wewz = w:sub(z:mul(ew))
        wn = w:sub(wewz:div(w:add(B.ONE):sub((w:add(2)):mul(wewz):div((w:mul(2):add(2))))))
        if (wn:sub(w):abs():lt(wn:abs():mul(tol))) then
            return wn
        end
        w = wn
    end
    error("Iteration failed to converge: "+z)
end

--- @return t.Omega.Low
function Big:as_table()
    return bigs[self] or self --- @diagnostic disable-line
end

function Big:get_array()
    return self:as_table().array
end

function Big:get_sign()
    return self:as_table().sign
end

for k,v in pairs(Big) do
    if type(v) == "function" then
        OmegaMeta.__index[k] = v --- @diagnostic disable-line
    end
end

------------------------metastuff----------------------------

function OmegaMeta.__add(b1, b2)
    if type(b1) == "number" then
        return Big:create(b1):add(b2)
    end
    return b1:add(b2)
end

function OmegaMeta.__sub(b1, b2)
    if type(b1) == "number" then
        return Big:create(b1):sub(b2)
    end
    return b1:sub(b2)
end

function OmegaMeta.__mul(b1, b2)
    if type(b1) == "number" then
        return Big:create(b1):mul(b2)
    end
    return b1:mul(b2)
end

function OmegaMeta.__div(b1, b2)
    if type(b1) == "number" then
        return Big:create(b1):div(b2)
    end
    return b1:div(b2)
end
function OmegaMeta.__mod(b1, b2)
    if type(b1) == "number" then
        return Big:create(b1):mod(b2)
    end
    return b1:mod(b2)
end

function OmegaMeta.__unm(b)
    return b:neg()
end

function OmegaMeta.__pow(b1, b2)
    if type(b1) == "number" then
        return Big:ensureBig(b1):pow(b2)
    end
    return b1:pow(b2)
end

function OmegaMeta.__le(b1, b2)
    b1 = Big:ensureBig(b1)
    return b1:lte(b2)
end

function OmegaMeta.__lt(b1, b2)
    b1 = Big:ensureBig(b1)
    return b1:lt(b2)
end

function OmegaMeta.__ge(b1, b2)
    b1 = Big:ensureBig(b1)
    return b1:gte(b2)
end

function OmegaMeta.__gt(b1, b2)
    b1 = Big:ensureBig(b1)
    return b1:gt(b2)
end

function OmegaMeta.__eq(b1, b2)
    b1 = Big:ensureBig(b1)
    return b1:eq(b2)
end

function OmegaMeta.__tostring(b)
    return number_format(b)
end

function OmegaMeta.__concat(a, b)
    return tostring(a) .. tostring(b)
end

ffi.metatype(TalismanOmega, OmegaMeta)

---------------------------------------

for i,v in pairs(R) do
    B[i] = Big:ensureBig(v)
end

B.LOMEGA = Big:create(0.56714329040978387299997)
B.E_LOG = B.E:log10()

return Big