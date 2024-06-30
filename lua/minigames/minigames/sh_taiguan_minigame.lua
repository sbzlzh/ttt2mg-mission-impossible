if SERVER then
    AddCSLuaFile()
end

MINIGAME.author = "sbzl"
MINIGAME.contact = "TTT2 Discord"

MINIGAME.conVarData = {
    ttt2_minigames_taig_innocent_base_armor = {
        slider = true,
        min = 0,
        max = 1,
        desc = "ttt2_minigames_taig_innocent_base_armor (Def. 1)"
    },
    ttt2_minigames_taig_innocent_armor = {
        slider = true,
        min = 0,
        max = 999,
        desc = "ttt2_minigames_taig_innocent_armor (Def. 100)"
    }
}

local ttt2_minigames_taig_innocent_base_armor = CreateConVar("ttt2_minigames_taig_innocent_base_armor", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Whether to enable civilian armor?")
local ttt2_minigames_taig_innocent_armor = CreateConVar("ttt2_minigames_taig_innocent_armor", "100", { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Setting up the Innocents Armor.")

if CLIENT then
    MINIGAME.lang = {
        name = {
            en = "Mission Impossible",
            zh_hans = "抬棺模式"
        },
        desc = {
            en = "One traitor, everyone else is innocent. Silenced shots. Players can only use Deagle.",
            zh_hans = "一个叛徒，其他人都是无辜的。消音射击。玩家只能使用沙漠之鹰."
        }
    }
end

if SERVER then
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
        local traitorSet = false
        local plys = util.GetAlivePlayers()
        local totalHealth = 0

        RunConsoleCommand("ttt_haste", "0")
        RunConsoleCommand("ttt_roundtime_minutes", "10")

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

        if #plys > 0 then
            local traitorIndex = math.random(#plys)
            local traitor = plys[traitorIndex]

            for i = 1, #plys do
                local ply = plys[i]
                ply:StripWeapons()

                if i == traitorIndex then
                    ply:SetRole(ROLE_TRAITOR)
                    traitorSet = true
                    ply:Give("weapon_ttt_minigames_traitor_revolver")
                else
                    ply:SetRole(ROLE_INNOCENT)
                    totalHealth = totalHealth + ply:Health()
                    ply:Give("weapon_ttt_minigames_revolver")
                end

                ply:GiveAmmo(50, "AlyxGun")
                ply:Give("weapon_zm_improvised")
                ply:Give("weapon_zm_carry")
                ply:Give("weapon_ttt_unarmed")
            end

            -- Ensure traitor and innocent roles are updated before setting armor
            timer.Simple(0.1, function()
                for i = 1, #plys do
                    local ply = plys[i]
                    if ply:GetRole() == ROLE_INNOCENT then
                        if ttt2_minigames_taig_innocent_base_armor:GetBool() then
                            ply:GiveArmor(GetConVar("ttt2_minigames_taig_innocent_armor"):GetInt())
                        end
                    end
                end

                -- Set traitor's health and armor after all innocents have been processed
                if traitorSet then
                    local traitor = GetPlayersByRole(ROLE_TRAITOR)[1]
                    if traitor then
                        traitor:SetHealth(totalHealth * 2)
                        traitor:GiveArmor(totalHealth / 2)
                    end
                end

                SendFullStateUpdate()
            end)
        end

        hook.Add("PlayerCanPickupWeapon", "MinigameRestrictWeapons", function(ply, wep)
            if wep:GetClass() ~= "weapon_ttt_minigames_traitor_revolver" and wep:GetClass() ~= "weapon_ttt_minigames_revolver" and wep:GetClass() ~= "weapon_zm_revolver" then
                return false
            end
        end)

        hook.Add("PlayerSwitchWeapon", "MinigameRestrictSwitchWeapon", function(ply, oldWep, newWep)
            if newWep:GetClass() ~= "weapon_ttt_minigames_traitor_revolver" and newWep:GetClass() ~= "weapon_ttt_minigames_revolver" and newWep:GetClass() ~= "weapon_zm_revolver" then
                return false
            end
        end)

        hook.Add("PlayerCanHearPlayersVoice", "MinigameMuteVoice", function(listener, talker)
            return false
        end)
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

        hook.Remove("PlayerCanPickupWeapon", "MinigameRestrictWeapons")
        hook.Remove("PlayerSwitchWeapon", "MinigameRestrictSwitchWeapon")
        hook.Remove("PlayerCanHearPlayersVoice", "MinigameMuteVoice")
    end
end
