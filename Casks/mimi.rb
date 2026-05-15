cask "mimi" do
  version "0.2.2"
  sha256 "6cba7226f5c27198aacc96e3d8df6d69f093d28dcdad833b2fd88f1ddaf02041"

  url "https://github.com/marlonxie/MIMI/releases/download/v#{version}/MIMI-#{version}-arm64.zip"
  name "MIMI"
  desc "Real-time interview assistant for macOS (Mandarin <-> English/German)"
  homepage "https://github.com/marlonxie/MIMI"

  depends_on macos: ">= :sequoia"
  depends_on arch: :arm64
  # 自动装 ollama daemon（朋友机器零配置跑本地 LLM）
  depends_on formula: "ollama"

  # bundle 内部叫 MimiApp.app；装到 /Applications/MIMI.app 给用户看
  app "MimiApp.app", target: "MIMI.app"

  # 安装后跑：起 ollama daemon、拉 Qwen3 模型、预热 mlx-whisper
  postflight do
    ohai "Starting Ollama daemon"
    system_command "/opt/homebrew/bin/brew",
                   args: ["services", "start", "ollama"],
                   sudo: false,
                   print_stderr: false
    sleep 3  # 等 daemon 起来再 pull

    ohai "Pulling Qwen3-4B-Instruct (~2.6GB) — first install only"
    system_command "/opt/homebrew/bin/ollama",
                   args: ["pull", "qwen3:4b-instruct-2507-q4_K_M"],
                   sudo: false

    ohai "Prefetching mlx-whisper small model (~500MB)"
    backend = staged_path/"MIMI.app/Contents/Resources/mimi-backend/mimi-backend"
    if backend.exist?
      system_command backend.to_s,
                     args: ["--prefetch-model"],
                     sudo: false,
                     timeout: 600  # 10 min 下载超时
    end
  end

  uninstall quit:    "com.marlon.MimiApp",
            signal: ["TERM", "com.marlon.MimiApp"]

  # `brew uninstall --zap mimi` 时清干净（包括 chroma_store / resources）
  zap trash: [
    "~/Library/Application Support/MIMI",
    "~/Library/Logs/MIMI",
    "~/Library/Preferences/com.marlon.MimiApp.plist",
    "~/Library/Saved Application State/com.marlon.MimiApp.savedState",
  ]
end
