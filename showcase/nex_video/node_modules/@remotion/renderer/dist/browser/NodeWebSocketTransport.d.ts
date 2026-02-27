import type { WS } from '../ws/ws-types';
interface ConnectionTransport {
    send(message: string): void;
    close(): void;
    onmessage?: (message: string) => void;
    onclose?: () => void;
}
export declare class NodeWebSocketTransport implements ConnectionTransport {
    #private;
    static create(urlString: string): Promise<NodeWebSocketTransport>;
    onmessage?: (message: string) => void;
    onclose?: () => void;
    constructor(ws: WS);
    send(message: string): void;
    close(): void;
}
export {};
