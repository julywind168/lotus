local skynet = require "skynet"
require "skynet.manager"


skynet.start(function()
    math.randomseed(tonumber(tostring(os.time()):reverse()))
    skynet.error("=============================================")
    skynet.error("lotus start")
    skynet.error("=============================================")

    if not skynet.getenv "daemon" then
        skynet.newservice("console")
    end

    skynet.exit()
end)