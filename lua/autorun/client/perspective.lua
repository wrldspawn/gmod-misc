local Tag = "perspective"
local Tag2 = "mc_zoom"

local perspective_enabled = false
local thirdperson_mode = 0

local camPitch, camYaw
local oldPitch, oldYaw

local lastUpdate = 0

local smooth = CreateClientConVar("mc_thirdperson_smooth", "0")
local smoothFirstPerson = CreateClientConVar("mc_firstperson_smooth", "0")

local invertYaw = CreateClientConVar("perspective_invert_yaw", "1")
local invertPitch = CreateClientConVar("perspective_invert_pitch", "0")

local smoothX_actualSum = 0
local smoothX_smoothedSum = 0
local smoothX_movementLatency = 0

local smoothY_actualSum = 0
local smoothY_smoothedSum = 0
local smoothY_movementLatency = 0

local function signum(x)
    return x > 0 and 1 or x < 0 and -1 or 0
end

local function smoothX(orig, smoother)
    smoothX_actualSum = smoothX_actualSum + orig
    local x = smoothX_actualSum - smoothX_smoothedSum
    local y = Lerp(0.5, smoothX_movementLatency, x)
    local z = signum(x)

    if z * x > z * smoothX_movementLatency then
        x = y
    end

    smoothX_movementLatency = y
    smoothX_smoothedSum = smoothX_smoothedSum + (x * smoother)

    return x * smoother
end

local function smoothY(orig, smoother)
    smoothY_actualSum = smoothY_actualSum + orig
    local x = smoothY_actualSum - smoothY_smoothedSum
    local y = Lerp(0.5, smoothY_movementLatency, x)
    local z = signum(x)

    if z * x > z * smoothY_movementLatency then
        x = y
    end

    smoothY_movementLatency = y
    smoothY_smoothedSum = smoothY_smoothedSum + (x * smoother)

    return x * smoother
end

concommand.Add("perspective_toggle", function()
    perspective_enabled = not perspective_enabled
    thirdperson_mode = 0

    if perspective_enabled then
        local ang = LocalPlayer():EyeAngles()
        camPitch = ang.x
        camYaw = ang.y
        oldPitch = ang.x
        oldYaw = ang.y
    end
end)

concommand.Add("+perspective", function()
    perspective_enabled = true
    thirdperson_mode = 0

    local ang = LocalPlayer():EyeAngles()
    camPitch = ang.x
    camYaw = ang.y
    oldPitch = ang.x
    oldYaw = ang.y
end)

concommand.Add("-perspective", function()
    perspective_enabled = false
    thirdperson_mode = 0
end)

concommand.Add("mc_thirdperson", function()
    thirdperson_mode = thirdperson_mode + 1
    perspective_enabled = false

    local ang = LocalPlayer():EyeAngles()
    camPitch = ang.x
    camYaw = ang.y + (thirdperson_mode == 2 and 180 or 0)

    if thirdperson_mode > 2 then
        thirdperson_mode = 0
    end
end)

local mc_fov = CreateClientConVar("mc_fov", "30", true, false, "Zooming FOV", 1, 100)
local mc_dist = CreateClientConVar("mc_dist", "128", true, false, "Distance away from the head position", 16, 384)

local zooming = false
local lastFOV = 0

local function doZoom()
    zooming = not zooming
end

concommand.Add("+zoom2", doZoom)
concommand.Add("-zoom2", doZoom)

hook.Add("PlayerBindPress", Tag2, function(ply, bind, pressed)
    if zooming and pressed then
        local step = ply:KeyDown(IN_SPEED) and 5 or 1

        if bind == "invprev" then
            mc_fov:SetInt(math.Clamp(mc_fov:GetInt() - step, 1, 100))
            lastFOV = RealTime()
            return true
        elseif bind == "invnext" then
            mc_fov:SetInt(math.Clamp(mc_fov:GetInt() + step, 1, 100))
            lastFOV = RealTime()
            return true
        elseif bind == "+reload" then
            mc_fov:SetInt(30)
            lastFOV = RealTime()
            return true
        end
    elseif (perspective_enabled or thirdperson_mode ~= 0) and ply:KeyDown(IN_WALK) and pressed then
        if bind == "invprev" then
            mc_dist:SetInt(math.Clamp(mc_dist:GetInt() - 8, 16, 384))
            return true
        elseif bind == "invnext" then
            mc_dist:SetInt(math.Clamp(mc_dist:GetInt() + 8, 16, 384))
            return true
        elseif bind == "+reload" then
            mc_dist:SetInt(128)
            return true
        end
    end
end)

