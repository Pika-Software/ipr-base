install( "packages/glua-extensions", "https://github.com/Pika-Software/glua-extensions" )
install( "packages/player-extensions", "https://github.com/Pika-Software/player-extensions" )

do

    local ENTITY = FindMetaTable( "Entity" )

    -- Entity:IsPlayerRagdoll()
    function ENTITY:IsPlayerRagdoll()
        return self:GetNW2Bool( "is-player-ragdoll", false )
    end

    -- Player:GetRagdollOwner()
    function ENTITY:GetRagdollOwner()
        if not self:IsPlayerRagdoll() then return end
        return self:GetCreator()
    end

end

-- Player:GetRagdollEntity()
do

    local PLAYER = FindMetaTable( "Player" )
    local packageName = _PKG:GetIdentifier()
    local ents_GetAll = ents.GetAll
    local ipairs = ipairs

    function PLAYER:GetRagdollEntity()
        local ragdoll = self[ packageName ]
        if IsValid( ragdoll ) then
            return ragdoll
        end

        local uid = self:UniqueID2()
        for _, entity in ipairs( ents_GetAll() ) do
            if not entity:IsPlayerRagdoll() then continue end
            if entity:GetNW2String( "entity-owner" ) ~= uid then continue end
            self[ packageName ] = entity
            return entity
        end
    end

end

if not SERVER then return end
include( "init.lua" )