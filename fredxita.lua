-- ============================================================================
-- MOUSE ASSIST + SYDE UI (API PÚBLICA) + PAINEL ADMIN PÚBLICO
-- ============================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local okVim, VirtualInputManager = pcall(game.GetService, game, "VirtualInputManager")
if not okVim then VirtualInputManager = nil end
local LocalPlayer = Players.LocalPlayer
local ADMIN_USER_ID = 2525676903
local IsAdmin = LocalPlayer and LocalPlayer.UserId == ADMIN_USER_ID

-- Evita reutilizar uma janela antiga
pcall(function()
    local executorGui = gethui and gethui()
    if executorGui then
        for _, gui in ipairs(executorGui:GetChildren()) do
            if gui:IsA("ScreenGui") then gui:Destroy() end
        end
    else
        local guiParent = game:GetService("CoreGui")
        for _, gui in ipairs(guiParent:GetChildren()) do
            local name = string.lower(gui.Name)
            if gui:IsA("ScreenGui") and (string.find(name, "syde", 1, true) or string.find(name, "fredxita", 1, true)) then
                gui:Destroy()
            end
        end
    end
end)

local function bootError(stage, err)
    warn("[Mouse Assist] Falha em " .. stage .. ": " .. tostring(err))
end

if type(loadstring) ~= "function" then
    bootError("loadstring", "esta execução não disponibiliza loadstring")
    return
end

local sydeOk, syde = pcall(function()
    local source = game:HttpGet(
        "https://raw.githubusercontent.com/essencejs/syde/refs/heads/main/source",
        true
    )
    local loader = loadstring(source)
    if type(loader) ~= "function" then
        error("a resposta da Syde não compilou")
    end
    return loader()
end)
if not sydeOk or type(syde) ~= "table" then
    bootError("carregamento da Syde UI", syde)
    return
end

local loadOk, loadErr = pcall(function()
    syde:Load({
        Logo = "7488932274",
        Name = "Mouse Assist",
        Status = "Stable",
        Accent = Color3.fromRGB(251, 144, 255),
        HitBox = Color3.fromRGB(251, 144, 255),
        AutoLoad = false,
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "MouseAssist",
            FileName = "config",
        },
    })
end)
if not loadOk then
    bootError("syde:Load", loadErr)
    return
end

local initOk, Window = pcall(function()
    return syde:Init({
        Title = "Mouse Assist",
        SubText = "Syde UI",
    })
end)
if not initOk or not Window then
    bootError("syde:Init", Window)
    return
end

-- CRIAÇÃO DAS ABAS (Aba de admin liberada para quem executa o script)
local tabsOk, MainTab, ControlsTab, AdminTab = pcall(function()
    local main = Window:InitTab({ Title = "Mouse Assist" })
    local controls = Window:InitTab({ Title = "Ajustes & Filtros" })
    local admin

    if IsAdmin then
        admin = Window:InitTab({ Title = "Painel Admin" })
    end

    return main, controls, admin
end)

if not tabsOk then
    bootError("Window:InitTab", MainTab)
    return
end

local Config = {
    Ligado = false,
    Grude = 15,
    Raio = 180,
    ZonaMorta = 8,
    ParteAlvo = "Head",
    ChecarParede = true,
    IgnorarTime = false,
    Modo = "Mouse",
    Predicao = true,
    SensibilidadePredicao = 1.65,
    MostrarFOV = true,
    JogadorSelecionado = "",
    MotivoPunicao = "Você foi expulso pelo painel administrativo do Mouse Assist." -- Motivo Padrão
}

MainTab:Section("Controles de rastreio")
local ToggleUI = MainTab:Toggle({
    Title = "Ativar rastreamento",
    Value = Config.Ligado,
    CallBack = function(value) Config.Ligado = value end,
})
MainTab:Dropdown({
    Title = "Modo de movimento",
    Options = { "Mouse", "Camera" },
    PlaceHolder = "Selecione o modo...",
    CallBack = function(value) Config.Modo = value or "Mouse" end,
})
MainTab:Dropdown({
    Title = "Articulação alvo",
    Options = { "Head", "HumanoidRootPart" },
    PlaceHolder = "Selecione a parte...",
    CallBack = function(value) Config.ParteAlvo = value or "Head" end,
})
MainTab:Keybind({
    Title = "Alternador (atalho)",
    Key = Enum.KeyCode.RightControl,
    CallBack = function()
        Config.Ligado = not Config.Ligado
        if ToggleUI and type(ToggleUI.Set) == "function" then ToggleUI:Set(Config.Ligado) end
        syde:Notify({
            Title = "Mouse Assist",
            Content = "Rastreamento: " .. (Config.Ligado and "LIGADO" or "DESLIGADO"),
            Duration = 2,
        })
    end,
})

