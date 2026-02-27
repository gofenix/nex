"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ToggleAspectRatio = void 0;
const jsx_runtime_1 = require("react/jsx-runtime");
const react_1 = require("react");
const colors_1 = require("../../helpers/colors");
const lock_1 = require("../../icons/lock");
const buttonStyle = {
    backgroundColor: colors_1.BACKGROUND,
    border: 'none',
    position: 'absolute',
    paddingLeft: 2,
    paddingRight: 2,
    marginLeft: 3,
};
const iconStyle = {
    width: 10,
    color: 'white',
};
const ToggleAspectRatio = ({ aspectRatioLocked, setAspectRatioLocked }) => {
    const onClick = (0, react_1.useCallback)(() => {
        setAspectRatioLocked(!aspectRatioLocked);
    }, [aspectRatioLocked, setAspectRatioLocked]);
    return ((0, jsx_runtime_1.jsx)("button", { type: "button", onClick: onClick, style: buttonStyle, children: aspectRatioLocked ? ((0, jsx_runtime_1.jsx)(lock_1.LockIcon, { style: iconStyle })) : ((0, jsx_runtime_1.jsx)(lock_1.UnlockIcon, { style: iconStyle })) }));
};
exports.ToggleAspectRatio = ToggleAspectRatio;
