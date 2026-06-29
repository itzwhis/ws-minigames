local RSGCore = exports['rsg-core']:GetCoreObject()

RegisterNetEvent('rsg-horsetrainer:server:tameSuccess', function(horseModel)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- حماية من التلاعب بالسيرفر (Exploits)
    if Player.PlayerData.job.name ~= "valhorsetrainer" then 
        print("محاولة تلاعب واختراق من لاعب لا يملك الوظيفة: " .. Player.PlayerData.name)
        return 
    end

    local citizenid = Player.PlayerData.citizenid
    local defaultHorseName = "Wild Tamed"

    -- إدخال الحصان في قاعدة بيانات الإسطبلات الخاصة بـ RSGCore
    MySQL.insert('INSERT INTO player_horses (citizenid, horse, name, state) VALUES (?, ?, ?, ?)', {
        citizenid,
        horseModel,
        defaultHorseName,
        1 -- متاح للاستدعاء داخل الإسطبل
    }, function(id)
        if id then
            TriggerClientEvent('RSGCore:Notify', src, 'تم تسجيل الحصان الجديد في إسطبلك بنجاح!', 'success')
        else
            TriggerClientEvent('RSGCore:Notify', src, 'حدث خطأ أثناء حفظ الحصان في قاعدة البيانات.', 'error')
        end
    end)
end)