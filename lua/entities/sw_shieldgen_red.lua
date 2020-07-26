AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName		= "Shield Generator (Red)"
ENT.Category = "Star Wars"
ENT.Spawnable = true
ENT.Editable = true
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
	self:NetworkVar("Bool",0,"Enable", { KeyName = "shrenabled", Edit = { type = "Boolean", order = 1, min = 0, max = 1 } } )
	self:NetworkVar("Int",0,"HP", { KeyName = "shrhp", Edit = { type = "Int", order = 4, min = 1, max = 5000000 } } )
	self:NetworkVar("Float",0,"ShieldSize", { KeyName = "shrradius", Edit = { type = "Float", order = 3, min = 5, max = 200 } } )
	self:NetworkVar("Bool",1,"BlockerExists")
	self:NetworkVar("Bool",2,"IsRecharging")
	self:NetworkVar("Bool",3,"IsUseable", { KeyName = "shruseable", Edit = { type = "Boolean", order = 2, min = 0, max = 1 } } )
	self:NetworkVar("Bool",4,"IsSphere", { KeyName = "shissphere", Edit = { type = "Boolean", order = 4, min = 0, max = 1 } } )
end
if SERVER then

function ENT:Initialize()
	self:SetModel("models/ace/sw/cwa/maridun_shield_gen.mdl")
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:PhysWake()
	self:SetHP(10000)
	self:SetShieldSize(30)
	self:SetBlockerExists(false)
	self:SetIsUseable(false)
end

	
function ENT:CreateBlocker()
	self.Blocker = ents.Create("prop_physics")
	if (!IsValid(self.Blocker)) then return end
	if self:GetIsSphere() then
		self.Blocker:SetModel("models/ace/misc/shieldsphere.mdl")
	else
		self.Blocker:SetModel("models/ace/misc/shieldshell.mdl")
	end
	self.Blocker:SetMoveType(MOVETYPE_VPHYSICS)
	self.Blocker:PhysicsInit(SOLID_VPHYSICS)
	self.Blocker:SetModelScale(self:GetShieldSize())
	self.Blocker:SetPos(self:GetPos()-Vector(0,0,20))
	self.Blocker:SetNoDraw(true)
	self.Blocker:SetParent(self)
	self.Blocker:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
	self.Blocker:SetSolid(SOLID_NONE)
	self.Blocker:AddEffects(EF_NOSHADOW)
	self.Blocker:AddEFlags(EFL_DONTBLOCKLOS)
	self.Blocker:Spawn()
	self.Blocker:Activate()
	self.Blocker.IsAShield = true
end

local soundID

function ENT:DeactivateShield()
	if self:GetBlockerExists() then
		self.Blocker:Remove()
	self:EmitSound("vehicles/APC/apc_shutdown.wav")
	end
	if soundID then
		self:StopLoopingSound(soundID)
	end
	self:SetEnable(false)
	self:SetBlockerExists(false)
end

function ENT:ActivateShield()
	if not self:GetIsRecharging() then
		soundID = self:StartLoopingSound("ambient/machines/combine_shield_loop3.wav")
		self:CreateBlocker()
		self:SetEnable(true)
		self:SetBlockerExists(true)
	end
end

function ENT:UpdateBlocker()
	if self:GetEnable() then
		if self:GetBlockerExists() then
			--self.Blocker:SetModelScale(self:GetShieldSize())
		else
			self:ActivateShield()
		end
	elseif not self:GetEnable() then
		if self:GetBlockerExists() then
			self.Blocker:Remove()
			self:SetBlockerExists(false)
		else
			return
		end
	end
end

function ENT:Think()
	if self:GetEnable() then
		self:UpdateBlocker()
	else
		self:DeactivateShield()
	end
end

function ENT:OnRemove()
	timer.Remove(self:EntIndex().."_genEnt")
	if soundID then
		self:StopLoopingSound(soundID)
	end
end


function ENT:ToggleShield()
	if self:GetEnable() then
		self:DeactivateShield()
	elseif not self:GetEnable() then
		self:ActivateShield()
	end
end

local usedelay = 0.5
local lastUse = -usedelay
function ENT:Use(a,c)
	local timeElapsed = CurTime() - lastUse
	if self:GetIsUseable() then
		if timeElapsed < usedelay then
			return
		else
			self:ToggleShield()
			lastUse = CurTime()
		end
	end
end
end

function ENT:Draw()
	self:DrawModel()
end