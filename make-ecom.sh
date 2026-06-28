#!/usr/bin/env bash
# 一行指令做完一整条电商内容线 —— 食品饮料 Demo (百炼 bl CLI)
# 用法: ./make-ecom.sh "白桃味0糖气泡水" "年轻、清爽、健康、夏日"
# 依赖: bl (bailian-cli, 已鉴权) + ffmpeg + python3
# 注意: dashscope 是国内端点, 跑前请确保代理已关 / aliyuncs.com 走直连, 否则会 code6 抽风
set -euo pipefail

PRODUCT="${1:-白桃味0糖气泡水}"
TONE="${2:-年轻、清爽、健康、夏日}"
VOICE="${3:-longyingxiao_v3}"        # 龙应笑·清甜推销女; 换音色: bl speech synthesize --list-voices --model cosyvoice-v3-flash
ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT="$ROOT/output"
mkdir -p "$OUT"/{text,images,posters,audio,video}

echo "==== 产品: $PRODUCT | 调性: $TONE ===="

# ① 文案 (用 --quiet 直接存纯文本正文; 别用 --output json 重定向, 那样存进去的不是合法 JSON)
echo "① 文案..."
bl text chat --system "你是资深电商内容运营，擅长写高转化商品文案" \
  --message "为『$PRODUCT』写电商内容：1)5个含关键词的标题 2)6条核心卖点 3)一段约30秒短视频口播脚本(口语化、有节奏)。品牌调性：$TONE。" \
  --quiet > "$OUT/text/copy.txt"
echo "   -> $OUT/text/copy.txt"

# 口播脚本 vo.txt: 由运营手动从 copy.txt 里摘出可朗读的纯口播(去掉[0-3s]这类分镜标记)
# 若不存在则用一句兜底, 保证脚本能一路跑通
[ -f "$OUT/text/vo.txt" ] || echo "夏天的第一口气泡，给你白桃的清甜。0糖0卡，畅快无负担，这个夏天就喝它！" > "$OUT/text/vo.txt"

# ② 主图 (纯白电商主图, 后续海报/视频都基于它)
echo "② 主图..."
bl image generate \
  --prompt "电商商品主图，一罐$PRODUCT，纯白背景，柔和棚拍布光，罐身挂满水珠，高级质感，4K产品摄影，居中构图" \
  --size 1:1 --out-dir "$OUT/images/"
IMG="$(ls -t "$OUT/images/"*.png | head -1)"
echo "   -> $IMG"

# ③ 海报 (基于②主图做促销海报; qwen-image-edit 中文上字效果不错)
echo "③ 海报..."
bl image edit --image "$IMG" \
  --prompt "把这张商品图做成电商促销海报：顶部大字中文标题『0糖0卡 真实白桃』，副标题『夏日尝鲜 清爽无负担』，底部醒目价格标签『尝鲜价 ¥9.9』，活力粉桃色渐变氛围，留出文字排版空间，精致电商促销风格" \
  --size 3:4 --out-dir "$OUT/posters/"

# ④ 配音 (念 vo.txt)
echo "④ 配音..."
bl speech synthesize --text-file "$OUT/text/vo.txt" --voice "$VOICE" --out "$OUT/audio/vo.mp3"

# ⑤ 短视频 (图生视频, 基于②主图; 最慢, 异步分钟级)
echo "⑤ 短视频(图生视频)..."
bl video generate --image "$IMG" \
  --prompt "镜头缓慢推进，罐身水珠缓缓滑落，气泡上升，光线流动，柔和唯美的产品广告镜头" \
  --resolution 720P --duration 5 --download "$OUT/video/clip1.mp4"

# ⑥ 合成 (视频 + 配音; 以视频时长为准)
echo "⑥ 合成成片..."
ffmpeg -y -i "$OUT/video/clip1.mp4" -i "$OUT/audio/vo.mp3" \
  -c:v copy -c:a aac -map 0:v -map 1:a -shortest "$OUT/final.mp4"

echo "==== ✅ 完成! 成片: $OUT/final.mp4 ===="
