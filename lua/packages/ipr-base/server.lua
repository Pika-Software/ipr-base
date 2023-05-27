install( "packages/player-extensions", "https://github.com/Pika-Software/player-extensions" )

-- Other
local packageName = gpm.Package:GetIdentifier()
local PLAYER = FindMetaTable( "Player" )

-- Libraries
local hook = hook
local ents = ents
local util = util

-- Variables
local COLLISION_GROUP_PASSABLE_DOOR = COLLISION_GROUP_PASSABLE_DOOR
local OBS_MODE_CHASE = OBS_MODE_CHASE
local IsValid = IsValid
local ipairs = ipairs
local type = type

function PLAYER:RemoveRagdoll()
    local ent = self:GetRagdollEntity()
    if not IsValid( ent ) then return end

    hook.Run( "PlayerRagdollRemoved", self, ent )
    return ent:Remove()
end

hook.Add( "PlayerDisconnected", packageName, PLAYER.RemoveRagdoll )

do

    local player_GetAll = player.GetAll

    function player.RemovePlayerRagdolls()
        for _, ply in ipairs( player_GetAll() ) do
            ply:RemoveRagdoll()
        end
    end

end

function PLAYER:CreateRagdoll()
    self:RemoveRagdoll()

    local ragdollClass = hook.Run( "PlayerRagdollClass", self )
    if ragdollClass == false then return end

    -- Creating
    local ent = nil
    if type( ragdollClass ) == "string" then
        ent = ents.Create( ragdollClass )
    else
        ent = ents.Create( self:GetBoneCount() > 1 and "prop_ragdoll" or "prop_physics" )
    end

    if not IsValid( ent ) then return end

    -- Position & angles
    ent:SetPos( self:GetPos() )
    ent:SetAngles( self:GetAngles() )

    -- Model
    local model = hook.Run( "PlayerRagdollModel", self, ent )
    if type( model ) == "string" then
        if not util.IsValidModel( model ) then return end
        ent:SetModel( model )
    else
        ent:SetModel( self:GetModel() )
    end

    -- Skin
    local modelSkin = hook.Run( "PlayerRagdollSkin", self, ent )
    if type( modelSkin ) == "number" then
        ent:SetSkin( modelSkin )
    elseif modelSkin ~= false then
        ent:SetSkin( self:GetSkin() )
    end

    -- Bodygroups
    local modelBodygroups = hook.Run( "PlayerRagdollBodyGroups", self, ent )
    if type( modelBodygroups ) == "table" then
        for _, bodygroup in ipairs( modelBodygroups ) do
            ent:SetBodygroup( bodygroup.id, bodygroup.value )
        end
    elseif modelBodygroups ~= false then
        for _, bodygroup in ipairs( self:GetBodyGroups() ) do
            ent:SetBodygroup( bodygroup.id, self:GetBodygroup( bodygroup.id ) )
        end
    end

    -- Flexes
    ent:SetFlexScale( self:GetFlexScale() )
    for flex = 1, ent:GetFlexNum() do
        ent:SetFlexWeight( flex, self:GetFlexWeight( flex ) )
    end

    -- Material
    ent:SetMaterial( self:GetMaterial() )

    -- Sub-materials
    for index in ipairs( ent:GetMaterials() ) do
        local materialPath = self:GetSubMaterial( index )
        if materialPath ~= "" then
            ent:SetSubMaterial( index, materialPath )
        end
    end

    -- Color
    ent:SetPlayerColor( self:GetPlayerColor() )
    ent:SetColor( self:GetColor() )

    -- Spawning
    ent:Spawn()

    -- Collision group
    ent:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )

    -- Network tags
    self:SetNW2Entity( "improved-player-ragdolls", ent )
    ent:SetNWBool( "improved-player-ragdolls", true )
    ent:SetCreator( self )

    -- Bone manipulations
    for boneID = 0, ent:GetBoneCount() do
        ent:ManipulateBonePosition( boneID, self:GetManipulateBonePosition( boneID ) )
        ent:ManipulateBoneAngles( boneID, self:GetManipulateBoneAngles( boneID ) )
        ent:ManipulateBoneJiggle( boneID, self:GetManipulateBoneJiggle( boneID ) )
        ent:ManipulateBoneScale( boneID, self:GetManipulateBoneScale( boneID ) )
    end

    -- Velocity
    local velocity = self:GetVelocity()
    if ent:IsRagdoll() then
        for physNum = 0, ent:GetPhysicsObjectCount() - 1 do
            local phys = ent:GetPhysicsObjectNum( physNum )
            if not IsValid( phys ) then continue end

            local boneID = ent:TranslatePhysBoneToBone( physNum )
            if boneID < 0 then continue end

            local pos, ang = self:GetBonePosition( boneID )
            phys:SetVelocity( velocity )
            phys:SetAngles( ang )
            phys:SetPos( pos )
            phys:Wake()
        end
    else
        local phys = ent:GetPhysicsObject()
        if IsValid( phys ) then
            phys:SetVelocity( velocity )
            phys:Wake()
        end
    end

    -- Fire transmission
    if self:IsOnFire() then
        self:Extinguish()
        ent:Ignite( 32, 64 )
    end

    -- Hook for dev's
    hook.Run( "PlayerRagdollCreated", self, ent )

    -- Spectating :
    if not IsValid( self:GetObserverTarget() ) then
        self:SpectateEntity( ent )
        self:Spectate( OBS_MODE_CHASE )
    end

    return ent
end

-- gmod_cameraprop ragdoll support
timer.Create( packageName, 0.5, 0, function()
    for _, camera in ipairs( ents.FindByClass( "gmod_cameraprop" ) ) do
        local ply, target = camera[ packageName ], camera:GetentTrack()

        if not ply then
            if not IsValid( target ) then continue end
            if not target:IsPlayer() then continue end
            if target:Alive() then continue end

            local ragdoll = target:GetRagdollEntity()
            if not IsValid( ragdoll ) then continue end
            camera:SetentTrack( ragdoll )
            camera[ packageName ] = target
            continue
        end

        if not IsValid( ply ) then continue end
        if not ply:Alive() then continue end
        camera:SetentTrack( ply )
        camera[ packageName ] = nil
    end
end )

local removeOnSpawn = CreateConVar( "ipr_remove_on_spawn", "1", FCVAR_ARCHIVE, "If 1, player ragdolls will be removed when the player is respawned.", 0, 1 )

hook.Add( "PlayerSpawn", packageName, function( ply, _ )
    if not removeOnSpawn:GetBool() then return end
    ply:RemoveRagdoll()
end )

hook.Add( "DoPlayerDeath", packageName, function( ply, _, damageInfo )
    ply:SetVelocity( -damageInfo:GetDamageForce() )
end )

hook.Run( "IPR - Initialized" )