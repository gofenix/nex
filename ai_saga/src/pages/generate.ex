defmodule AiSaga.Pages.Generate do
  use Nex

  def mount(_params) do
    %{title: "AI 自动生成论文解读"}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-3xl mx-auto space-y-6">
      <!-- 页面标题 -->
      <div class="text-center py-8">
        <div class="inline-block bg-[rgb(255,222,0)] px-4 py-1 text-sm font-bold border-2 border-black mb-4">
          🤖 AI 自动生成
        </div>
        <h1 class="text-3xl md:text-4xl font-black mb-4">
          发现下一篇重要论文
        </h1>
        <p class="text-lg opacity-60 max-w-xl mx-auto">
          AI 将从 HuggingFace 热门论文和 AI 历史经典中，<br/>
          为你推荐并解读下一篇值得收录的重要论文
        </p>
      </div>

      <!-- 功能说明 -->
      <div class="card-yellow p-6">
        <h2 class="text-xl font-bold mb-4">🎯 生成流程</h2>
        <ol class="space-y-2 text-sm">
          <li class="flex items-start gap-2">
            <span class="font-mono opacity-60">1.</span>
            <span>从 HuggingFace 获取最新热门论文（20篇候选）</span>
          </li>
          <li class="flex items-start gap-2">
            <span class="font-mono opacity-60">2.</span>
            <span>AI 根据已有知识库分析并推荐最有价值的论文</span>
          </li>
          <li class="flex items-start gap-2">
            <span class="font-mono opacity-60">3.</span>
            <span>从 arXiv 获取论文完整信息（标题、作者、摘要）</span>
          </li>
          <li class="flex items-start gap-2">
            <span class="font-mono opacity-60">4.</span>
            <span>AI 生成三视角深度分析（历史、范式变迁、人物）</span>
          </li>
          <li class="flex items-start gap-2">
            <span class="font-mono opacity-60">5.</span>
            <span>保存到数据库并自动跳转到新论文页面</span>
          </li>
        </ol>
        <div class="mt-4 p-3 bg-black/5 border-2 border-black text-sm">
          <span class="font-bold">⏱️ 预计时间：</span>60-90 秒（AI 分析需要时间）
        </div>
      </div>

      <!-- 开始生成按钮 -->
      <div id="generate-controls" class="text-center">
        <button
          id="start-btn"
          onclick="startGeneration()"
          class="md-btn md-btn-primary text-lg px-8 py-4"
        >
          🚀 开始生成
        </button>
        <p class="text-xs opacity-40 mt-3">
          请确保网络连接稳定
        </p>
      </div>

      <!-- 进度日志 -->
      <div id="progress-container" class="card p-6 hidden">
        <h3 class="text-lg font-bold mb-4 flex items-center gap-2">
          <span class="animate-pulse">⏳</span>
          生成进度
        </h3>
        <div
          id="progress-log"
          class="space-y-2 max-h-96 overflow-y-auto font-mono text-sm"
        >
        </div>
      </div>

      <!-- 状态显示 -->
      <div id="status" class="text-center text-lg font-bold hidden">
      </div>

      <!-- 返回首页链接 -->
      <div class="text-center">
        <a href="/" class="text-sm underline opacity-60 hover:opacity-100">
          ← 返回首页
        </a>
      </div>
    </div>

    <script>
      let eventSource = null;
      let hasError = false;

      function startGeneration() {
        // 禁用按钮
        const startBtn = document.getElementById('start-btn');
        startBtn.disabled = true;
        startBtn.classList.add('opacity-50', 'cursor-not-allowed');
        startBtn.innerHTML = '⏳ 生成中...';

        // 显示进度容器
        document.getElementById('progress-container').classList.remove('hidden');

        // 创建 SSE 连接
        eventSource = new EventSource('/api/generate_paper/stream');
        hasError = false;

        // 处理进度消息
        eventSource.onmessage = function(e) {
          const log = document.getElementById('progress-log');
          const entry = document.createElement('div');
          entry.innerHTML = e.data;
          entry.className = 'py-1';
          log.appendChild(entry);
          log.scrollTop = log.scrollHeight;
        };

        // 处理完成事件
        eventSource.addEventListener('done', function(e) {
          if (!hasError) {
            hasError = true;
            eventSource.close();

            try {
              const result = JSON.parse(e.data);
              const statusEl = document.getElementById('status');
              statusEl.classList.remove('hidden');

              if (result.status === 'success') {
                // 成功：显示消息并跳转
                statusEl.style.color = '#4ade80';
                statusEl.innerHTML = '✅ 生成完成！正在跳转到论文页面...';

                setTimeout(() => {
                  window.location.href = '/paper/' + result.slug;
                }, 1500);
              } else {
                // 失败：显示错误消息和重试按钮
                statusEl.style.color = '#f87171';
                statusEl.innerHTML = '❌ 生成失败: ' + result.message;

                // 启用重试按钮
                startBtn.disabled = false;
                startBtn.classList.remove('opacity-50', 'cursor-not-allowed');
                startBtn.innerHTML = '🔄 重试';
              }
            } catch (err) {
              console.error('Failed to parse result:', err);
              showError('解析结果失败: ' + e.data);
            }
          }
        });

        // 处理错误
        eventSource.onerror = function() {
          if (!hasError) {
            hasError = true;
            eventSource.close();
            showError('连接中断，请检查网络后重试');
          }
        };
      }

      function showError(message) {
        const statusEl = document.getElementById('status');
        statusEl.classList.remove('hidden');
        statusEl.style.color = '#f87171';
        statusEl.innerHTML = '❌ ' + message;

        // 启用重试按钮
        const startBtn = document.getElementById('start-btn');
        startBtn.disabled = false;
        startBtn.classList.remove('opacity-50', 'cursor-not-allowed');
        startBtn.innerHTML = '🔄 重试';
      }

      // 页面卸载时关闭连接
      window.addEventListener('beforeunload', function() {
        if (eventSource) {
          eventSource.close();
        }
      });
    </script>
    """
  end
end
