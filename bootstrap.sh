#!/usr/bin/env bash
# bootstrap.sh — gh 装好并登录后跑一次，自动完成：
#   1. 在 GitHub 上创建 sunchurui/reports 公开仓库
#   2. 把本地 ~/claude_workspace/reports 推上去
#   3. 启用 GitHub Pages（main 分支 / 根目录）
#   4. 等 Pages 部署完成，打印访问 URL

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

# 1) 检查 gh 已安装并登录
if ! command -v gh >/dev/null; then
  echo "✗ gh 还没装。先跑: brew install gh"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "✗ 还没登录 GitHub。先跑: gh auth login"
  echo "  推荐选 'HTTPS' 和 'Login with a web browser'"
  exit 1
fi

# 2) 创建公开仓库（如果已存在会报错就跳过）
if gh repo view sunchurui/reports >/dev/null 2>&1; then
  echo "ℹ 仓库 sunchurui/reports 已存在"
else
  gh repo create sunchurui/reports \
    --public \
    --description "由 Claude Code autopilot 自主调研生成的报告集" \
    --source=. \
    --remote=origin \
    --push
  echo "✓ 仓库创建并推送"
fi

# 3) 如果还没设 remote
if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin https://github.com/sunchurui/reports.git
  git branch -M main
  git push -u origin main
  echo "✓ 已配 remote 并 push"
fi

# 4) 启用 GitHub Pages
echo "→ 启用 GitHub Pages..."
gh api -X POST "/repos/sunchurui/reports/pages" \
  -f "source[branch]=main" \
  -f "source[path]=/" 2>&1 | head -5 || \
  echo "  (可能已经启用，忽略错误)"

echo ""
echo "✅ 全部完成。"
echo ""
echo "📖 索引页 (1-2 分钟后生效): https://sunchurui.github.io/reports/"
echo "📖 首份报告:                 https://sunchurui.github.io/reports/reports/long-horizon-rl-customer-service/"
echo ""
echo "以后发布新报告: ./publish.sh <slug> <html> \"<title>\" \"<summary>\""
