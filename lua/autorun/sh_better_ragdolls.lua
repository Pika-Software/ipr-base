local addonName = 'Better Ragdolls'

-- gLua Refresh Protection
pAddons = pAddons or {}
if pAddons[ addonName ] then return end
pAddons[ addonName ] = true

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

if (SERVER) then

	local ents_Create = ents.Create
	local hook_Add = hook.Add
	local hook_Run = hook.Run
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
		-- Removing old ragdoll (if exists)
		self:RemoveRagdoll()

		local ent = ents_Create( self:GetBoneCount() > 1 and 'prop_ragdoll' or 'prop_physics' )
		if IsValid( ent ) then
			ent:SetCreator( self )

			-- Model
			ent:SetModel( self:GetModel() )
			ent:SetSkin( self:GetSkin() )

			-- Bodygroups
			for _, bodygroup in ipairs( self:GetBodyGroups() ) do
				ent:SetBodygroup( bodygroup.id, self:GetBodygroup( bodygroup.id ) )
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
			for i = 0, self:GetBoneCount() do
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

			-- Hook for dev's
			hook_Run( 'PlayerRagdollCreated', self, ent )

			-- Spectating :
			if IsValid( self:GetObserverTarget() ) then
				return
			end

			self:SpectateEntity( ent )
			self:Spectate( OBS_MODE_CHASE )
		end
	end

	hook_Add('PlayerDisconnected', addonName, function( ply )
		ply:RemoveRagdoll()
	end)

	hook_Add('PlayerSpawn', addonName, function( ply, trans )
		if (trans) then return end
		ply:RemoveRagdoll()
	end)

end