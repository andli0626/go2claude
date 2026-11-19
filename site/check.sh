#!/usr/bin/env bash
# 零外部依赖自检：防止后续误加境外 CDN / 字体 / 统计
# 用法：在站点根目录执行 ./check.sh
RISK='fonts\.googleapis|fonts\.gstatic|cdn\.jsdelivr|unpkg\.com|cdnjs\.cloudflare'
RISK+='|google-analytics|googletagmanager|gtag\(|hm\.baidu'
RISK+='|raw\.githubusercontent|codeload\.github|objects\.githubusercontent'
RISK+='|releases\/download|polyfill\.io|staticfile\.org|bootcdn'

fail=0
for f in $(find . -name '*.html' -o -name '*.css' -o -name '*.js'); do
  hits=$(grep -nEo "$RISK" "$f" 2>/dev/null)
  if [ -n "$hits" ]; then
    echo "[风险] $f"
    echo "$hits" | sed 's/^/    /'
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "[通过] 未发现高风险外部依赖"
else
  echo "[失败] 请移除上述引用后再发布"
  exit 1
fi
