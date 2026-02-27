import { SourceMapConsumer } from 'source-map';
export declare const getOriginalPosition: (source_map: SourceMapConsumer, line: number, column: number) => {
    source: string | null;
    line: number | null;
    column: number | null;
};
export declare function getSourceMap(fileUri: string, fileContents: string): Promise<SourceMapConsumer | null>;
