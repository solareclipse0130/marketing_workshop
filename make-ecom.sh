#!/usr/bin/env bash
# 一行指令做完一整条电商内容线 —— 全链路集成版
#   百炼 bl CLI（文案/图像/配音/图生视频）+ frontend-design（HTML 海报）+ video-storyboard（5 分镜）
# 用法: ./make-ecom.sh "白桃味0糖气泡水" "年轻、清爽、健康、夏日"
# 依赖: bl(已鉴权) + ffmpeg + google-chrome(无头截图) + 系统 Noto CJK 字体
# 注意: dashscope 是国内端点, 跑前请确保代理已关 / aliyuncs.com 走直连, 否则会 code6 抽风
set -euo pipefail

PRODUCT="${1:-白桃味0糖气泡水}"
TONE="${2:-年轻、清爽、健康、夏日}"
VOICE="${3:-longyingxiao_v3}"        # 龙应笑·清甜推销女; 换音色: bl speech synthesize --list-voices --model cosyvoice-v3-flash
BRAND_EN="${BRAND_EN:-WHITE PEACH}"  # 海报英文品牌字
PRICE="${PRICE:-9.9}"                # 海报尝鲜价
NEG="字幕,水印,logo,多余文字,畸形手,多指,过曝,塑料假手,品牌字体破坏"

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/output"
TMP="$OUT/.tmp"
mkdir -p "$OUT"/{text,images,posters,poster-html,audio,storyboard} "$TMP"

# ---- 依赖自检 ----
for t in bl ffmpeg; do command -v "$t" >/dev/null || { echo "✗ 缺少依赖: $t"; exit 1; }; done
CHROME="$(command -v google-chrome || command -v google-chrome-stable || true)"
[ -n "$CHROME" ] || echo "⚠ 未找到 google-chrome, ③ 海报截图将跳过(仅生成 poster.html)"

