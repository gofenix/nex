"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.timelineStateReducer = void 0;
const timelineStateReducer = (state, action) => {
    if (action.type === 'collapse') {
        return {
            ...state,
            collapsed: {
                ...state.collapsed,
                [action.hash]: true,
            },
        };
    }
    if (action.type === 'expand') {
        return {
            ...state,
            collapsed: {
                ...state.collapsed,
                [action.hash]: false,
            },
        };
    }
    if (action.type === 'collapse-all') {
        return {
            ...state,
            collapsed: action.allHashes.reduce((a, b) => {
                return {
                    ...[a],
                    [b]: true,
                };
            }, {}),
        };
    }
    if (action.type === 'expand-all') {
        return {
            ...state,
            collapsed: action.allHashes.reduce((a, b) => {
                return {
                    ...a,
                    [b]: false,
                };
            }, {}),
        };
    }
    return state;
};
exports.timelineStateReducer = timelineStateReducer;
