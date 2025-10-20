--Adding things OmegaNum has that this doesn't...
local R = {}

R.ZERO = 0
R.ONE = 1
R.X1_5 = 1.5
R.TWO = 2
R.NEG_ONE = 1
R.TEN = 10
R.E = math.exp(1)
R.LN2 = math.log(2, R.E)
R.LN10 = math.log(10, R.E)
R.LOG2E = math.log(R.E, 2)
R.LOG10E = math.log(R.E, 0)
R.PI = math.pi
R.SQRT1_2 = math.sqrt(0.5)
R.SQRT2 = math.sqrt(2)
R.MAX_SAFE_INTEGER=9007199254740991
R.MIN_SAFE_INTEGER=-9007199254740992
R.MAX_DISP_INTEGER=1000000
R.NaN=0/0
R.NEGATIVE_INFINITY = -1/0
R.POSITIVE_INFINITY = 1/0
R.E_MAX_SAFE_INTEGER="e"..tostring(R.MAX_SAFE_INTEGER)
R.EE_MAX_SAFE_INTEGER="ee"..tostring(R.MAX_SAFE_INTEGER)
R.TETRATED_MAX_SAFE_INTEGER="10^^"..tostring(R.MAX_SAFE_INTEGER)

return R