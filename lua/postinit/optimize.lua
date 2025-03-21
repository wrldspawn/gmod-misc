do -- localized math.Clamp
	local math = math
	local math_max = math.max
	local math_min = math.min
	function math.Clamp(num, low, high)
		return math_min(math_max(num, low), high)
	end
end
