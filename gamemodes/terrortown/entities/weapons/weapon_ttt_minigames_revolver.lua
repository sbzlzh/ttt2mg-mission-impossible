if SERVER then
    AddCSLuaFile()
end

SWEP.HoldType = "pistol"

if CLIENT then
    SWEP.PrintName = "Deagle"
    SWEP.Slot = 1

    SWEP.ViewModelFlip = false
    SWEP.ViewModelFOV = 54

    SWEP.Icon = "vgui/ttt/icon_deagle"
end

SWEP.Base = "weapon_tttbase"

SWEP.Kind = WEAPON_PISTOL
SWEP.WeaponID = AMMO_DEAGLE
SWEP.builtin = true
SWEP.spawnType = WEAPON_TYPE_PISTOL

SWEP.Primary.Ammo = "AlyxGun" -- hijack an ammo type we don't use otherwise
SWEP.Primary.Recoil = 4
SWEP.Primary.Damage = 37
SWEP.Primary.Delay = 0.6
SWEP.Primary.Cone = 0.02
SWEP.Primary.ClipSize = 8
SWEP.Primary.ClipMax = 40
SWEP.Primary.DefaultClip = 8
SWEP.Primary.Automatic = true
SWEP.Primary.Sound = Sound("ttt/silencer.mp3")

SWEP.HeadshotMultiplier = 4

SWEP.AutoSpawnable = true
SWEP.Spawnable = true
SWEP.AmmoEnt = "item_ammo_revolver_ttt"

SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/cstrike/c_pist_deagle.mdl"
SWEP.WorldModel = "models/weapons/w_pist_deagle.mdl"
SWEP.idleResetFix = true

SWEP.IronSightsPos = Vector(-6.361, -3.701, 2.15)
SWEP.IronSightsAng = Vector(0, 0, 0)

if SERVER then
    local SOUND_RANGE = 100

    function SWEP:PrimaryAttack()
        if not self:CanPrimaryAttack() then return end

        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

        self:TakePrimaryAmmo(1)
        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        self:EmitSound(self.Primary.Sound)

        self:ShootBullet(self.Primary.Damage, self.Primary.Recoil, self.Primary.NumShots, self.Primary.Cone)

        for _, ply in ipairs(player.GetAll()) do
            if ply ~= owner and ply:GetPos():Distance(owner:GetPos()) <= SOUND_RANGE then
                ply:SendLua([[surface.PlaySound("ttt/silencer.mp3")]])
            end
        end
    end
end
