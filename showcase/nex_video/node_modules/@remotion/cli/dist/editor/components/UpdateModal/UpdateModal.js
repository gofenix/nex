"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpdateModal = void 0;
const jsx_runtime_1 = require("react/jsx-runtime");
const react_1 = require("react");
const colors_1 = require("../../helpers/colors");
const copy_text_1 = require("../../helpers/copy-text");
const modals_1 = require("../../state/modals");
const CopyButton_1 = require("../CopyButton");
const layout_1 = require("../layout");
const ModalContainer_1 = require("../ModalContainer");
const ModalHeader_1 = require("../ModalHeader");
const container = {
    padding: 20,
    paddingTop: 0,
};
const code = {
    background: colors_1.SELECTED_BACKGROUND,
    padding: '12px 10px',
    fontSize: 17,
    marginTop: 10,
    marginBottom: 10,
};
const link = {
    fontWeight: 'bold',
    color: 'inherit',
    textDecoration: 'none',
};
const commands = {
    npm: 'npm run upgrade',
    yarn: 'yarn upgrade',
    pnpm: 'pnpm run upgrade',
    unknown: 'npm run upgrade',
};
const UpdateModal = ({ info }) => {
    const { setSelectedModal } = (0, react_1.useContext)(modals_1.ModalsContext);
    const onQuit = (0, react_1.useCallback)(() => {
        setSelectedModal(null);
    }, [setSelectedModal]);
    const command = commands[info.packageManager];
    return ((0, jsx_runtime_1.jsxs)(ModalContainer_1.ModalContainer, { onOutsideClick: onQuit, onEscape: onQuit, children: [(0, jsx_runtime_1.jsx)(ModalHeader_1.NewCompHeader, { title: "Update available" }), (0, jsx_runtime_1.jsxs)("div", { style: container, children: [(0, jsx_runtime_1.jsx)("p", { children: "A new update for Remotion is available! Run the following command:" }), (0, jsx_runtime_1.jsxs)(layout_1.Row, { align: "center", children: [(0, jsx_runtime_1.jsx)(layout_1.Flex, { children: (0, jsx_runtime_1.jsx)("pre", { onClick: () => (0, copy_text_1.copyText)(command), style: code, children: command }) }), (0, jsx_runtime_1.jsx)(layout_1.Spacing, { x: 1 }), (0, jsx_runtime_1.jsx)(CopyButton_1.CopyButton, { textToCopy: command, label: "Copy command", labelWhenCopied: "Copied!" })] }), (0, jsx_runtime_1.jsxs)("p", { children: ["This will upgrade Remotion from ", info.currentVersion, " to", ' ', info.latestVersion, "."] }), (0, jsx_runtime_1.jsxs)("p", { children: ["Read the", ' ', (0, jsx_runtime_1.jsx)("a", { style: link, target: "_blank", href: "https://github.com/remotion-dev/remotion/releases", children: "Release notes" }), ' ', "to know what", "'s", " new in Remotion."] })] })] }));
};
exports.UpdateModal = UpdateModal;
