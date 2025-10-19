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

Talisman.config_tab = function()
    local tal_nodes = {{
        n = G.UIT.R,
        config = { align = "cm" },
        nodes = {
            { n = G.UIT.O, config = { object = DynaText({ string = localize("talisman_string_A"), colours = { G.C.WHITE }, shadow = true, scale = 0.4 }) } },
        }
    }, create_toggle({
        label = localize("talisman_string_B"),
        ref_table = Talisman.config_file,
        ref_value = "disable_anims",
        callback = function(_set_toggle)
            nativefs.write(Talisman.mod_path .. "/config.lua", STR_PACK(Talisman.config_file))
        end
    }),
        create_option_cycle({
            label = localize("talisman_string_C"),
            scale = 0.8,
            w = 6,
            options = { localize("talisman_vanilla"), localize("talisman_omeganum") .. "(e10##1000)" },
            opt_callback = 'talisman_upd_score_opt',
            current_option = Talisman.config_file.score_opt_id,
        })
    }
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
        nodes = tal_nodes
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

G.FUNCS.talisman_upd_score_opt = function(e)
    Talisman.config_file.score_opt_id = e.to_key
    local score_opts = { "", "omeganum" }
    Talisman.config_file.break_infinity = score_opts[e.to_key]
    nativefs.write(Talisman.mod_path .. "/config.lua", STR_PACK(Talisman.config_file))
end
