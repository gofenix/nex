"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FolderContextProvider = exports.FolderContext = void 0;
const jsx_runtime_1 = require("react/jsx-runtime");
const react_1 = require("react");
const persist_open_folders_1 = require("../helpers/persist-open-folders");
exports.FolderContext = (0, react_1.createContext)({
    foldersExpanded: {},
    setFoldersExpanded: () => {
        throw new Error('default state');
    },
});
const FolderContextProvider = ({ children }) => {
    const [foldersExpanded, setFoldersExpanded] = (0, react_1.useState)((0, persist_open_folders_1.loadExpandedFolders)());
    const value = (0, react_1.useMemo)(() => {
        return {
            foldersExpanded,
            setFoldersExpanded,
        };
    }, [foldersExpanded]);
    return ((0, jsx_runtime_1.jsx)(exports.FolderContext.Provider, { value: value, children: children }));
};
exports.FolderContextProvider = FolderContextProvider;
