defmodule AiSaga.Layouts do
  use Nex

  def render(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="zh-CN" data-theme="light">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
        <title>{@title}</title>
        <script src="https://cdn.tailwindcss.com?plugins=forms,typography,aspect-ratio"></script>
        <link href="https://cdn.jsdelivr.net/npm/daisyui@4.12.23/dist/full.min.css" rel="stylesheet" type="text/css" />
        <script src="https://unpkg.com/htmx.org@2.0.4"></script>
        <script src="https://unpkg.com/htmx-ext-sse@2.2.2/sse.js"></script>
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;900&family=Space+Mono:wght@400;700&display=swap" rel="stylesheet">
        <style>
          :root {
            /* MotherDuck Brand Colors */
            --md-bg: rgb(244, 239, 234);
            --md-yellow: rgb(255, 222, 0);
            --md-yellow-light: rgba(255, 222, 0, 0.1);
            --md-dark: rgb(56, 56, 56);
            --md-black: rgb(0, 0, 0);
            --md-blue: rgb(111, 194, 255);
            --md-blue-light: rgba(111, 194, 255, 0.1);
            --md-red: rgb(255, 100, 100);
            --md-red-light: rgba(255, 100, 100, 0.1);
            --md-white: rgb(255, 255, 255);
            --md-gray-50: rgb(249, 250, 251);
            --md-gray-100: rgb(243, 244, 246);
            --md-gray-200: rgb(229, 231, 235);
            --md-gray-600: rgb(75, 85, 99);
          }
          body {
            background-color: var(--md-bg);
            font-family: 'Inter', sans-serif;
            color: var(--md-dark);
          }
          /* Shadow Utilities */
          .md-shadow { box-shadow: var(--md-black) -8px 8px 0px 0px; }
          .md-shadow-sm { box-shadow: var(--md-black) -4px 4px 0px 0px; }
          .md-shadow-yellow { box-shadow: var(--md-yellow) -6px 6px 0px 0px; }
          .md-shadow-blue { box-shadow: var(--md-blue) -6px 6px 0px 0px; }
          /* Border Utilities */
          .md-border { border: 2px solid var(--md-black); }
          .md-border-sm { border: 1px solid var(--md-black); }
          /* Card Components */
          .card {
            background: var(--md-white);
            border: 2px solid var(--md-black);
            box-shadow: var(--md-black) -4px 4px 0px 0px;
            transition: transform 0.15s ease, box-shadow 0.15s ease;
          }
          .card:hover {
            transform: translate(1px, 1px);
            box-shadow: var(--md-black) -3px 3px 0px 0px;
          }
          .card-yellow {
            background: var(--md-yellow);
            border: 2px solid var(--md-black);
            box-shadow: var(--md-black) -6px 6px 0px 0px;
            transition: transform 0.15s ease, box-shadow 0.15s ease;
          }
          .card-yellow:hover {
            transform: translate(1px, 1px);
            box-shadow: var(--md-black) -5px 5px 0px 0px;
            background: rgb(255, 230, 50);
          }
          .card-blue {
            background: var(--md-blue);
            border: 2px solid var(--md-black);
            box-shadow: var(--md-black) -4px 4px 0px 0px;
            transition: transform 0.15s ease, box-shadow 0.15s ease;
          }
          .card-blue:hover {
            transform: translate(1px, 1px);
            box-shadow: var(--md-black) -3px 3px 0px 0px;
            background: rgb(140, 210, 255);
          }
          /* Badge Components */
          .badge {
            display: inline-flex;
            align-items: center;
            padding: 0.25rem 0.5rem;
            font-size: 0.75rem;
            font-family: 'Space Mono', monospace;
            border: 1px solid var(--md-black);
          }
          .badge-yellow {
            background: var(--md-yellow);
            color: var(--md-black);
          }
          .badge-blue {
            background: var(--md-blue);
            color: var(--md-black);
          }
          .badge-black {
            background: var(--md-black);
            color: var(--md-white);
          }
          .badge-gray {
            background: var(--md-gray-100);
            color: var(--md-dark);
            border-color: var(--md-dark);
          }
          /* Stat Box */
          .stat-box {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 0.75rem 1rem;
            border: 2px solid var(--md-black);
            text-align: center;
          }
          .stat-box .number {
            font-size: 1.5rem;
            font-weight: 900;
            line-height: 1.2;
          }
          .stat-box .label {
            font-size: 0.75rem;
            opacity: 0.6;
            margin-top: 0.25rem;
          }
          .stat-yellow { background: var(--md-yellow-light); }
          .stat-blue { background: var(--md-blue-light); }
          .stat-black { background: var(--md-black); color: var(--md-white); }
          .stat-black .label { opacity: 0.8; }
          /* Year Tag */
          .year-tag {
            font-family: 'Space Mono', monospace;
            font-size: 0.875rem;
            opacity: 0.6;
          }
          /* Icon Box */
          .icon-box {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 2.5rem;
            height: 2.5rem;
            background: var(--md-gray-100);
            border: 2px solid var(--md-black);
            font-size: 1.25rem;
          }
          .icon-box-yellow {
            background: var(--md-yellow);
          }
          .icon-box-blue {
            background: var(--md-blue);
          }
          /* Section Title */
          .section-title {
            display: flex;
            align-items: center;
            gap: 0.75rem;
            font-size: 1.5rem;
            font-weight: 900;
            margin-bottom: 1.5rem;
          }
          /* Page Header */
          .page-header {
            text-align: center;
            padding: 2rem 0;
          }
          .page-header h1 {
            font-size: 2.25rem;
            font-weight: 900;
            margin-bottom: 0.75rem;
          }
          .page-header p {
            font-size: 1.125rem;
            opacity: 0.6;
            max-width: 36rem;
            margin: 0 auto 1rem;
          }
          .page-header .meta {
            font-family: 'Space Mono', monospace;
            font-size: 0.875rem;
            opacity: 0.4;
          }
          /* Empty State */
          .empty-state {
            text-align: center;
            padding: 3rem;
            background: var(--md-gray-50);
            border: 2px solid var(--md-black);
          }
          .empty-state p {
            font-size: 1.125rem;
            opacity: 0.6;
          }
          .empty-state .hint {
            font-size: 0.875rem;
            opacity: 0.4;
            margin-top: 0.5rem;
          }
          /* Back Link */
          .back-link {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            font-family: 'Space Mono', monospace;
            font-size: 0.875rem;
            opacity: 0.6;
            transition: opacity 0.15s ease;
          }
          .back-link:hover {
            opacity: 1;
          }
          /* Form Inputs */
          .md-input {
            width: 100%;
            padding: 0.5rem 0.75rem;
            border: 2px solid var(--md-black);
            background: var(--md-white);
            font-family: 'Inter', sans-serif;
            outline: none;
          }
          .md-input:focus {
            box-shadow: 0 0 0 3px var(--md-yellow-light);
          }
          /* Button */
          .md-btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            padding: 0.75rem 1.5rem;
            font-weight: 700;
            border: 2px solid var(--md-black);
            transition: transform 0.15s ease, background 0.15s ease;
          }
          .md-btn:hover {
            transform: translate(1px, 1px);
          }
          .md-btn-primary {
            background: var(--md-yellow);
          }
          .md-btn-primary:hover {
            background: rgb(255, 230, 50);
          }
          .md-btn-secondary {
            background: var(--md-white);
          }
          .md-btn-secondary:hover {
            background: var(--md-gray-100);
          }
          .md-btn-dark {
            background: var(--md-black);
            color: var(--md-white);
            border-color: var(--md-black);
          }
          .md-btn-dark:hover {
            background: var(--md-dark);
          }
          .font-mono { font-family: 'Space Mono', monospace; }
          /* Timeline */
          .timeline-line {
            position: absolute;
            left: 2rem;
            top: 0;
            bottom: 0;
            width: 2px;
            background: var(--md-black);
          }
          @media (min-width: 768px) {
            .timeline-line {
              left: 50%;
              transform: translateX(-50%);
            }
          }
          .timeline-dot {
            position: absolute;
            left: 2rem;
            width: 1rem;
            height: 1rem;
            background: var(--md-yellow);
            border: 2px solid var(--md-black);
            z-index: 10;
          }
          @media (min-width: 768px) {
            .timeline-dot {
              left: 50%;
              transform: translateX(-50%);
            }
          }
        </style>
      </head>
      <body class="min-h-screen">
        <nav class="sticky top-0 z-50 bg-[rgb(244,239,234)] border-b-2 border-black">
          <div class="max-w-4xl mx-auto w-full px-6 py-4 flex items-center justify-between">
            <a href="/" class="text-2xl font-black tracking-tight hover:underline">🤖 AiSaga</a>
            <div class="flex gap-6 text-sm font-medium">
              <a href="/" class="hover:underline">首页</a>
              <a href="/paper" class="hover:underline">论文</a>
              <a href="/paradigm" class="hover:underline">范式</a>
              <a href="/timeline" class="hover:underline">时间线</a>
              <a href="/author" class="hover:underline">人物</a>
              <a href="/search" class="hover:underline">搜索</a>
            </div>
          </div>
        </nav>
        <main class="max-w-4xl mx-auto px-6 py-8">
          {raw(@inner_content)}
        </main>
        <footer class="border-t-2 border-black mt-16 py-8 text-center text-sm">
          <p class="font-mono opacity-60">理解 AI 的起点</p>
        </footer>
      </body>
    </html>
    """
  end
end
