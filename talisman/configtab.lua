local nativefs = require("nativefs")

if not SMODS or not JSON then
    local createOptionsRef = create_UIBox_options
    function create_UIBox_options()
        local contents = createOptionsRef()
        local m = UIBox_button({
            minw = 5,
            button = "talismanMenu",
            label = {
                localize({ type = "name_text", set = "Spectral", key = "c_talisman" })
            },
            colour = G.C.GOLD
        })
        table.insert(contents.nodes[1].nodes[1].nodes[1].nodes, m)
        return contents
    end
end

function Talisman.save_config()
    nativefs.write(Talisman.mod_path .. "/config.lua", STR_PACK(Talisman.config_file))
end

Talisman.config_sections = {}

function Talisman.config_sections.title()
    return {
        n = G.UIT.R,
        config = { align = "cm" },
        nodes = {
            { n = G.UIT.T, config = { text = localize("tal_feature_select"), scale = 0.4 } }
        }
    }
end

function Talisman.config_sections.disable_anim()
    return create_toggle({
        label = localize("tal_disable_anim"),
        ref_table = Talisman.config_file,
        ref_value = "disable_anims",
        callback = function()
            Talisman.save_config()
        end
    })
end

function Talisman.config_sections.disable_omega()
    return create_toggle({
        label = localize("tal_disable_omega"),
        ref_table = Talisman.config_file,
        ref_value = "disable_omega",
        callback = function(val)
            if val == false then
                require("talisman.break_inf")
            end
            Talisman.save_config()
        end
    })
end

function Talisman.config_sections.enable_type_compat()
    return create_toggle({
        label = localize("tal_enable_compat"),
        ref_table = Talisman.config_file,
        ref_value = "enable_compat",
        callback = function()
            Talisman.save_config()
        end
    })
end

--table.insert(Talisman.config_sections, Talisman.config_sections.title)
table.insert(Talisman.config_sections, Talisman.config_sections.disable_anim)
table.insert(Talisman.config_sections, Talisman.config_sections.disable_omega)
table.insert(Talisman.config_sections, Talisman.config_sections.enable_type_compat)

Talisman.config_tab = function()
    local nodes = {}
    for i,v in ipairs(Talisman.config_sections) do
        table.insert(nodes, v())
    end
    return {
        n = G.UIT.ROOT,
        config = {
            emboss = 0.05,
            minh = 6,
            r = 0.1,
            minw = 10,
            align = "cm",
            padding = 0.2,
            colour = G.C.BLACK
        },
        nodes = nodes
    }
end

G.FUNCS.talismanMenu = function(e)
    local tabs = create_tabs({
        snap_to_nav = true,
        tabs = {
            {
                label = localize({ type = "name_text", set = "Spectral", key = "c_talisman" }),
                chosen = true,
                tab_definition_function = Talisman.config_tab
            },
        }
    })
    G.FUNCS.overlay_menu {
        definition = create_UIBox_generic_options({
            back_func = "options",
            contents = { tabs }
        }),
        config = { offset = { x = 0, y = 10 } }
    }
end
