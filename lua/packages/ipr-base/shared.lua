import( "https://gist.githubusercontent.com/PrikolMen/17cf58e562bc154076f067a54afc4822/raw/d873b3cef8e56ce7728530e5158021ce77348822/setf.lua" )

do

    local ENTITY = FindMetaTable( "Entity" )

    -- Entity:IsPlayerRagdoll()
    function ENTITY:IsPlayerRagdoll()
        return self:GetNW2String( "ragdoll-owner" ) ~= nil
    end

    -- Player:GetRagdollOwner()
    do

        local getRagdollOwner = debug.setf( _PKG:GetIdentifier( "ENTITY.GetRagdollOwner" ), ENTITY.GetRagdollOwner )
        local player_GetBySteamID64 = player.GetBySteamID64
        local IsValid = IsValid

        function ENTITY:GetRagdollOwner()
            local steamid = self:GetNW2String( "ragdoll-owner" )
            if steamid then
                local entity = player_GetBySteamID64( steamid )
                if IsValid( entity ) then
                    return entity
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