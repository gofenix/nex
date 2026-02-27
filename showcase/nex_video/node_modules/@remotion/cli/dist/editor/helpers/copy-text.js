"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.copyText = void 0;
const copyText = (cmd) => {
    const permissionName = 'clipboard-write';
    navigator.permissions
        .query({ name: permissionName })
        .then((result) => {
        if (result.state === 'granted' || result.state === 'prompt') {
            navigator.clipboard.writeText(cmd);
        }
    })
        .catch((err) => {
        // eslint-disable-next-line no-alert
        alert('Could not copy:' + err);
    });
};
exports.copyText = copyText;
