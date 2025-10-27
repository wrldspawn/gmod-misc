local TAG = "pixelify"
local pushed = 0

local function SafePush()
	render.PushFilterMag(TEXFILTER.POINT)
	render.PushFilterMin(TEXFILTER.POINT)
	pushed = pushed + 1
end

local function SafePop()
	if pushed > 0 then
		render.PopFilterMag()
		render.PopFilterMin()
		pushed = pushed - 1
	end
end

hook.Add("RenderScene", TAG, SafePush)
hook.Add("PreDrawEffects", TAG, SafePop)

hook.Add("PreDrawOpaqueRenderables", TAG, SafePush)
hook.Add("PostDrawOpaqueRenderables", TAG, SafePop)

hook.Add("PreDrawTranslucentRenderables", TAG, SafePush)
hook.Add("PostDrawTranslucentRenderables", TAG, SafePop)

hook.Add("PostDraw2DSkyBox", TAG, SafePush)
hook.Add("PreDrawHUD", TAG, SafePop)

hook.Add("PostRender", TAG, function()
	while pushed > 0 do
		SafePop()
	end
end)
