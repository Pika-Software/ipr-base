import( "https://gist.githubusercontent.com/PrikolMen/17cf58e562bc154076f067a54afc4822/raw/d873b3cef8e56ce7728530e5158021ce77348822/setf.lua" )
install( "packages/glua-extensions", "https://github.com/Pika-Software/glua-extensions" )

do

    local ENTITY = FindMetaTable( "Entity" )

    -- Entity:IsPlayerRagdoll()
    function ENTITY:IsPlayerRagdoll()
        return self:GetNW2String( "ragdoll-owner" ) ~= nil
    end

    -- Player:GetRagdollOwner()
    do

        local getRagdollOwner = debug.setf( _PKG:GetIdentifier( "ENTITY.GetRagdollOwner" ), ENTITY.GetRagdollOwner )
        local player_GetByUniqueID2 = player.GetByUniqueID2
        local IsValid = IsValid

        function ENTITY:GetRagdollOwner()
            local uid = self:GetNW2String( "ragdoll-owner" )
            if uid then
                local ply = player_GetByUniqueID2( uid )
                if IsValid( ply ) then
                    return ply
                end
            end

            return getRagdollOwner( self )
        end

    end

end

-- Player:GetRagdollEntity()
do

    local PLAYER = FindMetaTable( "Player" )

    function PLAYER:GetRagdollEntity()
        return self:GetNW2Entity( "ragdoll" )
    end

end

if SERVER then
    include( "init.lua" )
end

hook.Run( "IPR - Initialized" )