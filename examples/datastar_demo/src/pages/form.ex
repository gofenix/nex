defmodule DatastarDemo.Pages.Form do
  use Nex

  def mount(_params) do
    %{
      title: "Form Validation - Datastar Demo"
    }
  end

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-8 max-w-2xl mx-auto">
      <h2 class="text-3xl font-bold text-gray-800 mb-6">Form Validation Demo</h2>

      <div class="mb-6">
        <h3 class="text-lg font-semibold text-gray-700 mb-2">特性 3: 前端表单验证 + 后端提交</h3>
        <p class="text-sm text-gray-600 mb-4">使用 Datastar 信号实现实时验证，无需 Alpine.js</p>
      </div>

      <div
        data-signals="{
          email: '',
          password: '',
          confirmPassword: '',
          submitted: false,
          result: ''
        }"
        data-computed:emailValid="$email.includes('@') && $email.includes('.')"
        data-computed:passwordValid="$password.length >= 8"
        data-computed:passwordsMatch="$password === $confirmPassword && $password !== ''"
        data-computed:formValid="$emailValid && $passwordValid && $passwordsMatch"
      >
        <form data-on:submit.prevent="@post('/form/submit')" class="space-y-6">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Email
            </label>
            <input
              type="email"
              data-bind:email
              placeholder="your@email.com"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <div class="mt-1 text-sm">
              <span data-show="$email && !$emailValid" class="text-red-600">
                ✗ 请输入有效的邮箱地址
              </span>
              <span data-show="$emailValid" class="text-green-600">
                ✓ 邮箱格式正确
              </span>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Password (至少 8 个字符)
            </label>
            <input
              type="password"
              data-bind:password
              placeholder="••••••••"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <div class="mt-1 text-sm">
              <span data-show="$password && !$passwordValid" class="text-red-600">
                ✗ 密码至少需要 8 个字符
              </span>
              <span data-show="$passwordValid" class="text-green-600">
                ✓ 密码长度符合要求
              </span>
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-2">
              Confirm Password
            </label>
            <input
              type="password"
              data-bind:confirmPassword
              placeholder="••••••••"
              class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
            <div class="mt-1 text-sm">
              <span data-show="$confirmPassword && !$passwordsMatch" class="text-red-600">
                ✗ 密码不匹配
              </span>
              <span data-show="$passwordsMatch" class="text-green-600">
                ✓ 密码匹配
              </span>
            </div>
          </div>

          <div class="flex items-center gap-4">
            <button
              type="submit"
              data-attr:disabled="!$formValid"
              class="px-6 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition disabled:bg-gray-300 disabled:cursor-not-allowed">
              提交注册
            </button>

            <span data-show="!$formValid" class="text-sm text-gray-500">
              请完成所有验证项
            </span>
          </div>

          <div id="form-result" data-show="$submitted" class="p-4 bg-green-50 border border-green-200 rounded-lg">
            <p class="text-green-800" data-text="$result"></p>
          </div>
        </form>

        <div class="mt-8 p-4 bg-blue-50 rounded">
          <p class="text-sm text-gray-700">
            <strong>关键特性：</strong><br>
            • <code>data-signals</code>: 定义响应式状态<br>
            • <code>data-bind</code>: 双向绑定输入框<br>
            • <code>data-computed</code>: 计算属性（类似 Vue computed）<br>
            • <code>data-show</code>: 条件显示（类似 Alpine x-show）<br>
            • <code>data-attr:disabled</code>: 动态属性绑定<br>
            • <code>@post()</code>: 发送后端请求
          </p>
        </div>
      </div>
    </div>
    """
  end

  def submit(req) do
    signals = req.body
    email = signals["email"]

    assigns = %{
      submitted: true,
      result: "注册成功！欢迎 #{email}"
    }

    ~H"""
    <div id="form-result" data-show="$submitted" class="p-4 bg-green-50 border border-green-200 rounded-lg">
      <p class="text-green-800">注册成功！欢迎 {@email}</p>
    </div>
    """
  end
end
