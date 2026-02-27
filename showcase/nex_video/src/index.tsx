import { registerRoot, Composition, AbsoluteFill, useCurrentFrame, useVideoConfig, spring, interpolate } from "remotion";

const NexBlue = "#3B82F6";
const NexDark = "#0F172A";
const NexAccent = "#8B5CF6";
const White = "#FFFFFF";
const Green = "#10B981";
const Amber = "#F59E0B";
const Gray = "#9CA3AF";
const CodeGreen = "#6A9955";
const CodeGray = "#D4D4D4";

const FRAME_RATE = 30;
const SECTION_FRAMES = 90; // 3 seconds per section

const Intro = ({ offset = 0 }: { offset?: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  const frameAdjusted = Math.max(0, frame - offset);
  const scale = spring({ frame: frameAdjusted, fps, config: { damping: 12, stiffness: 100 } });
  const opacity = interpolate(frameAdjusted, [0, 30], [0, 1], { extrapolateRight: "clamp" });
  
  return (
    <AbsoluteFill style={{ backgroundColor: NexDark, justifyContent: "center", alignItems: "center" }}>
      <div style={{ 
        color: White, 
        fontSize: 140, 
        fontWeight: "bold", 
        fontFamily: "system-ui",
        transform: `scale(${scale})`,
        opacity,
      }}>Nex</div>
      <div style={{ 
        color: NexBlue, 
        fontSize: 36, 
        marginTop: 24, 
        opacity,
        fontFamily: "system-ui"
      }}>The simplest way to build HTMX apps in Elixir</div>
    </AbsoluteFill>
  );
};

const AINative = ({ offset = 0 }: { offset?: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  const frameAdjusted = Math.max(0, frame - offset);
  const fade = spring({ frame: frameAdjusted, fps, config: { damping: 15 } });
  const slide = spring({ frame: frameAdjusted - 15, fps, config: { damping: 15 } });
  
  return (
    <AbsoluteFill style={{ backgroundColor: NexDark, padding: 80, justifyContent: "center" }}>
      <div style={{ 
        color: NexBlue, 
        fontSize: 72, 
        fontWeight: "bold", 
        fontFamily: "system-ui",
        transform: `translateY(${interpolate(slide, [0, 1], [-30, 0])}px)`,
        opacity: fade,
      }}>🤖 AI-Native & Vibe Coding</div>
      
      <div style={{ marginTop: 60, opacity: fade }}>
        <div style={{ color: Green, fontSize: 36, fontFamily: "system-ui", marginBottom: 8 }}>Locality of Behavior</div>
        <div style={{ color: Gray, fontSize: 24, fontFamily: "system-ui", marginLeft: 20 }}>UI and logic in one file — perfect for AI agents</div>
        
        <div style={{ color: Green, fontSize: 36, fontFamily: "system-ui", marginTop: 32, marginBottom: 8 }}>Unified Interface</div>
        <div style={{ color: Gray, fontSize: 24, fontFamily: "system-ui", marginLeft: 20 }}>Single `use Nex` for Pages, APIs, and Components</div>
        
        <div style={{ color: Green, fontSize: 36, fontFamily: "system-ui", marginTop: 32, marginBottom: 8 }}>Zero-Config Routing</div>
        <div style={{ color: Gray, fontSize: 24, fontFamily: "system-ui", marginLeft: 20 }}>Paths are routes — reduces AI hallucinations</div>
      </div>
    </AbsoluteFill>
  );
};

const Routing = ({ offset = 0 }: { offset?: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  const frameAdjusted = Math.max(0, frame - offset);
  const fade = spring({ frame: frameAdjusted, fps });
  const codeSlide = spring({ frame: frameAdjusted - 20, fps, config: { damping: 15 } });
  
  return (
    <AbsoluteFill style={{ backgroundColor: NexDark, padding: 80, justifyContent: "center", alignItems: "center" }}>
      <div style={{ 
        color: NexBlue, 
        fontSize: 72, 
        fontWeight: "bold", 
        fontFamily: "system-ui",
        transform: `translateY(${interpolate(fade, [0, 1], [-20, 0])}px)`,
        opacity: fade,
      }}>📁 File-based Routing</div>
      
      <div style={{ 
        marginTop: 50, 
        backgroundColor: "#1E1E1E", 
        padding: 40, 
        borderRadius: 12,
        transform: `translateY(${interpolate(codeSlide, [0, 1], [30, 0])}px)`,
        opacity: codeSlide,
      }}>
        <div style={{ color: CodeGreen, fontSize: 28, fontFamily: "monospace" }}>src/pages/index.ex &nbsp;&nbsp;→&nbsp;&nbsp; GET /</div>
        <div style={{ color: CodeGreen, fontSize: 28, fontFamily: "monospace", marginTop: 12 }}>src/pages/users.ex &nbsp;&nbsp;→&nbsp;&nbsp; GET /users</div>
        <div style={{ color: CodeGreen, fontSize: 28, fontFamily: "monospace", marginTop: 12 }}>src/users/[id].ex &nbsp;&nbsp;→&nbsp;&nbsp; GET /users/:id</div>
        <div style={{ color: CodeGreen, fontSize: 28, fontFamily: "monospace", marginTop: 12 }}>src/api/todos.ex &nbsp;&nbsp;→&nbsp;&nbsp; /api/todos</div>
      </div>
    </AbsoluteFill>
  );
};

const HTMX = ({ offset = 0 }: { offset?: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  const frameAdjusted = Math.max(0, frame - offset);
  const fade = spring({ frame: frameAdjusted, fps });
  const codeFade = spring({ frame: frameAdjusted - 25, fps, config: { damping: 15 } });
  
  return (
    <AbsoluteFill style={{ backgroundColor: NexDark, padding: 80, justifyContent: "center" }}>
      <div style={{ 
        color: NexBlue, 
        fontSize: 72, 
        fontWeight: "bold", 
        fontFamily: "system-ui",
        transform: `translateY(${interpolate(fade, [0, 1], [-20, 0])}px)`,
        opacity: fade,
      }}>⚡ HTMX-First Frontend</div>
      
      <div style={{ marginTop: 50, opacity: fade }}>
        <div style={{ color: Green, fontSize: 32, fontFamily: "system-ui", marginBottom: 16 }}>🚀 Zero JavaScript Required</div>
        <div style={{ 
          backgroundColor: "#1E1E1E", 
          padding: 24, 
          borderRadius: 8,
          opacity: codeFade,
          transform: `translateY(${interpolate(codeFade, [0, 1], [20, 0])}px)`,
        }}>
          <code style={{ color: CodeGray, fontSize: 22, fontFamily: "monospace" }}>
            &lt;form hx-post="/add" hx-target="#list" hx-swap="beforeend"&gt;
          </code>
        </div>
        
        <div style={{ color: Green, fontSize: 32, fontFamily: "system-ui", marginTop: 40, marginBottom: 16 }}>🛡️ Built-in Security</div>
        <div style={{ color: Amber, fontSize: 28, fontFamily: "system-ui" }}>Automatic CSRF protection on all state-changing requests</div>
      </div>
    </AbsoluteFill>
  );
};

const Realtime = ({ offset = 0 }: { offset?: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  const frameAdjusted = Math.max(0, frame - offset);
  const fade = spring({ frame: frameAdjusted, fps });
  const cardsFade = spring({ frame: frameAdjusted - 20, fps, config: { damping: 15 } });
  
  return (
    <AbsoluteFill style={{ backgroundColor: NexDark, padding: 80, justifyContent: "center" }}>
      <div style={{ 
        color: NexBlue, 
        fontSize: 72, 
        fontWeight: "bold", 
        fontFamily: "system-ui",
        transform: `translateY(${interpolate(fade, [0, 1], [-20, 0])}px)`,
        opacity: fade,
      }}>🔄 Real-time & APIs</div>
      
      <div style={{ display: "flex", justifyContent: "center", gap: 60, marginTop: 60, opacity: cardsFade }}>
        <div style={{ 
          backgroundColor: "#1E1E1E", 
          padding: 40, 
          borderRadius: 16,
          borderLeft: `6px solid ${Amber}`,
          transform: `translateY(${interpolate(cardsFade, [0, 1], [30, 0])}px)`,
        }}>
          <div style={{ color: Amber, fontSize: 32, fontFamily: "system-ui", marginBottom: 16 }}>🌊 SSE Streaming</div>
          <div style={{ color: CodeGray, fontSize: 20, fontFamily: "monospace" }}>Nex.stream for AI responses</div>
          <div style={{ color: CodeGray, fontSize: 20, fontFamily: "monospace", marginTop: 8 }}>and live updates</div>
        </div>
        
        <div style={{ 
          backgroundColor: "#1E1E1E", 
          padding: 40, 
          borderRadius: 16,
          borderLeft: `6px solid ${NexAccent}`,
          transform: `translateY(${interpolate(cardsFade, [0, 1], [30, 0])}px)`,
        }}>
          <div style={{ color: NexAccent, fontSize: 32, fontFamily: "system-ui", marginBottom: 16 }}>📡 JSON APIs</div>
          <div style={{ color: CodeGray, fontSize: 20, fontFamily: "monospace" }}>Next.js-aligned req object</div>
          <div style={{ color: CodeGray, fontSize: 20, fontFamily: "monospace", marginTop: 8 }}>Clean, simple API routes</div>
        </div>
      </div>
    </AbsoluteFill>
  );
};

const GettingStarted = ({ offset = 0 }: { offset?: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  const frameAdjusted = Math.max(0, frame - offset);
  const fade = spring({ frame: frameAdjusted, fps, config: { damping: 15 } });
  const codeFade = spring({ frame: frameAdjusted - 25, fps, config: { damping: 15 } });
  
  return (
    <AbsoluteFill style={{ backgroundColor: NexDark, padding: 80, justifyContent: "center", alignItems: "center" }}>
      <div style={{ 
        color: White, 
        fontSize: 72, 
        fontWeight: "bold", 
        fontFamily: "system-ui",
        transform: `translateY(${interpolate(fade, [0, 1], [-20, 0])}px)`,
        opacity: fade,
      }}>🚀 Get Started in Seconds</div>
      
      <div style={{ 
        marginTop: 50, 
        transform: `translateY(${interpolate(codeFade, [0, 1], [30, 0])}px)`,
        opacity: codeFade,
      }}>
        <div style={{ color: NexBlue, fontSize: 28, fontFamily: "system-ui", marginBottom: 12 }}># Install</div>
        <div style={{ color: Green, fontSize: 26, fontFamily: "monospace" }}>mix archive.install hex nex_new</div>
        
        <div style={{ color: NexBlue, fontSize: 28, fontFamily: "system-ui", marginTop: 28, marginBottom: 12 }}># Create project</div>
        <div style={{ color: Green, fontSize: 26, fontFamily: "monospace" }}>mix nex.new my_app</div>
        
        <div style={{ color: NexBlue, fontSize: 28, fontFamily: "system-ui", marginTop: 28, marginBottom: 12 }}># Start server</div>
        <div style={{ color: Green, fontSize: 26, fontFamily: "monospace" }}>mix nex.dev</div>
      </div>
    </AbsoluteFill>
  );
};

const Outro = ({ offset = 0 }: { offset?: number }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  
  const frameAdjusted = Math.max(0, frame - offset);
  const scale = spring({ frame: frameAdjusted, fps, config: { damping: 10, stiffness: 80 } });
  const opacity = interpolate(frameAdjusted, [0, 30], [0, 1], { extrapolateRight: "clamp" });
  
  return (
    <AbsoluteFill style={{ backgroundColor: NexDark, justifyContent: "center", alignItems: "center" }}>
      <div style={{ 
        color: White, 
        fontSize: 96, 
        fontWeight: "bold", 
        fontFamily: "system-ui",
        transform: `scale(${scale})`,
        opacity,
        textAlign: "center",
      }}>Build Real Apps.<br/>Ship Fast.</div>
      <div style={{ 
        color: NexBlue, 
        fontSize: 40, 
        marginTop: 40, 
        fontFamily: "system-ui",
        opacity,
      }}>nex-framework.dev</div>
    </AbsoluteFill>
  );
};

const Main = () => {
  return (
    <AbsoluteFill>
      <Intro offset={0} />
      <AbsoluteFill style={{ opacity: interpolate(useCurrentFrame(), [SECTION_FRAMES, SECTION_FRAMES + 30], [0, 1]) }}>
        {useCurrentFrame() >= SECTION_FRAMES && <AINative offset={SECTION_FRAMES} />}
      </AbsoluteFill>
      <AbsoluteFill style={{ opacity: interpolate(useCurrentFrame(), [SECTION_FRAMES * 2, SECTION_FRAMES * 2 + 30], [0, 1]) }}>
        {useCurrentFrame() >= SECTION_FRAMES * 2 && <Routing offset={SECTION_FRAMES * 2} />}
      </AbsoluteFill>
      <AbsoluteFill style={{ opacity: interpolate(useCurrentFrame(), [SECTION_FRAMES * 3, SECTION_FRAMES * 3 + 30], [0, 1]) }}>
        {useCurrentFrame() >= SECTION_FRAMES * 3 && <HTMX offset={SECTION_FRAMES * 3} />}
      </AbsoluteFill>
      <AbsoluteFill style={{ opacity: interpolate(useCurrentFrame(), [SECTION_FRAMES * 4, SECTION_FRAMES * 4 + 30], [0, 1]) }}>
        {useCurrentFrame() >= SECTION_FRAMES * 4 && <Realtime offset={SECTION_FRAMES * 4} />}
      </AbsoluteFill>
      <AbsoluteFill style={{ opacity: interpolate(useCurrentFrame(), [SECTION_FRAMES * 5, SECTION_FRAMES * 5 + 30], [0, 1]) }}>
        {useCurrentFrame() >= SECTION_FRAMES * 5 && <GettingStarted offset={SECTION_FRAMES * 5} />}
      </AbsoluteFill>
      <AbsoluteFill style={{ opacity: interpolate(useCurrentFrame(), [SECTION_FRAMES * 6, SECTION_FRAMES * 6 + 30], [0, 1]) }}>
        {useCurrentFrame() >= SECTION_FRAMES * 6 && <Outro offset={SECTION_FRAMES * 6} />}
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

registerRoot(() => (
  <Composition
    id="my-video"
    component={Main}
    durationInFrames={SECTION_FRAMES * 7}
    fps={FRAME_RATE}
    width={1920}
    height={1080}
  />
));
