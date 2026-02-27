"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getScale = exports.setScale = void 0;
let currentScale = 1;
const setScale = (newScale) => {
    if (typeof newScale !== 'number') {
        throw new Error('--scale flag must be a number.');
    }
    currentScale = newScale;
};
exports.setScale = setScale;
const getScale = () => {
    return currentScale;
};
exports.getScale = getScale;
