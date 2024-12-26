AddCSLuaFile()

SWEP.Base      = "weapon_base"
SWEP.PrintName = "Hands"
SWEP.Author    = "worldspawn"
SWEP.Purpose   = ""
SWEP.Category = "Other"

SWEP.Slot    = 1
SWEP.SlotPos = 0

SWEP.Spawnable = true

SWEP.ViewModel    = "models/weapons/c_arms.mdl"
SWEP.WorldModel   = ""
SWEP.ViewModelFOV = 90
SWEP.UseHands     = true

SWEP.AutoSwitchTo    = true
SWEP.AutoSwitchFrom    = true
SWEP.Weight = 1

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = true
SWEP.Primary.Ammo        = "none"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = true
SWEP.Secondary.Ammo        = "none"

SWEP.DrawAmmo = false

SWEP._firstrun = false

function SWEP:DrawWorldModel() end
function SWEP:DrawWorldModelTranslucent()  end
function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Reload() return false end
function SWEP:Holster() return true  end
function SWEP:ShouldDropOnDie() return false end

function SWEP:DrawWeaponSelection(x,y,w,h,a)
    y = y + 10
    x = x + 10
    w = w - 20

    draw.DrawText("C", "CreditsLogo", x + w / 2, y, Color(255,220,0), TEXT_ALIGN_CENTER)
end

function SWEP:Initialize()
    self:SetHoldType("normal")
    self:DrawShadow(false)
end

function SWEP:OnDrop()
    if SERVER then
        self:Remove()
    end
end

function SWEP:Deploy()
    if not self._firstrun then
        local vm = self:GetOwner():GetViewModel()
        if IsValid(vm) then
            vm:SendViewModelMatchingSequence(vm:LookupSequence("seq_admire"))
        end
        self._firstrun = true
    end

    self.Thinking = true
    return true
end

function SWEP:Think()
    if self.Thinking and IsValid(self:GetOwner()) and IsValid(self:GetOwner():GetViewModel()) then
        self.Thinking = false
    end
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end