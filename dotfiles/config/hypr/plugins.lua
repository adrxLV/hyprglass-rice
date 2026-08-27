---------------------------------------------------------------------
-- HyprExpo + GloView + Dynamic Cursors
---------------------------------------------------------------------

---------------------------------------------------------------------
-- HYPR EXPO
---------------------------------------------------------------------

hl.config({
    plugin = {
        hyprexpo = {
            -- Layout
            columns = 3,
            gaps_in = 12,
            gaps_out = 24,

            -- Fundo
            bg_col = "rgba(111111dd)",

            -- Workspace actual centrada
            workspace_method = "center current",

            -- Comportamento
            skip_empty = 0,
            gesture_distance = 220,
            cancel_key = "escape",
            show_cursor = 1,

            -- Tiles
            tile_rounding = 14,
            tile_rounding_power = 2.0,
            tile_rounding_focus = 16,
            tile_rounding_current = 16,
            tile_rounding_hover = 16,

            -- Borders
            border_width = 2,
            border_color = "rgba(ffffff20)",
            border_color_current = "rgb(ff3344)",
            border_color_focus = "rgb(ffffff)",
            border_color_hover = "rgba(ff3344cc)",

            -- Labels
            label_enable = 1,
            label_text_mode = "id",
            label_position = "top-right",
            label_show = "current+focus",

            label_color_default = "rgb(ffffff)",
            label_color_hover = "rgb(ffffff)",
            label_color_focus = "rgb(ffffff)",
            label_color_current = "rgb(ff3344)",

            label_font_size = 18,
            label_font_family = "JetBrains Mono",
            label_font_bold = 1,

            -- Fundo dos números
            label_bg_enable = 1,
            label_bg_color = "rgba(000000aa)",
            label_bg_shape = "rounded",
            label_bg_rounding = 8,
            label_padding = 7,

            -- Navegação por teclado
            keynav_enable = 1,
        },
    },
})


---------------------------------------------------------------------
-- HYPR EXPO — GESTO
---------------------------------------------------------------------

-- Swipe de 4 dedos para cima → abre o Expo
hl.plugin.hyprexpo.gesture({
    fingers = 4,
    direction = "up",
    action = "expo",
    scale = 1.0,
})


---------------------------------------------------------------------
-- GLOVIEW
---------------------------------------------------------------------

hl.config({
    plugin = {
        gloview = {
            -- Layout estilo Mission Control
            layout = "rows",

            gap = 28,
            padding = 60,
            padding_top = 30,
            padding_bottom = 60,

            max_scale = 1.0,

            -- Animações
            duration = 260,
            preview_round = 14,
            blur = 1,

            switch_animation = 1,
            switch_duration = 220,

            move_animation = 1,
            move_duration = 220,

            -- Strip de workspaces
            anchor = "top",
            strip_offset = 0,
            strip_height = 130,
            strip_margin = 18,
            strip_gap = 14,
            strip_card_round = 12,

            -- Interacção
            focus_follows_mouse = 1,
            scroll_switches_workspace = 1,
            passthrough_keys = 1,

            exit_on_click = 1,
            exit_on_switch = 0,

            -- Teclas
            key_close = "escape",
            key_next_workspace = "tab",
            key_prev_workspace = "shift+tab",
            key_activate = "enter",
            key_close_window = "d",

            -- Navegação Vim
            key_left = "h",
            key_right = "l",
            key_up = "k",
            key_down = "j",

            key_desktop = "shift",
            key_all_workspaces = "a",
            key_workspace = "1,2,3,4,5,6,7,8,9,0",

            -- Workspaces dinâmicas
            show_all_workspaces = 0,
            show_empty = 1,
            dynamic_workspaces = 1,
            autodelete_empty = 1,

            -- Labels
            show_workspace_labels = 1,
            show_window_labels = 1,
            show_special = 0,
            strip_all_card = 1,

            -- Drag & Drop
            drag_to_swap = 1,
            switch_on_drop = 0,
            switch_on_new_workspace = 1,

            -- Visual
            backdrop_color = 0xB8070A10,

            strip_band_color = 0x24FFFFFF,
            strip_card_color = 0x3A0E131C,
            strip_active_color = 0x4D1C2C44,

            strip_active_border = 0xF0FF3344,
            strip_active_border_size = 2,

            strip_hover_border = 0x80FF3344,
            strip_hover_border_size = 2,

            strip_plus_color = 0xD0EEF4FF,

            preview_bg = 0xFF14181F,
            shadow_color = 0x70000000,

            hover_border = 0xF0FF3344,
            hover_border_size = 3,

            select_border = 0xF0FF3344,
            select_border_size = 3,

            close_button_color = 0xE6E23B3B,

            -- Não esconder Waybar/notificações
            hide_top_layers = 0,
            hide_overlay_layers = 0,

            above_namespaces = "",

            debug_logs = 0,
        },
    },
})
---------------------------------------------------------------------
-- hypr-dynamic-cursors
-- https://github.com/VirtCode/hypr-dynamic-cursors
---------------------------------------------------------------------

