-- Ficheiro: ~/.config/hypr/plugins.lua

if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    -- 1. Configurações Globais do Hyprglass
    hg.config({
        manage_window_blur = true, 
        default_theme = "dark",
        default_preset = "apple",
        tint_color = 0x8899aa22,

        brightness = 0.9,
        dark = { 
            brightness = 0.98,      
            contrast = 1.4,         
            saturation = 0.9,       
            vibrancy = 0.2, 
            adaptive_dim = 0.85,    
            tint_color = 0x00000066 
        },
        light = { adaptive_boost = 0.5 },

        layers = { enabled = 1 },
    })

    -- 2. Presets
    hg.preset("clear", {
        glass_opacity = 0.8,
        blur_strength = 1.0,
        dark = { brightness = 0.82 },
        light = { brightness = 1.2 },
    })

    hg.preset("contrasted", {
        inherits = "high_contrast",
        contrast = 1.2,
        adaptive_dim = 1.0,
        dark = { tint_color = 0x02142aa9 },
    })

    hg.preset("glass", {
        blur_strength = 2.0,
        blur_iterations = 3,
        chromatic_aberration = 0.8,
        fresnel_strength = 0.8,
        edge_thickness = 0.08,
        tint_color = 0x1111111F, -- Substituído por um Hex escuro transparente fixo (sem depender de variáveis externas)
        lens_distortion = 0.9,
        brightness = 1.0,
        contrast = 1.7,
        saturation = 1,
        vibrancy = 0.8,
        vibrancy_darkness = 1,
        adaptive_boost = 0.5
    })

    -- O Preset Apple agora está muito mais claro e transparente
    hg.preset("apple", {
        blur_strength        = 0.65,
        blur_iterations      = 2,
        
        refraction_strength  = 0.35,
        
        lens_distortion      = 0.18,
        
        fresnel_strength     = 0.60,
        
        chromatic_aberration = 0.85,
        
        specular_strength    = 0.60,
        
        edge_thickness       = 0.07,

    dark = {
        brightness   = 1.18,
        contrast     = 1.00,
        saturation   = 0.92,
        vibrancy     = 0.20,
        adaptive_dim = 0.0,
    },

    light = {
        brightness     = 1.08,
        contrast       = 1.00,
        saturation     = 0.95,
        vibrancy       = 0.10,
        adaptive_boost = 0.30,
    },
})
        -- O Preset Apple2
    hg.preset("apple-small", {

        blur_strength        = 0.45,
        blur_iterations      = 2,
        refraction_strength  = 0.80,
        lens_distortion      = 1.45,
        fresnel_strength     = 1.0,
        chromatic_aberration = 0.85,
        specular_strength    = 0.95,
        edge_thickness       = 0.05,
        vibrancy             = 0.15,

    dark = {
        brightness = 1.48,
        contrast = 0.92,
        saturation = 0.82,
        vibrancy = 0.30,
        adaptive_dim = 0.0,
    },

    light = {
        brightness = 1.10,
        contrast = 0.95,
        saturation = 0.88,
        vibrancy = 0.18,
        adaptive_boost = 0.35,
    }
})

    -- 3. Layer surfaces
    hg.layer("waybar", { preset = "subtle", mask_threshold = 0.05 })
    hg.layer("swaync-control-center", { preset = "apple" })
    hg.layer("swaync-notification-window", { preset = "apple" })
    hg.layer("tide-island", { preset = "apple-small" })
    hg.layer("quickshell", { preset = "apple-small" })
    hg.layer("quickshell:bezel", { preset = "ui", mask_threshold = 0.3 })
    hg.layer("debug-panel", { exclude = true })

    -- 4. Regras por Janela (Com controlo de opacidade forçado para o terminal)
    hl.window_rule({ match = { class = "mpv" }, tag = "+hyprglass_disabled"})
    hl.window_rule({ match = { fullscreen = true }, tag = "+hyprglass_disabled"})
    hl.window_rule({ match = { class = "firefox" }, tag = "+hyprglass_preset_high_contrast"})

    hl.window_rule({ match = { class = "kitty" }, tag = "+hyprglass_enabled" })
    hl.window_rule({ match = { class = "kitty" }, tag = "+hyprglass_preset_apple" })
    
    hl.window_rule({ match = { class = "vesktop" }, tag = "+hyprglass_enabled" })
    hl.window_rule({ match = { class = "vesktop" }, tag = "+hyprglass_preset_apple" })
    hl.window_rule({ match = { class = "vesktop" }, opacity = 0.85 })

    hl.window_rule({ match = { class = "discord" }, tag = "+hyprglass_enabled" })
    hl.window_rule({ match = { class = "discord" }, tag = "+hyprglass_preset_apple" })
    hl.window_rule({ match = { class = "discord" }, opacity = 0.85 })
end