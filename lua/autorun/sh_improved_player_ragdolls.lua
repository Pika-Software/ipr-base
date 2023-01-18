local addonName = 'Improved Player Ragdolls'

local PLAYER = FindMetaTable( 'Player' )
function PLAYER:GetRagdollEntity()
	return self:GetNW2Entity( 'm_Ragdoll' )
end

local ENTITY = FindMetaTable( 'Entity' )
function ENTITY:GetPlayerColor()
	local vector = self:GetNWVector( 'm_PlayerColor', false )
	if (vector) then
		return vector
	end
end

function ENTITY:SetPlayerColor( vec )
	self:SetNWVector( 'm_PlayerColor', vec )
end

function ENTITY:IsPlayerRagdoll()
	return self:GetNWBool( 'PlayerRagdoll', false )
end

if (SERVER) then

	local util_IsValidModel = util.IsValidModel
	local ents_Create = ents.Create
	local hook_Add = hook.Add
	local hook_Run = hook.Run
	local isstring = isstring
	local isnumber = isnumber
	local istable = istable
	local IsValid = IsValid
	local ipairs = ipairs

	function PLAYER:RemoveRagdoll()
		local ent = self:GetRagdollEntity()
		if IsValid( ent ) then
			hook_Run( 'PlayerRagdollRemoved', self, ent )
			ent:Remove()
		end
	end

	do
		local player_GetAll = player.GetAll
		function player.ClearRagdolls()
			for _, ply in ipairs( player_GetAll() ) do
				ply:RemoveRagdoll()
			end
		end
	end

	function PLAYER:CreateRagdoll()
		self:RemoveRagdoll()

		local ent = NULL
		local ragdollClass = hook_Run( 'PlayerRagdollClass', self )
		if isstring( ragdollClass ) then
			ent = ents_Create( ragdollClass )
		else
			ent = ents_Create( self:GetBoneCount() > 1 and 'prop_ragdoll' or 'prop_physics' )
		end

		if IsValid( ent ) then
			ent:SetNWBool( 'PlayerRagdoll', true )
			ent:SetCreator( self )

			-- Model
			local model = hook_Run( 'PlayerRagdollModel', self, ent )
			if isstring( model ) and util_IsValidModel( model ) then
				ent:SetModel( model )
			elseif (model ~= false) then
				ent:SetModel( self:GetModel() )
			else
				return
			end

			-- Skin
			local modelSkin = hook_Run( 'PlayerRagdollSkin', self, ent )
			if isnumber( modelSkin ) then
				ent:SetSkin( modelSkin )
			elseif (modelSkin ~= false) then
				ent:SetSkin( self:GetSkin() )
			end

			-- Bodygroups
			local modelBodygroups = hook_Run( 'PlayerRagdollBodyGroups', self, ent )
			if istable( modelBodygroups ) then
				for _, bodygroup in ipairs( modelBodygroups ) do
					ent:SetBodygroup( bodygroup.id, bodygroup.value )
				end
			elseif (modelBodygroups ~= false) then
				for _, bodygroup in ipairs( self:GetBodyGroups() ) do
					ent:SetBodygroup( bodygroup.id, self:GetBodygroup( bodygroup.id ) )
				end
			end

			-- Flexes
			ent:SetFlexScale( self:GetFlexScale() )
			for flex = 1, ent:GetFlexNum() do
				ent:SetFlexWeight( flex, self:GetFlexWeight( flex ) )
			end

			-- Colors & Material
			ent:SetColor( self:GetColor() )
			ent:SetMaterial( self:GetMaterial() )
			ent:SetPlayerColor( self:GetPlayerColor() )

			-- Position
			ent:SetPos( self:GetPos() )
			ent:SetAngles( self:GetAngles() )

			-- Collision Group
			ent:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )

			-- Spawning...
			self:SetNW2Entity( 'm_Ragdoll', ent )
			ent:Spawn()

			-- Bone Manipulations
			for i = 0, ent:GetBoneCount() do
				ent:ManipulateBonePosition( i, self:GetManipulateBonePosition( i ) )
				ent:ManipulateBoneAngles( i, self:GetManipulateBoneAngles( i ) )
				ent:ManipulateBoneJiggle( i, self:GetManipulateBoneJiggle( i ) )
				ent:ManipulateBoneScale( i, self:GetManipulateBoneScale( i ) )
			end

			-- Velocity
			local velocity = self:GetVelocity()
			if ent:IsRagdoll() then
				for physNum = 0, ent:GetPhysicsObjectCount() - 1 do
					local phys = ent:GetPhysicsObjectNum( physNum )
					if IsValid( phys ) then
						local bone = ent:TranslatePhysBoneToBone( physNum )
						if (bone >= 0) then
							local pos, ang = self:GetBonePosition( bone )
							phys:SetVelocity( velocity )
							phys:SetAngles( ang )
							phys:SetPos( pos )
							phys:Wake()
						end
					end
				end
			else

				local phys = ent:GetPhysicsObject()
				if IsValid( phys ) then
					phys:SetVelocity( velocity )
					phys:Wake()
				end

			end

			-- Active Weapon
			local activeWeapon = self:GetActiveWeapon()
			if IsValid( activeWeapon ) then
				ent.ActiveWeapon = activeWeapon:GetClass()
			end

			-- Weapons
			ent.Weapons = {}
			for _, wep in ipairs( self:GetWeapons() ) do
				table.insert( ent.Weapons, wep:GetClass() )
			end

			-- Fire Transmission
			if self:IsOnFire() then
				self:Extinguish()
				ent:Ignite( 10, 0 )
			end

			-- Hook for dev's
			hook_Run( 'PlayerRagdollCreated', self, ent )

			-- Spectating :
			if IsValid( self:GetObserverTarget() ) then
				return ent
			end

			self:SpectateEntity( ent )
			self:Spectate( OBS_MODE_CHASE )
			return ent
		end
	end

	hook_Add('PlayerDisconnected', addonName, function( ply )
		ply:RemoveRagdoll()
	end)

	hook_Add('PlayerSpawn', addonName, function( ply, trans )
		if (trans) then return end
		ply:RemoveRagdoll()
	end)

	-- gmod_cameraprop ragdoll support
	do
		local ents_FindByClass = ents.FindByClass
		timer.Create(addonName .. ' - Camera Fix', 0.5, 0, function()
			for _, ent in ipairs( ents_FindByClass( 'gmod_cameraprop' ) ) do
				local ply = ent.TargetPlayer
				local tEnt = ent:GetentTrack()
				if IsValid( ply ) and ply:Alive() then
					if (ply == tEnt) then continue end
					ent:SetentTrack( ply )
				elseif IsValid( tEnt ) and tEnt:IsPlayer() then
					if tEnt:Alive() then continue end

					local ragdoll = tEnt:GetRagdollEntity()
					if IsValid( ragdoll ) then
						ent.TargetPlayer = tEnt
						ent:SetentTrack( ragdoll )
					end
				end
			end
		end)
	end

end
