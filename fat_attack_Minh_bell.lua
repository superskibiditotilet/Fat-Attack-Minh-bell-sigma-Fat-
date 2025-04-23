getgenv().Config = {
    FastAttack = true,
    ClickAttack = true,
    SuperFastMode = true
}

local WeaponDelay = 0.025
local CONFIG = {
    EnemyRange = 300,
    AttackInterval = getgenv().Config.SuperFastMode and 0.015 or 0.025
}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

pcall(function()
    require(ReplicatedStorage.Util.CameraShaker):Stop()
end)

local CombatFramework = require(player.PlayerScripts.CombatFramework)
local controller = debug.getupvalues(CombatFramework)[2].activeController

local function getBlade()
    local blade = controller.blades and controller.blades[1]
    while blade and blade.Parent ~= character do
        blade = blade.Parent
    end
    return blade
end

local function getTargets()
    local RigLib = require(ReplicatedStorage.CombatFramework.RigLib)
    local hits = RigLib.getBladeHits(character, {character.HumanoidRootPart}, CONFIG.EnemyRange)

    local valid = {}
    local seen = {}
    for _, v in pairs(hits) do
        local root = v.Parent:FindFirstChild("HumanoidRootPart")
        if root and not seen[v.Parent] then
            table.insert(valid, root)
            seen[v.Parent] = true
        end
    end
    return valid
end

coroutine.wrap(function()
    for _, func in pairs(getreg()) do
        if typeof(func) == "function" and getfenv(func).script == player.PlayerScripts.CombatFramework then
            for _, val in pairs(debug.getupvalues(func)) do
                if typeof(val) == "table" then
                    spawn(function()
                        RunService.RenderStepped:Connect(function()
                            if getgenv().Config.FastAttack then
                                pcall(function()
                                    val.activeController.timeToNextAttack = -(math.huge^math.huge^math.huge)
                                    val.activeController.attacking = false
                                    val.activeController.increment = 4
                                    val.activeController.blocking = false
                                    val.activeController.hitboxMagnitude = 150
                                    val.activeController.humanoid.AutoRotate = true
                                    val.activeController.focusStart = 0
                                    val.activeController.currentAttackTrack = 0
                                    sethiddenproperty(player, "SimulationRaxNerous", math.huge)
                                end)
                            end
                        end)
                    end)
                end
            end
        end
    end
end)()

spawn(function()
    RunService.RenderStepped:Connect(function()
        if getgenv().Config.ClickAttack then
            pcall(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):Button1Down(Vector2.new(0,1,0,1))
            end)
        end
    end)
end)

spawn(function()
    while task.wait(CONFIG.AttackInterval) do
        if getgenv().Config.FastAttack and controller and controller.blades and controller.blades[1] then
            local targets = getTargets()
            if #targets > 0 then
                ReplicatedStorage.RigControllerEvent:FireServer("weaponChange", tostring(getBlade()))
                ReplicatedStorage.RigControllerEvent:FireServer("hit", targets, 1, "")
            end
        end
    end
end)
