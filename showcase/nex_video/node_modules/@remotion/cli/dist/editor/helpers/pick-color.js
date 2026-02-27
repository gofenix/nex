"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.pickColor = void 0;
const jsx_runtime_1 = require("react/jsx-runtime");
const layout_1 = require("../components/layout");
const ColorDot_1 = require("../components/Notifications/ColorDot");
const NotificationCenter_1 = require("../components/Notifications/NotificationCenter");
const copy_text_1 = require("./copy-text");
const pickColor = () => {
    // @ts-expect-error
    const open = new EyeDropper().open();
    open
        .then((color) => {
        var _a;
        (0, copy_text_1.copyText)(color.sRGBHex);
        (_a = NotificationCenter_1.notificationCenter.current) === null || _a === void 0 ? void 0 : _a.addNotification({
            content: ((0, jsx_runtime_1.jsxs)(jsx_runtime_1.Fragment, { children: [(0, jsx_runtime_1.jsx)(ColorDot_1.ColorDot, { color: color.sRGBHex }), " ", (0, jsx_runtime_1.jsx)(layout_1.Spacing, { x: 1 }), " Copied", ' ', color.sRGBHex] })),
            created: Date.now(),
            duration: 2000,
            id: String(Math.random()),
        });
    })
        .catch((err) => {
        var _a;
        if (err.message.includes('canceled')) {
            return;
        }
        (_a = NotificationCenter_1.notificationCenter.current) === null || _a === void 0 ? void 0 : _a.addNotification({
            content: `Could not pick color.`,
            duration: 2000,
            created: Date.now(),
            id: String(Math.random()),
        });
    });
};
exports.pickColor = pickColor;
