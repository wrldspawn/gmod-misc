AddCSLuaFile()

local IN_ATTACK3           = bit.lshift(1, 25)

SWEP.Base                  = "weapon_base"
SWEP.PrintName             = "Hands"
SWEP.Author                = "worldspawn"
SWEP.Purpose               = ""
SWEP.Category              = "Other"

SWEP.Slot                  = 1
SWEP.SlotPos               = 0

SWEP.Spawnable             = true

SWEP.ViewModel             = "models/weapons/c_arms.mdl"
SWEP.WorldModel            = ""
SWEP.ViewModelFOV          = 90
SWEP.UseHands              = true

SWEP.AutoSwitchTo          = true
SWEP.AutoSwitchFrom        = true
SWEP.Weight                = 1

SWEP.Primary.ClipSize      = -1
SWEP.Primary.DefaultClip   = -1
SWEP.Primary.Automatic     = true
SWEP.Primary.Ammo          = "none"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = true
SWEP.Secondary.Ammo        = "none"

SWEP.DrawAmmo              = false

SWEP._firstrun             = false

function SWEP:SetupDataTables()
    self:NetworkVar("Float", "InspectEndTime")
end

function SWEP:DrawWorldModel() end

function SWEP:DrawWorldModelTranslucent() end

function SWEP:CanPrimaryAttack() return false end

function SWEP:CanSecondaryAttack() return false end

function SWEP:Reload() return false end

function SWEP:Holster() return true end

function SWEP:ShouldDropOnDie() return false end

if CLIENT then
    local function ScreenScaleHClamped(v)
        return v * (math.min(ScrH(), 1080) / 480)
    end

    surface.CreateFont("LambdaPhyscannonFont", {
        font = "HalfLife2",
        size = ScreenScaleHClamped(70),
        weight = 0,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        additive = true,
    })

    surface.CreateFont("LambdaPhyscannonFont2", {
        font = "HalfLife2",
        size = ScreenScaleHClamped(70),
        weight = 0,
        blursize = ScreenScaleH(4),
        scanlines = ScreenScaleH(2),
        antialias = true,
        additive = true,
    })

    function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
        surface.SetTextColor(255, 220, 0, alpha)

        surface.SetFont("LambdaPhyscannonFont")
        local w, h = surface.GetTextSize("C")
        local cx, cy = x + (wide / 2) - (w / 2), y + (tall / 2) - (h / 2) - (h / 6)

        surface.SetTextPos(cx, cy)

        surface.SetFont("LambdaPhyscannonFont2")
        surface.DrawText("C")

        surface.SetTextPos(cx, cy)

        surface.SetFont("LambdaPhyscannonFont")
        surface.DrawText("C")
    end
end

function SWEP:Initialize()
    self:SetHoldType("normal")
    self:DrawShadow(false)
end

function SWEP:OnDrop()
    if SERVER then
        SafeRemoveEntity(self)
    end
end

function SWEP:Inspect()
    if CurTime() < self:GetInspectEndTime() then return end

    local owner = self:GetOwner()
    if not (owner:IsValid() and owner:IsPlayer()) then return end
    ---@cast owner Player

    local vm = owner:GetViewModel()
    if IsValid(vm) then
        local seq = vm:LookupSequence("seq_admire")
        vm:SendViewModelMatchingSequence(seq)
        self:SetInspectEndTime(CurTime() + vm:SequenceDuration(seq))
    end
end

function SWEP:Deploy()
    local owner = self:GetOwner()
    if not (owner:IsValid() and owner:IsPlayer()) then return end
    ---@cast owner Player

    if not self._firstrun then
        self:Inspect()
        self._firstrun = true
    end

    return true
end

local g_bSinglePlayer = game.SinglePlayer()
function SWEP:Think()
    local owner = self:GetOwner()
    if not (owner:IsValid() and owner:IsPlayer()) then return end
    ---@cast owner Player

    local cmd
    if g_bSinglePlayer then
        cmd = owner.m_LastUserCommand
    elseif owner == GetPredictionPlayer() then
        cmd = owner:GetCurrentCommand()

        owner.m_LastUserCommand = cmd
        owner.m_LastUserCommandNumber = cmd:CommandNumber()
    else
        cmd = owner.m_LastUserCommand
    end

    local obtns = owner:GetInternalVariable("m_nButtons")
    local btns = g_bSinglePlayer and obtns or (cmd and cmd:GetButtons() or obtns)

    if bit.band(btns, IN_ATTACK3) ~= 0 then
        self:Inspect()
    end
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end

