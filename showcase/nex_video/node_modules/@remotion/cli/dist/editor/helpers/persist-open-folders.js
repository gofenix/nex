"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.loadExpandedFolders = exports.persistExpandedFolders = exports.openFolderKey = void 0;
const openFolderKey = (folderName, parentName) => {
    return [parentName !== null && parentName !== void 0 ? parentName : 'no-parent', folderName].join('/');
};
exports.openFolderKey = openFolderKey;
const localStorageKey = 'remotion.expandedFolders';
const persistExpandedFolders = (state) => {
    window.localStorage.setItem(localStorageKey, JSON.stringify(state));
};
exports.persistExpandedFolders = persistExpandedFolders;
const loadExpandedFolders = () => {
    const item = window.localStorage.getItem(localStorageKey);
    if (item === null) {
        return {};
    }
    return JSON.parse(item);
};
exports.loadExpandedFolders = loadExpandedFolders;
