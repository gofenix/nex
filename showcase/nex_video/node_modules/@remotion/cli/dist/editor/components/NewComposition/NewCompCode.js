"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getNewCompositionCode = void 0;
const jsx_runtime_1 = require("react/jsx-runtime");
const strColor = '#9ECBFF';
const consColor = '#79B8FF';
const propColor = '#B392F0';
const keywordColor = '#F97583';
const cssReset = {
    fontFamily: 'monospace',
};
const makeProperty = (key, val, type, raw) => {
    if (raw) {
        return makePropertyRaw(key, val, type);
    }
    return [
        `  `,
        (0, jsx_runtime_1.jsx)("span", { style: { ...cssReset, color: propColor }, children: key }, key + 'key'),
        (0, jsx_runtime_1.jsx)("span", { style: { ...cssReset, color: keywordColor }, children: '=' }, key + 'equal'),
        type === 'string'
            ? [
                (0, jsx_runtime_1.jsxs)("span", { style: { ...cssReset, color: strColor }, children: ['"', val, '"'] }, key + 'value'),
            ]
            : [
                '{',
                (0, jsx_runtime_1.jsx)("span", { style: {
                        ...cssReset,
                        color: typeof val === 'number' ? consColor : strColor,
                    }, children: val }, key + 'value'),
                '}',
            ],
        (0, jsx_runtime_1.jsx)("br", {}, key + 'br'),
    ];
};
const makePropertyRaw = (key, val, type) => {
    return [
        `  `,
        key,
        '=',
        type === 'string' ? ['"' + val + '"'].join('') : ['{', val, '}'].join(''),
        '\n',
    ].join('');
};
const getNewCompositionCode = ({ type, height, width, fps, durationInFrames, name, raw, }) => {
    const compName = type === 'still' ? 'Still' : 'Composition';
    const props = [
        ...makeProperty('id', name, 'string', raw),
        ...makeProperty('component', name, 'const', raw),
        ...(type === 'composition'
            ? makeProperty('durationInFrames', durationInFrames, 'const', raw)
            : []),
        ...makeProperty('height', height, 'const', raw),
        ...makeProperty('width', width, 'const', raw),
        ...(type === 'composition' ? makeProperty('fps', fps, 'const', raw) : []),
    ];
    if (raw) {
        return ['<', compName, '\n', ...props, '/>'].join('');
    }
    return [
        `<`,
        (0, jsx_runtime_1.jsx)("span", { style: { ...cssReset, color: '#79B8FF' }, children: compName }, "compname"),
        (0, jsx_runtime_1.jsx)("br", {}, "linebr1"),
        ...props,
        '/>',
    ];
};
exports.getNewCompositionCode = getNewCompositionCode;
