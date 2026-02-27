"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseFfmpegProgress = void 0;
const parseFfmpegProgress = (input) => {
    const match = input.match(/frame=(\s+)?([0-9]+)\s/);
    if (!match) {
        return undefined;
    }
    return Number(match[2]);
};
exports.parseFfmpegProgress = parseFfmpegProgress;