if hl.plugin.dynamic_cursors then
    hl.config({
        plugin = {
            dynamic_cursors = {
                enabled = true,

                -- Stretch como comportamento principal
                mode = "stretch",

                -- Mantém a actualização suave
                threshold = 2,

                -----------------------------------------------------
                -- STRETCH
                -----------------------------------------------------

                stretch = {
                    -- Quanto MENOR, mais facilmente deforma.
                    -- 3000 = demasiado rápido para movimentos normais.
                    limit = 1200,

                    -- Mais agressivo e perceptível que quadratic.
                    activation = "negative_quadratic",

                    -- Um pouco menor para responder mais rapidamente
                    -- às mudanças de velocidade.
                    window = 70,
                },

                -----------------------------------------------------
                -- TILT
                -----------------------------------------------------

                tilt = {
                    -- Só será usado pelas shape rules abaixo.
                    limit = 3500,
                    activation = "negative_quadratic",
                    window = 80,
                    full = 45,
                },

                -----------------------------------------------------
                -- SHAKE TO FIND
                -----------------------------------------------------

                shake = {
                    enabled = true,

                    threshold = 6.0,

                    base = 4.0,
                    speed = 4.0,

                    influence = 0.0,

                    -- Sem limite máximo
                    limit = 0.0,

                    timeout = 1800,

                    -- O cursor continua com o efeito normal
                    -- enquanto está a fazer shake.
                    effects = false,

                    ipc = false,
                },

                -----------------------------------------------------
                -- HYPRCURSOR
                -----------------------------------------------------

                hyprcursor = {
                    enabled = true,

                    -- 1 = nearest quando não há imagem high-res
                    nearest = 1,

                    -- -1 = tamanho normal × shake:base
                    resolution = -1,

                    fallback = "clientside",
                },
            },
        },
    })


    -----------------------------------------------------------------
    -- TILT PARA CURSORES DE GRAB
    -----------------------------------------------------------------

    hl.plugin.dynamic_cursors.shape_rule({
        shape = "grab",

        mode = "tilt",

        tilt = {
            limit = 3000,
            activation = "negative_quadratic",
            window = 80,
            full = 45,
        },
    })

    hl.plugin.dynamic_cursors.shape_rule({
        shape = "grabbing",

        mode = "tilt",

        tilt = {
            limit = 3000,
            activation = "negative_quadratic",
            window = 80,
            full = 45,
        },
    })


    -----------------------------------------------------------------
    -- TEXT: STRETCH MAIS SUAVE
    -----------------------------------------------------------------

    hl.plugin.dynamic_cursors.shape_rule({
        shape = "text",

        mode = "stretch",

        stretch = {
            limit = 1600,
            activation = "quadratic",
            window = 80,
        },
    })
end

---------------------------------------------------------------------
-- KEYBINDS
---------------------------------------------------------------------

-- GloView
hl.bind("SUPER + TAB", hl.plugin.gloview.toggle)

-- HyprExp
hl.bind("SUPER + SHIFT + TAB", function()
    hl.plugin.hyprexpo.expo("toggle")
end)

-- GloView: desktop mode
hl.bind("SUPER + SHIFT + D", hl.plugin.gloview.desktop)

-- GloView: todas as workspaces
hl.bind("SUPER + CTRL + TAB", hl.plugin.gloview.allworkspaces)

-- GloView: workspace seguinte/anterior
hl.bind("SUPER + bracketright", hl.plugin.gloview.next)
hl.bind("SUPER + bracketleft", hl.plugin.gloview.prev)