"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getBundleMode = exports.setBundleMode = void 0;
let bundleMode = {
    type: 'index',
};
const setBundleMode = (state) => {
    bundleMode = state;
};
exports.setBundleMode = setBundleMode;
const getBundleMode = () => {
    return bundleMode;
};
exports.getBundleMode = getBundleMode;