latest(){ ls -t "$1"/*."$2" 2>/dev/null | head -1; }   # 取目录里最新的某类文件

echo "==== 产品: $PRODUCT | 调性: $TONE ===="

# ============================================================
# ① 文案 + 广告剧本
# ============================================================
echo "① 文案 + 剧本..."
bl text chat --system "你是资深电商内容运营，擅长写高转化商品文案" \
  --message "为『$PRODUCT』写电商内容：1)5个含关键词的标题 2)6条核心卖点 3)一段约30秒短视频口播脚本(口语化、有节奏)。品牌调性：$TONE。" \
  --quiet > "$OUT/text/copy.txt"

# 连贯口播 VO（喂给 ④ 配音；5 分镜逐句对应，整段约 25s）
cat > "$OUT/text/vo-ad.txt" <<EOF
夏天想喝甜的，又怕胖？这罐${PRODUCT}，给你答案。真实白桃风味，绵密气泡，0蔗糖、0卡路里，喝着甜，身上不长肉。一口透心凉，从工位到露营，整个夏天都清爽无负担。点下方链接，把夏天第一口沁爽带回家！
EOF

# 5 分镜广告剧本（PAS + Hook-Value-CTA，video-storyboard 的产物形态）
cat > "$OUT/script.md" <<EOF
# ${PRODUCT} · 短视频广告剧本
- 格式：9:16 竖屏 / 抖音·小红书 / 约 25s / 5 分镜
- 结构：Hook → Problem → Solution → CTA（PAS + Hook-Value-CTA）
- 连贯锁定：同一罐「${BRAND_EN} 0 SUGAR」+ 白桃片 + 冰块水珠 + 粉桃色调贯穿全片

| 镜 | 内容 | VO |
|----|------|----|
| 1·Hook | 冰桶手持开盖·气雾喷出 | 夏天想喝甜的，又怕胖？ |
| 2·转折 | 注入冰杯·白桃片漂浮 | 这罐白桃0糖气泡水，给你答案。 |
| 3·卖点 | 罐身水珠特写·0 SUGAR 高亮 | 真实白桃风味，0蔗糖0卡，喝着甜不长肉。 |
| 4·场景 | 草地女孩仰头畅饮 | 一口透心凉，整个夏天清爽无负担。 |
| 5·CTA | 堆头陈列·冰镇排罐 | 点下方链接，把夏天第一口带回家！ |
EOF
echo "   -> $OUT/text/copy.txt · $OUT/text/vo-ad.txt · $OUT/script.md"

# ============================================================
# ② 主图（纯白电商主图，海报/分镜的视觉基准）
# ============================================================
echo "② 主图..."
bl image generate \
  --prompt "电商商品主图，一罐${PRODUCT}易拉罐，罐身印「${BRAND_EN} 0 SUGAR」，纯白背景，正面居中，柔和棚拍布光，罐身挂满冷凝水珠，高级质感，4K产品摄影" \
  --size 3:4 --out-dir "$OUT/images/"
HERO="$(latest "$OUT/images" png)"
cp "$HERO" "$OUT/poster-html/can.png"     # 海报用：白底产品图配 mix-blend-mode:multiply 融图
echo "   -> $HERO"

# ============================================================
# ③ 海报（frontend-design：HTML/CSS 高级感 + 无头截图）
# ============================================================
echo "③ 海报(HTML/CSS)..."
cat > "$OUT/poster-html/poster.html" <<EOF
<!DOCTYPE html><html lang="zh"><head><meta charset="UTF-8"><style>
  *{margin:0;padding:0;box-sizing:border-box;}
  html,body{width:1080px;height:1920px;}
  .poster{width:1080px;height:1920px;position:relative;overflow:hidden;
    background:linear-gradient(168deg,#FCEFEA 0%,#F8DFD5 50%,#F0C7B9 100%);
    font-family:"Noto Sans CJK SC",sans-serif;color:#3A2A28;}
  .poster::after{content:"";position:absolute;inset:0;pointer-events:none;
    background:radial-gradient(120% 70% at 50% 14%,rgba(255,255,255,.55),rgba(255,255,255,0) 58%);}
  .brand{position:absolute;top:84px;left:0;right:0;text-align:center;z-index:3;
    font-family:"Noto Serif CJK SC",serif;font-weight:700;font-size:38px;letter-spacing:10px;}
  .brand small{display:block;margin-top:14px;font-family:"Noto Sans CJK SC",sans-serif;
    font-size:22px;letter-spacing:13px;font-weight:500;color:#B07C77;}
  .zero{position:absolute;top:120px;left:50%;transform:translateX(-50%);
    font-family:"Noto Serif CJK SC",serif;font-weight:900;font-size:1180px;line-height:1;
    color:rgba(154,74,87,.09);z-index:0;user-select:none;}
  .can{position:absolute;top:300px;left:50%;transform:translateX(-50%);width:580px;
    mix-blend-mode:multiply;z-index:1;filter:drop-shadow(0 36px 44px rgba(154,74,87,.22));}
  .eyebrow{position:absolute;top:902px;left:0;right:0;text-align:center;z-index:2;
    font-size:26px;letter-spacing:18px;font-weight:600;color:#A85C61;text-indent:18px;}
  .headline{position:absolute;top:960px;left:0;right:0;text-align:center;z-index:2;
    font-family:"Noto Serif CJK SC",serif;font-weight:700;font-size:128px;line-height:1.16;letter-spacing:8px;}
  .headline .accent{color:#9A4A57;}
  .sub{position:absolute;top:1280px;left:0;right:0;text-align:center;z-index:2;
    font-size:31px;letter-spacing:7px;color:#6E534E;}
  .divider{position:absolute;top:1372px;left:50%;transform:translateX(-50%);width:110px;height:2px;
    background:rgba(58,42,40,.28);z-index:2;}
  .price{position:absolute;top:1418px;left:0;right:0;text-align:center;z-index:2;}
  .price .label{font-size:28px;letter-spacing:10px;color:#A85C61;}
  .price .amount{font-family:"Noto Serif CJK SC",serif;font-weight:900;font-size:158px;color:#9A4A57;line-height:1.05;}
  .price .amount .cur{font-size:66px;vertical-align:8px;margin-right:4px;}
  .price .unit{font-size:30px;color:#6E534E;letter-spacing:3px;}
  .cta{position:absolute;top:1672px;left:50%;transform:translateX(-50%);z-index:2;
    background:#9A4A57;color:#fff;font-size:39px;letter-spacing:10px;font-weight:600;text-indent:10px;
    padding:32px 92px;border-radius:60px;box-shadow:0 18px 40px rgba(154,74,87,.38);}
  .trust{position:absolute;bottom:84px;left:0;right:0;text-align:center;z-index:2;
    font-size:24px;letter-spacing:6px;color:#A7837B;text-indent:6px;}
</style></head><body>
  <div class="poster">
    <div class="zero">0</div>
    <div class="brand">${BRAND_EN}<small>白 桃 气 泡 水</small></div>
    <img class="can" src="can.png" alt="">
    <div class="eyebrow">夏 日 限 定 · SUMMER</div>
    <div class="headline">白桃之夏<br><span class="accent">0 糖 0 卡</span></div>
    <div class="sub">真实白桃原浆 · 绵密微气泡 · 赤藓糖醇代糖</div>
    <div class="divider"></div>
    <div class="price"><div class="label">尝 鲜 价</div>
      <div class="amount"><span class="cur">¥</span>${PRICE}</div>
      <div class="unit">/ 罐 · 整箱更划算</div></div>
    <div class="cta">立即尝鲜 →</div>
    <div class="trust">0 蔗糖 · 0 防腐剂 · 喝甜不升糖</div>
  </div>
</body></html>
EOF
if [ -n "$CHROME" ]; then
  "$CHROME" --headless --no-sandbox --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=1 --window-size=1080,1920 \
    --screenshot="$OUT/poster-html/poster.png" "file://$OUT/poster-html/poster.html" 2>/dev/null
  cp "$OUT/poster-html/poster.png" "$OUT/posters/poster.png"
  echo "   -> $OUT/poster-html/poster.png"
fi

# ============================================================
# ④ 配音（念连贯 VO，cosyvoice）
# ============================================================
echo "④ 配音..."
bl speech synthesize --text-file "$OUT/text/vo-ad.txt" --voice "$VOICE" --out "$OUT/audio/vo-ad.mp3"

# ============================================================
# ⑤ 短视频（video-storyboard：5 分镜，逐镜 关键帧 → 图生视频）
# ============================================================
echo "⑤ 5 分镜(关键帧 → 图生视频)..."
STYLE="竖屏9:16，电影感产品广告，浅景深，柔和暖光，粉桃色调，4K质感，同一罐 ${BRAND_EN} 0 SUGAR 白桃气泡水"
KF=(
  "$STYLE，极近特写：冰桶里一只年轻女性的手，握住挂满水珠的白桃气泡水罐，拉环刚开盖，罐口冒出白色清凉气雾"
  "$STYLE，慢动作特写：气泡水注入装满冰块的玻璃杯，绵密气泡翻涌上升，新鲜白桃片漂浮"
  "$STYLE，产品特写：罐身正面缓缓旋转，冷凝水珠滑落，阳光质感，「0 SUGAR」标识高亮"
  "$STYLE，生活方式：一位年轻女孩在夏日草地仰头畅快喝一口，满足表情，光影通透清爽"
  "$STYLE，场景：一排冰镇的白桃气泡水堆头陈列，水珠特写，罐子整齐排列，诱人促销氛围"
)
MV=(
  "单镜头缓推，气雾与水珠制造刚开盖那一刻的清凉冲击感"
  "慢动作跟随液体流动，气泡翻涌，白桃片随水流漂浮"
  "镜头环绕缓慢旋转，水珠滑落，光线在罐身流动"
  "人物中景缓缓推近到面部特写，仰头畅饮，发丝与光影自然流动"
  "产品堆头横移，水珠滚落，结尾定格于诱人排罐"
)
for i in 1 2 3 4 5; do
  k=$((i-1))
  echo "   · Shot $i 关键帧..."
  bl image generate --prompt "${KF[$k]}" --negative-prompt "$NEG" \
    --size 9:16 --out-dir "$TMP/kf$i/"
  frame="$(latest "$TMP/kf$i" png)"
  cp "$frame" "$OUT/storyboard/scene-0$i.png"
  echo "   · Shot $i 图生视频(分钟级)..."
  bl video generate --image "$frame" --prompt "${MV[$k]}，${STYLE}" \
    --negative-prompt "$NEG" --resolution 720P --duration 5 \
    --download "$OUT/storyboard/scene-0$i.mp4"
done

# ============================================================
# ⑥ 合成（裁水印/归一化 720×1280@30fps → 拼接 → 配音对齐）
# ============================================================
echo "⑥ 合成竖屏成片..."
: > "$TMP/concat.txt"
for i in 1 2 3 4 5; do
  # 居中裁到 720×1280（顺带切掉边缘潜在水印）、统一 30fps、丢弃模型自带音轨
  ffmpeg -y -loglevel error -i "$OUT/storyboard/scene-0$i.mp4" -an \
    -vf "scale=-2:1280:flags=lanczos,crop=720:1280,fps=30,format=yuv420p,setsar=1" \
    -c:v libx264 -preset medium -crf 18 "$TMP/n$i.mp4"
  echo "file '$TMP/n$i.mp4'" >> "$TMP/concat.txt"
done
ffmpeg -y -loglevel error -f concat -safe 0 -i "$TMP/concat.txt" -c copy "$TMP/video_only.mp4"
ffmpeg -y -loglevel error -i "$TMP/video_only.mp4" -i "$OUT/audio/vo-ad.mp3" \
  -c:v copy -c:a aac -b:a 192k -map 0:v -map 1:a -shortest "$OUT/final-vertical.mp4"

rm -rf "$TMP"
echo "==== ✅ 完成! ===="
echo "  竖屏成片 : $OUT/final-vertical.mp4"
echo "  海报     : $OUT/poster-html/poster.png"
echo "  剧本     : $OUT/script.md"
echo "  分镜      : $OUT/storyboard/scene-0[1-5].mp4"