hook.Add("HUDShouldDraw", Tag2, function(elem)
    if (zooming or ((perspective_enabled or thirdperson_mode ~= 0) and LocalPlayer():KeyDown(IN_WALK))) and elem == "_chud_weaponswitcher" then
        return false
    end
end)

local alpha = 0
hook.Add("HUDPaint", Tag2, function()
    local x, y = ScrW() / 2, ScrH() * 0.75

    local now = RealTime()

    if lastFOV + 2 > now then
        alpha = 255
    elseif lastFOV + 2 < now then
        alpha = Lerp(RealFrameTime() * 4, alpha, 0)
    end

    surface.SetFont("ChatFont")

    local fov = tostring(mc_fov:GetInt())
    local text = "FOV set to: "

    local tw = surface.GetTextSize(fov)
    local tw2 = surface.GetTextSize(text)

    surface.SetTextColor(192, 192, 192, alpha)
    surface.SetTextPos(x - tw, y)
    surface.DrawText(text)

    surface.SetTextColor(128, 255, 128, alpha)
    surface.SetTextPos(x - (tw / 2) + (tw2 / 2), y)
    surface.DrawText(fov)
end)

local m_sens = 3
hook.Add("AdjustMouseSensitivity", Tag, function(sens)
    m_sens = sens
end)

hook.Add("CreateMove", Tag, function(cmd)
    if not perspective_enabled and thirdperson_mode == 0 then
        if smoothFirstPerson:GetBool() and smooth:GetBool() then
            if not smooth:GetBool() then
                local ang = cmd:GetViewAngles()
                camPitch = ang.x
                camYaw = ang.y
            else
                if not camPitch or not camYaw then
                    local ang = cmd:GetViewAngles()
                    camPitch = ang.x
                    camYaw = ang.y
                end

                local time = RealTime()
                local min = time - lastUpdate
                lastUpdate = time

                local sens = m_sens * 0.6 * 0.2
                local mult = sens * sens * sens * 8

                local deltaX = smoothX(cmd:GetMouseX() * mult, min * mult)
                local deltaY = smoothY(cmd:GetMouseY() * mult, min * mult)

                camYaw = camYaw - (deltaX / 8)
                camPitch = camPitch + (deltaY / 8)

                if math.abs(camPitch) > 90 then
                    camPitch = camPitch > 0 and 90 or -90
                end

                cmd:SetViewAngles(Angle(camPitch, camYaw, 0))
            end
        else
            if not zooming then
                local ang = cmd:GetViewAngles()
                camPitch = ang.x
                camYaw = ang.y

                smoothX_actualSum = 0
                smoothX_smoothedSum = 0
                smoothX_movementLatency = 0

                smoothY_actualSum = 0
                smoothY_smoothedSum = 0
                smoothY_movementLatency = 0
            end
        end

        return
    end

    local time = RealTime()
    local min = time - lastUpdate
    lastUpdate = time

    local sens = 3 * 0.6 * 0.2
    local mult = sens * sens * sens * 8 * ((smooth:GetBool() or zooming) and 1 or 0.5)

    local deltaX
    local deltaY

    if smooth:GetBool() or zooming then
        deltaX = smoothX(cmd:GetMouseX() * mult, min * mult)
        deltaY = smoothY(cmd:GetMouseY() * mult, min * mult)
    else
        if not zooming then
            smoothX_actualSum = 0
            smoothX_smoothedSum = 0
            smoothX_movementLatency = 0

            smoothY_actualSum = 0
            smoothY_smoothedSum = 0
            smoothY_movementLatency = 0
        end

        deltaX = cmd:GetMouseX() * mult
        deltaY = cmd:GetMouseY() * mult
    end

    camYaw = camYaw + (deltaX / 8) * (perspective_enabled and (invertYaw:GetBool() and 1 or -1) or -1)
    camPitch = camPitch + (deltaY / 8) * (perspective_enabled and (invertPitch:GetBool() and -1 or 1) or 1)

    if math.abs(camPitch) > 90 then
        camPitch = camPitch > 0 and 90 or -90
    end

    if perspective_enabled then
        cmd:SetViewAngles(Angle(oldPitch, oldYaw, 0))
    else
        cmd:SetViewAngles(Angle(camPitch * (thirdperson_mode == 2 and -1 or 1),
            camYaw + (thirdperson_mode == 2 and 180 or 0), 0))
    end
end)

