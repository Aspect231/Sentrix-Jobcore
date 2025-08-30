local Players = {}

local function Notify(playerId, title, description, icon, type)
    TriggerClientEvent('ox_lib:notify', playerId, {
        title = title,
        description = description or '',
        icon = icon or '',
        type = type or 'info'
    })
end

local function GetJobByName(jobName)
    return Config.Jobs[jobName]
end

function GetLevelFromXP(xp)
    local levels = Config.Levels
    local highestLevel = levels[#levels]

    for _, levelData in ipairs(levels) do
        if xp >= levelData.minXP and xp < levelData.maxXP then
            local currentXP = xp
            local neededXP = levelData.maxXP 
            return levelData.level, currentXP, neededXP, false
        end
    end

    if xp >= highestLevel.maxXP then
        return highestLevel.level, highestLevel.maxXP - highestLevel.minXP, highestLevel.maxXP - highestLevel.minXP, true
    end

    return 1, 0, levels[1].maxXP, false
end

local XP = {}
XP.__index = XP

function XP:new(identifier, job)
    local self = setmetatable({ identifier = identifier, job = job, xp = 0}, XP)

    self:Load()
    return self
end

function XP:Load()
    local result = MySQL.single.await(
        'SELECT xp FROM jobcore_xp WHERE identifier = ? AND job = ?',
        { self.identifier, self.job }
    )

    if result then
        self.xp = result.xp
    else
        MySQL.insert.await(
            'INSERT INTO jobcore_xp (identifier, job, xp) VALUES (?, ?, 0)',
            { self.identifier, self.job }
        )
    end
end

function XP:Save()
    MySQL.update.await(
        'UPDATE jobcore_xp SET xp = ? WHERE identifier = ? AND job = ?',
        { self.xp, self.identifier, self.job }
    )
end

function XP:Add(amount)
    if amount > 0 then
        self.xp = self.xp + amount
        self:Save()
    end
    return self.xp
end

function XP:Remove(amount)
    if amount > 0 and self.xp > 0 then
        self.xp = math.max(0, self.xp - amount)
        self:Save()
    end
    return self.xp
end

function XP:Get()
    return self.xp
end

local PlayerJob = {}
PlayerJob.__index = PlayerJob

function PlayerJob:new(xPlayer, jobName, jobData)
    local self = setmetatable({}, PlayerJob)
    self.id = xPlayer.source
    self.identifier = xPlayer.identifier
    self.jobName = jobName
    self.jobData = jobData
    self.xp = XP:new(xPlayer.identifier, jobName)
    return self
end

local Manager = {}

function Manager:Add(xPlayer, jobName, jobData)
    Players[xPlayer.identifier] = PlayerJob:new(xPlayer, jobName, jobData)
    return Players[xPlayer.identifier]
end

function Manager:Remove(xPlayer)
    Players[xPlayer.identifier] = nil
end

function Manager:Get(xPlayer)
    return Players[xPlayer.identifier]
end

function Manager:IsClockedIn(xPlayer)
    return Players[xPlayer.identifier] ~= nil
end

lib.callback.register('sentrix_jobcore:request:config', function()
    return Config
end)

lib.callback.register('sentrix_jobcore:get:job', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.getJob() or nil
end)

lib.callback.register('sentrix_jobcore:toggle:clock:status', function(source, jobName, jobData)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    if Manager:IsClockedIn(xPlayer) then
        Manager:Remove(xPlayer)
        Notify(source, jobName, ("You have clocked Out as %s"):format(jobName), 'fa-solid fa-clock', 'success')
    else
        Manager:Add(xPlayer, jobName, jobData)
        Notify(source, jobName, ("You have clocked In as %s"):format(jobName), 'fa-solid fa-clock', 'success')
    end

    return Manager:IsClockedIn(xPlayer)
end)

lib.callback.register('sentrix_jobcore:check:clock:status', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and Manager:IsClockedIn(xPlayer) or false
end)

lib.callback.register('sentrix_jobcore:point:completed', function(source, pointIndex)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local playerData = Manager:Get(xPlayer)
    if not playerData then return end

    local job = GetJobByName(playerData.jobName)
    if job and job.WhenPointDone then
        job.WhenPointDone(source, pointIndex, playerData.xp) 
    end
end)

lib.callback.register('sentrix_jobcore:all:completed', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local playerData = Manager:Get(xPlayer)
    if not playerData then return end

    local job = GetJobByName(playerData.jobName)
    if job and job.WhenAllDone then
        job.WhenAllDone(source, playerData.xp)
    end
end)

lib.callback.register('sentrix_jobcore:request:xp', function(source, jobName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local playerData = Manager:Get(xPlayer)
    local xp = 0
    if playerData and playerData.jobName == jobName then
        xp = playerData.xp:Get()
    else
        local tempXP = XP:new(xPlayer.identifier, jobName)
        xp = tempXP:Get()
    end

    local level, currentXP, neededXP, maxed = GetLevelFromXP(xp)
    return {
        xp = xp,
        level = level,
        progress = currentXP,
        needed = neededXP,
        maxed = maxed
    }
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if Manager:IsClockedIn(xPlayer) then
        Manager:Remove(xPlayer)
    end
end)
