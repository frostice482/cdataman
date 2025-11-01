local nativefs = require("nativefs")

if not SMODS then
    local createOptionsRef = create_UIBox_options
    function create_UIBox_options()
        local contents = createOptionsRef()
        local m = UIBox_button({
            minw = 5,
            button = "talismanMenu",
            label = {
                "cdataman"
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

function Talisman.config_sections.type_compat_alert(nodes)
    for i,chk in ipairs(localize('tal_enable_compat_warning')) do
        table.insert(nodes, {
            n = G.UIT.R,
            config = { align = 'cm' },
            nodes = {{
                n = G.UIT.T,
                config = {
                    text = chk,
                    scale = 0.3,
                    colour = G.C.ORANGE
                }
            }}
        })
    end
end

Talisman.config_sections_array = {
    Talisman.config_sections.disable_anim,
    Talisman.config_sections.disable_omega,
    Talisman.config_sections.enable_type_compat,
    Talisman.config_sections.type_compat_alert,
}

Talisman.config_ui_base = {
    emboss = 0.05,
    minh = 6,
    r = 0.1,
    minw = 10,
    align = "cm",
    padding = 0.2,
    colour = G.C.BLACK
}

function Talisman.config_tab()
    local nodes = {}
    for i,v in ipairs(Talisman.config_sections_array) do
        local n = v(nodes)
        if n then
            table.insert(nodes, n)
        end
    end
    return {
        n = G.UIT.ROOT,
        config = Talisman.config_ui_base,
        nodes = nodes
    }
end

function Talisman.credits_tab()
    return {
        n = G.UIT.ROOT,
        config = Talisman.config_ui_base,
        nodes = {
            { n = G.UIT.R, nodes = {{ n = G.UIT.T, config = { text = "cdataman devs:", scale = 0.4 } }}, config = { padding = 0.1 } },
            { n = G.UIT.R, nodes = {{ n = G.UIT.T, config = { text = "- frostice482", scale = 0.4 } }} },

            { n = G.UIT.R, nodes = {{ n = G.UIT.T, config = { text = "Talisman devs:", scale = 0.4 } }}, config = { padding = 0.1 } },
            { n = G.UIT.R, nodes = {{ n = G.UIT.T, config = { text = "- MathIsFun_", scale = 0.4 } }} },
            { n = G.UIT.R, nodes = {{ n = G.UIT.T, config = { text = "- Mathguy24", scale = 0.4 } }} },
            { n = G.UIT.R, nodes = {{ n = G.UIT.T, config = { text = "- jenwalter666", scale = 0.4 } }} },
            { n = G.UIT.R, nodes = {{ n = G.UIT.T, config = { text = "- cg-223", scale = 0.4 } }} },
            { n = G.UIT.R, nodes = {{ n = G.UIT.T, config = { text = "- lord.ruby", scale = 0.4 } }} },
        }
    }
end

function G.FUNCS.talismanMenu(e)
    local tabs = create_tabs({
        snap_to_nav = true,
        tabs = {
            {
                label = "cdataman",
                chosen = true,
                tab_definition_function = Talisman.config_tab
            },
            {
                label = "Credits",
                tab_definition_function = Talisman.credits_tab
            }
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

G.UIDEF.tal_credits = Talisman.credits_tab
