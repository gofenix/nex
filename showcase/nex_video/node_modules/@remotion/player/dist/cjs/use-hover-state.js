"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useHoverState = void 0;
const react_1 = require("react");
const useHoverState = (ref) => {
    const [hovered, stetHovered] = (0, react_1.useState)(false);
    (0, react_1.useEffect)(() => {
        const { current } = ref;
        if (!current) {
            return;
        }
        const onHover = () => {
            stetHovered(true);
        };
        const onLeave = () => {
            stetHovered(false);
        };
        current.addEventListener('mouseenter', onHover);
        current.addEventListener('mouseleave', onLeave);
        return () => {
            current.removeEventListener('mouseenter', onHover);
            current.removeEventListener('mouseenter', onLeave);
        };
    }, [ref]);
    return hovered;
};
exports.useHoverState = useHoverState;
