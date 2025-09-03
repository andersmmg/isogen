function init(plugin)
    plugin:newCommand{
        id = "isogen",
        title = "IsoGen",
        group = "edit_insert",
        onclick = function()
            local pluginScript = dofile(app.fs.joinPath(app.fs.userConfigPath, "extensions", "isogen", "IsoGen.lua"))
            pluginScript.showDialog()
        end
    }
end
