"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NewCompAspectRatio = void 0;
const jsx_runtime_1 = require("react/jsx-runtime");
const new_comp_layout_1 = require("./new-comp-layout");
const render_aspect_ratio_1 = require("./render-aspect-ratio");
const ToggleAspectRatio_1 = require("./ToggleAspectRatio");
const GUIDE_HEIGHT = 55;
const GUIDE_WIDTH = 10;
const container = {
    display: 'flex',
    flexDirection: 'row',
    marginLeft: 10,
    alignItems: 'center',
};
const NewCompAspectRatio = ({ width, height, aspectRatioLocked, setAspectRatioLocked }) => {
    const pixels = Number(width) * Number(height);
    return ((0, jsx_runtime_1.jsx)("div", { children: (0, jsx_runtime_1.jsxs)("div", { style: container, children: [(0, jsx_runtime_1.jsx)("svg", { width: GUIDE_WIDTH, height: GUIDE_HEIGHT, children: (0, jsx_runtime_1.jsx)("path", { d: `M 0 0 L ${GUIDE_WIDTH} 0 L ${GUIDE_WIDTH} ${GUIDE_HEIGHT} L 0 ${GUIDE_HEIGHT}`, fill: "transparent", strokeWidth: "2", stroke: "rgba(255, 255, 255, 0.2)" }) }), (0, jsx_runtime_1.jsx)(ToggleAspectRatio_1.ToggleAspectRatio, { aspectRatioLocked: Boolean(aspectRatioLocked), setAspectRatioLocked: setAspectRatioLocked }), pixels > 0 ? ((0, jsx_runtime_1.jsxs)("div", { style: new_comp_layout_1.rightLabel, children: ["Aspect ratio ", (0, render_aspect_ratio_1.aspectRatio)(Number(width), Number(height))] })) : null] }) }));
};
exports.NewCompAspectRatio = NewCompAspectRatio;
