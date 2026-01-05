# AI SDK Core Reference

AI SDK Core 是一组函数，允许您与语言模型和其他 AI 模型进行交互。这些函数易于使用且灵活，允许您从语言模型和其他 AI 模型生成文本、结构化数据和嵌入。

官方文档：https://ai-sdk.dev/docs/reference/ai-sdk-core

---

## 主要函数

### generateText()

生成文本并调用工具。

**导入：**
```typescript
import { generateText } from "ai"
```

**示例：**
```typescript
import { generateText } from "ai"

const { text } = await generateText({
  model: "anthropic/claude-sonnet-4-5",
  prompt: '发明一个新的节日并描述其传统。'
})

console.log(text)
```

**参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `model` | LanguageModel | 是 | 要使用的语言模型 |
| `system` | string \| SystemModelMessage \| SystemModelMessage[] | 否 | 系统提示词 |
| `prompt` | string \| Array<...ModelMessage> | 是 | 输入提示词 |
| `messages` | Array<ModelMessage> | 否 | 消息列表 |
| `tools` | ToolSet | 否 | 可用工具集 |
| `toolChoice` | "auto" \| "none" \| "required" \| {...} | 否 | 工具选择设置 |
| `maxOutputTokens` | number | 否 | 最大输出 token 数 |
| `temperature` | number | 否 | 温度参数 |
| `topP` | number | 否 | 核采样参数 |
| `topK` | number | 否 | Top K 采样 |
| `presencePenalty` | number | 否 | 存在惩罚 |
| `frequencyPenalty` | number | 否 | 频率惩罚 |
| `stopSequences` | string[] | 否 | 停止序列 |
| `seed` | number | 否 | 随机种子 |
| `maxRetries` | number | 否 | 最大重试次数 |
| `abortSignal` | AbortSignal | 否 | 中止信号 |
| `headers` | Record<string, string> | 否 | HTTP 头 |
| `experimental_telemetry` | TelemetrySettings | 否 | 遥测配置 |
| `providerOptions` | Record<string, JSONObject> | 否 | 提供商特定选项 |
| `activeTools` | Array<TOOLNAME> | 否 | 活跃工具限制 |
| `stopWhen` | StopCondition<TOOLS> \| Array<...> | 否 | 停止条件 |
| `prepareStep` | function | 否 | 步骤准备函数 |
| `output` | Output | 否 | 输出规范 |
| `onStepFinish` | function | 否 | 步骤完成回调 |
| `onFinish` | function | 否 | 完成回调 |

**返回值：**

```typescript
{
  text: string,                          // 生成的完整文本
  toolCalls: ToolCall[],                // 执行的工具调用
  toolResults: ToolResult[],            // 工具结果
  usage: LanguageModelUsage,            // Token 使用统计
  warnings: Warning[] | undefined,      // 警告信息
  response: Response,                   // 响应元数据
  isContinued: boolean                  // 是否有后续步骤
}
```

---

### streamText()

流式传输文本并调用工具。

**导入：**
```typescript
import { streamText } from "ai"
```

**示例：**
```typescript
import { streamText } from "ai"

const result = streamText({
  model: "anthropic/claude-sonnet-4-5",
  prompt: '解释一下什么是人工智能。'
})

for await (const chunk of result.textStream) {
  console.log(chunk)
}
```

---

### generateObject()

从语言模型生成结构化数据。

**导入：**
```typescript
import { generateObject } from "ai"
```

**示例：**
```typescript
import { generateObject, z } from "ai"

const { object } = await generateObject({
  model: "anthropic/claude-sonnet-4-5",
  schema: z.object({
    recipe: z.object({
      name: z.string(),
      ingredients: z.array(z.string()),
      steps: z.array(z.string())
    })
  }),
  prompt: '创建一个巧克力蛋糕的食谱。'
})
```

---

### streamObject()

流式传输结构化数据。

**导入：**
```typescript
import { streamObject } from "ai"
```

---

### embed()

使用嵌入模型为单个值生成嵌入。

**导入：**
```typescript
import { embed } from "ai"
```

**示例：**
```typescript
import { embed } from "ai"

const { embedding } = await embed({
  model: "openai/text-embedding-3-small",
  value: "Hello, world!"
})
```

---

### embedMany()

使用嵌入模型为多个值生成嵌入（批量嵌入）。

**导入：**
```typescript
import { embedMany } from "ai"
```

---

### generateImage()

使用图像模型根据给定提示生成图像。

**导入：**
```typescript
import { generateImage } from "ai"
```

**示例：**
```typescript
import { generateImage } from "ai"

const { image } = await generateImage({
  model: "openai/dall-e-3",
  prompt: '一只在草地上跑的可爱小狗'
})
```

