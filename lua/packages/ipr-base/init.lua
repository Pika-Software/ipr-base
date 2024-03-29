local PLAYER = FindMetaTable( "Player" )

-- Libraries
local hook = hook
local ents = ents
local util = util

-- Variables
local COLLISION_GROUP_PASSABLE_DOOR = COLLISION_GROUP_PASSABLE_DOOR
local MOVETYPE_VPHYSICS = MOVETYPE_VPHYSICS
local SOLID_VPHYSICS = SOLID_VPHYSICS
local OBS_MODE_CHASE = OBS_MODE_CHASE
local player_GetAll = player.GetAll
local IsValid = IsValid
local ipairs = ipairs
local Model = Model
local type = type

function PLAYER:RemoveRagdoll()
    local entity = self:GetRagdollEntity()
    if IsValid( entity ) then
        entity:Remove()
    end
end

function player.RemovePlayerRagdolls()
    for _, ply in ipairs( player_GetAll() ) do
        ply:RemoveRagdoll()
    end
end

hook.Add( "PlayerDisconnected", "RemoveOnDisconnect", PLAYER.RemoveRagdoll )

function PLAYER:CreateRagdoll()
    self:RemoveRagdoll()

    local ragdollClass = hook.Run( "PlayerRagdollClass", self )
    if ragdollClass == false then return end

    -- Creating
    local entity = nil
    if type( ragdollClass ) == "string" then
        entity = ents.Create( ragdollClass )
    else
        entity = ents.Create( self:GetBoneCount() > 1 and "prop_ragdoll" or "prop_physics" )
    end

    if not IsValid( entity ) then return end

    -- Position & angles
    entity:SetPos( self:GetPos() )
    entity:SetAngles( self:GetAngles() )

    -- Model
    local model = hook.Run( "PlayerRagdollModel", self, entity )
    if type( model ) == "string" then
        if not util.IsValidModel( model ) then return end
        entity:SetModel( Model( model ) )
    else
        entity:SetModel( self:GetModel() )
    end

    -- Skin
    local modelSkin = hook.Run( "PlayerRagdollSkin", self, entity )
    if type( modelSkin ) == "number" then
        entity:SetSkin( modelSkin )
    elseif modelSkin ~= false then
        entity:SetSkin( self:GetSkin() )
    end

    -- Bodygroups
    local modelBodygroups = hook.Run( "PlayerRagdollBodyGroups", self, entity )
    if type( modelBodygroups ) == "table" then
        for _, bodygroup in ipairs( modelBodygroups ) do
            entity:SetBodygroup( bodygroup.id, bodygroup.value )
        end
    elseif modelBodygroups ~= false then
        for _, bodygroup in ipairs( self:GetBodyGroups() ) do
            entity:SetBodygroup( bodygroup.id, self:GetBodygroup( bodygroup.id ) )
        end
    end

    -- Flexes
    entity:SetFlexScale( self:GetFlexScale() )
    for flex = 1, entity:GetFlexNum() do
        entity:SetFlexWeight( flex, self:GetFlexWeight( flex ) )
    end

    -- Visual
    entity:SetMaterial( self:GetMaterial() )
    entity:SetColor( self:GetColor() )

    for index in ipairs( entity:GetMaterials() ) do
        local materialPath = self:GetSubMaterial( index )
        if materialPath ~= "" then
            entity:SetSubMaterial( index, materialPath )
        end
    end

    -- Collision group
    entity:SetCollisionGroup( COLLISION_GROUP_PASSABLE_DOOR )

    -- Network tags
    self:SetNW2Entity( "player-ragdoll", entity )
    entity:SetNW2Bool( "player-ragdoll", true )
    entity:SetCreator( self )

    -- Spawning
    entity:Spawn()

    -- Physics
    entity:SetMoveType( MOVETYPE_VPHYSICS )
    entity:SetSolid( SOLID_VPHYSICS )
    entity:PhysicsInit( SOLID_VPHYSICS )
    entity:PhysWake()

    -- Bone manipulations
    for boneID = 0, entity:GetBoneCount() do
        entity:ManipulateBonePosition( boneID, self:GetManipulateBonePosition( boneID ) )
        entity:ManipulateBoneAngles( boneID, self:GetManipulateBoneAngles( boneID ) )
        entity:ManipulateBoneJiggle( boneID, self:GetManipulateBoneJiggle( boneID ) )
        entity:ManipulateBoneScale( boneID, self:GetManipulateBoneScale( boneID ) )
    end

    -- Velocity
    local velocity = self:GetVelocity()
    if entity:IsRagdoll() then
        for physNum = 0, entity:GetPhysicsObjectCount() - 1 do
            local phys = entity:GetPhysicsObjectNum( physNum )
            if not IsValid( phys ) then continue end

            local boneID = entity:TranslatePhysBoneToBone( physNum )
            if boneID < 0 then continue end

            local pos, ang = self:GetBonePosition( boneID )
            phys:SetVelocity( velocity )
            phys:SetAngles( ang )
            phys:SetPos( pos )
            phys:Wake()
        end
    else
        local phys = entity:GetPhysicsObject()
        if IsValid( phys ) then
            phys:SetVelocity( velocity )
            phys:Wake()
        end
    end

    -- Fire transmission
    if self:IsOnFire() then
        self:Extinguish()
        entity:Ignite( 32, 64 )
    end

    -- Hook for dev's
    hook.Run( "PlayerRagdollCreated", self, entity )

    -- Spectating :
    if not IsValid( self:GetObserverTarget() ) then
        self:SetObserverMode( OBS_MODE_CHASE )
        self:SpectateEntity( entity )
    end

    return entity
end

-- gmod_cameraprop ragdoll support
local packageName = _PKG:GetIdentifier()
timer.Create( "gmod_cameraprop", 0.5, 0, function()
    for _, camera in ipairs( ents.FindByClass( "gmod_cameraprop" ) ) do
        local ply, target = camera[ packageName ], camera:GetentTrack()

        if not ply then
            if not IsValid( target ) then continue end
            if not target:IsPlayer() then continue end
            if target:Alive() then continue end

            local ragdoll = target:GetRagdollEntity()
            if IsValid( ragdoll ) then
                camera:SetentTrack( ragdoll )
                camera[ packageName ] = target
            end

            continue
        end

        if not IsValid( ply ) then continue end
        camera:SetentTrack( ply )
        camera[ packageName ] = nil
    end
end )

local removeOnSpawn = CreateConVar( "ipr_remove_on_spawn", "1", FCVAR_ARCHIVE, "If 1, player ragdolls will be removed when the player is respawned.", 0, 1 )

hook.Add( "PlayerSpawn", "RemoveOnSpawn", function( ply, _ )
    if removeOnSpawn:GetBool() then
        ply:RemoveRagdoll()
    end

    ply:SpectateEntity( ply )
end )

hook.Add( "DoPlayerDeath", "RemoveDamageVelocity", function( ply, _, damageInfo )
    ply:SetVelocity( -damageInfo:GetDamageForce() )
end )

hook.Add( "PlayerUse", "Usage", function( ply, entity )
    if not entity:IsPlayerRagdoll() then return end
    hook.Run( "PlayerRagdollUse", entity, ply )
end )