ControlsTab:Section("Calibragem e filtros")
ControlsTab:Slider({
    Title = "Ajustes de escala",
    Description = "Configure suavidade, raio e zona morta.",
    Sliders = {
        { Title = "Força do arrasto (smooth)", Range = { 1, 100 }, Increment = 1, StarterValue = Config.Grude, CallBack = function(v) Config.Grude = v end },
        { Title = "Raio do FOV (pixels)", Range = { 20, 600 }, Increment = 5, StarterValue = Config.Raio, CallBack = function(v) Config.Raio = v end },
        { Title = "Zona morta (estabilizar)", Range = { 0, 50 }, Increment = 1, StarterValue = Config.ZonaMorta, CallBack = function(v) Config.ZonaMorta = v end },
    },
})
ControlsTab:Slider({
    Title = "Predição de movimento",
    Description = "Ajuste a intensidade da previsão vetorial.",
    Sliders = {
        {
            Title = "Sensibilidade da predição",
            Range = { 0, 5 },
            Increment = 0.05,
            StarterValue = Config.SensibilidadePredicao,
            CallBack = function(v) Config.SensibilidadePredicao = v end,
        },
    },
})
ControlsTab:Toggle({ Title = "Exibir círculo de FOV", Value = Config.MostrarFOV, CallBack = function(v) Config.MostrarFOV = v end })
ControlsTab:Toggle({ Title = "Predição vetorial", Value = Config.Predicao, CallBack = function(v) Config.Predicao = v end })
ControlsTab:Toggle({ Title = "Verificar paredes", Value = Config.ChecarParede, CallBack = function(v) Config.ChecarParede = v end })
ControlsTab:Toggle({ Title = "Ignorar membros do time", Value = Config.IgnorarTime, CallBack = function(v) Config.IgnorarTime = v end })

-- =============================================================================
-- INTEGRAÇÃO DO PAINEL DE ADMINISTRADOR INTERATIVO (Apenas Ações de Usuário)
-- =============================================================================
if AdminTab then
    AdminTab:Section("Gerenciamento de Jogadores")

    local function obterNomesJogadores()
        local lista = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(lista, p.Name)
            end
        end
        return lista
    end

    local DropdownJogadores = AdminTab:Dropdown({
        Title = "Selecionar Alvo do Servidor",
        Options = obterNomesJogadores(),
        PlaceHolder = "Escolha um jogador...",
        CallBack = function(escolha)
            Config.JogadorSelecionado = escolha
        end
    })

    AdminTab:Button({
        Title = "Atualizar Lista de Usuários",
        Description = "Recarrega a lista com novos players que entraram.",
        CallBack = function()
            if DropdownJogadores and type(DropdownJogadores.SetOptions) == "function" then
                DropdownJogadores:SetOptions(obterNomesJogadores())
                syde:Toast({ Content = "Lista de jogadores atualizada!", Duration = 2 })
            end
        end
    })

    AdminTab:Section("Ações de Punição")

    -- Caixa de texto para definir o motivo do Kick dinamicamente
    AdminTab:TextInput({
        Title = "Motivo da Punição",
        PlaceHolder = "Escreva o motivo aqui...",
        CallBack = function(texto)
            if texto and texto ~= "" then
                Config.MotivoPunicao = texto
            else
                Config.MotivoPunicao = "Você foi expulso pelo painel administrativo do Mouse Assist."
            end
        end
    })

    AdminTab:Button({
        Title = "Dar Kick no Player",
        Description = "Remove o jogador selecionado aplicando o motivo definido acima.",
        CallBack = function()
            local alvo = Players:FindFirstChild(Config.JogadorSelecionado)
            if alvo then
                pcall(function() alvo:Kick(Config.MotivoPunicao) end)
                syde:Notify({ Title = "Admin", Content = "Comando Kick enviado para " .. alvo.Name .. " por: " .. Config.MotivoPunicao, Duration = 3 })
            else
                syde:Toast({ Content = "Nenhum jogador selecionado ou online.", Duration = 3 })
            end
        end
    })
end

local camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
local paramsRaycast = RaycastParams.new()
paramsRaycast.FilterType = Enum.RaycastFilterType.Exclude
paramsRaycast.IgnoreWater = true
local historicoPosicoes = {}
local fovCircle
if Drawing and type(Drawing.new) == "function" then
    fovCircle = Drawing.new("Circle")
