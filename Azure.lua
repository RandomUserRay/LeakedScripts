if (not LPH_OBFUSCATED) then
    LPH_NO_VIRTUALIZE = function(...) return (...) end;
end

function notify(title, text, icon, duration)
    game.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Icon = icon,
        Duration = duration
    })
end

function StopAudio()
    game:GetService("ReplicatedStorage"):WaitForChild("MainEvent"):FireServer("BoomboxStop")
end

function stop(ID, Key)
    local OriginalKeyUpValue = 0
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local cor = coroutine.wrap(function()
        wait(LocalPlayer.Character.LowerTorso.BOOMBOXSOUND.TimeLength-0.1)
        if LocalPlayer.Character.LowerTorso.BOOMBOXSOUND.SoundId == "rbxassetid://"..ID and OriginalKeyUpValue == Key then
            StopAudio()
        end
    end)
    cor()
end

function Play(ID)
    local OriginalKeyUpValue = 0
    local LocalPlayer = game:GetService("Players").LocalPlayer
    if LocalPlayer.Backpack:FindFirstChild("[Boombox]") then
        local Tool = nil
        LocalPlayer.Backpack["[Boombox]"].Parent = LocalPlayer.Character
        game.ReplicatedStorage.MainEvent:FireServer("Boombox", ID)
        LocalPlayer.Character["[Boombox]"].RequiresHandle = false
        LocalPlayer.Character["[Boombox]"].Parent = LocalPlayer.Backpack
        LocalPlayer.PlayerGui.MainScreenGui.BoomboxFrame.Visible = false
        if Tool ~= true then
            if Tool then
                Tool.Parent = LocalPlayer.Character
            end
        end
        LocalPlayer.Character.LowerTorso:WaitForChild("BOOMBOXSOUND")
            local cor = coroutine.wrap(function()
                repeat wait() until LocalPlayer.Character.LowerTorso.BOOMBOXSOUND.SoundId == "rbxassetid://"..ID and LocalPlayer.Character.LowerTorso.BOOMBOXSOUND.TimeLength > 0.01
                OriginalKeyUpValue = OriginalKeyUpValue+1
                stop(ID, OriginalKeyUpValue)
            end)
        cor()
    end
end

