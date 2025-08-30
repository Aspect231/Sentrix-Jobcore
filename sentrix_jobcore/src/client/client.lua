local Config = lib.callback.await('sentrix_jobcore:request:config', false)

local Entity = {}
Entity.__index = Entity

function Entity:new(id, coords)
    local self = setmetatable({}, Entity)
    self.id     = id
    self.coords = coords
    return self
end

function Entity:getCoords()
    return self.coords
end

local WorkPoint = setmetatable({}, { __index = Entity })
WorkPoint.__index = WorkPoint

function WorkPoint:new(id, data, jobName)
    local self = setmetatable(Entity:new(id, data.coords), WorkPoint)
    self.interact    = data.Interact or "Work"
    self.label       = data.label or "Working..."
    self.duration    = data.duration or 5000
    self.description = data.description or "Performing work task"
    self.icon        = data.icon or 'fa-solid fa-hammer'
    self.position    = data.position or 'bottom'
    self.useWhileDead = data.useWhileDead or false
    self.canCancel   = data.canCancel ~= false
    self.disable     = data.disable or { car = true, move = true, combat = true }
    self.anim        = data.anim
    self.prop        = data.prop
    self.objectData  = data.object
    self.jobName     = jobName
    self.blip        = nil
    self.targetId    = nil
    self.object      = nil
    self.completed   = false
    return self
end

function WorkPoint:spawnObject()
    if self.objectData and self.objectData.enabled then
        local model = joaat(self.objectData.model)
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(0) end
        self.object = CreateObject(model, self.coords.x, self.coords.y, self.coords.z, false, false, false)
        SetEntityHeading(self.object, self.coords.w)
        FreezeEntityPosition(self.object, true)
    end
end