local CAM_ANG = Angle(camPitch, camYaw, 0)
local function clipToSpace(dist)
    local lply = LocalPlayer()
    local vec1 = lply:EyePos()
    local vec2 = vec1 - CAM_ANG:Forward() * dist

    ---@type Entity[]
    local ignore = { lply }

    for _, child in pairs(lply:GetChildren()) do
        if child:IsVehicle() and child:GetDriver():IsPlayer() then
            ignore[#ignore + 1] = child
            ignore[#ignore + 1] = child:GetDriver()
        end
    end

    local tr_p = {
        start = vec1,
        endpos = vec2,
        filter = ignore,
        mask = MASK_SOLID
    }

    local tr = util.TraceLine(tr_p)

    local ent = tr.Entity

    if IsValid(ent) and ent:GetCollisionGroup() ~= COLLISION_GROUP_NONE and ent:GetCollisionGroup() ~= lply:GetCollisionGroup() then
        ignore[#ignore + 1] = ent
        for _, child in pairs(ent:GetChildren()) do
            ignore[#ignore + 1] = child
        end
        if IsValid(ent:GetParent()) then
            local parent = ent:GetParent()
            ignore[#ignore + 1] = parent
            for _, child in pairs(parent:GetChildren()) do
                ignore[#ignore + 1] = child
            end
        end
    end

    tr = util.TraceLine(tr_p)

    if tr.Hit then
        local d = tr.HitPos:Distance(lply:EyePos())
        if d < dist then
            dist = d
        end
    end

    return dist
end

local function getHeadPos(ply)
    local bone = ply:LookupBone("ValveBiped.Bip01_Head1")
    local pos = ply:EyePos()
    if bone then
        local _pos = ply:GetBonePosition(bone)
        if _pos then
            pos = _pos
        end
    end

    local bcount = ply:GetBoneCount()
    if not bone or (not ply:GetBoneName(bone):lower():find("head") and bcount >= bone) then
        for i = 0, bcount do
            if ply:GetBoneName(i):lower():find("head") then
                pos = ply:GetBonePosition(i)
                if not pos then
                    pos = ply:EyePos()
                end
                bone = i
            end
        end
    end

    return pos
end

hook.Add("CalcView", Tag, function(ply, origin, angles, fov, znear, zfar)
    if not perspective_enabled and thirdperson_mode == 0 then return end

    CAM_ANG.x = camPitch
    CAM_ANG.y = camYaw

    local lply = LocalPlayer()
    local rag = lply:GetRagdollEntity()
    ---@type Entity
    local ent = lply
    if not lply:Alive() and rag:IsValid() then
        ent = rag
    end

    local view = {
        origin = getHeadPos(ent) + (CAM_ANG:Forward() * -clipToSpace(mc_dist:GetInt() * ent:GetModelScale())),
        angles = CAM_ANG,
        drawviewer = true
    }

    if zooming then
        view.fov = mc_fov:GetInt()
    end

    return view
end)

hook.Add("CalcView", Tag2, function(ply, pos, ang, fov, znear, zfar)
    if zooming then
        local view = {
            fov = mc_fov:GetInt()
        }

        if perspective_enabled or thirdperson_mode ~= 0 then return end

        return view
    end
end)

hook.Add("CreateMove", Tag2, function(cmd)
    if perspective_enabled or thirdperson_mode ~= 0 then
        if not smooth:GetBool() and not zooming then
            smoothX_actualSum = 0
            smoothX_smoothedSum = 0
            smoothX_movementLatency = 0

            smoothY_actualSum = 0
            smoothY_smoothedSum = 0
            smoothY_movementLatency = 0
        end

        return
    end

    if not zooming then
        if not smooth:GetBool() then
            smoothX_actualSum = 0
            smoothX_smoothedSum = 0
            smoothX_movementLatency = 0

            smoothY_actualSum = 0
            smoothY_smoothedSum = 0
            smoothY_movementLatency = 0
        end

        return
    end

    local time = RealTime()
    local min = time - lastUpdate
    lastUpdate = time

    local sens = 3 * 0.6 * 0.2
    local mult = sens * sens * sens * 8

    local deltaX
    local deltaY
    local smoothDeltaX = smoothX(cmd:GetMouseX() * mult, min * mult)
    local smoothDeltaY = smoothY(cmd:GetMouseY() * mult, min * mult)

    deltaX = smoothDeltaX
    deltaY = smoothDeltaY

    camYaw = camYaw - (deltaX / 8)
    camPitch = camPitch + (deltaY / 8)

    if math.abs(camPitch) > 90 then
        camPitch = camPitch > 0 and 90 or -90
    end

    CAM_ANG.x = camPitch
    CAM_ANG.y = camYaw

    cmd:SetViewAngles(CAM_ANG)
end)