---

### experimental_transcribe()

从音频文件生成转录。

**导入：**
```typescript
import { experimental_transcribe as transcribe } from "ai"
```

---

### experimental_generateSpeech()

从文本生成语音音频。

**导入：**
```typescript
import { experimental_generateSpeech as generateSpeech } from "ai"
```

---

### rerank()

对文档进行重新排序。

**导入：**
```typescript
import { rerank } from "ai"
```

---

## 辅助函数

### tool()

工具的类型推断辅助函数。

**示例：**
```typescript
import { tool, generateText } from "ai"

const weatherTool = tool({
  description: "获取天气信息",
  parameters: {
    type: "object",
    properties: {
      city: { type: "string", description: "城市名称" }
    },
    required: ["city"]
  },
  execute: async ({ city }) => {
    return { temperature: 22, city }
  }
})

const result = await generateText({
  model: "anthropic/claude-sonnet-4-5",
  tools: [weatherTool],
  prompt: "北京的天气怎么样？"
})
```

---

### createMCPClient()

创建连接到 MCP（Model Context Protocol）服务器的客户端。

---

### jsonSchema()

创建 AI SDK 兼容的 JSON schema 对象。

---

### zodSchema()

创建 AI SDK 兼容的 Zod schema 对象。

---

### createProviderRegistry()

创建用于使用多个提供商模型的注册表。

**示例：**
```typescript
import { createProviderRegistry } from "ai"

const registry = createProviderRegistry({
  // 注册提供商
})
```

---

### cosineSimilarity()

计算两个向量之间的余弦相似度。

**示例：**
```typescript
import { cosineSimilarity } from "ai"

const similarity = cosineSimilarity(
  [1, 2, 3],
  [4, 5, 6]
)
```

---

### simulateReadableStream()

创建一个可读流，以可配置的延迟发出值。

---

### wrapLanguageModel()

用中间件包装语言模型。

---

### extractReasoningMiddleware()

从生成的文本中提取推理，并将其作为 `reasoning` 属性暴露在结果中。

---

### simulateStreamingMiddleware()

使用非流式语言模型的响应模拟流式行为。

---

### defaultSettingsMiddleware()

向语言模型应用默认设置。

---

### smoothStream()

平滑文本流输出。

**示例：**
```typescript
import { streamText, smoothStream } from "ai"

const result = streamText({
  model: "anthropic/claude-sonnet-4-5",
  prompt: "写一首诗",
  stream: smoothStream({
    delayMs: 30,
    chunking: "word" // 或 "token"
  })
})
```

---

### generateId()

生成唯一 ID 的辅助函数。

---

### createIdGenerator()

创建 ID 生成器。

---

## 消息类型

### SystemModelMessage
```typescript
{
  role: 'system'
  content: string
}
```

### UserModelMessage
```typescript
{
  role: 'user'
  content: string | Array<TextPart | ImagePart | FilePart>
}
```

### AssistantModelMessage
```typescript
{
  role: 'assistant'
  content: string | Array<TextPart | FilePart | ReasoningPart | ToolCallPart>
}
```

### ToolModelMessage
```typescript
{
  role: 'tool'
  content: Array<ToolResultPart>
}
```

---

## 输出规范 (Output)

### Output.text()
文本生成的输出规范（默认）。

### Output.object()
结构化对象生成的输出规范。

```typescript
Output.object({
  schema: z.object({...}),
  name?: string,
  description?: string
})
```

### Output.array()
数组生成的输出规范。

```typescript
Output.array({
  element: schema,
  name?: string,
  description?: string
})
```

### Output.choice()
选择生成的输出规范。

```typescript
Output.choice({
  options: ["选项1", "选项2", "选项3"],
  name?: string,
  description?: string
})
```

### Output.json()
非结构化 JSON 生成的输出规范。

```typescript
Output.json({
  name?: string,
  description?: string
})
```

---

## 工具定义

```typescript
Tool {
  description?: string           // 工具用途说明
  inputSchema: Zod Schema | JSON Schema  // 输入模式
  execute?: async (...) => RESULT // 执行函数
}
```

---

## 相关链接

- [AI SDK Core 概览](/docs/ai-sdk-core/overview)
- [生成文本](/docs/ai-sdk-core/generating-text)
- [生成结构化数据](/docs/ai-sdk-core/generating-structured-data)
- [工具调用](/docs/ai-sdk-core/tools-and-tool-calling)
- [嵌入](/docs/ai-sdk-core/embeddings)
- [图像生成](/docs/ai-sdk-core/image-generation)
