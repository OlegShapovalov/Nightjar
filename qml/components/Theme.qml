import QtQuick

Item {
    id: theme

    // 0: Nightjar Dark, 1: Catppuccin Mocha, 2: Dracula, 3: Monokai Pro, 4: Clean Light, 5: System
    property int currentTheme: 0
    property string fontFamily: "monospace"

    property SystemPalette sysPal: SystemPalette { colorGroup: SystemPalette.Active }

    readonly property color bgApp: {
        switch (currentTheme) {
            case 1: return "#1e1e2e";
            case 2: return "#282a36";
            case 3: return "#2d2a2e";
            case 4: return "#f4f4f5";
            case 5: return sysPal.window;
            default: return "#18181b";
        }
    }

    readonly property color bgSurface: {
        switch (currentTheme) {
            case 1: return "#181825";
            case 2: return "#21222c";
            case 3: return "#221f22";
            case 4: return "#ffffff";
            case 5: return sysPal.base;
            default: return "#1f1f23";
        }
    }

    readonly property color bgInput: {
        switch (currentTheme) {
            case 1: return "#313244";
            case 2: return "#44475a";
            case 3: return "#403e41";
            case 4: return "#e4e4e7";
            case 5: return sysPal.alternateBase;
            default: return "#27272a";
        }
    }

    readonly property color accent: {
        switch (currentTheme) {
            case 1: return "#89b4fa";
            case 2: return "#bd93f9";
            case 3: return "#ffd866";
            case 4: return "#2563eb";
            case 5: return sysPal.highlight;
            default: return "#3b82f6";
        }
    }

    readonly property color accentActive: {
        switch (currentTheme) {
            case 1: return "#b4befe";
            case 2: return "#ff79c6";
            case 3: return "#ff6188";
            case 4: return "#1d4ed8";
            case 5: return sysPal.highlight;
            default: return "#2563eb";
        }
    }

    readonly property color border: {
        switch (currentTheme) {
            case 1: return "#45475a";
            case 2: return "#6272a4";
            case 3: return "#49464e";
            case 4: return "#d4d4d8";
            case 5: return sysPal.mid;
            default: return "#27272a";
        }
    }

    readonly property color textPrimary: {
        switch (currentTheme) {
            case 1: return "#cdd6f4";
            case 2: return "#f8f8f2";
            case 3: return "#fcfcfa";
            case 4: return "#09090b";
            case 5: return sysPal.text;
            default: return "#f4f4f5";
        }
    }

    readonly property color textSecondary: {
        switch (currentTheme) {
            case 1: return "#a6adc8";
            case 2: return "#6272a4";
            case 3: return "#727072";
            case 4: return "#71717a";
            case 5: return sysPal.dark;
            default: return "#71717a";
        }
    }

    readonly property color dirColor: {
        switch (currentTheme) {
            case 1: return "#89dceb";
            case 2: return "#8be9fd";
            case 3: return "#78dce8";
            case 4: return "#0284c7";
            case 5: return sysPal.highlight;
            default: return "#60a5fa";
        }
    }

    readonly property color rowAlternate: {
        switch (currentTheme) {
            case 1: return "#11111b";
            case 2: return "#1e1f29";
            case 3: return "#19181a";
            case 4: return "#fafafa";
            case 5: return sysPal.window;
            default: return "#1f1f23";
        }
    }
}
