if SERVER then
    AddCSLuaFile()
end

MINIGAME.author = "sbzl"
MINIGAME.contact = "TTT2 Discord"

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

        for i = 1, #plys do
            plys[i]:StripWeapons()  -- 移除所有武器

            if not traitorSet then
                plys[i]:SetRole(ROLE_TRAITOR)
                traitorSet = true
                plys[i]:Give("weapon_ttt_minigames_traitor_revolver")
            else
                plys[i]:SetRole(ROLE_INNOCENT)
                totalHealth = totalHealth + plys[i]:Health()
                plys[i]:Give("weapon_ttt_minigames_revolver")
            end
            plys[i]:GiveAmmo(50, "AlyxGun")
            plys[i]:Give("weapon_zm_improvised")
        end

        timer.Create("INNOCENTMinigame", 0, 1, function()
            for i = 1, #plys do
                if plys[i]:GetSubRole() == ROLE_INNOCENT then
                    timer.Create("SuddenMinigame", 2, 2, function()
                        plys[i]:SetArmor(100)
                        plys[i]:SetMaxArmor(100)
                    end)
                    print(plys[i]:Nick() .. "的护甲值是：" .. plys[i]:Armor())
                end
            end
        end)

        -- Set traitor's health and armor after all innocents have been processed
        if traitorSet then
            local traitor = GetPlayersByRole(ROLE_TRAITOR)[1]
            if traitor then
                traitor:SetHealth(totalHealth * 2)
                timer.Create("TRAITORMinigame", 1, 3, function()
                    traitor:SetArmor(totalHealth / 2)
                    traitor:SetMaxArmor(totalHealth / 2)
                end)
            end
        end

        SendFullStateUpdate()
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
        hook.Remove("PlayerCanPickupWeapon", "MinigameRestrictWeapons")
        hook.Remove("PlayerSwitchWeapon", "MinigameRestrictSwitchWeapon")
        hook.Remove("PlayerEndVoice", "MinigameMuteVoice")
    end
end