function load()
    --// Services
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local Workspace = game:GetService("Workspace")
    local Lighting = game:GetService("Lighting")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    --// Variables
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace:FindFirstChildWhichIsA("Camera")
    local Hitsounds = {}

    --// Script Table
    local Script = {
        Functions = {},
        Locals = {
            Target = nil,
            IsTargetting = false,
            Resolver = {
                OldTick = tick(),
                OldPos = Vector3.new(0, 0, 0),
                ResolvedVelocity = Vector3.new(0, 0, 0)
            },
            AutoSelectTick = tick(),
            AntiAimViewer = {
                MouseRemoteFound = false,
                MouseRemote = nil,
                MouseRemoteArgs = nil,
                MouseRemotePositionIndex = nil
            },
            HitEffect = nil,
            Gun = {
                PreviousGun = nil,
                PreviousAmmo = 999,
                Shotguns = {"[Double-Barrel SG]", "[TacticalShotgun]", "[Shotgun]"}
            },
            PlayerHealth = {},
            JumpOffset = 0,
            BulletPath = {
                [4312377180] = Workspace:FindFirstChild("MAP") and Workspace.MAP:FindFirstChild("Ignored") or nil,
                [1008451066] = Workspace:FindFirstChild("Ignored") and Workspace.Ignored:FindFirstChild("Siren") and Workspace.Ignored.Siren:FindFirstChild("Radius") or nil,
                [3985694250] = Workspace and Workspace:FindFirstChild("Ignored") or nil,
                [5106782457] = Workspace and Workspace:FindFirstChild("Ignored") or nil,
                [4937639028] = Workspace and Workspace:FindFirstChild("Ignored") or nil,
                [1958807588] = Workspace and Workspace:FindFirstChild("Ignored") or nil
            },
            World = {
                FogColor = Lighting.FogColor,
                FogStart = Lighting.FogStart,
                FogEnd = Lighting.FogEnd,
                Ambient = Lighting.Ambient,
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                ExposureCompensation = Lighting.ExposureCompensation
            },
            SavedCFrame = nil,
            NetworkPreviousTick = tick(),
            NetworkShouldSleep = false,
            FFlags = {
      }
            ,OriginalVelocity = {},
            RotationAngle = 0
        },
        Utility = {
            Drawings = {},
            EspCache = {}
        },
        Connections = {
            GunConnections = {}
        },
        AzureIgnoreFolder = Instance.new("Folder", game:GetService("Workspace"))
    }

    --// Settings Table
    local Settings = {
        Combat = {
            Enabled = false,
            AimPart = "HumanoidRootPart",
            Silent = false,
            Mouse = false,
            Alerts = false,
            LookAt = false,
            Spectate = false,
            AntiAimViewer = false,
            AutoSelect = {
                Enabled = false,
                Cooldown = {
                    Enabled = false,
                    Amount = 0.5
                }
            },
            Checks = {
                Enabled = false,
                Knocked = false,
                Crew = false,
                Wall = false,
                Grabbed = false,
                Vehicle = false
            },
            Smoothing = {
                Horizontal = 1,
                Vertical = 1
            },
            Prediction = {
                Horizontal = 0.134,
                Vertical = 0.134
            },
            Resolver = {
                Enabled = false,
                RefreshRate = 0
            },
            Fov = {
                Enabled = false,
                Visualize = {
                    Enabled = false,
                    Color = Color3.new(1, 1, 1)
                },
                Radius = 80
            },
            Visuals = {
                Enabled = false,
                Tracer = {
                    Enabled = false,
                    Color = Color3.new(1, 1, 1),
                    Thickness = 2
                },
                Dot = {
                    Enabled = false,
                    Color = Color3.new(1, 1, 1),
                    Filled = false,
                    Size = 6
                },
                Chams = {
                    Enabled = false,
                    Fill = {
                        Color = Color3.new(1, 1, 1),
                        Transparency = 0.5
                    },
                    Outline = {
                        Color = Color3.new(1, 1, 1),
                        Transparency = 0.5
                    }
                }
            },
            Air = {
                Enabled = false,
                AirAimPart = {
                    Enabled = false,
                    HitPart = "LowerTorso"
                },
                JumpOffset = {
                    Enabled = false,
                    Offset = 0.09
                }
            }
        },
        Visuals = {
            Esp = {
                Enabled = false,
                Boxes = {
                    Enabled = false,
                    Filled = {
                        Enabled = false,
                        Color = Color3.new(1, 1, 1),
                        Transparency = 0.3
                    },
                    Color = Color3.new(1, 1, 1)
                }
            },
            BulletTracers = {
                Enabled = false,
                Color = {
                    Gradient1 = Color3.new(1, 1, 1),
                    Gradient2 = Color3.new(0, 0, 0)
                },
                Duration = 1,
                Fade = {
                    Enabled = false,
                    Duration = 0.5
                }
            },
            BulletImpacts = {
                Enabled = false,
                Color = Color3.new(1, 1, 1),
                Duration = 1,
                Size = 1,
                Material = "SmoothPlastic",
                Fade = {
                    Enabled = false,
                    Duration = 0.5
                }
            },
            OnHit = {
                Enabled = false,
                Effect = {
                    Enabled = false,
                    Color = Color3.new(1, 1, 1)
                },
                Sound = {
                    Enabled = false,
                    Volume = 5,
                    Value = "Skeet"
                },
                Chams = {
                    Enabled = false,
                    Color = Color3.new(1, 1, 1),
                    Material = "ForceField",
                    Duration = 1
                }
            },
            World = {
                Enabled = false,
                Fog = {
                    Enabled = false,
                    Color = Color3.new(1, 1, 1),
                    End = 1000,
                    Start = 10000
                },
                Ambient = {
                    Enabled = false,
                    Color = Color3.new(1, 1, 1)
                },
                Brightness = {
                    Enabled = false,
                    Value = 0
                },
                ClockTime = {
                    Enabled = false,
                    Value = 24
                },
                WorldExposure = {
                    Enabled = false,
                    Value = -0.1
                }
            },
            Crosshair = {
                Enabled = false,
                Color = Color3.new(1, 1, 1),
                Size = 10,
                Gap = 2,
                Rotation = {
                    Enabled = false,
                    Speed = 1
                }
            }
        },
        AntiAim = {
            VelocitySpoofer = {
                Enabled = false,
                Visualize = {
                    Enabled = false,
                    Color = Color3.new(1, 1, 1),
                    Prediction = 0.134
                },
                Type = "Underground",
                Roll = 0,
                Pitch = 0,
                Yaw = 0
            },
            CSync = {
                Enabled = false,
                Type = "Custom",
                Visualize = {
                    Enabled = false,
                    Color = Color3.new(1, 1, 1)
                },
                RandomDistance = 16,
                Custom = {
                    X = 0,
                    Y = 0,
                    Z = 0
                },
                TargetStrafe = {
                    Speed = 1,
                    Distance = 1,
                    Height = 1
                }
            },
            Network = {
                Enabled = false,
                WalkingCheck = false,
                Amount = 0.1
            },
            VelocityDesync = {
                Enabled = false,
                Range = 1
            },
            FFlagDesync = {
                Enabled = false,
                SetNew = false,
                FFlags = {"S2PhysicsSenderRate"},
                SetNewAmount = 15,
                Amount = 2
            },
        },
        Misc = {
            Movement = {
                Speed = {
                    Enabled = false,
                    Amount = 1
                },
            },
            Exploits = {
                Enabled = false,
                NoRecoil = false,
                NoJumpCooldown = false,
                NoSlowDown = false,
				AutoReload = false,
				AutoArmor = false,
				AutoFireArmor = false,
				AntiStomp = false,
				AntiBag = false,
				AntiGrab = false,
				AutoStomp = false,
            }
        }
    }

    --// Functions
    do
    
        --// Utility Functions
        do
            Script.Functions.WorldToScreen = function(Position: Vector3)
                if not Position then return end

                local ViewportPointPosition, OnScreen = Camera:WorldToViewportPoint(Position)
                local ScreenPosition = Vector2.new(ViewportPointPosition.X, ViewportPointPosition.Y)
                return {
                    Position = ScreenPosition,
                    OnScreen = OnScreen
                }
            end

            Script.Functions.Connection = function(ConnectionType: any, Function: any)
                local Connection = ConnectionType:Connect(Function)
                return Connection
            end

            Script.Functions.MoveMouse = function(Position: Vector2, SmoothingX: number, SmoothingY: number)
                local MousePosition = UserInputService:GetMouseLocation()

                mousemoverel((Position.X - MousePosition.X) / SmoothingX, (Position.Y - MousePosition.Y) / SmoothingY)
            end

            Script.Functions.CreateDrawing = function(DrawingType: string, Properties: any)
                local DrawingObject = Drawing.new(DrawingType)

                for Property, Value in pairs(Properties) do
                    DrawingObject[Property] = Value
                end
                return DrawingObject
            end

            Script.Functions.WallCheck = function(Part: any)
                local RayCastParams = RaycastParams.new()
                RayCastParams.FilterType = Enum.RaycastFilterType.Exclude
                RayCastParams.IgnoreWater = true
                RayCastParams.FilterDescendantsInstances = Script.AzureIgnoreFolder:GetChildren()

                local CameraPosition = Camera.CFrame.Position
                local Direction = (Part.Position - CameraPosition).Unit
                local RayCastResult = Workspace:Raycast(CameraPosition, Direction * 10000, RayCastParams)

                return RayCastResult.Instance and RayCastResult.Instance == Part
            end

            Script.Functions.Create = function(ObjectType: string, Properties: any)
                local Object = Instance.new(ObjectType)

                for Property, Value in pairs(Properties) do
                    Object[Property] = Value
                end
                return Object
            end

            Script.Functions.GetGun = function(Player: any)
                local Info = {
                    Tool = nil,
                    Ammo = nil,
                    IsGunEquipped = false
                }

                local Tool = Player.Character:FindFirstChildWhichIsA("Tool")

                if not Tool then return end

                if game.GameId == 1958807588 then
                    local ArmoryGun = Player.Information.Armory:FindFirstChild(Tool.Name)
                    if ArmoryGun then
                        Info.Tool = Tool
                        Info.Ammo = ArmoryGun.Ammo.Normal
                        Info.IsGunEquipped = true
                    else
                        for _, Object in pairs(Tool:GetChildren()) do
                            if Object.Name:lower():find("ammo") and not Object.Name:lower():find("max") then
                                Info.Tool = Tool
                                Info.IsGunEquipped = true
                                Info.Ammo = Object
                            end
                        end
                    end
                elseif game.GameId == 3634139746 then
                    for _, Object in pairs(Tool:getdescendants()) do
                        if Object.Name:lower():find("ammo") and not Object.Name:lower():find("max") and not Object.Name:lower():find("no") then
                            Info.Tool = Tool
                            Info.Ammo = Object
                            Info.IsGunEquipped = true
                        end
                    end
                else
                    for _, Object in pairs(Tool:GetChildren()) do
                        if Object.Name:lower():find("ammo") and not Object.Name:lower():find("max") then
                            Info.Tool = Tool
                            Info.IsGunEquipped = true
                            Info.Ammo = Object
                        end
                    end
                end


                return Info
            end

            Script.Functions.Beam = function(StartPos: Vector3, EndPos: Vector3)
                local ColorSequence = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Settings.Visuals.BulletTracers.Color.Gradient1),
                    ColorSequenceKeypoint.new(1, Settings.Visuals.BulletTracers.Color.Gradient2),
                })
                local Part = Instance.new("Part", Script.AzureIgnoreFolder)
                Part.Size = Vector3.new(0, 0, 0)
                Part.Massless = true
                Part.Transparency = 1
                Part.CanCollide = false
                Part.Position = StartPos
                Part.Anchored = true
                local Attachment = Instance.new("Attachment", Part)
                local Part2 = Instance.new("Part", Script.AzureIgnoreFolder)
                Part2.Size = Vector3.new(0, 0, 0)
                Part2.Transparency = 0
                Part2.CanCollide = false
                Part2.Position = EndPos
                Part2.Anchored = true
                Part2.Material = Enum.Material.ForceField
                Part2.Color = Color3.fromRGB(255, 0, 212)
                Part2.Massless = true
                local Attachment2 = Instance.new("Attachment", Part2)
                local Beam = Instance.new("Beam", Part)
                Beam.FaceCamera = true
                Beam.Color = ColorSequence
                Beam.Attachment0 = Attachment
                Beam.Attachment1 = Attachment2
                Beam.LightEmission = 6
                Beam.LightInfluence = 1
                Beam.Width0 = 1.5
                Beam.Width1 = 1.5
                Beam.Texture = "http://www.roblox.com/asset/?id=446111271"
                Beam.TextureSpeed = 2
                Beam.TextureLength = 1
                task.delay(Settings.Visuals.BulletTracers.Duration, function()
                    if Settings.Visuals.BulletTracers.Fade.Enabled then
                        local TweenValue = Instance.new("NumberValue")
                        TweenValue.Parent = Beam
                        local Tween = TweenService:Create(TweenValue, TweenInfo.new(Settings.Visuals.BulletTracers.Fade.Duration), {Value = 1})
                        Tween:Play()

                        local Connection
                        Connection = Script.Functions.Connection(TweenValue:GetPropertyChangedSignal("Value"), function()
                            Beam.Transparency = NumberSequence.new(TweenValue.Value, TweenValue.Value)
                        end)

                        Script.Functions.Connection(Tween.Completed, function()
                            Connection:Disconnect()
                            Part:Destroy()
                            Part2:Destroy()
                        end)
                    else
                        Part:Destroy()
                        Part2:Destroy()
                    end
                end)
            end

            Script.Functions.Impact = function(Pos: Vector3)
                local Part = Script.Functions.Create("Part", {
                    Parent = Script.AzureIgnoreFolder,
                    Color = Settings.Visuals.BulletImpacts.Color,
                    Size = Vector3.new(Settings.Visuals.BulletImpacts.Size, Settings.Visuals.BulletImpacts.Size, Settings.Visuals.BulletImpacts.Size),
                    Position = Pos,
                    Anchored = true,
                    Material = Enum.Material[Settings.Visuals.BulletImpacts.Material]
                })

                task.delay(Settings.Visuals.BulletImpacts.Duration, function()
                    if Settings.Visuals.BulletImpacts.Fade.Enabled then
                        local Tween = TweenService:Create(Part, TweenInfo.new(Settings.Visuals.BulletImpacts.Fade.Duration), {Transparency = 1})
                        Tween:Play()

                        Script.Functions.Connection(Tween.Completed, function()
                            Part:Destroy()
                        end)
                    else
                        Part:Destroy()
                    end
                end)
            end

            Script.Functions.GetClosestPlayerDamage = function(Position: Vector3, MaxRadius: number)
                local Radius = MaxRadius
                local ClosestPlayer

                for PlayerName, Health in pairs(Script.Locals.PlayerHealth) do
                    local Player = Players:FindFirstChild(PlayerName)
                    if Player and Player.Character then
                        local PlayerPosition = Player.Character.PrimaryPart.Position
                        local Distance = (Position - PlayerPosition).Magnitude
                        local CurrentHealth = Player.Character.Humanoid.Health
                        if (Distance < Radius) and (CurrentHealth < Health) then
                            Radius = Distance
                            ClosestPlayer = Player
                        end
                    end
                end
                return ClosestPlayer
            end


            Script.Functions.Effect = function(Part, Color)
                local Clone = Script.Locals.HitEffect:Clone()
                Clone.Parent = Part

                for _, Effect in pairs(Clone:GetChildren()) do
                    if Effect:IsA("ParticleEmitter") then
                        Effect.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                            ColorSequenceKeypoint.new(0.495, Settings.Visuals.OnHit.Effect.Color),
                            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
                        })
                        Effect:Emit(1)
                    end
                end

                task.delay(2, function()
                    Clone:Destroy()
                end)
            end

            Script.Functions.PlaySound = function(SoundId, Volume)
                local Sound = Instance.new("Sound")
                Sound.Parent = Script.AzureIgnoreFolder
                Sound.Volume = Volume
                Sound.SoundId = SoundId

                Sound:Play()

                Script.Functions.Connection(Sound.Ended, function()
                    Sound:Destroy()
                end)
            end

            Script.Functions.Hitcham = function(Player, Color)
                for _, BodyPart in pairs(Player.Character:GetChildren()) do
                    if BodyPart.Name ~= "HumanoidRootPart" and BodyPart:IsA("BasePart") then
                        local Part = Instance.new("Part")
                        Part.Name = BodyPart.Name .. "_Clone"
                        Part.Parent = Script.AzureIgnoreFolder
                        Part.Material = Enum.Material[Settings.Visuals.OnHit.Chams.Material]
                        Part.Color = Settings.Visuals.OnHit.Chams.Color
                        Part.Transparency = 0
                        Part.Anchored = true
                        Part.Size = BodyPart.Size
                        Part.CFrame = BodyPart.CFrame

                        task.delay(Settings.Visuals.OnHit.Chams.Duration, function()
                            Part:Destroy()
                        end)
                    end
                end
            end

            Script.Functions.Rotate = function(Vector, Origin, Angle)
                local CosA = math.cos(Angle)
                local SinA = math.sin(Angle)
                local X = Vector.X - Origin.X
                local Y = Vector.Y - Origin.Y
                local NewX = X * CosA - Y * SinA
                local NewY = X * SinA + Y * CosA
                return Vector2.new(NewX + Origin.x, NewY + Origin.y)
            end
        end

        --// General Functions
        do
            Script.Functions.GetClosestPlayer = function()
                local Radius = Settings.Combat.Fov.Enabled and Settings.Combat.Fov.Radius or math.huge
                local ClosestPlayer
                local Mouse = UserInputService:GetMouseLocation()

                for _, Player in pairs(Players:GetPlayers()) do
                    if Player ~= LocalPlayer then
                        --// Variables
                        local ScreenPosition = Script.Functions.WorldToScreen(Player.Character.PrimaryPart.Position)
                        local Distance = (Mouse - ScreenPosition.Position).Magnitude

                        --// OnScreen Check
                        if not ScreenPosition.OnScreen then continue end

                        --// Checks
                        if (Settings.Combat.Checks.Enabled and (Settings.Combat.Checks.Vehicle and Player.Character:FindFirstChild("[CarHitBox]")) or (Settings.Combat.Checks.Knocked and Player.Character.BodyEffects["K.O"].Value == true) or (Settings.Combat.Checks.Grabbed and Player.Character:FindFirstChild("GRABBING_CONSTRAINT")) or (Settings.Combat.Checks.Crew and Player.DataFolder.Information.Crew.Value == LocalPlayer.DataFolder.Information.Crew.Value) or (Settings.Combat.Checks.Wall and Script.Functions.WallCheck(Player.Character.PrimaryPart))) then continue end

                        if (Distance < Radius) then
                            Radius = Distance
                            ClosestPlayer = Player
                        end
                    end
                end

                return ClosestPlayer
            end

            Script.Functions.GetPredictedPosition = function()
                local BodyPart = Script.Locals.Target.Character[Settings.Combat.AimPart]
                local Velocity = Settings.Combat.Resolver.Enabled and Script.Locals.Resolver.ResolvedVelocity or Script.Locals.Target.Character.HumanoidRootPart.Velocity
                local Position = BodyPart.Position + Velocity * Vector3.new(Settings.Combat.Prediction.Horizontal, Settings.Combat.Prediction.Vertical, Settings.Combat.Prediction.Horizontal)

                if Settings.Combat.Air.Enabled and Settings.Combat.Air.JumpOffset.Enabled then
                    Position = Position + Vector3.new(0, Script.Locals.JumpOffset, 0)
                end

                return Position
            end

            Script.Functions.Resolve = function()
                if Settings.Combat.Enabled and Settings.Combat.Resolver.Enabled and Script.Locals.IsTargetting and Script.Locals.Target then
                    --// Variables
                    local HumanoidRootPart = Script.Locals.Target.Character.HumanoidRootPart
                    local CurrentPosition = HumanoidRootPart.Position
                    local DeltaTime = tick() - Script.Locals.Resolver.OldTick
                    local NewVelocity = (CurrentPosition - Script.Locals.Resolver.OldPos) / DeltaTime

                    --// Set the velocity
                    Script.Locals.Resolver.ResolvedVelocity = NewVelocity

                    --// Update the old tick and old position
                    if tick() - Script.Locals.Resolver.OldTick >= 1 / Settings.Combat.Resolver.RefreshRate then
                        Script.Locals.Resolver.OldTick, Script.Locals.Resolver.OldPos = tick(), HumanoidRootPart.Position
                    end
                end
            end

            Script.Functions.MouseAim = function()
                if Settings.Combat.Enabled and Settings.Combat.Mouse and Script.Locals.IsTargetting and Script.Locals.Target then
                    local Position = Script.Functions.GetPredictedPosition()
                    local ScreenPosition = Script.Functions.WorldToScreen(Position)

                    if ScreenPosition.OnScreen then
                        Script.Functions.MoveMouse(ScreenPosition.Position, Settings.Combat.Smoothing.Horizontal, Settings.Combat.Smoothing.Vertical)
                    end
                end
            end

            Script.Functions.UpdateFieldOfView = function()
                Script.Utility.Drawings["FieldOfViewVisualizer"].Visible = Settings.Combat.Enabled and Settings.Combat.Fov.Enabled and Settings.Combat.Fov.Visualize.Enabled
                Script.Utility.Drawings["FieldOfViewVisualizer"].Color = Settings.Combat.Fov.Visualize.Color
                Script.Utility.Drawings["FieldOfViewVisualizer"].Radius = Settings.Combat.Fov.Radius
                Script.Utility.Drawings["FieldOfViewVisualizer"].Position = UserInputService:GetMouseLocation()
            end

            Script.Functions.UpdateTargetVisuals = function()
                --// ScreenPosition, Will be changed later
                local Position

                --// Variable to indicate if you"re targetting or not with a check if the target visuals are enabled
                local IsTargetting = Settings.Combat.Enabled and Settings.Combat.Visuals.Enabled and Script.Locals.IsTargetting and Script.Locals.Target or false

                --// Change the position
                if IsTargetting then
                    local PredictedPosition = Script.Functions.GetPredictedPosition()
                    Position = Script.Functions.WorldToScreen(PredictedPosition)
                end

                --// Variable to indicate if the drawing elements should show
                local TracerShow = IsTargetting and Settings.Combat.Visuals.Tracer.Enabled and Position.OnScreen or false
                local DotShow = IsTargetting and Settings.Combat.Visuals.Dot.Enabled and Position.OnScreen or false
                local ChamsShow = IsTargetting and Settings.Combat.Visuals.Chams.Enabled and Script.Locals.Target and Script.Locals.Target.Character or nil


                --// Set the drawing elements visibility
                Script.Utility.Drawings["TargetTracer"].Visible = TracerShow
                Script.Utility.Drawings["TargetDot"].Visible = DotShow
                Script.Utility.Drawings["TargetChams"].Parent = ChamsShow


                --// Update the drawing elements
                if TracerShow then
                    Script.Utility.Drawings["TargetTracer"].From = UserInputService:GetMouseLocation()
                    Script.Utility.Drawings["TargetTracer"].To = Position.Position
                    Script.Utility.Drawings["TargetTracer"].Color = Settings.Combat.Visuals.Tracer.Color
                    Script.Utility.Drawings["TargetTracer"].Thickness = Settings.Combat.Visuals.Tracer.Thickness
                end

                if DotShow then
                    Script.Utility.Drawings["TargetDot"].Position = Position.Position
                    Script.Utility.Drawings["TargetDot"].Radius = Settings.Combat.Visuals.Dot.Size
                    Script.Utility.Drawings["TargetDot"].Filled = Settings.Combat.Visuals.Dot.Filled
                    Script.Utility.Drawings["TargetDot"].Color = Settings.Combat.Visuals.Dot.Color
                end

                if ChamsShow then
                    Script.Utility.Drawings["TargetChams"].FillColor = Settings.Combat.Visuals.Chams.Fill.Color
                    Script.Utility.Drawings["TargetChams"].FillTransparency = Settings.Combat.Visuals.Chams.Fill.Transparency
                    Script.Utility.Drawings["TargetChams"].OutlineTransparency = Settings.Combat.Visuals.Chams.Outline.Transparency
                    Script.Utility.Drawings["TargetChams"].OutlineColor = Settings.Combat.Visuals.Chams.Outline.Color
                end
            end

            Script.Functions.AutoSelect = function()
                if (Settings.Combat.Enabled and Settings.Combat.AutoSelect.Enabled) and (tick() - Script.Locals.AutoSelectTick >= Settings.Combat.AutoSelect.Cooldown.Amount and Settings.Combat.AutoSelect.Cooldown.Enabled or true) then
                    local NewTarget = Script.Functions.GetClosestPlayer()
                    Script.Locals.Target = NewTarget or nil
                    Script.Locals.IsTargetting =  NewTarget and true or false
                    Script.Locals.AutoSelectTick = tick()
                end
            end

            Script.Functions.GunEvents = function()
                local CurrentGun = Script.Functions.GetGun(LocalPlayer)

                if CurrentGun and CurrentGun.IsGunEquipped and CurrentGun.Tool then
                    if CurrentGun.Tool ~= Script.Locals.Gun.PreviousGun then
                        Script.Locals.Gun.PreviousGun = CurrentGun.Tool
                        Script.Locals.Gun.PreviousAmmo = 999

                        --// Connections
                        for _, Connection in pairs(Script.Connections.GunConnections) do
                            Connection:Disconnect()
                        end
                        Script.Connections.GunConnections = {}
                    end

                    if not Script.Connections.GunConnections["GunActivated"] and Settings.Combat.Enabled and Settings.Combat.Silent and Script.Locals.AntiAimViewer.MouseRemoteFound then
                        Script.Connections.GunConnections["GunActivated"] = Script.Functions.Connection(CurrentGun.Tool.Activated, function()
                            if Script.Locals.IsTargetting and Script.Locals.Target then
                                if Settings.Combat.AntiAimViewer then
                                    local Arguments = Script.Locals.AntiAimViewer.MouseRemoteArgs

                                    Arguments[Script.Locals.AntiAimViewer.MouseRemotePositionIndex] = Script.Functions.GetPredictedPosition()
                                    Script.Locals.AntiAimViewer.MouseRemote:FireServer(unpack(Arguments))
                                end
                            end
                        end)
                    end


                    if not Script.Connections.GunConnections["GunAmmoChanged"] then
                        Script.Connections.GunConnections["GunAmmoChanged"] = Script.Functions.Connection(CurrentGun.Ammo:GetPropertyChangedSignal("Value") , function()
                            local NewAmmo = CurrentGun.Ammo.Value
                            if (NewAmmo < Script.Locals.Gun.PreviousAmmo or (game.GameId == 3985694250 and NewAmmo > Script.Locals.Gun.PreviousAmmo)) and Script.Locals.Gun.PreviousAmmo then

                                local ChildAdded
                                local ChildrenAdded = 0
                                ChildAdded = Script.Functions.Connection(Script.Locals.BulletPath[game.GameId].ChildAdded, function(Object)
                                    if Object.Name == "BULLET_RAYS" then
                                        ChildrenAdded += 1
                                        if (table.find(Script.Locals.Gun.Shotguns, CurrentGun.Tool.Name) and ChildrenAdded <= 5) or (ChildrenAdded == 1) then
                                            local GunBeam = Object:WaitForChild("GunBeam")
                                            local StartPos, EndPos = Object.Position, GunBeam.Attachment1.WorldPosition

                                            if Settings.Visuals.BulletTracers.Enabled then
                                                GunBeam:Destroy()
                                                Script.Functions.Beam(StartPos, EndPos)
                                            end

                                            if Settings.Visuals.BulletImpacts.Enabled then
                                                Script.Functions.Impact(EndPos)
                                            end

                                            if Settings.Visuals.OnHit.Enabled then
                                                local Player = Script.Functions.GetClosestPlayerDamage(EndPos, 20)
                                                if Player then
                                                    if Settings.Visuals.OnHit.Effect.Enabled then
                                                        Script.Functions.Effect(Player.Character.HumanoidRootPart)
                                                    end

                                                    if Settings.Visuals.OnHit.Sound.Enabled then
                                                        local Sound = string.format("hitsounds/%s", Settings.Visuals.OnHit.Sound.Value)
                                                        Script.Functions.PlaySound(getcustomasset(Sound), Settings.Visuals.OnHit.Sound.Volume)
                                                    end

                                                    if Settings.Visuals.OnHit.Chams.Enabled then
                                                        Script.Functions.Hitcham(Player, Settings.Visuals.OnHit.Chams.Color)
                                                    end
                                                end
                                            end
                                            ChildAdded:Disconnect()
                                        end
                                    else
                                        ChildAdded:Disconnect()
                                    end
                                end)
                            end
                            Script.Locals.Gun.PreviousAmmo = NewAmmo
                        end)
                    end
                end
            end

            Script.Functions.Air = function()
                if Settings.Combat.Enabled and Script.Locals.IsTargetting and Script.Locals.Target and Settings.Combat.Air.Enabled then
                    local Humanoid = Script.Locals.Target.Character.Humanoid

                    if Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                        Script.Locals.JumpOffset = Settings.Combat.Air.JumpOffset.Offset
                    else
                        Script.Locals.JumpOffset = 0
                    end
                end
            end

            Script.Functions.UpdateHealth = function()
                if Settings.Visuals.OnHit.Enabled then
                    for _, Player in pairs(Players:GetPlayers()) do
                        if Player.Character and Player.Character.Humanoid then
                            Script.Locals.PlayerHealth[Player.Name] = Player.Character.Humanoid.Health
                        end
                    end
                end
            end

            Script.Functions.UpdateAtmosphere = function()
                Lighting.FogColor = Settings.Visuals.World.Enabled and Settings.Visuals.World.Fog.Enabled and Settings.Visuals.World.Fog.Color or Script.Locals.World.FogColor
                Lighting.FogStart = Settings.Visuals.World.Enabled and Settings.Visuals.World.Fog.Enabled and Settings.Visuals.World.Fog.Start or Script.Locals.World.FogStart
                Lighting.FogEnd = Settings.Visuals.World.Enabled and Settings.Visuals.World.Fog.Enabled and Settings.Visuals.World.Fog.End or Script.Locals.World.FogEnd
                Lighting.Ambient = Settings.Visuals.World.Enabled and Settings.Visuals.World.Ambient.Enabled and Settings.Visuals.World.Ambient.Color or Script.Locals.World.Ambient
                Lighting.Brightness = Settings.Visuals.World.Enabled and Settings.Visuals.World.Brightness.Enabled and Settings.Visuals.World.Brightness.Value or Script.Locals.World.Brightness
                Lighting.ClockTime = Settings.Visuals.World.Enabled and Settings.Visuals.World.ClockTime.Enabled and Settings.Visuals.World.ClockTime.Value or Script.Locals.World.ClockTime
                Lighting.ExposureCompensation = Settings.Visuals.World.Enabled and Settings.Visuals.World.WorldExposure.Enabled and Settings.Visuals.World.WorldExposure.Value or Script.Locals.World.ExposureCompensation
            end

            Script.Functions.VelocitySpoof = function()
                local ShowVisualizerDot = Settings.AntiAim.VelocitySpoofer.Enabled and Settings.AntiAim.VelocitySpoofer.Visualize.Enabled

                Script.Utility.Drawings["VelocityDot"].Visible = ShowVisualizerDot


                if Settings.AntiAim.VelocitySpoofer.Enabled then
                    --// Variables
                    local Type = Settings.AntiAim.VelocitySpoofer.Type
                    local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
                    local Velocity = HumanoidRootPart.Velocity

                    --// Main
                    if Type == "Underground" then
                        HumanoidRootPart.Velocity = HumanoidRootPart.Velocity + Vector3.new(0, -Settings.AntiAim.VelocitySpoofer.Yaw, 0)
                    elseif Type == "Sky" then
                        HumanoidRootPart.Velocity = HumanoidRootPart.Velocity + Vector3.new(0, Settings.AntiAim.VelocitySpoofer.Yaw, 0)
                    elseif Type == "Multiplier" then
                        HumanoidRootPart.Velocity = HumanoidRootPart.Velocity + Vector3.new(Settings.AntiAim.VelocitySpoofer.Yaw, Settings.AntiAim.VelocitySpoofer.Pitch, Settings.AntiAim.VelocitySpoofer.Roll)
                    elseif Type == "Custom" then
                        HumanoidRootPart.Velocity = Vector3.new(Settings.AntiAim.VelocitySpoofer.Yaw, Settings.AntiAim.VelocitySpoofer.Pitch, Settings.AntiAim.VelocitySpoofer.Roll)
                    elseif Type == "Prediction Breaker" then
                        HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                    end

                    if ShowVisualizerDot then
                        local ScreenPosition = Script.Functions.WorldToScreen(LocalPlayer.Character.HumanoidRootPart.Position + LocalPlayer.Character.HumanoidRootPart.Velocity * Settings.AntiAim.VelocitySpoofer.Visualize.Prediction)

                        Script.Utility.Drawings["VelocityDot"].Position = ScreenPosition.Position
                        Script.Utility.Drawings["VelocityDot"].Color = Settings.AntiAim.VelocitySpoofer.Visualize.Color
                    end

                    RunService.RenderStepped:Wait()
                    HumanoidRootPart.Velocity = Velocity
                end
            end

            Script.Functions.CSync = function()
                Script.Utility.Drawings["CFrameVisualize"].Parent = Settings.AntiAim.CSync.Visualize.Enabled and Settings.AntiAim.CSync.Enabled and Script.AzureIgnoreFolder or nil

                if Settings.AntiAim.CSync.Enabled then
                    local Type = Settings.AntiAim.CSync.Type
                    local FakeCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                    Script.Locals.SavedCFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                    if Type == "Custom" then
                        FakeCFrame = FakeCFrame * CFrame.new(Settings.AntiAim.CSync.Custom.X, Settings.AntiAim.CSync.Custom.Y, Settings.AntiAim.CSync.Custom.Z)
                    elseif Type == "Target Strafe" and Script.Locals.IsTargetting and Script.Locals.Target and Settings.Combat.Enabled then
                        local CurrentTime = tick()
                        FakeCFrame = CFrame.new(Script.Locals.Target.Character.HumanoidRootPart.Position) * CFrame.Angles(0, 2 * math.pi * CurrentTime * Settings.AntiAim.CSync.TargetStrafe.Speed % (2 * math.pi), 0) * CFrame.new(0, Settings.AntiAim.CSync.TargetStrafe.Height, Settings.AntiAim.CSync.TargetStrafe.Distance)
                    elseif Type == "Local Strafe" then
                        local CurrentTime = tick()
                        FakeCFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position) * CFrame.Angles(0, 2 * math.pi * CurrentTime * Settings.AntiAim.CSync.TargetStrafe.Speed % (2 * math.pi), 0) * CFrame.new(0, Settings.AntiAim.CSync.TargetStrafe.Height, Settings.AntiAim.CSync.TargetStrafe.Distance)
                    elseif Type == "Random" then
                        FakeCFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(math.random(-Settings.AntiAim.CSync.RandomDistance, Settings.AntiAim.CSync.RandomDistance), math.random(-Settings.AntiAim.CSync.RandomDistance, Settings.AntiAim.CSync.RandomDistance), math.random(-Settings.AntiAim.CSync.RandomDistance, Settings.AntiAim.CSync.RandomDistance))) * CFrame.Angles(math.rad(math.random(0, 360)), math.rad(math.random(0, 360)), math.rad(math.random(0, 360)))
                    elseif Type == "Random Target" and Script.Locals.IsTargetting and Script.Locals.Target and Settings.Combat.Enabled then
                        FakeCFrame = CFrame.new(Script.Locals.Target.Character.HumanoidRootPart.Position + Vector3.new(math.random(-Settings.AntiAim.CSync.RandomDistance, Settings.AntiAim.CSync.RandomDistance), math.random(-Settings.AntiAim.CSync.RandomDistance, Settings.AntiAim.CSync.RandomDistance), math.random(-Settings.AntiAim.CSync.RandomDistance, Settings.AntiAim.CSync.RandomDistance))) * CFrame.Angles(math.rad(math.random(0, 360)), math.rad(math.random(0, 360)), math.rad(math.random(0, 360)))
                    end

                    Script.Utility.Drawings["CFrameVisualize"]:SetPrimaryPartCFrame(FakeCFrame)

                    for _, Part in pairs(Script.Utility.Drawings["CFrameVisualize"]:GetChildren()) do
                        Part.Color = Settings.AntiAim.CSync.Visualize.Color
                    end

                    LocalPlayer.Character.HumanoidRootPart.CFrame = FakeCFrame
                    RunService.RenderStepped:Wait()
                    LocalPlayer.Character.HumanoidRootPart.CFrame = Script.Locals.SavedCFrame
                end
            end

            Script.Functions.Network = function()
                if Settings.AntiAim.Network.Enabled then
                    if (tick() - Script.Locals.NetworkPreviousTick) >= ((Settings.AntiAim.Network.Amount / math.pi) / 10000) or (Settings.AntiAim.Network.WalkingCheck and LocalPlayer.Character.Humanoid.MoveDirection.Magnitude > 0) then
                        Script.Locals.NetworkShouldSleep = not Script.Locals.NetworkShouldSleep
                        Script.Locals.NetworkPreviousTick = tick()
                        sethiddenproperty(LocalPlayer.Character.HumanoidRootPart, "NetworkIsSleeping", Script.Locals.NetworkShouldSleep)
                    end
                end
            end

            Script.Functions.Speed = function()
                if Settings.Misc.Movement.Speed.Enabled then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame + LocalPlayer.Character.Humanoid.MoveDirection * Settings.Misc.Movement.Speed.Amount
                end
            end

            Script.Functions.VelocityDesync = function()
                if Settings.AntiAim.VelocityDesync.Enabled then
                    local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
                    local Velocity = HumanoidRootPart.Velocity
                    local Amount = Settings.AntiAim.VelocityDesync.Range * 1000
                    HumanoidRootPart.Velocity = Vector3.new(math.random(-Amount, Amount), math.random(-Amount, Amount), math.random(-Amount, Amount))
                    RunService.RenderStepped:Wait()
                    HumanoidRootPart.Velocity = Velocity
                end
            end

            Script.Functions.FFlagDesync = function()
                if Settings.AntiAim.FFlagDesync.Enabled then
                    for FFlag, _ in pairs(Settings.AntiAim.FFlagDesync.FFlags) do
                        local Value = Settings.AntiAim.FFlagDesync.Amount
                        setfflag(FFlag, tostring(Value))

                        RunService.RenderStepped:Wait()
                        if Settings.AntiAim.FFlagDesync.SetNew then
                            setfflag(FFlag, Settings.AntiAim.FFlagDesync.SetNewAmount)
                        end
                    end
                end
            end
			
			Script.Functions.AntiSTOMP = function()
			    if Settings.Misc.Exploits.AntiStomp then
                    if LocalPlayer.Character.Humanoid.Health < 15 then
                        for __, v in pairs(LocalPlayer.Character:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v:Destroy()
							end
						end
					end
				end
			end
			
			Script.Functions.AntiBAG = function()
			    if Settings.Misc.Exploits.AntiBag then
				    if LocalPlayer.Character:FindFirstChild("Christmas_Sock") then
                        LocalPlayer.Character["Christmas_Sock"]:Destroy()
                    end
				end
			end
			
			Script.Functions.AntiGRAB = function()
			    if Settings.Misc.Exploits.AntiGrab then
				    local grabbingConstraint = game.Players.LocalPlayer.Character:FindFirstChild("GRABBING_CONSTRAINT")
                    if grabbingConstraint then
                        game.Players.LocalPlayer.Character.Humanoid:ChangeState(15)
                        wait()
                        game.Players.LocalPlayer.Character.Humanoid:ChangeState(16)
                        wait()
                        game.Players.LocalPlayer.Character.Humanoid:ChangeState(0)
                    end
				end
			end
			
			Script.Functions.AutoSTOMP = function()
			    if Settings.Misc.Exploits.AutoStomp then
				    ReplicatedStorage.MainEvent:FireServer("Stomp")
				end
			end
			
			Script.Functions.AutoARMOR = function()
			    if Settings.Misc.Exploits.AutoArmor then
				    if LocalPlayer.Character.BodyEffects.Armor.Value < 20 then 
						local Pos = LocalPlayer.Character.HumanoidRootPart.CFrame
						LocalPlayer.Character.HumanoidRootPart.CFrame = Workspace.Ignored.Shop["[High-Medium Armor] - $2440"].Head.CFrame
						fireclickdetector(Workspace.Ignored.Shop["[High-Medium Armor] - $2440"].ClickDetector, 0)
						RunService.RenderStepped:Wait()
						LocalPlayer.Character.HumanoidRootPart.CFrame = Pos
					end
				end
			end
		
		    Script.Functions.AutoFIREARMOR = function()
			    if Settings.Misc.Exploits.AutoFireArmor then
				    if LocalPlayer.Character.BodyEffects.FireArmor.Value < 30 then 
						local Pos = LocalPlayer.Character.HumanoidRootPart.CFrame
						LocalPlayer.Character.HumanoidRootPart.CFrame = Workspace.Ignored.Shop["[Fire Armor] - $2493"].Head.CFrame
						fireclickdetector(Workspace.Ignored.Shop["[Fire Armor] - $2493"].ClickDetector, 0)
						RunService.RenderStepped:Wait()
						LocalPlayer.Character.HumanoidRootPart.CFrame = Pos
					end
				end
			end

            Script.Functions.AutoRELOAD = function()
                if Settings.Misc.Exploits.AutoReload then
                    if LocalPlayer.Character:FindFirstChildWhichIsA("Tool") ~= nil then
            if
                LocalPlayer.Character:FindFirstChildWhichIsA("Tool"):FindFirstChild(
                    "Ammo"
                )
             then
                if
                    LocalPlayer.Character:FindFirstChildWhichIsA("Tool"):FindFirstChild(
                        "Ammo"
                    ).Value <= 0
                 then
                    ReplicatedStorage.MainEvent:FireServer(
                        "Reload",
                        LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
                    )
                end
            end
        end
			    end
			end

            --// Invisible Desync

            Script.Functions.NoSlowdown = function()
                if Settings.Misc.Exploits.NoSlowDown then
                    if LocalPlayer.Character.BodyEffects.Reload.Value then
						LocalPlayer.Character.BodyEffects.Reload.Value = false
					end
                    local Slowdown = LocalPlayer.Character.BodyEffects.Movement:FindFirstChild('NoJumping') or LocalPlayer.Character.BodyEffects.Movement:FindFirstChild('NoWalkSpeed') or LocalPlayer.Character.BodyEffects.Movement:FindFirstChild('ReduceWalk')
                    if Slowdown then
                        Slowdown:Destroy()
                    end
                end
            end

            --// Horrid code
            Script.Functions.UpdateCrosshair = function()
                if Settings.Visuals.Crosshair.Enabled then
                    local MouseX, MouseY
                    local RotationAngle = Script.Locals.RotationAngle
                    local RealSize = Settings.Visuals.Crosshair.Size * 2

                    if not MouseX or not MouseY then
                        MouseX, MouseY = UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y
                    end

                    local Gap = Settings.Visuals.Crosshair.Gap
                    if Settings.Visuals.Crosshair.Rotation.Enabled then
                        Script.Locals.RotationAngle = Script.Locals.RotationAngle + Settings.Visuals.Crosshair.Rotation.Speed
                    else
                        Script.Locals.RotationAngle = 0
                    end

                    Script.Utility.Drawings["CrosshairLeft"].Visible = true
                    Script.Utility.Drawings["CrosshairLeft"].Color = Settings.Visuals.Crosshair.Color
                    Script.Utility.Drawings["CrosshairLeft"].Thickness = 1
                    Script.Utility.Drawings["CrosshairLeft"].Transparency = 1
                    Script.Utility.Drawings["CrosshairLeft"].From = Vector2.new(MouseX + Gap, MouseY)
                    Script.Utility.Drawings["CrosshairLeft"].To = Vector2.new(MouseX + RealSize, MouseY)
                    if Settings.Visuals.Crosshair.Rotation.Enabled then
                        Script.Utility.Drawings["CrosshairLeft"].From = Script.Functions.Rotate(Script.Utility.Drawings["CrosshairLeft"].From, Vector2.new(MouseX, MouseY), math.rad(RotationAngle))
                        Script.Utility.Drawings["CrosshairLeft"].To = Script.Functions.Rotate(Script.Utility.Drawings["CrosshairLeft"].To, Vector2.new(MouseX, MouseY), math.rad(RotationAngle))
                    end

                    Script.Utility.Drawings["CrosshairRight"].Visible = true
                    Script.Utility.Drawings["CrosshairRight"].Color = Settings.Visuals.Crosshair.Color
                    Script.Utility.Drawings["CrosshairRight"].Thickness = 1
                    Script.Utility.Drawings["CrosshairRight"].Transparency = 1
                    Script.Utility.Drawings["CrosshairRight"].From = Vector2.new(MouseX - Gap, MouseY)
                    Script.Utility.Drawings["CrosshairRight"].To = Vector2.new(MouseX - RealSize, MouseY)
                    if Settings.Visuals.Crosshair.Rotation.Enabled then
                        Script.Utility.Drawings["CrosshairRight"].From = Script.Functions.Rotate(Script.Utility.Drawings["CrosshairRight"].From, Vector2.new(MouseX, MouseY), math.rad(RotationAngle))
                        Script.Utility.Drawings["CrosshairRight"].To = Script.Functions.Rotate(Script.Utility.Drawings["CrosshairRight"].To, Vector2.new(MouseX, MouseY), math.rad(RotationAngle))
                    end

                    Script.Utility.Drawings["CrosshairTop"].Visible = true
                    Script.Utility.Drawings["CrosshairTop"].Color = Settings.Visuals.Crosshair.Color
                    Script.Utility.Drawings["CrosshairTop"].Thickness = 1
                    Script.Utility.Drawings["CrosshairTop"].Transparency = 1
                    Script.Utility.Drawings["CrosshairTop"].From = Vector2.new(MouseX, MouseY + Gap)
                    Script.Utility.Drawings["CrosshairTop"].To = Vector2.new(MouseX, MouseY + RealSize)
                    if Settings.Visuals.Crosshair.Rotation.Enabled then
                        Script.Utility.Drawings["CrosshairTop"].From = Script.Functions.Rotate(Script.Utility.Drawings["CrosshairTop"].From, Vector2.new(MouseX, MouseY), math.rad(RotationAngle))
                        Script.Utility.Drawings["CrosshairTop"].To = Script.Functions.Rotate(Script.Utility.Drawings["CrosshairTop"].To, Vector2.new(MouseX, MouseY), math.rad(RotationAngle))
                    end

                    Script.Utility.Drawings["CrosshairBottom"].Visible = true
                    Script.Utility.Drawings["CrosshairBottom"].Color = Settings.Visuals.Crosshair.Color
                    Script.Utility.Drawings["CrosshairBottom"].Thickness = 1
                    Script.Utility.Drawings["CrosshairBottom"].Transparency = 1
                    Script.Utility.Drawings["CrosshairBottom"].From = Vector2.new(MouseX, MouseY - Gap)
                    Script.Utility.Drawings["CrosshairBottom"].To = Vector2.new(MouseX, MouseY - RealSize)
                    if Settings.Visuals.Crosshair.Rotation.Enabled then
                        Script.Utility.Drawings["CrosshairBottom"].From = Script.Functions.Rotate(Script.Utility.Drawings["CrosshairBottom"].From, Vector2.new(MouseX, MouseY), math.rad(RotationAngle))
                        Script.Utility.Drawings["CrosshairBottom"].To = Script.Functions.Rotate(Script.Utility.Drawings["CrosshairBottom"].To, Vector2.new(MouseX, MouseY), math.rad(RotationAngle))
                    end
                else
                    Script.Utility.Drawings["CrosshairBottom"].Visible = false
                    Script.Utility.Drawings["CrosshairTop"].Visible = false
                    Script.Utility.Drawings["CrosshairRight"].Visible = false
                    Script.Utility.Drawings["CrosshairLeft"].Visible = false
                end
            end

            Script.Functions.UpdateLookAt = function()
                if Settings.Combat.Enabled and Settings.Combat.LookAt and Script.Locals.IsTargetting and Script.Locals.Target then
                    LocalPlayer.Character.Humanoid.AutoRotate = false
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(LocalPlayer.Character.HumanoidRootPart.CFrame.Position, Vector3.new(Script.Locals.Target.Character.HumanoidRootPart.CFrame.X, LocalPlayer.Character.HumanoidRootPart.CFrame.Position.Y, Script.Locals.Target.Character.HumanoidRootPart.CFrame.Z))
                else
                    LocalPlayer.Character.Humanoid.AutoRotate = true
                end
            end

            Script.Functions.UpdateSpectate = function()
                if Settings.Combat.Enabled and Settings.Combat.Spectate and Script.Locals.IsTargetting and Script.Locals.Target then
                    Camera.CameraSubject = Script.Locals.Target.Character.Humanoid
                else
                    Camera.CameraSubject = LocalPlayer.Character.Humanoid
                end
            end
        end

        --// Esp Function
        do

        end
    end

    --// Drawing objects
    do
        Script.Utility.Drawings["FieldOfViewVisualizer"] = Script.Functions.CreateDrawing("Circle", {
            Visible = Settings.Combat.Fov.Visualize.Enabled,
            Color = Settings.Combat.Fov.Visualize.Color,
            Radius = Settings.Combat.Fov.Radius
        })

        Script.Utility.Drawings["TargetTracer"] = Script.Functions.CreateDrawing("Line",{
            Visible = false,
            Color = Settings.Combat.Visuals.Tracer.Color,
            Thickness = Settings.Combat.Visuals.Tracer.Thickness
        })

        Script.Utility.Drawings["TargetDot"] = Script.Functions.CreateDrawing("Circle", {
            Visible = false,
            Color = Settings.Combat.Visuals.Dot.Color,
            Radius = Settings.Combat.Visuals.Dot.Size
        })

        Script.Utility.Drawings["VelocityDot"] = Script.Functions.CreateDrawing("Circle", {
            Visible = false,
            Color = Settings.AntiAim.VelocitySpoofer.Visualize.Color,
            Radius = 6,
            Filled = true
        })

        Script.Utility.Drawings["TargetChams"] = Script.Functions.Create("Highlight", {
            Parent = nil,
            FillColor = Settings.Combat.Visuals.Chams.Fill.Color,
            FillTransparency = Settings.Combat.Visuals.Chams.Fill.Transparency,
            OutlineColor = Settings.Combat.Visuals.Chams.Fill.Color,
            OutlineTransparency = Settings.Combat.Visuals.Chams.Outline.Transparency
        })

        Script.Utility.Drawings["CrosshairTop"] = Script.Functions.CreateDrawing("Line", {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 1,
            Visible = false,
            ZIndex = 10000
        })

        Script.Utility.Drawings["CrosshairBottom"] = Script.Functions.CreateDrawing("Line", {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 1,
            Visible = false,
            ZIndex = 10000
        })

        Script.Utility.Drawings["CrosshairLeft"] = Script.Functions.CreateDrawing("Line", {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 1,
            Visible = false,
            ZIndex = 10000
        })

        Script.Utility.Drawings["CrosshairRight"] = Script.Functions.CreateDrawing("Line", {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 1,
            Visible = false,
            ZIndex = 10000
        })


        Script.Utility.Drawings["CFrameVisualize"] = game:GetObjects("rbxassetid://9474737816")[1]; Script.Utility.Drawings["CFrameVisualize"].Head.Face:Destroy(); for _, v in pairs(Script.Utility.Drawings["CFrameVisualize"]:GetChildren()) do v.Transparency = v.Name == "HumanoidRootPart" and 1 or 0.70; v.Material = "Neon"; v.Color = Settings.AntiAim.CSync.Visualize.Color; v.CanCollide = false; v.Anchored = false end
    end


    --// Hitsounds
    do
        --// Hitsounds
        Hitsounds = {
            ["bell.wav"] = "https://github.com/nyulachan/nyula/blob/main/Sounds/bell.wav?raw=true",
            ["bepis.wav"] = "https://github.com/nyulachan/nyula/blob/main/Sounds/bepis.wav?raw=true",
            ["bubble.wav"] = "https://github.com/nyulachan/nyula/blob/main/Sounds/bubble.wav?raw=true",
            ["cock.wav"] = "https://github.com/nyulachan/nyula/blob/main/Sounds/cock.wav?raw=true",
            ["cod.wav"] = "https://github.com/nyulachan/nyula/blob/main/Sounds/cod.wav?raw=true",
            ["fatality.wav"] = "https://github.com/nyulachan/nyula/blob/main/Sounds/fatality.wav?raw=true",
            ["phonk.wav"] = "https://github.com/nyulachan/nyula/blob/main/Sounds/phonk.wav?raw=true",
            ["sparkle.wav"] = "https://github.com/nyulachan/nyula/blob/main/Sounds/sparkle.wav?raw=true",
        }

        if not isfolder("hitsounds") then
            makefolder("hitsounds")
        end

        for Name, Url in pairs(Hitsounds) do
            local Path = "hitsounds" .. "/" .. Name
            if not isfile(Path) then
                writefile(Path, game:HttpGet(Url))
            end
        end
    end
    --// Hit Effects
    do
        --// Nova
        do
            local Part = Instance.new("Part")
            Part.Parent = ReplicatedStorage

            local Attachment = Instance.new("Attachment")
            Attachment.Name = "Attachment"
            Attachment.Parent = Part

            Script.Locals.HitEffect = Attachment

            local ParticleEmitter = Instance.new("ParticleEmitter")
            ParticleEmitter.Name = "ParticleEmitter"
            ParticleEmitter.Acceleration = Vector3.new(0, 0, 1)
            ParticleEmitter.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(0.495, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
            })
            ParticleEmitter.Lifetime = NumberRange.new(0.5, 0.5)
            ParticleEmitter.LightEmission = 1
            ParticleEmitter.LockedToPart = true
            ParticleEmitter.Rate = 1
            ParticleEmitter.Rotation = NumberRange.new(0, 360)
            ParticleEmitter.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 10),
                NumberSequenceKeypoint.new(1, 1),
            })
            ParticleEmitter.Speed = NumberRange.new(0, 0)
            ParticleEmitter.Texture = "rbxassetid://1084991215"
            ParticleEmitter.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(0.534, 0.25),
                NumberSequenceKeypoint.new(1, 0.5),
                NumberSequenceKeypoint.new(1, 0),
            })
            ParticleEmitter.ZOffset = 1
            ParticleEmitter.Parent = Attachment
            local ParticleEmitter1 = Instance.new("ParticleEmitter")
            ParticleEmitter1.Name = "ParticleEmitter"
            ParticleEmitter1.Acceleration = Vector3.new(0, 1, -0.001)
            ParticleEmitter1.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(0.495, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
            })
            ParticleEmitter1.Lifetime = NumberRange.new(0.5, 0.5)
            ParticleEmitter1.LightEmission = 1
            ParticleEmitter1.LockedToPart = true
            ParticleEmitter1.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
            ParticleEmitter1.Rate = 1
            ParticleEmitter1.Rotation = NumberRange.new(0, 360)
            ParticleEmitter1.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 10),
                NumberSequenceKeypoint.new(1, 1),
            })
            ParticleEmitter1.Speed = NumberRange.new(0, 0)
            ParticleEmitter1.Texture = "rbxassetid://1084991215"
            ParticleEmitter1.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0, 0.1),
                NumberSequenceKeypoint.new(0.534, 0.25),
                NumberSequenceKeypoint.new(1, 0.5),
                NumberSequenceKeypoint.new(1, 0),
            })
            ParticleEmitter1.ZOffset = 1
            ParticleEmitter1.Parent = Attachment
        end
    end

    --// Connections
    do
        --// Combat Connections
        do
            Script.Functions.Connection(RunService.Heartbeat, function()
                Script.Functions.MouseAim()

                Script.Functions.Resolve()

                Script.Functions.Air()

                Script.Functions.UpdateLookAt()
            end)

            Script.Functions.Connection(RunService.RenderStepped, function()
                Script.Functions.UpdateFieldOfView()

                Script.Functions.UpdateTargetVisuals()

                Script.Functions.AutoSelect()

                Script.Functions.UpdateSpectate()
            end)
        end

        --// Visual Connections
        do
            Script.Functions.Connection(RunService.RenderStepped, function()
                Script.Functions.GunEvents()

                Script.Functions.UpdateHealth()

                Script.Functions.UpdateAtmosphere()

                Script.Functions.UpdateCrosshair()
            end)
        end

        --// Anti Aim Connection
        do
            Script.Functions.Connection(RunService.Heartbeat, function()
                Script.Functions.VelocitySpoof()

                Script.Functions.CSync()

                Script.Functions.Network()

                Script.Functions.VelocityDesync()

                Script.Functions.FFlagDesync()
            end)
        end

        --// Movement Connections
        do
            Script.Functions.Connection(RunService.Heartbeat, function()
                Script.Functions.Speed()

                Script.Functions.NoSlowdown()
            end)
        end
		
		--// Exploits Connections
		do 
		    Script.Functions.Connection(RunService.RenderStepped, function()
			    Script.Functions.AutoRELOAD()
				
				Script.Functions.AutoARMOR()
				
				Script.Functions.AutoFIREARMOR()
				
				Script.Functions.AntiSTOMP()
				
				Script.Functions.AntiBAG()
				
				Script.Functions.AntiGRAB()
				
				Script.Functions.AutoSTOMP()
			end)
		end
    end

    --// Hooks
    do
        local __namecall
        local __newindex
        local __index

        __index = hookmetamethod(game, "__index", LPH_NO_VIRTUALIZE(function(Self, Index)
            if not checkcaller() and Settings.AntiAim.CSync.Enabled and Script.Locals.SavedCFrame and Index == "CFrame" and Self == LocalPlayer.Character.HumanoidRootPart then
                return Script.Locals.SavedCFrame
            end
            return __index(Self, Index)
        end))

        __namecall = hookmetamethod(game, "__namecall", LPH_NO_VIRTUALIZE(function(Self, ...)
            local Arguments = {...}
            local Method = tostring(getnamecallmethod())

            if not checkcaller() and Method == "FireServer" then
                for _, Argument in pairs(Arguments) do
                    if typeof(Argument) == "Vector3" then
                        Script.Locals.AntiAimViewer.MouseRemote = Self
                        Script.Locals.AntiAimViewer.MouseRemoteFound = true
                        Script.Locals.AntiAimViewer.MouseRemoteArgs = Arguments
                        Script.Locals.AntiAimViewer.MouseRemotePositionIndex = _

                        if Settings.Combat.Enabled and Settings.Combat.Silent and not Settings.Combat.AntiAimViewer and Script.Locals.IsTargetting and Script.Locals.Target then
                            Arguments[_] =  Script.Functions.GetPredictedPosition()
                        end

                        return __namecall(Self, unpack(Arguments))
                    end
                end
            end
            return __namecall(Self, ...)
        end))

        __newindex = hookmetamethod(game, "__newindex", LPH_NO_VIRTUALIZE(function(Self, Property, Value)
		    local Framework = LocalPlayer.PlayerGui:FindFirstChild("Framework")
            local CallingScript = getcallingscript()

            --// Atmosphere caching
            if not checkcaller() and Self == Lighting and Script.Locals.World[Property] ~= Value then
                Script.Locals.World[Property] = Value
            end

            --// No Recoil
            if Framework and CallingScript == Framework and Self == Camera and Property == "CFrame" and Settings.Misc.Exploits.Enabled and Settings.Misc.Exploits.NoRecoil then
                return
            end

            --// No Jump Cooldown
            if Framework and CallingScript == Framework and Self == LocalPlayer.Character.Humanoid and Property == "JumpPower" and Settings.Misc.Exploits.Enabled and Settings.Misc.Exploits.NoJumpCooldown then
                return
            end
			
            return __newindex(Self, Property, Value)
        end))
    end

    do
        --// UI
        local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/RandomUserRay/UnknownScript/main/AzureUiLib.lua"))()
        local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()
        local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/caIIed/Linoria-Rewrite/main/Theme%20Manager.lua"))()

        --// Main Window
        local Window = Library:CreateWindow({
            Title = "AzureV4Modded.lua",
            Center = true,
            AutoShow = true,
            TabPadding = 8,
            MenuFadeTime = 0.2
        })

        local Tabs = {
            Combat = Window:AddTab("Combat"),
            Visuals = Window:AddTab("Visuals"),
            AntiAim = Window:AddTab("Anti Aim"),
            Misc = Window:AddTab("Misc"),
			TeleportMap = Window:AddTab("Teleport"),
            Settings = Window:AddTab("Settings")
        }

        local Sections = {
            Combat = {
                Main = Tabs.Combat:AddLeftGroupbox("Main"),
                Checks = Tabs.Combat:AddRightGroupbox("Checks"),
                AutoSelect = Tabs.Combat:AddRightGroupbox("Auto Select"),
                Visuals = Tabs.Combat:AddRightGroupbox("Visuals"),
                Smoothing = Tabs.Combat:AddLeftGroupbox("Smoothing"),
                Resolver = Tabs.Combat:AddLeftGroupbox("Resolver"),
                FieldOfView = Tabs.Combat:AddLeftGroupbox("Field Of View"),
                Air = Tabs.Combat:AddRightGroupbox("Air")
            },
            Visuals = {
                --// Esp = Tabs.Visuals:AddLeftGroupbox("Esp"),
                Atmosphere = Tabs.Visuals:AddLeftGroupbox("Atmosphere"),
                Crosshair = Tabs.Visuals:AddLeftGroupbox("Crosshair"),
                BulletTracers = Tabs.Visuals:AddRightGroupbox("Bullet Tracers"),
                BulletImpacts = Tabs.Visuals:AddRightGroupbox("Bullet Impacts"),
                OnHit = Tabs.Visuals:AddRightGroupbox("On Hit")
            },
            AntiAim = {
                CSync = Tabs.AntiAim:AddLeftGroupbox("C-Sync"),
                Network = Tabs.AntiAim:AddLeftGroupbox("Network"),
                VelocitySpoofer = Tabs.AntiAim:AddRightGroupbox("Velocity Spoofer"),
                VelocityDesync = Tabs.AntiAim:AddRightGroupbox("Velocity Desync"),
                FFlag = Tabs.AntiAim:AddRightGroupbox("FFlag Desync"),
            },
            Misc = {
                Speed = Tabs.Misc:AddLeftGroupbox("CFrame Speed"),
                Exploits = Tabs.Misc:AddRightGroupbox("Exploits"),
				Experimental = Tabs.Misc:AddLeftGroupbox("Experimental"),
				Animations = Tabs.Misc:AddRightGroupbox("Animations")
            },
			TeleportMap = {
			    Teleport = Tabs.TeleportMap:AddLeftGroupbox("Map Teleport")
			}
        }

        --// Combat Tab
        do
            --// Main
            do
                Sections.Combat.Main:AddToggle("CombatMainEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil
                }):AddKeyPicker("CombatMainToggle", {
                    Default = "Q",
                    SyncToggleState = false,
                    Mode = "Toggle",
                    Text = "Targetting",
                    NoUI = false,
                })

                Toggles.CombatMainEnabled:OnChanged(function()
                    Settings.Combat.Enabled = Toggles.CombatMainEnabled.Value
                end)

                Options.CombatMainToggle:OnClick(function()
                    if Settings.Combat.Enabled then
                        Script.Locals.IsTargetting = not Script.Locals.IsTargetting

                        local NewTarget = Script.Functions.GetClosestPlayer()
                        Script.Locals.Target = Script.Locals.IsTargetting and NewTarget.Character and NewTarget or nil

                        if Settings.Combat.Alerts then
                            Library:Notify(string.format("Targetting: %s", Script.Locals.Target.Character.Humanoid.DisplayName))
                        end
                    end
                end)

                Sections.Combat.Main:AddToggle("CombatSilentEnabled", {
                    Text = "Silent",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatSilentEnabled:OnChanged(function()
                    Settings.Combat.Silent = Toggles.CombatSilentEnabled.Value
                end)

                Sections.Combat.Main:AddToggle("CombatMouseEnabled", {
                    Text = "Mouse",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatMouseEnabled:OnChanged(function()
                    Settings.Combat.Mouse = Toggles.CombatMouseEnabled.Value
                end)

                Sections.Combat.Main:AddToggle("CombatAlertsEnabled", {
                    Text = "Alerts",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatAlertsEnabled:OnChanged(function()
                    Settings.Combat.Alerts = Toggles.CombatAlertsEnabled.Value
                end)

                Sections.Combat.Main:AddToggle("CombatLookAtEnabled", {
                    Text = "Look At",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatLookAtEnabled:OnChanged(function()
                    Settings.Combat.LookAt = Toggles.CombatLookAtEnabled.Value
                end)

                Sections.Combat.Main:AddToggle("CombatSpectatEnabled", {
                    Text = "Spectate",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatSpectatEnabled:OnChanged(function()
                    Settings.Combat.Spectate = Toggles.CombatSpectatEnabled.Value
                end)

                Sections.Combat.Main:AddToggle("CombatAntiAimViewerEnabled", {
                    Text = "Anti AimViewer",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatAntiAimViewerEnabled:OnChanged(function()
                    Settings.Combat.AntiAimViewer = Toggles.CombatAntiAimViewerEnabled.Value
                end)

                Sections.Combat.Main:AddDropdown("CombatHitPartDropdown", {
                    Values = {"Head","HumanoidRootPart","LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftUpperArm","RightUpperArm","LeftFoot","LeftLowerLeg","UpperTorso","LeftUpperLeg","RightFoot","RightLowerLeg","LowerTorso","RightUpperLeg"},
                    Default = 2,
                    Multi = false,

                    Text = "Aim Part",
                    Tooltip = nil
                })

                Options.CombatHitPartDropdown:OnChanged(function()
                    Settings.Combat.AimPart = Options.CombatHitPartDropdown.Value
                end)

                Sections.Combat.Main:AddInput("CombatVerticalPrediction", {
                    Default = nil,
                    Numeric = false,
                    Finished = false,

                    Text = "Vertical Prediction",
                    Tooltip = nil,

                    Placeholder = "Vertical Prediction Amount"
                })

                Options.CombatVerticalPrediction:OnChanged(function()
                    Settings.Combat.Prediction.Vertical = tonumber(Options.CombatVerticalPrediction.Value)
                end)

                Sections.Combat.Main:AddInput("CombatHorizontalPrediction", {
                    Default = nil,
                    Numeric = false,
                    Finished = false,

                    Text = "Horizontal Prediction",
                    Tooltip = nil,

                    Placeholder = "Horizontal Prediction Amount"
                })


                Options.CombatHorizontalPrediction:OnChanged(function()
                    Settings.Combat.Prediction.Horizontal = tonumber(Options.CombatHorizontalPrediction.Value)
                end)
            end

            --// Checks
            do
                Sections.Combat.Checks:AddToggle("CombatChecksEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatChecksEnabled:OnChanged(function()
                    Settings.Combat.Checks.Enabled = Toggles.CombatChecksEnabled.Value
                end)

                Sections.Combat.Checks:AddToggle("CombatChecksKnockedEnabled", {
                    Text = "Knocked",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatChecksKnockedEnabled:OnChanged(function()
                    Settings.Combat.Checks.Knocked = Toggles.CombatChecksKnockedEnabled.Value
                end)

                Sections.Combat.Checks:AddToggle("CombatChecksGrabbedEnabled", {
                    Text = "Grabbed",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatChecksGrabbedEnabled:OnChanged(function()
                    Settings.Combat.Checks.Grabbed = Toggles.CombatChecksGrabbedEnabled.Value
                end)

                Sections.Combat.Checks:AddToggle("CombatChecksCrewEnabled", {
                    Text = "Crew",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatChecksCrewEnabled:OnChanged(function()
                    Settings.Combat.Checks.Crew = Toggles.CombatChecksCrewEnabled.Value
                end)

                Sections.Combat.Checks:AddToggle("CombatChecksVehicleEnabled", {
                    Text = "Vehicle",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatChecksVehicleEnabled:OnChanged(function()
                    Settings.Combat.Checks.Vehicle = Toggles.CombatChecksVehicleEnabled.Value
                end)

                Sections.Combat.Checks:AddToggle("CombatChecksWallEnabled", {
                    Text = "Wall",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatChecksWallEnabled:OnChanged(function()
                    Settings.Combat.Checks.Wall = Toggles.CombatChecksWallEnabled.Value
                end)
            end

            --// Auto Select
            do
                Sections.Combat.AutoSelect:AddToggle("CombatAutoSelectEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatAutoSelectEnabled:OnChanged(function()
                    Settings.Combat.AutoSelect.Enabled = Toggles.CombatAutoSelectEnabled.Value
                end)

                Sections.Combat.AutoSelect:AddToggle("CombatAutoSelectCooldownEnabled", {
                    Text = "Cooldown",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatAutoSelectCooldownEnabled:OnChanged(function()
                    Settings.Combat.AutoSelect.Cooldown.Enabled = Toggles.CombatAutoSelectCooldownEnabled.Value
                end)

                Sections.Combat.AutoSelect:AddSlider("CombatAutoSelectCooldownAmount", {
                    Text = "Cooldown Amount (MS)",
                    Default = 0.1,
                    Min = 0,
                    Max = 1,
                    Rounding = 3,
                    Compact = false
                })

                Options.CombatAutoSelectCooldownAmount:OnChanged(function()
                    Settings.Combat.AutoSelect.Cooldown.Amount = Options.CombatAutoSelectCooldownAmount.Value
                end)
            end

            --// Smoothing
            do
                Sections.Combat.Smoothing:AddSlider("CombatSmoothingVertical", {
                    Text = "Vertical Smoothing",
                    Default = 10,
                    Min = 1,
                    Max = 50,
                    Rounding = 2,
                    Compact = false
                })

                Options.CombatSmoothingVertical:OnChanged(function()
                    Settings.Combat.Smoothing.Vertical = Options.CombatSmoothingVertical.Value
                end)

                Sections.Combat.Smoothing:AddSlider("CombatSmoothingHorizontal", {
                    Text = "Horizontal Smoothing",
                    Default = 10,
                    Min = 1,
                    Max = 50,
                    Rounding = 2,
                    Compact = false
                })

                Options.CombatSmoothingHorizontal:OnChanged(function()
                    Settings.Combat.Smoothing.Horizontal = Options.CombatSmoothingHorizontal.Value
                end)
            end

            --// Resolver
            do
                Sections.Combat.Resolver:AddToggle("CombatResolverEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatResolverEnabled:OnChanged(function()
                    Settings.Combat.Resolver.Enabled = Toggles.CombatResolverEnabled.Value
                end)

                Sections.Combat.Resolver:AddSlider("CombatResolverRefreshRate", {
                    Text = "Refresh Rate",
                    Default = 200,
                    Min = 1,
                    Max = 200,
                    Rounding = 1,
                    Compact = false
                })

                Options.CombatResolverRefreshRate:OnChanged(function()
                    Settings.Combat.Resolver.RefreshRate = Options.CombatResolverRefreshRate.Value
                end)
            end

            --// Field Of View
            do
                Sections.Combat.FieldOfView:AddToggle("CombatFovEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatFovEnabled:OnChanged(function()
                    Settings.Combat.Fov.Enabled = Toggles.CombatFovEnabled.Value
                end)

                Sections.Combat.FieldOfView:AddToggle("CombatFovVisualizeEnabled", {
                    Text = "Visualize",
                    Default = false,
                    Tooltip = nil
                }):AddColorPicker("CombatFovVisualizeColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Fov Visualize Color",
                    Transparency = nil
                })

                Toggles.CombatFovVisualizeEnabled:OnChanged(function()
                    Settings.Combat.Fov.Visualize.Enabled = Toggles.CombatFovVisualizeEnabled.Value
                end)

                Options.CombatFovVisualizeColor:OnChanged(function()
                    Settings.Combat.Fov.Visualize.Color = Options.CombatFovVisualizeColor.Value
                end)

                Sections.Combat.FieldOfView:AddSlider("CombatFieldOfViewRadius", {
                    Text = "Radius",
                    Default = 80,
                    Min = 1,
                    Max = 800,
                    Rounding = 2,
                    Compact = false
                })

                Options.CombatFieldOfViewRadius:OnChanged(function()
                    Settings.Combat.Fov.Radius = Options.CombatFieldOfViewRadius.Value
                end)
            end

            --// Visuals
            do
                Sections.Combat.Visuals:AddToggle("CombatVisualsEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatVisualsEnabled:OnChanged(function()
                    Settings.Combat.Visuals.Enabled = Toggles.CombatVisualsEnabled.Value
                end)

                Sections.Combat.Visuals:AddToggle("CombatVisualsTracerEnabled", {
                    Text = "Tracer",
                    Default = false,
                    Tooltip = nil
                }):AddColorPicker("CombatVisualsTracerColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Tracer Color",
                    Transparency = nil
                })

                Toggles.CombatVisualsTracerEnabled:OnChanged(function()
                    Settings.Combat.Visuals.Tracer.Enabled = Toggles.CombatVisualsTracerEnabled.Value
                end)

                Options.CombatVisualsTracerColor:OnChanged(function()
                    Settings.Combat.Visuals.Tracer.Color = Options.CombatVisualsTracerColor.Value
                end)

                Sections.Combat.Visuals:AddSlider("CombatVisualsTracerThickness", {
                    Text = "Thickness",
                    Default = 2,
                    Min = 1,
                    Max = 10,
                    Rounding = 2,
                    Compact = false
                })

                Options.CombatVisualsTracerThickness:OnChanged(function()
                    Settings.Combat.Visuals.Tracer.Thickness = Options.CombatVisualsTracerThickness.Value
                end)

                Sections.Combat.Visuals:AddToggle("CombatVisualsDotEnabled", {
                    Text = "Dot",
                    Default = false,
                    Tooltip = nil
                }):AddColorPicker("CombatVisualsDotColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Dot Color",
                    Transparency = nil
                })

                Toggles.CombatVisualsDotEnabled:OnChanged(function()
                    Settings.Combat.Visuals.Dot.Enabled = Toggles.CombatVisualsDotEnabled.Value
                end)

                Options.CombatVisualsDotColor:OnChanged(function()
                    Settings.Combat.Visuals.Dot.Color = Options.CombatVisualsDotColor.Value
                end)

                Sections.Combat.Visuals:AddToggle("CombatVisualsDotFilled", {
                    Text = "Dot Filled",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatVisualsDotFilled:OnChanged(function()
                    Settings.Combat.Visuals.Dot.Filled = Toggles.CombatVisualsDotFilled.Value
                end)

                Sections.Combat.Visuals:AddSlider("CombatVisualsDotSize", {
                    Text = "Size",
                    Default = 6,
                    Min = 1,
                    Max = 20,
                    Rounding = 2,
                    Compact = false
                })

                Options.CombatVisualsDotSize:OnChanged(function()
                    Settings.Combat.Visuals.Dot.Size = Options.CombatVisualsDotSize.Value
                end)

                local TargetChamsToggle = Sections.Combat.Visuals:AddToggle("CombatVisualsChamsEnabled", {
                    Text = "Chams",
                    Default = false,
                    Tooltip = nil
                })

                TargetChamsToggle:AddColorPicker("CombatVisualsChamsFillColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Fill Color",
                    Transparency = 0.5
                })

                TargetChamsToggle:AddColorPicker("CombatVisualsChamsOutlineColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Outline Color",
                    Transparency = 0.5
                })

                Toggles.CombatVisualsChamsEnabled:OnChanged(function()
                    Settings.Combat.Visuals.Chams.Enabled = Toggles.CombatVisualsChamsEnabled.Value
                end)

                Options.CombatVisualsChamsFillColor:OnChanged(function()
                    Settings.Combat.Visuals.Chams.Fill.Color = Options.CombatVisualsChamsFillColor.Value
                    Settings.Combat.Visuals.Chams.Fill.Transparency = Options.CombatVisualsChamsFillColor.Transparency
                end)

                Options.CombatVisualsChamsOutlineColor:OnChanged(function()
                    Settings.Combat.Visuals.Chams.Outline.Color = Options.CombatVisualsChamsOutlineColor.Value
                    Settings.Combat.Visuals.Chams.Outline.Transparency = Options.CombatVisualsChamsOutlineColor.Transparency
                end)
            end

            --// Air
            do
                Sections.Combat.Air:AddToggle("CombatAirEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatAirEnabled:OnChanged(function()
                    Settings.Combat.Air.Enabled = Toggles.CombatAirEnabled.Value
                end)

                Sections.Combat.Air:AddToggle("CombatJumpOffsetEnabled", {
                    Text = "Jump Offset",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.CombatJumpOffsetEnabled:OnChanged(function()
                    Settings.Combat.Air.JumpOffset.Enabled = Toggles.CombatJumpOffsetEnabled.Value
                end)

                Sections.Combat.Air:AddSlider("CombatJumpOffSet", {
                    Text = "Offset",
                    Default = 0.09,
                    Min = -10,
                    Max = 10,
                    Rounding = 3,
                    Compact = false
                })

                Options.CombatJumpOffSet:OnChanged(function()
                    Settings.Combat.Air.JumpOffset.Offset = Options.CombatJumpOffSet.Value
                end)
            end
        end

        --// Visuals tab
        do
 
            --// Bullet Tracers
            do

                local BulletTracersToggle = Sections.Visuals.BulletTracers:AddToggle("VisualsBulletTracersEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil
                })

                BulletTracersToggle:AddColorPicker("VisualsBulletTracersColor1", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Bullet Tracers Color Gradient 1",
                    Transparency = nil
                })

                BulletTracersToggle:AddColorPicker("VisualsBulletTracersColor2", {
                    Default = Color3.new(0, 0, 0),
                    Title = "Bullet Tracers Color Gradient 2",
                    Transparency = nil
                })

                Sections.Visuals.BulletTracers:AddToggle("VisualsBulletTracersFadeEnabled", {
                    Text = "Fade",
                    Default = false,
                    Tooltip = nil
                })

                Toggles.VisualsBulletTracersEnabled:OnChanged(function()
                    Settings.Visuals.BulletTracers.Enabled = Toggles.VisualsBulletTracersEnabled.Value
                end)

                Toggles.VisualsBulletTracersFadeEnabled:OnChanged(function()
                    Settings.Visuals.BulletTracers.Fade.Enabled = Toggles.VisualsBulletTracersFadeEnabled.Value
                end)

                Options.VisualsBulletTracersColor1:OnChanged(function()
                    Settings.Visuals.BulletTracers.Color.Gradient1 = Options.VisualsBulletTracersColor1.Value
                end)

                Options.VisualsBulletTracersColor2:OnChanged(function()
                    Settings.Visuals.BulletTracers.Color.Gradient2 = Options.VisualsBulletTracersColor2.Value
                end)

                Sections.Visuals.BulletTracers:AddSlider("VisualsBulletTracersDuration", {
                    Text = "Duration",
                    Default = 1,
                    Min = 0.1,
                    Max = 10,
                    Rounding = 1,
                    Compact = false
                })

                Sections.Visuals.BulletTracers:AddSlider("VisualsBulletTracersFadeDuration", {
                    Text = "Fade Duration",
                    Default = 0.5,
                    Min = 0.1,
                    Max = 10,
                    Rounding = 1,
                    Compact = false
                })


                Options.VisualsBulletTracersDuration:OnChanged(function()
                    Settings.Visuals.BulletTracers.Duration = Options.VisualsBulletTracersDuration.Value
                end)

                Options.VisualsBulletTracersFadeDuration:OnChanged(function()
                    Settings.Visuals.BulletTracers.Fade.Duration = Options.VisualsBulletTracersFadeDuration.Value
                end)
            end

            --// Bullet Impacts
            do
                Sections.Visuals.BulletImpacts:AddToggle("VisualsBulletImpactsEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil
                }):AddColorPicker("VisualsBulletImpactsColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Bullet Impact Color",
                    Transparency = nil
                })

                Sections.Visuals.BulletImpacts:AddToggle("VisualsBulletImpactsFadeEnabled", {
                    Text = "Fade",
                    Default = false,
                    Tooltip = nil
                })

                Sections.Visuals.BulletImpacts:AddDropdown("VisualsBulletImpactsMaterial", {
                    Values = {"SmoothPlastic", "ForceField", "Neon"},
                    Default = 1,
                    Multi = false,

                    Text = "Material",
                    Tooltip = nil
                })

                Options.VisualsBulletImpactsMaterial:OnChanged(function()
                    Settings.Visuals.BulletImpacts.Material = Options.VisualsBulletImpactsMaterial.Value
                end)

                Sections.Visuals.BulletImpacts:AddSlider("VisualsBulletImpactsSize", {
                    Text = "Size",
                    Default = 1,
                    Min = 0.1,
                    Max = 10,
                    Rounding = 2,
                    Compact = false
                })

                Sections.Visuals.BulletImpacts:AddSlider("VisualsBulletImpactsDuration", {
                    Text = "Duration",
                    Default = 1,
                    Min = 0.1,
                    Max = 10,
                    Rounding = 1,
                    Compact = false
                })

                Sections.Visuals.BulletImpacts:AddSlider("VisualsBulletImpactsFadeDuration", {
                    Text = "Fade Duration",
                    Default = 0.5,
                    Min = 0.1,
                    Max = 10,
                    Rounding = 1,
                    Compact = false
                })


                Options.VisualsBulletImpactsDuration:OnChanged(function()
                    Settings.Visuals.BulletImpacts.Duration = Options.VisualsBulletImpactsDuration.Value
                end)

                Options.VisualsBulletImpactsSize:OnChanged(function()
                    Settings.Visuals.BulletImpacts.Size = Options.VisualsBulletImpactsSize.Value
                end)

                Options.VisualsBulletImpactsFadeDuration:OnChanged(function()
                    Settings.Visuals.BulletImpacts.Fade.Duration = Options.VisualsBulletImpactsFadeDuration.Value
                end)

                Toggles.VisualsBulletImpactsEnabled:OnChanged(function()
                    Settings.Visuals.BulletImpacts.Enabled = Toggles.VisualsBulletImpactsEnabled.Value
                end)

                Toggles.VisualsBulletImpactsFadeEnabled:OnChanged(function()
                    Settings.Visuals.BulletImpacts.Fade.Enabled = Toggles.VisualsBulletImpactsFadeEnabled.Value
                end)

                Options.VisualsBulletImpactsColor:OnChanged(function()
                    Settings.Visuals.BulletImpacts.Color = Options.VisualsBulletImpactsColor.Value
                end)
            end

            --// On Hit
            do
                Sections.Visuals.OnHit:AddToggle("VisualsOnHitEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil
                })

                Sections.Visuals.OnHit:AddToggle("VisualsOnHitEffectEnabled", {
                    Text = "Effect",
                    Default = false,
                    Tooltip = nil
                }):AddColorPicker("VisualsOnHitEffectColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Bullet Impact Color",
                    Transparency = nil
                })

                Sections.Visuals.OnHit:AddToggle("VisualsOnHiSoundEnabled", {
                    Text = "Sound",
                    Default = false,
                    Tooltip = nil
                })

                Sections.Visuals.OnHit:AddSlider("VisualsOnHitSoundVolume", {
                    Text = "Sound Volume",
                    Default = 5,
                    Min = 0.1,
                    Max = 10,
                    Rounding = 2,
                    Compact = false
                })

                local Sounds = {}

                for Sound, _ in pairs(Hitsounds) do
                    table.insert(Sounds, Sound)
                end

                Sections.Visuals.OnHit:AddDropdown("VisualsOnHitSound", {
                    Values = Sounds,
                    Default = 1,
                    Multi = false,
                    Text = "Sound To Play",
                    Tooltip = nil
                })


                Sections.Visuals.OnHit:AddToggle("VisualsOnHitChamsEnabled", {
                    Text = "Chams",
                    Default = false,
                    Tooltip = nil
                }):AddColorPicker("VisualsOnHitChamsColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Hit Chams Color",
                    Transparency = nil
                })

                Sections.Visuals.OnHit:AddSlider("VisualsOnHitChamsDuration", {
                    Text = "Duration",
                    Default = 1,
                    Min = 0.1,
                    Max = 10,
                    Rounding = 2,
                    Compact = false
                })

                Sections.Visuals.OnHit:AddDropdown("VisualsOnHitChamsMaterial", {
                    Values = {"ForceField", "Neon"},
                    Default = 1,
                    Multi = false,
                    Text = "Material",
                    Tooltip = nil
                })

                Options.VisualsOnHitChamsDuration:OnChanged(function()
                    Settings.Visuals.OnHit.Chams.Duration = Options.VisualsOnHitChamsDuration.Value
                end)

                Options.VisualsOnHitChamsMaterial:OnChanged(function()
                    Settings.Visuals.OnHit.Chams.Material = Options.VisualsOnHitChamsMaterial.Value
                end)

                Options.VisualsBulletImpactsMaterial:OnChanged(function()
                    Settings.Visuals.BulletImpacts.Material = Options.VisualsBulletImpactsMaterial.Value
                end)

                Toggles.VisualsOnHitEnabled:OnChanged(function()
                    Settings.Visuals.OnHit.Enabled = Toggles.VisualsOnHitEnabled.Value
                end)

                Toggles.VisualsOnHitChamsEnabled:OnChanged(function()
                    Settings.Visuals.OnHit.Chams.Enabled = Toggles.VisualsOnHitChamsEnabled.Value
                end)

                Options.VisualsOnHitChamsColor:OnChanged(function()
                    Settings.Visuals.OnHit.Chams.Color = Options.VisualsOnHitChamsColor.Value
                end)

                Toggles.VisualsOnHitEffectEnabled:OnChanged(function()
                    Settings.Visuals.OnHit.Effect.Enabled = Toggles.VisualsOnHitEffectEnabled.Value
                end)

                Options.VisualsOnHitEffectColor:OnChanged(function()
                    Settings.Visuals.OnHit.Effect.Color = Options.VisualsOnHitEffectColor.Value
                end)

                Toggles.VisualsOnHiSoundEnabled:OnChanged(function()
                    Settings.Visuals.OnHit.Sound.Enabled = Toggles.VisualsOnHiSoundEnabled.Value
                end)

                Options.VisualsOnHitSoundVolume:OnChanged(function()
                    Settings.Visuals.OnHit.Sound.Volume = Options.VisualsOnHitSoundVolume.Value
                end)

                Options.VisualsOnHitSound:OnChanged(function()
                    Settings.Visuals.OnHit.Sound.Value = Options.VisualsOnHitSound.Value
                end)
            end

            --// Atmosphere
            do
                Sections.Visuals.Atmosphere:AddToggle("VisualsAtmosphereEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil,
                })


                Toggles.VisualsAtmosphereEnabled:OnChanged(function()
                    Settings.Visuals.World.Enabled = Toggles.VisualsAtmosphereEnabled.Value
                end)

                Sections.Visuals.Atmosphere:AddToggle("VisualsAtmosphereFogEnabled", {
                    Text = "Fog",
                    Default = false,
                    Tooltip = nil,
                }):AddColorPicker("VisualsAtmosphereFogColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Fog Color",
                    Transparency = nil,
                })

                Toggles.VisualsAtmosphereFogEnabled:OnChanged(function()
                    Settings.Visuals.World.Fog.Enabled = Toggles.VisualsAtmosphereFogEnabled.Value
                end)

                Options.VisualsAtmosphereFogColor:OnChanged(function()
                    Settings.Visuals.World.Fog.Color = Options.VisualsAtmosphereFogColor.Value
                end)

                Sections.Visuals.Atmosphere:AddSlider("VisualsAtmosphereFogStart", {
                    Text = "Fog Start",
                    Default = 1000,
                    Min = 1,
                    Max = 10000,
                    Rounding = 0,
                    Compact = false,
                })

                Sections.Visuals.Atmosphere:AddSlider("VisualsAtmosphereFogEnd", {
                    Text = "Fog End",
                    Default = 1000,
                    Min = 1,
                    Max = 10000,
                    Rounding = 0,
                    Compact = false,
                })

                Options.VisualsAtmosphereFogStart:OnChanged(function()
                    Settings.Visuals.World.Fog.Start = Options.VisualsAtmosphereFogStart.Value
                end)

                Options.VisualsAtmosphereFogEnd:OnChanged(function()
                    Settings.Visuals.World.Fog.End = Options.VisualsAtmosphereFogEnd.Value
                end)

                Sections.Visuals.Atmosphere:AddToggle("VisualsAtmosphereAmbientEnabled", {
                    Text = "Ambient",
                    Default = false,
                    Tooltip = nil,
                }):AddColorPicker("VisualsAtmosphereAmbientColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Ambient Color",
                    Transparency = nil,
                })

                Toggles.VisualsAtmosphereAmbientEnabled:OnChanged(function()
                    Settings.Visuals.World.Ambient.Enabled = Toggles.VisualsAtmosphereAmbientEnabled.Value
                end)

                Options.VisualsAtmosphereAmbientColor:OnChanged(function()
                    Settings.Visuals.World.Ambient.Color = Options.VisualsAtmosphereAmbientColor.Value
                end)

                Sections.Visuals.Atmosphere:AddToggle("VisualsAtmosphereBrightnessChangerEnabled", {
                    Text = "Brightness Changer",
                    Default = false,
                    Tooltip = nil,
                })

                Sections.Visuals.Atmosphere:AddSlider("VisualsAtmosphereBrightnessChangerValue", {
                    Text = "Brightness Value",
                    Default = 0,
                    Min = 0,
                    Max = 10,
                    Rounding = 2,
                    Compact = false,
                })

                Toggles.VisualsAtmosphereBrightnessChangerEnabled:OnChanged(function()
                    Settings.Visuals.World.Brightness.Enabled = Toggles.VisualsAtmosphereBrightnessChangerEnabled.Value
                end)

                Options.VisualsAtmosphereBrightnessChangerValue:OnChanged(function()
                    Settings.Visuals.World.Brightness.Value = Options.VisualsAtmosphereBrightnessChangerValue.Value
                end)

                Sections.Visuals.Atmosphere:AddToggle("VisualsAtmosphereTimeChangerEnabled", {
                    Text = "Clock Time",
                    Default = false,
                    Tooltip = nil,
                })

                Sections.Visuals.Atmosphere:AddSlider("VisualsAtmosphereTimeChangerValue", {
                    Text = "Time",
                    Default = 1,
                    Min = 0.1,
                    Max = 24,
                    Rounding = 1,
                    Compact = false,
                })

                Toggles.VisualsAtmosphereTimeChangerEnabled:OnChanged(function()
                    Settings.Visuals.World.ClockTime.Enabled = Toggles.VisualsAtmosphereTimeChangerEnabled.Value
                end)

                Options.VisualsAtmosphereTimeChangerValue:OnChanged(function()
                    Settings.Visuals.World.ClockTime.Value = Options.VisualsAtmosphereTimeChangerValue.Value
                end)

                Sections.Visuals.Atmosphere:AddToggle("VisualsAtmosphereExposureChangerEnabled", {
                    Text = "Exposure Changer",
                    Default = false,
                    Tooltip = nil,
                })

                Sections.Visuals.Atmosphere:AddSlider("VisualsAtmosphereExposureChangerValue", {
                    Text = "Exposure",
                    Default = 1,
                    Min = -3,
                    Max = 3,
                    Rounding = 1,
                    Compact = false,
                })

                Toggles.VisualsAtmosphereExposureChangerEnabled:OnChanged(function()
                    Settings.Visuals.World.WorldExposure.Enabled = Toggles.VisualsAtmosphereExposureChangerEnabled.Value
                end)

                Options.VisualsAtmosphereExposureChangerValue:OnChanged(function()
                    Settings.Visuals.World.WorldExposure.Value = Options.VisualsAtmosphereExposureChangerValue.Value
                end)
            end

            --// Crosshair
            do
                Sections.Visuals.Crosshair:AddToggle("VisualsCrosshairEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil,
                }):AddColorPicker("VisualsCrossahairColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Crosshair Color",
                    Transparency = nil,
                })

                Toggles.VisualsCrosshairEnabled:OnChanged(function()
                    Settings.Visuals.Crosshair.Enabled = Toggles.VisualsCrosshairEnabled.Value
                end)

                Options.VisualsCrossahairColor:OnChanged(function()
                    Settings.Visuals.Crosshair.Color = Options.VisualsCrossahairColor.Value
                end)

                Sections.Visuals.Crosshair:AddSlider("VisualsCrosshairSize", {
                    Text = "Size",
                    Default = 1,
                    Min = 0.1,
                    Max = 30,
                    Rounding = 3,
                    Compact = false,
                })

                Options.VisualsCrosshairSize:OnChanged(function()
                    Settings.Visuals.Crosshair.Size = Options.VisualsCrosshairSize.Value
                end)

                Sections.Visuals.Crosshair:AddSlider("VisualsCrosshairGap", {
                    Text = "Gap",
                    Default = 2,
                    Min = 0.1,
                    Max = 10,
                    Rounding = 3,
                    Compact = false,
                })

                Options.VisualsCrosshairGap:OnChanged(function()
                    Settings.Visuals.Crosshair.Gap = Options.VisualsCrosshairGap.Value
                end)

                Sections.Visuals.Crosshair:AddToggle("VisualsCrosshairRotateEnabled", {
                    Text = "Rotate",
                    Default = false,
                    Tooltip = nil,
                })

                Sections.Visuals.Crosshair:AddSlider("VisualsCrosshairRotateAmount", {
                    Text = "Rotation Speed",
                    Default = 1,
                    Min = 0.1,
                    Max = 10,
                    Rounding = 3,
                    Compact = false,
                })

                Toggles.VisualsCrosshairRotateEnabled:OnChanged(function()
                    Settings.Visuals.Crosshair.Rotation.Enabled = Toggles.VisualsCrosshairRotateEnabled.Value
                end)

                Options.VisualsCrosshairRotateAmount:OnChanged(function()
                    Settings.Visuals.Crosshair.Rotation.Speed = Options.VisualsCrosshairRotateAmount.Value
                end)
            end
        end

        --// Anti Aim
        do

            --// Velocity Spoofer
            do
                Sections.AntiAim.VelocitySpoofer:AddToggle("AntiAimVelocitySpooferEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.AntiAimVelocitySpooferEnabled:OnChanged(function()
                    Settings.AntiAim.VelocitySpoofer.Enabled = Toggles.AntiAimVelocitySpooferEnabled.Value
                end)

                Sections.AntiAim.VelocitySpoofer:AddDropdown("AntiAimVelocitySpooferType", {
                    Values = {"Underground", "Sky", "Multiplier", "Prediction Breaker", "Custom"},
                    Default = 1,
                    Multi = false,

                    Text = "Type",
                    Tooltip = nil
                })

                Options.AntiAimVelocitySpooferType:OnChanged(function()
                    Settings.AntiAim.VelocitySpoofer.Type = Options.AntiAimVelocitySpooferType.Value
                end)

                Sections.AntiAim.VelocitySpoofer:AddToggle("AntiAimVelocitySpooferVisualizeEnabled", {
                    Text = "Visualize",
                    Default = false,
                    Tooltip = nil,
                }):AddColorPicker("AntiAimVelocitySpooferVisualizeColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "Velocity Visualize Color",
                    Transparency = nil,
                })

                Sections.AntiAim.VelocitySpoofer:AddInput("AntiAimVelocitySpooferVisualizePrediction", {
                    Default = nil,
                    Numeric = false,
                    Finished = false,

                    Text = "Visualize Prediction",
                    Tooltip = nil,

                    Placeholder = "Visualize Prediction Amount"
                })

                Options.AntiAimVelocitySpooferVisualizePrediction:OnChanged(function()
                    Settings.AntiAim.VelocitySpoofer.Visualize.Prediction = tonumber(Options.AntiAimVelocitySpooferVisualizePrediction.Value)
                end)

                Toggles.AntiAimVelocitySpooferVisualizeEnabled:OnChanged(function()
                    Settings.AntiAim.VelocitySpoofer.Visualize.Enabled = Toggles.AntiAimVelocitySpooferVisualizeEnabled.Value
                end)

                Options.AntiAimVelocitySpooferVisualizeColor:OnChanged(function()
                    Settings.AntiAim.VelocitySpoofer.Visualize.Color = Options.AntiAimVelocitySpooferVisualizeColor.Value
                end)

                Sections.AntiAim.VelocitySpoofer:AddSlider("AntiAimVelocitySpooferYaw", {
                    Text = "Yaw",
                    Default = 0,
                    Min = 0,
                    Max = 100,
                    Rounding = 3,
                    Compact = false
                })

                Options.AntiAimVelocitySpooferYaw:OnChanged(function()
                    Settings.AntiAim.VelocitySpoofer.Yaw = Options.AntiAimVelocitySpooferYaw.Value
                end)

                Sections.AntiAim.VelocitySpoofer:AddSlider("AntiAimVelocitySpooferPitch", {
                    Text = "Pitch",
                    Default = 0,
                    Min = 0,
                    Max = 100,
                    Rounding = 3,
                    Compact = false
                })

                Options.AntiAimVelocitySpooferPitch:OnChanged(function()
                    Settings.AntiAim.VelocitySpoofer.Pitch = Options.AntiAimVelocitySpooferPitch.Value
                end)

                Sections.AntiAim.VelocitySpoofer:AddSlider("AntiAimVelocitySpooferRoll", {
                    Text = "Roll",
                    Default = 0,
                    Min = 0,
                    Max = 100,
                    Rounding = 3,
                    Compact = false
                })

                Options.AntiAimVelocitySpooferRoll:OnChanged(function()
                    Settings.AntiAim.VelocitySpoofer.Roll = Options.AntiAimVelocitySpooferRoll.Value
                end)
            end

            --// C-Sync
            do
                Sections.AntiAim.CSync:AddToggle("CSyncAntiAimEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil,
                }):AddKeyPicker("CSyncAntiAimKeyPicker", {
                    Default = "b",
                    SyncToggleState = true,
                    Mode = "Toggle",

                    Text = "C-Sync",
                    NoUI = false,
                })

                Toggles.CSyncAntiAimEnabled:OnChanged(function()
                    Settings.AntiAim.CSync.Enabled = Toggles.CSyncAntiAimEnabled.Value
                end)

                Sections.AntiAim.CSync:AddToggle("CSyncAntiAimVisualizeEnabled", {
                    Text = "Visualize",
                    Default = false,
                    Tooltip = nil,
                }):AddColorPicker("CSyncAntiAimVisualizeColor", {
                    Default = Color3.new(1, 1, 1),
                    Title = "CFrame Visualize Color",
                    Transparency = nil,
                })

                Sections.AntiAim.CSync:AddDropdown("CSyncAntiAimType", {
                    Values = {"Custom", "Random", "Random Target", "Target Strafe", "Local Strafe"},
                    Default = 1,
                    Multi = false,
                    Text = "Type",
                    Tooltip = nil,
                })

                Toggles.CSyncAntiAimVisualizeEnabled:OnChanged(function()
                    Settings.AntiAim.CSync.Visualize.Enabled = Toggles.CSyncAntiAimVisualizeEnabled.Value
                end)

                Options.CSyncAntiAimVisualizeColor:OnChanged(function()
                    Settings.AntiAim.CSync.Visualize.Color = Options.CSyncAntiAimVisualizeColor.Value
                end)

                Options.CSyncAntiAimType:OnChanged(function()
                    Settings.AntiAim.CSync.Type = Options.CSyncAntiAimType.Value
                end)

                Sections.AntiAim.CSync:AddSlider("CSyncAntiAimRandomRange", {
                    Text = "Random Range",
                    Default = 0.1,
                    Min = 0,
                    Max = 20,
                    Rounding = 1,
                    Compact = false,
                })

                Options.CSyncAntiAimRandomRange:OnChanged(function()
                    Settings.AntiAim.CSync.RandomDistance = Options.CSyncAntiAimRandomRange.Value
                end)

                Sections.AntiAim.CSync:AddSlider("CSyncAntiAimCustomX", {
                    Text = "Custom X",
                    Default = 0.1,
                    Min = 0,
                    Max = 500,
                    Rounding = 1,
                    Compact = false,
                })

                Options.CSyncAntiAimCustomX:OnChanged(function()
                    Settings.AntiAim.CSync.Custom.X = Options.CSyncAntiAimCustomX.Value
                end)

                Sections.AntiAim.CSync:AddSlider("CSyncAntiAimCustomY", {
                    Text = "Custom Y",
                    Default = 0.1,
                    Min = 0,
                    Max = 500,
                    Rounding = 1,
                    Compact = false,
                })

                Options.CSyncAntiAimCustomY:OnChanged(function()
                    Settings.AntiAim.CSync.Custom.Y = Options.CSyncAntiAimCustomY.Value
                end)

                Sections.AntiAim.CSync:AddSlider("CSyncAntiAimCustomZ", {
                    Text = "Custom Z",
                    Default = 0.1,
                    Min = 0,
                    Max = 500,
                    Rounding = 1,
                    Compact = false,
                })

                Options.CSyncAntiAimCustomZ:OnChanged(function()
                    Settings.AntiAim.CSync.Custom.Z = Options.CSyncAntiAimCustomZ.Value
                end)

                Sections.AntiAim.CSync:AddSlider("CSyncAntiAimTargetStrafeSpeed", {
                    Text = "Target Strafe Speed",
                    Default = 1,
                    Min = 0,
                    Max = 20,
                    Rounding = 1,
                    Compact = false,
                })

                Options.CSyncAntiAimTargetStrafeSpeed:OnChanged(function()
                    Settings.AntiAim.CSync.TargetStrafe.Speed = Options.CSyncAntiAimTargetStrafeSpeed.Value
                end)

                Sections.AntiAim.CSync:AddSlider("CSyncAntiAimTargetStrafeDistance", {
                    Text = "Target Strafe Distance",
                    Default = 1,
                    Min = 0,
                    Max = 20,
                    Rounding = 1,
                    Compact = false,
                })

                Options.CSyncAntiAimTargetStrafeDistance:OnChanged(function()
                    Settings.AntiAim.CSync.TargetStrafe.Distance = Options.CSyncAntiAimTargetStrafeDistance.Value
                end)

                Sections.AntiAim.CSync:AddSlider("CSyncAntiAimTargetStrafeHeight", {
                    Text = "Target Strafe Height",
                    Default = 1,
                    Min = 0,
                    Max = 20,
                    Rounding = 1,
                    Compact = false,
                })

                Options.CSyncAntiAimTargetStrafeHeight:OnChanged(function()
                    Settings.AntiAim.CSync.TargetStrafe.Height = Options.CSyncAntiAimTargetStrafeHeight.Value
                end)
            end

            --// Fake Lag
            do
                Sections.AntiAim.Network:AddToggle("AntiAimNetworkEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil,
                }):AddKeyPicker("AntiAimNetworkKeyPicker", {
                    Default = "b",
                    SyncToggleState = true,
                    Mode = "Toggle",

                    Text = "Network",
                    NoUI = false,
                })

                Toggles.AntiAimNetworkEnabled:OnChanged(function()
                    Settings.AntiAim.Network.Enabled = Toggles.AntiAimNetworkEnabled.Value
                end)

                Sections.AntiAim.Network:AddToggle("AntiAimNetworkWalkingCheck", {
                    Text = "Walking Check",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.AntiAimNetworkWalkingCheck:OnChanged(function()
                    Settings.AntiAim.Network.WalkingCheck = Toggles.AntiAimNetworkWalkingCheck.Value
                end)

                Sections.AntiAim.Network:AddSlider("AntiAimNetworkAmount", {
                    Text = "Amount",
                    Default = 0.1,
                    Min = 0,
                    Max = 30,
                    Rounding = 3,
                    Compact = false,
                })

                Options.AntiAimNetworkAmount:OnChanged(function()
                    Settings.AntiAim.Network.Amount = Options.AntiAimNetworkAmount.Value
                end)
            end

            --// Velocity Desync
            do
                Sections.AntiAim.VelocityDesync:AddToggle("AntiAimVelocityDesyncEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil,
                }):AddKeyPicker("AntiAimVelocityDesyncKeyPicker", {
                    Default = "b",
                    SyncToggleState = true,
                    Mode = "Toggle",

                    Text = "Velocity Desync",
                    NoUI = false,
                })

                Toggles.AntiAimVelocityDesyncEnabled:OnChanged(function()
                    Settings.AntiAim.VelocityDesync.Enabled = Toggles.AntiAimVelocityDesyncEnabled.Value
                end)

                Sections.AntiAim.VelocityDesync:AddSlider("AntiAimVelocityDesyncRange", {
                    Text = "Range",
                    Default = 1,
                    Min = 0.1,
                    Max = 10,
                    Rounding = 3,
                    Compact = false,
                })

                Options.AntiAimVelocityDesyncRange:OnChanged(function()
                    Settings.AntiAim.VelocityDesync.Range = Options.AntiAimVelocityDesyncRange.Value
                end)
            end

            --// FFlag Desync
            do
                Sections.AntiAim.FFlag:AddToggle("AntiAimFFlagDesyncEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil,
                }):AddKeyPicker("AntiAimFFlagDesyncKeyPicker", {
                    Default = "b",
                    SyncToggleState = true,
                    Mode = "Toggle",

                    Text = "FFlag Desync",
                    NoUI = false,
                })

                Toggles.AntiAimFFlagDesyncEnabled:OnChanged(function()
                    Settings.AntiAim.FFlagDesync.Enabled = Toggles.AntiAimFFlagDesyncEnabled.Value

                    if not Settings.AntiAim.FFlagDesync.Enabled then
                        for FFlag, Value in pairs(Script.Locals.FFlags) do
                            setfflag(FFlag, Value)
                        end
                    end
                end)

                Sections.AntiAim.FFlag:AddToggle("AntiAimFFlagDesyncSetNew", {
                    Text = "Set New",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.AntiAimFFlagDesyncSetNew:OnChanged(function()
                    Settings.AntiAim.FFlagDesync.SetNew = Toggles.AntiAimFFlagDesyncSetNew.Value
                end)

                Sections.AntiAim.FFlag:AddDropdown("AntiAimFFlagDesyncFFlags", {
                    Values = {"S2PhysicsSenderRate", "PhysicsSenderMaxBandwidthBps", "DataSenderMaxJoinBandwidthBps"},
                    Default = {"S2PhysicsSenderRate"},
                    Multi = true,
                    Text = "FFlags",
                    Tooltip = nil,
                })

                Options.AntiAimFFlagDesyncFFlags:OnChanged(function()
                    Settings.AntiAim.FFlagDesync.FFlags = Options.AntiAimFFlagDesyncFFlags.Value
                end)

                Sections.AntiAim.FFlag:AddSlider("AntiAimFFlagDesyncAmount", {
                    Text = "Amount",
                    Default = 2,
                    Min = 0.1,
                    Max = 10,
                    Rounding = 3,
                    Compact = false,
                })

                Options.AntiAimFFlagDesyncAmount:OnChanged(function()
                    Settings.AntiAim.FFlagDesync.Amount = Options.AntiAimFFlagDesyncAmount.Value
                end)

                Sections.AntiAim.FFlag:AddSlider("AntiAimFFlagDesyncSetnewAmount", {
                    Text = "Set New Amount",
                    Default = 15,
                    Min = 0.1,
                    Max = 20,
                    Rounding = 3,
                    Compact = false,
                })

                Options.AntiAimFFlagDesyncSetnewAmount:OnChanged(function()
                    Settings.AntiAim.FFlagDesync.SetNewAmount = Options.AntiAimFFlagDesyncSetnewAmount.Value
                end)
            end

            --// Invisible Desync
        end

        --// Misc
        do

            --// Speed
            do
                Sections.Misc.Speed:AddToggle("MiscCFrameSpeedEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil,
                }):AddKeyPicker("MiscCFrameSpeedKeybind", {
                    Default = "b",
                    SyncToggleState = true,
                    Mode = "Toggle",

                    Text = "Speed",
                    NoUI = false,
                })

                Toggles.MiscCFrameSpeedEnabled:OnChanged(function()
                    Settings.Misc.Movement.Speed.Enabled = Toggles.MiscCFrameSpeedEnabled.Value
                end)

                Sections.Misc.Speed:AddSlider("MiscCFrameSpeedAmount", {
                    Text = "Amount",
                    Default = 0.1,
                    Min = 0,
                    Max = 10,
                    Rounding = 3,
                    Compact = false,
                })

                Options.MiscCFrameSpeedAmount:OnChanged(function()
                    Settings.Misc.Movement.Speed.Amount = Options.MiscCFrameSpeedAmount.Value
                end)
            end

            --// Exploits
            do
                Sections.Misc.Exploits:AddToggle("MiscExploitsEnabled", {
                    Text = "Enabled",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.MiscExploitsEnabled:OnChanged(function()
                    Settings.Misc.Exploits.Enabled = Toggles.MiscExploitsEnabled.Value
                end)
				
                Sections.Misc.Exploits:AddToggle("MiscExploitsAntiStomp", {
                    Text = "Anti Stomp",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.MiscExploitsAntiStomp:OnChanged(function()
                    Settings.Misc.Exploits.AntiStomp = Toggles.MiscExploitsAntiStomp.Value
                end)
				
                Sections.Misc.Exploits:AddToggle("MiscExploitsAntiBag", {
                    Text = "Anti Bag",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.MiscExploitsAntiBag:OnChanged(function()
                    Settings.Misc.Exploits.AntiBag = Toggles.MiscExploitsAntiBag.Value
                end)
				
                Sections.Misc.Exploits:AddToggle("MiscExploitsAntiGrab", {
                    Text = "Anti Grab",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.MiscExploitsAntiGrab:OnChanged(function()
                    Settings.Misc.Exploits.AntiGrab = Toggles.MiscExploitsAntiGrab.Value
                end)
				
                Sections.Misc.Exploits:AddToggle("MiscExploitsNoSlowdown", {
                    Text = "No Slowdown",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.MiscExploitsNoSlowdown:OnChanged(function()
                    Settings.Misc.Exploits.NoSlowDown = Toggles.MiscExploitsNoSlowdown.Value
                end)
				
                Sections.Misc.Exploits:AddToggle("MiscExploitsAutoStomp", {
                    Text = "Auto Stomp",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.MiscExploitsAutoStomp:OnChanged(function()
                    Settings.Misc.Exploits.AutoStomp = Toggles.MiscExploitsAutoStomp.Value
                end)
				
                Sections.Misc.Exploits:AddToggle("MiscExploitsAutoReload", {
                    Text = "Auto Reload",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.MiscExploitsAutoReload:OnChanged(function()
                    Settings.Misc.Exploits.AutoReload = Toggles.MiscExploitsAutoReload.Value
                end)
				
                Sections.Misc.Exploits:AddToggle("MiscExploitsNoRecoil", {
                    Text = "No Recoil",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.MiscExploitsNoRecoil:OnChanged(function()
                    Settings.Misc.Exploits.NoRecoil = Toggles.MiscExploitsNoRecoil.Value
                end)

                Sections.Misc.Exploits:AddToggle("MiscExploitsNoJumpCooldown", {
                    Text = "No Jump Cooldown",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.MiscExploitsNoJumpCooldown:OnChanged(function()
                    Settings.Misc.Exploits.NoJumpCooldown = Toggles.MiscExploitsNoJumpCooldown.Value
                end)
				
                Sections.Misc.Exploits:AddToggle("MiscExploitsAutoArmor", {
                    Text = "Auto Armor",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.MiscExploitsAutoArmor:OnChanged(function()
                    Settings.Misc.Exploits.AutoArmor = Toggles.MiscExploitsAutoArmor.Value
                end)
                
                Sections.Misc.Exploits:AddToggle("MiscExploitsAutoFireArmor", {
                    Text = "Auto Fire Armor",
                    Default = false,
                    Tooltip = nil,
                })

                Toggles.MiscExploitsAutoFireArmor:OnChanged(function()
                    Settings.Misc.Exploits.AutoFireArmor = Toggles.MiscExploitsAutoFireArmor.Value
                end)
            end
			
			--// Experimental
			do
			    Sections.Misc.Experimental:AddButton("Destroy EXP", function()
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "Anti Exploiters"

local function respawnTool()
    local backpack = player.Backpack
    local existingTool = backpack:FindFirstChild(tool.Name)
    if not existingTool then
        tool.Parent = backpack
    end
end

tool.Activated:Connect(function()
    local pos = mouse.Hit + Vector3.new(0, 2.5, 0)
    pos = CFrame.new(pos.X, pos.Y, pos.Z)
    local vim = game:GetService("VirtualInputManager")
    vim:SendKeyEvent(true, "X", false, game)
end)

player.CharacterAdded:Connect(respawnTool)

respawnTool()

local FINOBE_KEYBIND = "X"

getgenv().Finobe1 = true 
local NewCFrame = CFrame.new
local LocalFinobe = game.Players.LocalPlayer
local InputService = game:GetService("UserInputService")
local Runfinobe = game:GetService("RunService")

local Finobe2; 
Runfinobe.heartbeat:Connect(function()
    if LocalFinobe.Character then 
        local FinobeChar = LocalFinobe.Character.HumanoidRootPart
        local Offset = FinobeChar.CFrame * NewCFrame(9e9, 0/0, math.huge)
        
        if getgenv().Finobe1 then 
            Finobe2 = FinobeChar.CFrame
            FinobeChar.CFrame = Offset
            Runfinobe.RenderStepped:Wait()
            FinobeChar.CFrame = Finobe2
        end 
    end 
end)

InputService.InputBegan:Connect(function(sigma)
    if sigma.KeyCode == Enum.KeyCode[FINOBE_KEYBIND] then 
        getgenv().Finobe1 = not getgenv().Finobe1
        
        if not Finobe1 then 
            LocalFinobe.Character.HumanoidRootPart.CFrame = Finobe2
            -- 
            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title = "Destroy Exploiters";
                Text = "Disabled";
            })
        else 
            Finobe2 = nil 
            -- 
            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title = "Destroy Exploiters";
                Text = "Enabled";
            })
        end 
    end 
end)    

local finobeHookSigmaChatWtfCreateRemindedMeAboutThisShittyAssExploitBtw_MiseryOwnerIsACuck
finobeHookSigmaChatWtfCreateRemindedMeAboutThisShittyAssExploitBtw_MiseryOwnerIsACuck = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not checkcaller() then
        if key == "CFrame" and getgenv().Finobe1 and LocalFinobe.Character and LocalFinobe.Character:FindFirstChild("HumanoidRootPart") and LocalFinobe.Character:FindFirstChild("Humanoid") and LocalFinobe.Character:FindFirstChild("Humanoid").Health > 0 then
            if self == LocalFinobe.Character.HumanoidRootPart and Finobe2 ~= nil then
                return Finobe2
            end
        end
    end
    -- 
    return finobeHookSigmaChatWtfCreateRemindedMeAboutThisShittyAssExploitBtw_MiseryOwnerIsACuck(self, key)
    end))
				end)
                Sections.Misc.Experimental:AddButton("Neck Grab", function()
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Character = LocalPlayer.Character
    
    local IM = game:GetService("ReplicatedStorage").IM.ANIM
    
    local PlayersChar = Workspace.Players
    
    if _G.JOINTWATCHER then
        _G.JOINTWATCHER:Disconnect()
    end
    
    local function Align(P0, P1, P, R)
        local A0, A1 = Instance.new("Attachment", P0), Instance.new("Attachment", P1)
        
        local AP, AO = Instance.new("AlignPosition", P0), Instance.new("AlignOrientation", P0)
        
        A1.Position = P
        A0.Rotation = R
        
        AP.RigidityEnabled = true
        AP.Responsiveness = 200
        AP.Attachment0 = A0
        AP.Attachment1 = A1
        
        AO.MaxTorque = 9e9
        AO.Responsiveness = 200
        AO.RigidityEnabled = true
        AO.Attachment0 = A0
        AO.Attachment1 = A1
        
        return A0, A1, AP, A0
    end
    
    _G.JOINTWATCHER = PlayersChar.DescendantAdded:Connect(function(Ins)
        if Ins:IsA("Weld") and Ins.Name == "GRABBING_CONSTRAINT" then
            repeat task.wait() until Ins.Part0 ~= nil
            repeat task.wait() until Ins:FindFirstChildOfClass("RopeConstraint")
            
            local AT0, AT1, AP, A0
            
            if Ins.Part0:IsDescendantOf(LocalPlayer.Character) then
                Ins:FindFirstChildOfClass("RopeConstraint").Length = 9e9
                
                Character.Animate.Disabled = true
				
                for _, Anim in pairs(Character.Humanoid:GetPlayingAnimationTracks()) do
                    Anim:Stop()
                end
                
                Character.Animate.Disabled = false
				
local DefaultDanceanim = Instance.new('Animation')
DefaultDanceanim.AnimationId = "rbxassetid://3135389157"

local humanoid = game:GetService('Players').LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')
local animation = humanoid:LoadAnimation(DefaultDanceanim)

animation:Play()
animation.TimePosition = 0
animation:AdjustSpeed(0.2)

            local DefaultDanceanim2 = Instance.new('Animation')
            DefaultDanceanim2.AnimationId = "rbxassetid://3135389157"
            
            local humanoid = Character:FindFirstChildWhichIsA('Humanoid')
            local animation2 = humanoid:LoadAnimation(DefaultDanceanim2)

            animation2:Play()
            animation2.TimePosition = 0.1
            animation2:AdjustSpeed(0) 
				
                AT0, AT1, AP, A0 = Align(Ins.Parent.UpperTorso, LocalPlayer.Character.RightHand, Vector3.new(1, -0, -0), Vector3.new(90, 70, 160))
            end
            
            repeat task.wait() until Ins.Parent == nil
            
            Character.Animate.Disabled = true
                
        for _, Anim in pairs(Character.Humanoid:GetPlayingAnimationTracks()) do
            Anim:Stop()
        end
        
        Character.Animate.Disabled = false
            
            AT0:Destroy()
            AT1:Destroy()
            AP:Destroy()
            A0:Destroy()
        end
    end)
                end)
                Sections.Misc.Experimental:AddButton("Holding", function()
    local KIckAnim = Instance.new('Animation');
    KIckAnim.AnimationId = "rbxassetid://3355740058";
        tool = Instance.new("Tool")
        tool.RequiresHandle = false
        tool.Name = "Activate"
        tool.Activated:Connect(function()
           Play(2848703459)
            game.ReplicatedStorage.MainEvent:FireServer("Grabbing",true)
        wait(0.1)
        end)
        tool.Parent = game.Players.LocalPlayer.Backpack
           
    game:GetService('Players').LocalPlayer.Character:WaitForChild('FULLY_LOADED_CHAR');
                end)
				Sections.Misc.Experimental:AddButton("Rip In Half", function()
    local KIckAnim = Instance.new('Animation')
    KIckAnim.AnimationId = "rbxassetid://13850675130"
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "Rip In Half"
    
    tool.Activated:Connect(function()
        local grabbedValue = game.Players.LocalPlayer.Character.BodyEffects.Grabbed.Value
        if not grabbedValue then
            notify("cannot active tool drag player first", "drag player first to work", "rbxthumb://type=Asset&id=9915433572&w=150&h=150", 4)
            return
        end
        
        wait(.1)
        game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("I’m gonna rip you in half now.", "All")
        Play(7148332723)
        wait(2.3)
        Play(4752240968)
        local humanoid = game:GetService('Players').LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')
        if humanoid then
            wait(0.3) humanoid:LoadAnimation(KIckAnim):Play()
        end
        wait(0.1)
        
        local grabbedCharacter = game.Players:GetPlayerFromCharacter(grabbedValue).Character
        if grabbedCharacter then
            local lowerTorso = grabbedCharacter:FindFirstChild("LowerTorso")
            if lowerTorso then
                lowerTorso.Position = Vector3.new(0, -1200, 0)
            end

            local RightUpperArm = grabbedCharacter:FindFirstChild("RightUpperArm")
            if RightUpperArm then
                RightUpperArm.Position = Vector3.new(0, -1200, 0)
            end

           local LeftUpperArm = grabbedCharacter:FindFirstChild("LeftUpperArm")
            if LeftUpperArm then
                LeftUpperArm.Position = Vector3.new(0, -1200, 0)
            end

           local RightUpperLeg = grabbedCharacter:FindFirstChild("RightUpperLeg")
            if RightUpperLeg then
                RightUpperLeg.Position = Vector3.new(0, -1200, 0)
            end

           local LeftUpperLeg = grabbedCharacter:FindFirstChild("LeftUpperLeg")
            if LeftUpperLeg then
                LeftUpperLeg.Position = Vector3.new(0, -1200, 0)
            end
        end
        
        wait(0.1)
        game.ReplicatedStorage.MainEvent:FireServer("Grabbing")
    end)
    
    tool.Parent = game.Players.LocalPlayer.Backpack
				end)
				Sections.Misc.Experimental:AddButton("Throw", function()
getgenv().POWERFLING = 400
local KIckAnim = Instance.new('Animation');
KIckAnim.AnimationId = "rbxassetid://3096047107";
tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "Throw"
tool.Activated:Connect(function()
    game:GetService('Players').LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid'):LoadAnimation(KIckAnim):Play()
    wait(.1)
    for i , v in pairs(game.Players[tostring(game.Players.LocalPlayer.Character.BodyEffects.Grabbed.Value)].Character:GetChildren()) do
	    if v:IsA("MeshPart") then
		    v.CFrame =  game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(100, 0, 0)
		end
	end
	game:GetService("RunService").heartbeat:Connect(function()
    for _, v in next, game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks() do
        if (v.Animation.AnimationId:match("rbxassetid://3096047107")) then
            local Vel = game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity
            game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector.X*getgenv().POWERFLING,game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector.Z*getgenv().POWERFLING)
            game:GetService("RunService").RenderStepped:Wait()
            game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vel
            end
        end
    end)
	wait(0.1)
	game.ReplicatedStorage.MainEvent:FireServer("Grabbing")
	Play(2174940386)
end)
tool.Parent = game.Players.LocalPlayer.Backpack

game:GetService('Players').LocalPlayer.Character:WaitForChild('FULLY_LOADED_CHAR');

				end)
				Sections.Misc.Experimental:AddButton("Super Throw", function()
getgenv().POWERFLING = 800
local KIckAnim = Instance.new('Animation');
KIckAnim.AnimationId = "rbxassetid://3096047107";
tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "Super Throw"
tool.Activated:Connect(function()
    game:GetService('Players').LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid'):LoadAnimation(KIckAnim):Play()
    wait(.1)
    for i , v in pairs(game.Players[tostring(game.Players.LocalPlayer.Character.BodyEffects.Grabbed.Value)].Character:GetChildren()) do
	    if v:IsA("MeshPart") then
		    v.CFrame =  game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(100, 0, 100)
		end
	end
	game:GetService("RunService").heartbeat:Connect(function()
    for _, v in next, game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):GetPlayingAnimationTracks() do
        if (v.Animation.AnimationId:match("rbxassetid://3096047107")) then
            local Vel = game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity
            game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector.X*getgenv().POWERFLING,game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.LookVector.Z*getgenv().POWERFLING)
            game:GetService("RunService").RenderStepped:Wait()
            game.Players.LocalPlayer.Character.HumanoidRootPart.Velocity = Vel
            end
        end
    end)
    wait(0.3)
   Play(2174940386)
    game.ReplicatedStorage.MainEvent:FireServer("Grabbing")
end)
tool.Parent = game.Players.LocalPlayer.Backpack

game:GetService('Players').LocalPlayer.Character:WaitForChild('FULLY_LOADED_CHAR');

				end)
				Sections.Misc.Experimental:AddButton("Break Arms", function()
    local KIckAnim = Instance.new('Animation')
    KIckAnim.AnimationId = "rbxassetid://3096047107"
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "break arms"
    
    tool.Activated:Connect(function()
        local grabbedValue = game.Players.LocalPlayer.Character.BodyEffects.Grabbed.Value
        if not grabbedValue then
            notify("cannot active tool drag player first", "drag player first to work", "rbxthumb://type=Asset&id=9915433572&w=150&h=150", 4)
            return
        end
        
        wait(.1)
        game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("hifgg js took ur arms gng", "All")
        Play(4752240968)
        local humanoid = game:GetService('Players').LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')
        if humanoid then
            wait(0.1) humanoid:LoadAnimation(KIckAnim):Play()
        end
        wait(0.1)
        
        local grabbedCharacter = game.Players:GetPlayerFromCharacter(grabbedValue).Character
        if grabbedCharacter then
            local RightUpperArm = grabbedCharacter:FindFirstChild("RightUpperArm")
            if RightUpperArm then
                RightUpperArm.Position = Vector3.new(0, -1200, 0)
            end

           local LeftUpperArm = grabbedCharacter:FindFirstChild("LeftUpperArm")
            if LeftUpperArm then
                LeftUpperArm.Position = Vector3.new(0, -1200, 0)
            end
        end
        
        wait(0.1)
        game.ReplicatedStorage.MainEvent:FireServer("Grabbing")
    end)
    
    tool.Parent = game.Players.LocalPlayer.Backpack
				end)
				Sections.Misc.Experimental:AddButton("Break Limbs", function()
    local KIckAnim = Instance.new('Animation')
    KIckAnim.AnimationId = "rbxassetid://3096047107"
    local tool = Instance.new("Tool")
    tool.RequiresHandle = false
    tool.Name = "break limbs"
    
    tool.Activated:Connect(function()
        local grabbedValue = game.Players.LocalPlayer.Character.BodyEffects.Grabbed.Value
        if not grabbedValue then
            notify("cannot active tool drag player first", "drag player first to work", "rbxthumb://type=Asset&id=9915433572&w=150&h=150", 4)
            return
        end
        
        wait(.1)
        game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("hifgg js took ur limbs gng", "All")
        Play(4752240968)
        local humanoid = game:GetService('Players').LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')
        if humanoid then
            wait(0.1) humanoid:LoadAnimation(KIckAnim):Play()
        end
        wait(0.1)
        
        local grabbedCharacter = game.Players:GetPlayerFromCharacter(grabbedValue).Character
        if grabbedCharacter then
            local RightUpperArm = grabbedCharacter:FindFirstChild("RightUpperArm")
            if RightUpperArm then
                RightUpperArm.Position = Vector3.new(0, -1200, 0)
            end

           local LeftUpperArm = grabbedCharacter:FindFirstChild("LeftUpperArm")
            if LeftUpperArm then
                LeftUpperArm.Position = Vector3.new(0, -1200, 0)
            end

           local RightUpperLeg = grabbedCharacter:FindFirstChild("RightUpperLeg")
            if RightUpperLeg then
                RightUpperLeg.Position = Vector3.new(0, -1200, 0)
            end

           local LeftUpperLeg = grabbedCharacter:FindFirstChild("LeftUpperLeg")
            if LeftUpperLeg then
                LeftUpperLeg.Position = Vector3.new(0, -1200, 0)
            end
        end
        
        wait(0.1)
        game.ReplicatedStorage.MainEvent:FireServer("Grabbing")
    end)
    
    tool.Parent = game.Players.LocalPlayer.Backpack
				end)
				Sections.Misc.Experimental:AddButton("TP Tool", function()
mouse = game.Players.LocalPlayer:GetMouse()
tool = Instance.new("Tool")
tool.RequiresHandle = false
tool.Name = "Teleport"
tool.Activated:connect(function()
local pos = mouse.Hit+Vector3.new(0,2.5,0)
pos = CFrame.new(pos.X,pos.Y,pos.Z)
game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = pos

local args = {
    [1] = "Boombox",
    [2] = "7549600066"
}

game:GetService("ReplicatedStorage"):FindFirstChild(".gg/untitledhood"):FireServer(unpack(args))
wait(1.4)

local args = {
    [1] = "BoomboxStop"
}

game:GetService("ReplicatedStorage"):FindFirstChild(".gg/untitledhood"):FireServer(unpack(args))
end)
tool.Parent = game.Players.LocalPlayer.Backpack
				end)
				Sections.Misc.Experimental:AddButton("PP Bat", function()
local savepos = game.Players.LocalPlayer.Character.UpperTorso.Position
             local Brokie = game.Workspace.Ignored.Shop["[Bat] - $265"]
             game.Players.LocalPlayer.Character:MoveTo(Brokie.Head.Position)
             wait(0.25)
             fireclickdetector(Brokie.ClickDetector)
             wait(0.25)
         game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(savepos)
         wait(.25)
     local surg = game.Players.LocalPlayer.Backpack:FindFirstChild("[Bat]")
      surg.Parent = game.Players.LocalPlayer.Character
      local New = game.Players.LocalPlayer.Character:FindFirstChild("[Bat]")
       New.Parent = game.Players.LocalPlayer.Backpack

game.Players.LocalPlayer.Backpack:FindFirstChild("[Bat]").GripPos = Vector3.new(-1.5,-1,1.55)
    game.Players.LocalPlayer.Backpack:FindFirstChild("[Bat]").GripForward = Vector3.new(0, 0, 0)
    game.Players.LocalPlayer.Backpack:FindFirstChild("[Bat]").GripRight = Vector3.new(0.19607843458652496, 0.019607843831181526, 0.9803922176361084)

game.Players.LocalPlayer.Backpack:FindFirstChild("[Bat]").GripUp = Vector3.new(-0.9755268096923828, -0.09755268692970276, 0.19705550372600555)

game.Players.LocalPlayer.Backpack:FindFirstChild("[Bat]")
    game.Players.LocalPlayer.Backpack:FindFirstChild("[Bat]")
    game.Players.LocalPlayer.Backpack:FindFirstChild("[Bat]")
    game.Players.LocalPlayer.Backpack:FindFirstChild("[Bat]")
    game.Players.LocalPlayer.Backpack["[Bat]"].Parent = game.Players.LocalPlayer.Character
				end)
				Sections.Misc.Experimental:AddButton("PP StopSign", function()
local d = game.Players.LocalPlayer.Character.HumanoidRootPart.Position
    local k = game.Workspace.Ignored.Shop["[StopSign] - $318"]
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = k.Head.CFrame + Vector3.new(0, 3, 0)
    if (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - k.Head.Position).Magnitude <= 50 then
        wait(.2)
        fireclickdetector(k:FindFirstChild("ClickDetector"), 4)
        toolf = game.Players.LocalPlayer.Backpack:WaitForChild("[StopSign]")
        toolf.Parent = game.Players.LocalPlayer.Character
        end
game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(d)
wait()
local Plr = game.Players.LocalPlayer
local LastPos = Plr.Character.HumanoidRootPart.CFrame
local pp = Plr.Character["[StopSign]"]
wait(0.1)
pp.Sign:Destroy()

pp.Grip = CFrame.new(-1, 2, 1.45000005, 0, -0, -1, -0, 1, -0, 1, 0, -0)
				end)
				
				                Sections.Misc.Experimental:AddButton("Rape Grab", function()
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local LocalPlayer = game.Players.LocalPlayer
    local Character = LocalPlayer.Character
    
    local IM = game:GetService("ReplicatedStorage").IM.ANIM
    
    local PlayersChar = workspace.Players
    
    if _G.JOINTWATCHER then
        _G.JOINTWATCHER:Disconnect()
    end
    
    local function Align(P0, P1, P, R)
        local A0, A1 = Instance.new("Attachment", P0), Instance.new("Attachment", P1)
        
        local AP, AO = Instance.new("AlignPosition", P0), Instance.new("AlignOrientation", P0)
        
        A1.Position = P
        A0.Rotation = R
        
        AP.RigidityEnabled = true
        AP.Responsiveness = 200
        AP.Attachment0 = A0
        AP.Attachment1 = A1
        
        AO.MaxTorque = 9e9
        AO.Responsiveness = 200
        AO.RigidityEnabled = true
        AO.Attachment0 = A0
        AO.Attachment1 = A1
        
        return A0, A1, AP, A0
    end
    
    _G.JOINTWATCHER = PlayersChar.DescendantAdded:Connect(function(Ins)
        if Ins:IsA("Weld") and Ins.Name == "GRABBING_CONSTRAINT" then
            repeat task.wait() until Ins.Part0 ~= nil
            repeat task.wait() until Ins:FindFirstChildOfClass("RopeConstraint")
            
            local AT0, AT1, AP, A0
            
            if Ins.Part0:IsDescendantOf(LocalPlayer.Character) then
                Ins:FindFirstChildOfClass("RopeConstraint").Length = 9e9
                
                Character.Animate.Disabled = true
                
                for _, Anim in pairs(Character.Humanoid:GetPlayingAnimationTracks()) do
                    Anim:Stop()
                end
                
                Character.Animate.Disabled = false
                
                Character.Humanoid:LoadAnimation(IM.RightAim):Play()
                Character.Humanoid:LoadAnimation(IM.LeftAim):Play()
                
                AT0, AT1, AP, A0 = Align(Ins.Parent.UpperTorso, LocalPlayer.Character.UpperTorso, Vector3.new(0, 0, 10), Vector3.new(90, 545, 0))
                
                spawn(function()
                    while Ins.Parent ~= nil do
                        task.wait()
                        local Sine = tick() * 60
                        
                        AT1.Position = Vector3.new(0, -1.2, -4 + 1 * math.sin(Sine / 8))
                    end
                end)
            end
            
            repeat task.wait() until Ins.Parent == nil
            
            Character.Animate.Disabled = true
                
        for _, Anim in pairs(Character.Humanoid:GetPlayingAnimationTracks()) do
            Anim:Stop()
        end
        
        Character.Animate.Disabled = false
            
            AT0:Destroy()
            AT1:Destroy()
            AP:Destroy()
            A0:Destroy()
        end
    end)
                end)
			end
			
			--// Animation
			do
			    Sections.Misc.Animations:AddButton("DaHood Animation", function()
    local Char = game.Players.LocalPlayer.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    
    for i,v in next, Hum:GetPlayingAnimationTracks() do
        v:Stop()
    end
    wait(1)
    local Animate = game.Players.LocalPlayer.Character.Animate
    Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=3119980985"
    Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=3119980985"
    Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=707897309"
    Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=2791325054"
    Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=707853694"
    Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=3135793091"
    Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=2791328524"
    game.Players.LocalPlayer.Character.Humanoid.Jump = true   
				end)
				
				Sections.Misc.Animations:AddButton("Bold Animation", function()
    local Char = game.Players.LocalPlayer.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    
    for i,v in next, Hum:GetPlayingAnimationTracks() do
        v:Stop()
    end
    wait(1)
    local Animate = game.Players.LocalPlayer.Character.Animate
    Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=16738333868"
    Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=16738334710"
    Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=16738340646"
    Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=16738337225"
    Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=16738336650"
    Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=16738332169"
    Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=16738333171"
game.Players.LocalPlayer.Character.Humanoid.Jump = true
				end)
				
				Sections.Misc.Animations:AddButton("Best Animation", function()
	local Char = game.Players.LocalPlayer.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    
    for i,v in next, Hum:GetPlayingAnimationTracks() do
        v:Stop()
    end
    wait(1)
    local Animate = game.Players.LocalPlayer.Character.Animate
    Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=4417977954"
    Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=4417978624"
    Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=707897309"
    Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=4417979645"
    Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=707853694"
    Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=3135793091"
    Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=2791328524"
    game.Players.LocalPlayer.Character.Humanoid.Jump = true   
    
				end)
				
				Sections.Misc.Animations:AddButton("Mega Animation", function()
    local Char = game.Players.LocalPlayer.Character
local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

for i,v in next, Hum:GetPlayingAnimationTracks() do
    v:Stop()
end
wait(1)
local Animate = game.Players.LocalPlayer.Character.Animate
Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=707742142"
Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=707855907"
Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=707897309"
Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=707861613"
Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=707853694"
Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=707826056"
Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=707829716"

game.Players.LocalPlayer.Character.Humanoid.Jump = true    
				end)
				
				Sections.Misc.Animations:AddButton("Levitation Animation", function()
local Char = game.Players.LocalPlayer.Character
local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

for i,v in next, Hum:GetPlayingAnimationTracks() do
    v:Stop()
end
wait(1)
local Animate = game.Players.LocalPlayer.Character.Animate
Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=616006778"
Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=616008087"
Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=616013216"
Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=616010382"
Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=616008936"
Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=616003713"
Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=616005863"
game.Players.LocalPlayer.Character.Humanoid.Jump = true  
				end)
				
				Sections.Misc.Animations:AddButton("JOJO Animation", function()
    local Char = game.Players.LocalPlayer.Character
local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

for i,v in next, Hum:GetPlayingAnimationTracks() do
    v:Stop()
end
wait(1)
local Animate = game.Players.LocalPlayer.Character.Animate
Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=1149612882"
Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=1149612882"
Animate.run.RunAnim.AnimationId = "rbxassetid://1150967949"
Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=1148863382"
Animate.walk.WalkAnim.AnimationId = "rbxassetid://657552124"
Animate.climb.ClimbAnim.AnimationId = "rbxassetid://658360781"
Animate.fall.FallAnim.AnimationId = "rbxassetid://1148863382"
Animate.swim.Swim.AnimationId = "rbxassetid://657560551"
Animate.swimidle.SwimIdle.AnimationId = "rbxassetid://657557095"
game.Players.LocalPlayer.Character.Humanoid.Jump = true    
				end)
				
				Sections.Misc.Animations:AddButton("Cool Animation", function()
local Char = game.Players.LocalPlayer.Character
local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

for i,v in next, Hum:GetPlayingAnimationTracks() do
v:Stop()
end
wait(1)
local Animate = game.Players.LocalPlayer.Character.Animate
Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=10921301576"
Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=10921302207"
Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=10921162768"
Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=10921157929"
Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=10921242013"
Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=10921229866"
Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=10921241244"
game.Players.LocalPlayer.Character.Humanoid.Jump = true
				end)
				
				Sections.Misc.Animations:AddButton("Zombie Animation", function()
local Char = game.Players.LocalPlayer.Character
local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

for i,v in next, Hum:GetPlayingAnimationTracks() do
    v:Stop()
end
wait(1)
local Animate = game.Players.LocalPlayer.Character.Animate
    Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=10921301576"
    Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=10921302207"
    Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=616168032"
    Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=616163682"
    Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=616161997"
    Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=616156119"
    Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=616157476"
    game.Players.LocalPlayer.Character.Humanoid.Jump = true
				end)
				
				Sections.Misc.Animations:AddButton("Cartoony Animation", function()
local Char = game.Players.LocalPlayer.Character
local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

for i,v in next, Hum:GetPlayingAnimationTracks() do
    v:Stop()
end
wait(1)
local Animate = game.Players.LocalPlayer.Character.Animate
    Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=742637544"
    Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=742638445"
    Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=742640026"
    Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=742638842"
    Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=742637942"
    Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=742636889"
    Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=742637151"
    game.Players.LocalPlayer.Character.Humanoid.Jump = true
				end)
				
				Sections.Misc.Animations:AddButton("Elder Animation", function()
    local Char = game.Players.LocalPlayer.Character
    local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
    
    for i,v in next, Hum:GetPlayingAnimationTracks() do
        v:Stop()
    end
    wait(1)
    local Animate = game.Players.LocalPlayer.Character.Animate
    Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=845397899"
    Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=845400520"
    Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=845403856"
    Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=845386501"
    Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=845398858"
    Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=845392038"
    Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=845396048"
    game.Players.LocalPlayer.Character.Humanoid.Jump = true
				end)
				
				Sections.Misc.Animations:AddButton("Ninja Animation", function()
local Char = game.Players.LocalPlayer.Character
local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

for i,v in next, Hum:GetPlayingAnimationTracks() do
    v:Stop()
end
wait(1)
local Animate = game.Players.LocalPlayer.Character.Animate
Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=10921301576"
Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=10921302207"
Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=656121766"
Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=656118852"
Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=656117878"
Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=656114359"
Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=656115606"
game.Players.LocalPlayer.Character.Humanoid.Jump = true
				end)
				
				Sections.Misc.Animations:AddButton("No Animation", function()
    local Char = game.Players.LocalPlayer.Character
local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

for i,v in next, Hum:GetPlayingAnimationTracks() do
    v:Stop()
end
wait(1)
local Animate = game.Players.LocalPlayer.Character.Animate
Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=1"
Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=1"
Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=1"
Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=1"
Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=1"
Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=1"
Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=1"
game.Players.LocalPlayer.Character.Humanoid.Jump = true
				end)
			end
        end
		
		--// Teleportation
		do
		
		
		    --// TeleportMap
		    do
		        Sections.TeleportMap.Teleport:AddButton("Uphill GunStore", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(481.3045959472656, 48.07050323486328, -620.1513671875)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Downhill GunStore", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-578.5796508789062, 8.314779281616211, -736.3884887695312)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Hood Fitness", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-76.4957275390625, 22.700284957885742, -630.9816284179688)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Bar", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-264.5504455566406, 48.52669143676758, -446.29254150390625)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Bank", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-432.1439208984375, 38.9649658203125, -284.1016540527344)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Safe 2", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-117, -57, 147)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Safe 3", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-546, 173, 1)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Safe 5", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0,150,0)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Safe For Test", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(11, 12, 214)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Da Furniture", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-489.1640319824219, 21.8498477935791, -76.60957336425781)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("School", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-531.3531494140625, 21.74999237060547, 252.47506713867188)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Da Casino", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-863.4664306640625, 21.59995460510254, -152.92788696289062)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Da Theatre", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-1004.9942626953125, 25.10002326965332, -135.17315673828125)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Basketball Court", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-896.5643310546875, 21.999818801879883, -528.7317504882812)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Hair Salon", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-855.55810546875, 22.005008697509766, -665.0170288085938)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Foods Mart", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-906.5833740234375, 22.005002975463867, -653.2225952148438)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Mat Laundry", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-971.4241333007812, 22.005887985229492, -630.115478515625)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Swift", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-799.7603149414062, 21.8799991607666, -662.3109741210938)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Military Base", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-50.412960052490234, 25.25499725341797, -868.921142578125)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Da Boxing Club", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-232.0669708251953, 22.067293167114258, -1119.9541015625)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Flowers", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-71.62272644042969, 23.15056800842285, -327.79412841796875)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Hospital", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(98.40196228027344, 22.799989700317383, -484.89385986328125)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Hood Kicks", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-203.53347778320312, 21.845796585083008, -410.1529846191406)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Police Station", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-265.4999694824219, 21.797977447509766, -96.51517486572266)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Barba", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(9.003872871398926, 21.74802017211914, -107.73101043701172)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Church", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(205.8213653564453, 23.77802085876465, -58.47077560424805)
				end)
				
				Sections.TeleportMap.Teleport:AddButton("Train", function()
				    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-426.41705322265625, -21.25197982788086, 44.953758239746094)
				end)
			end
		end

        --// Settings Tab
        do
            local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")

            Library.KeybindFrame.Visible = true

            MenuGroup:AddToggle("KeybindsListEnabled", {
                Text = "Keybinds List",
                Default = true,
                Tooltip = nil,
            })

            Toggles.KeybindsListEnabled:OnChanged(function()
                Library.KeybindFrame.Visible = Toggles.KeybindsListEnabled.Value
            end)

            MenuGroup:AddButton("Unload", function() Library:Unload() end)
            MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "End", NoUI = true, Text = "Menu keybind" })
            Library.ToggleKeybind = Options.MenuKeybind

            ThemeManager:SetLibrary(Library)
            SaveManager:SetLibrary(Library)

            ThemeManager:SetFolder("Azure")
            SaveManager:SetFolder("Azure/Hood")

            SaveManager:BuildConfigSection(Tabs.Settings)
            ThemeManager:ApplyToTab(Tabs.Settings)
        end
    end
end

load()
