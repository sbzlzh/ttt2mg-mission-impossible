if SERVER then
    AddCSLuaFile()
end

MINIGAME.author = "sbzl"
MINIGAME.contact = "TTT2 Discord"
MINIGAME.conVarData = {
    ttt2_minigames_traitor_only = {
        checkbox = true,
        desc = "ttt2_minigames_traitor_only (Def. 1)"
    },
    --[[ttt2_min_taig_armor = {
        checkbox = true,
        desc = "ttt2_min_taig_armor (Def. 100)"
    }]]
}

if CLIENT then
    MINIGAME.lang = {
        name = {
            en = "Mission Impossible"
        },
        desc = {
            en = "One traitor,everyone else is innocent. Silenced shots. Players can only use Deagle."
        }
    }
end

if SERVER then
    local ttt2_minigames_traitor_only = CreateConVar("ttt2_minigames_traitor_only", "1", { FCVAR_ARCHIVE }, "Only one traitor, everyone else is innocent")
    --local ttt2_min_taig_armor = CreateConVar("ttt2_min_taig_armor", "100", { FCVAR_ARCHIVE }, "set armor")

    function GetPlayersByRole(role)
        local players = {}
        for _, ply in ipairs(player.GetAll()) do
            if ply:GetRole() == role then
                table.insert(players, ply)
            end
        end
        return players
    end

    function TRAITORCheck()
        local plys = util.GetAlivePlayers()
        for i = 1, #plys do
            if plys[i]:GetBaseRole() == ROLE_TRAITOR then
                return true
            end
        end
        return false
    end

    function MINIGAME:IsSelectable()
        return TRAITORCheck()
    end

    function MINIGAME:OnActivation()
        RunConsoleCommand("ttt_haste", "0")
        RunConsoleCommand("ttt_roundtime_minutes", "5")

        timer.Create("StartMusic", 0, 1, function()
            for _, ply in ipairs(player.GetAll()) do
                ply:SendLua('surface.PlaySound("ttt/astronomia.mp3")')
            end

            timer.Create("StartFinalMusic", 196, 1, function()
                for _, ply in ipairs(player.GetAll()) do
                    ply:SendLua('surface.PlaySound("ttt/global_final.mp3")')
                end

                timer.Create("StartFinal2Music", 78, 1, function()
                    for _, ply in ipairs(player.GetAll()) do
                        ply:SendLua('surface.PlaySound("ttt/global_final2.mp3")')
                    end
                end)
            end)
        end)

        if ttt2_minigames_traitor_only:GetBool() then
            local traitorSet = false
            local plys = util.GetAlivePlayers()
            local totalHealth = 0
            --local totalArmor = 0
            for i = 1, #plys do
                local ply = plys[i]
                if not traitorSet then
                    ply:SetRole(ROLE_TRAITOR)
                    traitorSet = true
                    ply:Give("weapon_ttt_minigames_traitor_revolver")
                    ply:GiveAmmo(50, "AlyxGun")
                else
                    ply:SetRole(ROLE_INNOCENT)
                    totalHealth = totalHealth + ply:Health()
                    --ply:SetArmor(100)
                    --totalArmor = totalArmor + ply:Armor()
                    ply:Give("weapon_ttt_minigames_revolver")
                    ply:GiveAmmo(50, "AlyxGun")
                end
            end
            if traitorSet then
                local traitor = GetPlayersByRole(ROLE_TRAITOR)[1]
                if traitor then
                    traitor:SetHealth(totalHealth)
                   -- traitor:SetArmor(totalArmor / 2)
                    --print("Traitor's armor: " .. traitor:Armor())
                end
            end
            SendFullStateUpdate()
        else
            print("[TTT2][MINIGAMES][sh_jesters_minigame] ttt2_minigames_traitor_only is not enabled.")
        end
    end

    function MINIGAME:OnDeactivation()
        RunConsoleCommand("ttt_haste", "1")
        RunConsoleCommand("ttt_roundtime_minutes", "10")

        for _, ply in ipairs(player.GetAll()) do
            ply:SendLua('RunConsoleCommand("stopsound")')
        end

        if timer.Exists("StartMusic") then
            timer.Remove("StartMusic")
        end

        if timer.Exists("StartFinalMusic") then
            timer.Remove("StartFinalMusic")
        end

        if timer.Exists("StartFinal2Music") then
            timer.Remove("StartFinal2Music")
        end

        hook.Remove("PlayerStartVoice", "MinigameMuteVoice")
        hook.Remove("PlayerEndVoice", "MinigameMuteVoice")
    end

    hook.Add("PlayerCanPickupWeapon", "MinigameRestrictWeapons", function(ply, wep)
        if wep:GetClass() ~= "weapon_ttt_minigames_traitor_revolver" and wep:GetClass() ~= "weapon_ttt_minigames_revolver" then
            return false
        end
    end)

    hook.Add("PlayerSwitchWeapon", "MinigameRestrictSwitchWeapon", function(ply, oldWep, newWep)
        if newWep:GetClass() ~= "weapon_ttt_minigames_traitor_revolver" and newWep:GetClass() ~= "weapon_ttt_minigames_revolver" then
            return false
        end
    end)

    hook.Add("PlayerStartVoice", "MinigameMuteVoice", function(ply)
        return false
    end)

    hook.Add("PlayerEndVoice", "MinigameMuteVoice", function(ply)
        ply:StopSpeaking(true)
    end)
end