function WorkPoint:createBlip()
    self.blip = AddBlipForCoord(self.coords.x, self.coords.y, self.coords.z)
    SetBlipSprite(self.blip, 566)
    SetBlipDisplay(self.blip, 4)
    SetBlipScale(self.blip, 0.8)
    SetBlipColour(self.blip, 5)
    SetBlipAsShortRange(self.blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(self.interact)
    EndTextCommandSetBlipName(self.blip)
end

function WorkPoint:addTarget(onSelect)
    self.targetId = exports.ox_target:addSphereZone({
        coords = vec3(self.coords.x, self.coords.y, self.coords.z),
        radius = 1.5,
        options = {
            {
                name = 'workpoint_' .. self.jobName .. '_' .. self.id,
                icon = self.icon,
                label = self.interact,
                onSelect = function() onSelect(self) end
            }
        }
    })
end

function WorkPoint:remove()
    if self.targetId then
        exports.ox_target:removeZone(self.targetId)
        self.targetId = nil
    end
    if self.object and DoesEntityExist(self.object) then
        DeleteEntity(self.object)
        self.object = nil
    end
    if self.blip and DoesBlipExist(self.blip) then
        RemoveBlip(self.blip)
        self.blip = nil
    end
end

function WorkPoint:doWork(callback)
    if self.completed then return end

    if lib.progressBar({
        duration = 5000,
        label = self.label,
        description = self.description,
        icon = self.icon,
        position = self.position,
        useWhileDead = self.useWhileDead,
        canCancel = self.canCancel,
        disable = self.disable,
        anim = self.anim,
        prop = self.prop
    }) then
        self.completed = true
        self:remove()
        callback(true, self)
    else
        callback(false, self)
    end
end

local Job = {}
Job.__index = Job

function Job:new(name, data)
    local self = setmetatable({}, Job)
    self.name      = name
    self.data      = data
    self.workPoints = {}
    return self
end

function Job:spawnWorkPoints(onComplete)
    if not self.data.Points['Work Points'] then return end
    for i, wpData in pairs(self.data.Points['Work Points']) do
        local wp = WorkPoint:new(i, wpData, self.name)
        wp:spawnObject()
        wp:createBlip()
        wp:addTarget(function(point)
            point:doWork(function(success, obj)
                if success then
                    onComplete(point)
                end
            end)
        end)
        self.workPoints[i] = wp
    end
end

function Job:removeWorkPoints()
    for _, wp in pairs(self.workPoints) do
        wp:remove()
    end
    self.workPoints = {}
end

function Job:isComplete()
    local total, done = 0, 0
    for _, wp in pairs(self.workPoints) do
        total = total + 1
        if wp.completed then done = done + 1 end
    end
    return done >= total and total > 0
end

local JobCore = {}
JobCore.__index = JobCore

function JobCore:new()
    local self = setmetatable({}, JobCore)
    self.loadedPeds = {}
    self.currentJob = nil
    self.uiOpen = false
    return self
end

function JobCore:removePeds()
    for _, ped in pairs(self.loadedPeds) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
    self.loadedPeds = {}
end

function JobCore:initiatePeds()
    self:removePeds()
    local playerJob = lib.callback.await('sentrix_jobcore:get:job', false)

    for jobName, job in pairs(Config.Jobs) do
        if not job.job.enabled or (playerJob and playerJob.name == job.job.jobName) then
            for pointName, data in pairs(job.Points) do
                if pointName ~= 'Work Points' then
                    local model = joaat(data.ped)
                    RequestModel(model)
                    while not HasModelLoaded(model) do Wait(0) end

                    local ped = CreatePed(4, model, data.coords.x, data.coords.y, data.coords.z - 1.0, data.coords.w, false, true)
                    SetEntityInvincible(ped, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    FreezeEntityPosition(ped, true)

                    table.insert(self.loadedPeds, ped)

                    exports.ox_target:addLocalEntity(ped, {
                        {
                            name = 'jobcore:'..pointName,
                            icon = 'fa-solid fa-briefcase',
                            label = string.format('[%s] Talk to manager', jobName),
                            onSelect = function()
                                self:openClockMenu(jobName, job)
                            end
                        }
                    })
                end
            end
        end
    end
end

function JobCore:openClockMenu(jobName, jobData)
    if self and self.currentJob and self.currentJob.name ~= jobName then
        lib.notify({
            title = 'You are already busy with another job!',
            type = 'error'
        })
        return
    end
    
    local isClockedIn = lib.callback.await('sentrix_jobcore:check:clock:status', false, jobName)
    local xpData = lib.callback.await('sentrix_jobcore:request:xp', false, jobName)

    SendNUIMessage({
        action = 'openJobMenu',
        jobName = jobName,
        jobData = jobData,
        isClockedIn = isClockedIn,
        xpData = xpData
    })

    self.uiOpen = true
    SetNuiFocus(true, true)
end

function JobCore:startJob(jobName, jobData)
    self.currentJob = Job:new(jobName, jobData)
    self.currentJob:spawnWorkPoints(function(point)
        lib.callback.await('sentrix_jobcore:point:completed', false, point.id)
        if self.currentJob:isComplete() then
            lib.callback.await('sentrix_jobcore:all:completed', false)
        end
    end)
end

function JobCore:stopJob()
    if self.currentJob then
        self.currentJob:removeWorkPoints()
        self.currentJob = nil
    end
end

local Core = JobCore:new()

RegisterNUICallback('closeUI', function(data, cb)
    Core.uiOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('clockAction', function(data, cb)
    if data.action == 'clockIn' then
        local success = lib.callback.await('sentrix_jobcore:toggle:clock:status', false, data.jobName, data.jobData)
        if success then
            Core:startJob(data.jobName, data.jobData)
        end
    elseif data.action == 'clockOut' then
        lib.callback.await('sentrix_jobcore:toggle:clock:status', false, data.jobName, data.jobData)
        Core:stopJob()
    end
    cb('ok')
end)

RegisterNetEvent('esx:setJob', function(job)
    playerJob = job
    Core:initiatePeds()
end)

RegisterNetEvent('esx:setJob2', function(job2)
    playerJob2 = job2
    Core:initiatePeds()
end)

Citizen.CreateThread(function()
    Wait(1000)
    Core:initiatePeds()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    Core:removePeds()

    if Core.currentJob then
        Core.currentJob:removeWorkPoints()
    end
    
    if Core.uiOpen then
        SetNuiFocus(false, false)
    end
end)
