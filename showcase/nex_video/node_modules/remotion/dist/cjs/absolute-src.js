"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAbsoluteSrc = void 0;
const getAbsoluteSrc = (relativeSrc) => {
    return new URL(relativeSrc, window.location.origin).href;
};
exports.getAbsoluteSrc = getAbsoluteSrc;
