Config = {}

Config.Levels = {
    { level = 1, minXP = 0,   maxXP = 200 },
    { level = 2, minXP = 200, maxXP = 500 },
    { level = 3, minXP = 500, maxXP = 1000 },
    { level = 4, minXP = 1000, maxXP = 2000 },
    { level = 5, minXP = 2000, maxXP = 5000 },
    { level = 6, minXP = 5000, maxXP = 10000 }
}

Config.Jobs = {
    Miner = {
        job = { enabled = true, jobName = 'miner' },
        Points = {
            ['Clock In/Out'] = {
                coords = vec4(2746.13, 2787.89, 35.55, 32.00),
                ped = 's_m_y_construct_01'
            },
            ['Work Points'] = {
                {
                    object = { enabled = true, model = 'prop_rock_3_b' },
                    coords = vec4(2991.1621, 2753.0781, 42.1565, 166.8611),
                    Interact = 'Mine Stone',
                    label = 'Mining..',
                    description = 'Mining ores from the ground',
                    icon = 'fa-solid fa-hammer',
                    position = 'bottom',
                    duration = 10000,
                    useWhileDead = false,
                    canCancel = true,
                    disable = { car = true, move = true, combat = true },
                    anim = { dict = 'melee@hatchet@streamed_core', clip = 'plyr_rear_takedown_b', flag = 1 },
                    prop = { bone = 28422, model = 'prop_tool_pickaxe', pos = vec3(0.09, -0.05, -0.02), rot = vec3(-78.0, 13.0, 28.0) }
                },
                {
                    object = { enabled = true, model = 'prop_rock_3_c' },
                    coords = vec4(2997.0486, 2751.5938, 44.0109, 218.2450),
                    Interact = 'Mine Stone',
                    label = 'Mining..',
                    description = 'Mining ores from the ground',
                    icon = 'fa-solid fa-hammer',
                    position = 'bottom',
                    duration = 10000,
                    useWhileDead = false,
                    canCancel = true,
                    disable = { car = true, move = true, combat = true },
                    anim = { dict = 'melee@hatchet@streamed_core', clip = 'plyr_rear_takedown_b', flag = 1 },
                    prop = { bone = 28422, model = 'prop_tool_pickaxe', pos = vec3(0.09, -0.05, -0.02), rot = vec3(-78.0, 13.0, 28.0) }
                }
            }
        },
        WhenPointDone = function(playerId, pointIndex, xp)
            local newXP = xp:Add(10) 

            print(("Player %s earned XP, now has %s"):format(playerId, newXP))
            Notify(playerId, "XP Gained", ("You earned 10 XP! Total: %s"):format(newXP), "fa-solid fa-star", "success")
        end,
        WhenAllDone = function(playerId) 
            
        end
    },

    Delivery = {
        job = { enabled = false, jobName = 'delivery' },
        Points = {
            ['Clock In/Out'] = {
                coords = vec4(896.00, -896.33, 27.80, 91.65),
                ped = 's_m_m_postal_01'
            },
            ['Work Points'] = {
                {
                    object = { enabled = false, model = 'prop_box_wood02a' },
                    coords = vec4(845.41, -893.76, 25.25, 83.85),
                    Interact = 'Deliver Package',
                    label = 'Delivering Package..',
                    description = 'Picking up delivery package',
                    icon = 'fa-solid fa-box',
                    position = 'bottom',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { car = true, move = true, combat = true },
                    anim = { dict = 'anim@heists@box_carry@', clip = 'idle', flag = 1 }
                }
            }
        },
        WhenPointDone = function(playerId, pointIndex, xp)
            local newXP = xp:Add(10) 
            
            print(("Player %s earned XP, now has %s"):format(playerId, newXP))
            Notify(playerId, "XP Gained", ("You earned 10 XP! Total: %s"):format(newXP), "fa-solid fa-star", "success")
        end,
        WhenAllDone = function(playerId) 
            
        end
    }
}

function Notify(playerId, title, description, icon, type)
    TriggerClientEvent('ox_lib:notify', playerId, {
        title = title,
        description = description or '',
        icon = icon or '',
        type = type or 'info'
    })
end
