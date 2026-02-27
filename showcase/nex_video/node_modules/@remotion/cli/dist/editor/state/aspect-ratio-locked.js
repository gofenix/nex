"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadAspectRatioOption = exports.persistAspectRatioOption = void 0;
const aspectRatioLocalStorageKey = 'aspectRatio';
const persistAspectRatioOption = (option) => {
    localStorage.setItem(aspectRatioLocalStorageKey, String(option));
};
exports.persistAspectRatioOption = persistAspectRatioOption;
const loadAspectRatioOption = () => {
    const item = localStorage.getItem(aspectRatioLocalStorageKey);
    if (item === null) {
        return true;
    }
    return item !== 'false';
};
exports.loadAspectRatioOption = loadAspectRatioOption;
