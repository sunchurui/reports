#!/usr/bin/env bash
# publish.sh — 把新报告 HTML 添加到仓库并 push
#
# 用法:
#   ./publish.sh <slug> <html-file> "<title>" "<summary>" <sources> <chars> tag1,tag2,...
#
# 示例:
#   ./publish.sh claude-code-amplify ~/research/claude-code-amplify.html \
#     "Claude Code 使用量增大攻略" "三层路径..." 12 1785 productivity,claude-code

set -euo pipefail

if [ "$#" -lt 4 ]; then
  cat <<USAGE
用法: $0 <slug> <html-file> "<title>" "<summary>" [sources] [chars] [tag1,tag2,...]

参数:
  slug       URL 段，比如 long-horizon-rl-customer-service（小写、连字符）
  html-file  本地 HTML 文件路径
  title      报告标题（显示在索引页）
  summary    一两句话摘要
  sources    可选：信息源数（默认 0）
  chars      可选：汉字数（默认 0）
  tags       可选：逗号分隔的标签

仓库根：$(cd "$(dirname "$0")" && pwd)
USAGE
  exit 1
fi

SLUG="$1"
HTML="$2"
TITLE="$3"
SUMMARY="$4"
SOURCES="${5:-0}"
CHARS="${6:-0}"
TAGS_RAW="${7:-research}"

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TODAY="$(date +%Y-%m-%d)"

if [ ! -f "$HTML" ]; then
  echo "错误: 找不到 HTML 文件 $HTML"
  exit 1
fi

# slug 合法性
if [[ ! "$SLUG" =~ ^[a-z0-9-]+$ ]]; then
  echo "错误: slug 只能用小写字母、数字、连字符。当前: $SLUG"
  exit 1
fi

TARGET_DIR="$REPO_DIR/reports/$SLUG"
mkdir -p "$TARGET_DIR"
cp "$HTML" "$TARGET_DIR/index.html"
echo "✓ 复制 HTML → reports/$SLUG/index.html"

# 把 tags 转成 JSON 数组
TAGS_JSON=$(echo "$TAGS_RAW" | python3 -c 'import sys, json; print(json.dumps([t.strip() for t in sys.stdin.read().split(",") if t.strip()]))')

# 更新 reports.json
python3 - "$REPO_DIR" "$SLUG" "$TITLE" "$SUMMARY" "$TODAY" "$SOURCES" "$CHARS" "$TAGS_JSON" <<'PYEOF'
import json, sys, os
repo, slug, title, summary, date, sources, chars, tags_json = sys.argv[1:]
fp = os.path.join(repo, "reports.json")
data = []
if os.path.exists(fp):
    with open(fp) as f:
        try:
            data = json.load(f)
        except Exception:
            data = []
data = [r for r in data if r.get("slug") != slug]
data.append({
    "slug": slug,
    "title": title,
    "date": date,
    "summary": summary,
    "tags": json.loads(tags_json),
    "sources": int(sources),
    "chars": int(chars),
})
data.sort(key=lambda r: r["date"], reverse=True)
with open(fp, "w") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print(f"✓ 更新 reports.json (共 {len(data)} 份报告)")
PYEOF

# 提交并推送
cd "$REPO_DIR"
git add -A
if git diff --cached --quiet; then
  echo "无需提交（无变更）"
  exit 0
fi
git commit -m "Add/update report: $SLUG — $TITLE"
echo "✓ 提交完成"

# 如果有远程，自动 push
if git remote get-url origin >/dev/null 2>&1; then
  git push
  echo "✓ 推送到 origin"
  echo ""
  echo "📖 报告地址: https://sunchurui.github.io/reports/reports/$SLUG/"
  echo "📋 索引页:   https://sunchurui.github.io/reports/"
else
  echo "提示: 还没配 remote。配好后再 push。"
fi