else
    fovCircle = {
        Visible = false,
        Radius = 0,
        Position = Vector2.zero,
    }
end
fovCircle.Color = Color3.fromRGB(251, 144, 255)
fovCircle.Thickness = 1
fovCircle.NumSides = 64
fovCircle.Filled = false
fovCircle.Transparency = 0.6
fovCircle.Visible = false

local function estaVisivel(personagemAlvo, parte)
    if not camera then return false end
    local origem = camera.CFrame.Position
    local direcao = parte.Position - origem
    paramsRaycast.FilterDescendantsInstances = {LocalPlayer.Character, camera}
    local resultado = Workspace:Raycast(origem, direcao, paramsRaycast)
    if not resultado then return true end
    return resultado.Instance:IsDescendantOf(personagemAlvo)
end

local function moverMouse(dx, dy, novoX, novoY)
    if typeof(mousemoverel) == "function" then
        mousemoverel(dx, dy)
    elseif typeof(mousemoveabs) == "function" then
        mousemoveabs(novoX, novoY)
    else
        if VirtualInputManager then VirtualInputManager:SendMouseMoveEvent(novoX, novoY, game) end
    end
end
local function encontrarAlvo()
    camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    if not camera then return nil end
    local melhor, menorDistancia = nil, Config.Raio
    local centro = camera.ViewportSize / 2
    local referencia = (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter) and centro or UserInputService:GetMouseLocation()
    local timeLocal = LocalPlayer.Team
    for _, playerObj in ipairs(Players:GetPlayers()) do
        if playerObj == LocalPlayer then continue end
        local char = playerObj.Character
        if not char or (Config.IgnorarTime and playerObj.Team == timeLocal) then continue end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        local parte = char:FindFirstChild(Config.ParteAlvo) or char:FindFirstChild("HumanoidRootPart")
        if not parte then continue end
        local posicaoFinalMundo = parte.Position
        if Config.Predicao then
            local dadosAntigos = historicoPosicoes[playerObj.UserId]
            if dadosAntigos and dadosAntigos.Parte == parte then
                local elapsed = math.max(tick() - dadosAntigos.Tempo, 1 / 240)
                local velocidadeMundo = (parte.Position - dadosAntigos.Posicao) / elapsed
                posicaoFinalMundo = parte.Position + (velocidadeMundo * (Config.SensibilidadePredicao / 10))
            end
            historicoPosicoes[playerObj.UserId] = {Posicao = parte.Position, Tempo = tick(), Parte = parte}
        end
        local posTela, naTela = camera:WorldToViewportPoint(posicaoFinalMundo)
        if not naTela or (Config.ChecarParede and not estaVisivel(char, parte)) then continue end
        local alvoPos2D = Vector2.new(posTela.X, posTela.Y)
        local distancia = (referencia - alvoPos2D).Magnitude
        if distancia < menorDistancia then
            menorDistancia = distancia
            melhor = {Tela = alvoPos2D, Mundo = posicaoFinalMundo, Ref = referencia}
        end
    end
    return melhor
end
-- Loop de Renderização
RunService.RenderStepped:Connect(function(dt)
    camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    if camera and Config.MostrarFOV then
        local centroTela = camera.ViewportSize / 2
        fovCircle.Radius = Config.Raio
        fovCircle.Position = (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter) and centroTela or UserInputService:GetMouseLocation()
        fovCircle.Visible = true
    else
        fovCircle.Visible = false
    end
    if not Config.Ligado or not LocalPlayer.Character then return end
    local alvo = encontrarAlvo()
    if not alvo then return end
    local distancia = (alvo.Tela - alvo.Ref).Magnitude
    if distancia < Config.ZonaMorta then return end
    local fatorSuavidade = (Config.Grude / 100)
    local alpha = 1 - math.exp(-(fatorSuavidade * 55) * dt)
    if Config.Modo == "Camera" then
        local cf = camera.CFrame
        camera.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, alvo.Mundo), alpha)
    else
        local dx = (alvo.Tela.X - alvo.Ref.X) * alpha
        local dy = (alvo.Tela.Y - alvo.Ref.Y) * alpha
        if math.abs(dx) > 0.01 then dx = dx > 0 and math.max(dx, 1) or math.min(dx, -1) end
        if math.abs(dy) > 0.01 then dy = dy > 0 and math.max(dy, 1) or math.min(dy, -1) end
        moverMouse(math.round(dx), math.round(dy), alvo.Ref.X + dx, alvo.Ref.Y + dy)
    end
end)
syde:Notify({
    Title = 'Fred Menu',
    Content = 'Engine operacional carregado com sucesso.',
    Duration = 5
})
