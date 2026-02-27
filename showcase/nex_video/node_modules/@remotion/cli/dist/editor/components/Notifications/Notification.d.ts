import React from 'react';
export declare const Notification: React.FC<{
    children: React.ReactNode;
    created: number;
    duration: number;
    id: string;
    onRemove: (id: string) => void;
}>;
