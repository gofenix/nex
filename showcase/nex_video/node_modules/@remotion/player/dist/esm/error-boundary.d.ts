import React from 'react';
export declare class ErrorBoundary extends React.Component<{
    onError: (error: Error) => void;
    children: React.ReactNode;
    errorFallback: (info: {
        error: Error;
    }) => React.ReactNode;
}, {
    hasError: Error | null;
}> {
    state: {
        hasError: null;
    };
    static getDerivedStateFromError(error: Error): {
        hasError: Error;
    };
    componentDidCatch(error: Error): void;
    render(): string | number | boolean | JSX.Element | React.ReactFragment | null | undefined;
}
