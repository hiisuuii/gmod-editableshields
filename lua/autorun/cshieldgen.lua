if CLIENT then
	local shldmat = Material('models/props_combine/stasisshield_sheet')
	local shldmat2 = Material('models/props_combine/portalball001_sheet')
	local bmmb = Material('cable/physbeam')
	local bmmr = Material('cable/physbeamred')
	local blue_shg = Color(0,64,255,120)
	local red_shg = Color(255,64,120)
	local radius = (300/6.6)
	local height = (500/11)
	local quality = 32
	local shldgnstab = {}

	local function qc(t,p0,p1,p2)
		return (1-t)^2*p0+2*(1-t)*t*p1+t^2*p2
	end

	local shieldtypes = {
		["sw_shieldgen_blue"] = true,
		["sw_shieldgen_blue_id"] = true,
		["sw_shieldgen_red"] = true,
		["sw_shieldgen_red_id"] = true
	}
	hook.Add("Tick","SWShieldGen",function()
		shldgnstab = {}
		for k,v in pairs (ents.GetAll()) do
			if shieldtypes[v:GetClass()] then
				shldgnstab[#shldgnstab+1] = v
			end
		end
	end)

	local redshields = {
		["sw_shieldgen_red"] = true,
		["sw_shieldgen_red_id"] = true
	}
	local blueshields = {
		["sw_shieldgen_blue"] = true,
		["sw_shieldgen_blue_id"] = true
	}
	hook.Add('PostDrawTranslucentRenderables','SWShieldGen',function(bDepth,bSkybox)
		if bSkybox then return end
		for k,v in pairs(shldgnstab) do
			if !IsValid(v) or !v:GetEnable() then continue end
			local pos = v:GetPos()
			local vec1 = v:GetUp()
			local vec2 = vec1:Dot(pos) - 100
			local radius = radius * v:GetShieldSize()
			local height = height * v:GetShieldSize()
			if blueshields[v:GetClass()] then
				render.SetMaterial(bmmb)
				render.DrawBeam(pos+v:GetUp()*40,pos+v:GetUp()*height/*+Vector(0,0,height)*/,32,CurTime()*2,CurTime()*2-1,Color(0,192,255))
			elseif redshields[v:GetClass()] then
				render.SetMaterial(bmmr)
				render.DrawBeam(pos+Vector(0,0,40),pos+Vector(0,0,height),32,CurTime()*2,CurTime()*2-1,Color(255,0,0))
			end
			local oldEC = render.EnableClipping(true)
			if !v:GetIsSphere() then
				render.PushCustomClipPlane(vec1,vec2)
			end
			render.SetColorMaterial()
			if blueshields[v:GetClass()] then
				render.DrawSphere(pos,radius,32,32,blue_shg)
			elseif redshields[v:GetClass()] then
				render.DrawSphere(pos,radius,32,32,red_shg)
			end
			render.SetMaterial(shldmat)
			render.OverrideBlend(true,3,1,BLENDFUNC_ADD)
			render.DrawSphere(pos,radius,32,32)
			render.OverrideBlend(false,3,1,BLENDFUNC_ADD)
			render.SetMaterial(shldmat2)
			render.OverrideBlend(true,2,1,BLENDFUNC_ADD)
			render.DrawSphere(pos,radius,32,32)
			render.OverrideBlend(false,2,1,BLENDFUNC_ADD)
			if !v:GetIsSphere() then
				render.PopCustomClipPlane()
				render.EnableClipping(oldEC)
			end
		end
	end)
end


if SERVER then
	hook.Add('EntityTakeDamage','SWShieldGen',function(ent,dmg)
		if ent.IsAShield and ent:IsValid() then
			if not ent.IsInvincibleShield then
				local genEnt = ent:GetParent()
				local newhp = genEnt:GetHP() - dmg:GetDamage()
				if newhp < 1 then
					genEnt:DeactivateShield()
					genEnt:EmitSound("vehicles/APC/apc_shutdown.wav")
					genEnt:SetHP(10000)
					genEnt:SetIsRecharging(true)
					timer.Create(genEnt:EntIndex().."_genEnt",30,1,function()
						if genEnt:IsValid() then
							genEnt:SetIsRecharging(false)
						end
					end)
				else
					genEnt:SetHP(genEnt:GetHP() - dmg:GetDamage())
				end
			end
			local ed = EffectData()
			local dmgpos = dmg:GetDamagePosition()
			ed:SetOrigin(dmgpos)
			ed:SetNormal((dmgpos-ent:GetPos()):GetNormalized())
			ed:SetRadius(1)
			util.Effect('cball_bounce',ed)
			util.Effect('AR2Explosion',ed)
			return true
		end
	end)
end