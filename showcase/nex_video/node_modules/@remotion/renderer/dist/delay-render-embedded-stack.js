"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseDelayRenderEmbeddedStack = void 0;
const remotion_1 = require("remotion");
const parse_browser_error_stack_1 = require("./parse-browser-error-stack");
const parseDelayRenderEmbeddedStack = (message) => {
    const index = message.indexOf(remotion_1.Internals.DELAY_RENDER_CALLSTACK_TOKEN);
    if (index === -1) {
        return null;
    }
    const msg = message
        .substring(index + remotion_1.Internals.DELAY_RENDER_CALLSTACK_TOKEN.length)
        .trim();
    const parsed = (0, parse_browser_error_stack_1.parseStack)(msg.split('\n'));
    return parsed;
};
exports.parseDelayRenderEmbeddedStack = parseDelayRenderEmbeddedStack;
