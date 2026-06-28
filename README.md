# 一行指令做完一整条电商内容线

> Workshop 作品 · 用阿里云**百炼 CLI（`bl`）**把一句自然语言指令，跑成一条完整的电商内容生产线。

**演示商品**：白桃味 0 糖气泡水（食品饮料 / 夏日新品）
**交付物**：商品文案 + 主图/海报 + 短视频成片 + 口播配音，全链路 AI 生成。

---

## 🎬 最终成片

| 交付物 | 文件 | 规格 |
|--------|------|------|
| 竖屏短视频广告 | [`output/final-vertical.mp4`](output/final-vertical.mp4) | 9:16 · 720×1280 · 25.7s |
| 高级促销海报 | [`output/poster-html/poster.png`](output/poster-html/poster.png) | 9:16 · 1080×1920 |
| 短视频广告剧本 | [`output/script.md`](output/script.md) | 5 分镜 / PAS 框架 |

成片由 5 段独立**图生视频**镜头按剧本顺序拼接，配音逐句对齐：

| 镜 | 内容 | 时段 |
|----|------|------|
| 1 · Hook | 冰桶手持开盖 · 气雾喷出 | 0–5.1s |
| 2 · 转折 | 注入冰杯 · 白桃片漂浮 | 5.1–10.3s |
| 3 · 卖点 | 罐身水珠特写 | 10.3–15.4s |
| 4 · 场景 | 草地女孩仰头畅饮 | 15.4–20.5s |
| 5 · CTA | 堆头陈列 · 冰镇排罐 | 20.5–25.7s |

---

## 🛠 内容生产线（6 步）

```
① 文案    bl text chat        →  标题 / 卖点 / 口播脚本
② 主图    bl image generate   →  纯白电商主图（9:16 关键帧）
③ 海报    HTML/CSS + 截图      →  高级感促销海报
④ 配音    bl speech synthesize →  口播配音（cosyvoice-v3）
⑤ 视频    bl video generate    →  图生视频 ×5 分镜
⑥ 合成    ffmpeg              →  裁水印 / 归一化 / 拼接 / 混音
```

所有模型调用通过百炼一个 CLI 完成（文本 qwen / 图像 qwen-image / 视频 i2v / 语音 cosyvoice），`ffmpeg` 仅做后期合成。

一键复跑：

```bash
./make-ecom.sh "白桃味0糖气泡水" "年轻、清爽、健康、夏日"
```

---

## 🧩 用到的 Skill

**驱动生产线的 skill**

| Skill | 用途 |
|-------|------|
| `bailian-cli`（`bl`） | 全链路模型调用：文案 / 主图 / 配音 / 图生视频 |
| `video-storyboard` | 生成 5 段分镜图板 + 图生视频提示词脚本，保证镜头连贯 |
| `frontend-design` | HTML/CSS 海报的视觉方向与高级感（排版、配色、融图手法） |

**百炼 skill 包（`skills-lock.json`）**

| Skill | 说明 |
|-------|------|
| `bailian-docs-llm-wiki` | 百炼文档 / 用法知识 |
| `bailian-model-recommend` | 模型选型建议（文本 / 图像 / 视频） |
| `happyhorse-prompt-studio` | 视频模型（happyhorse）提示词工坊 |
| `financial-expert` | 百炼示例 skill |
| `novel-game` | 百炼示例 skill |
| `spark-video-episode` | 百炼视频剧集 skill |

---

## 📁 目录结构

```
.
├── PLAN.md                 # 半天 workshop 作战计划
├── make-ecom.sh            # 一键流水线脚本
├── skills-lock.json        # 用到的 skill 清单
└── output/
    ├── final-vertical.mp4  # ★ 9:16 竖屏成片
    ├── script.md           # 5 分镜广告剧本
    ├── text/               # 文案（3 版）+ 口播稿
    ├── images/             # 主图 v1/v2/v3
    ├── poster-html/        # HTML 海报源码 + poster.png
    ├── posters/            # 海报导出
    ├── storyboard/         # 5 段分镜视频 + 关键帧 + 分镜脚本
    └── audio/              # 配音 mp3
```

---

## 💡 设计要点

- **剧本编排**：PAS（痛点→放大→解决）+ Hook-Value-CTA，前 3 秒强钩子「夏天想喝甜的，又怕胖？」
- **画面一致性**：白罐「WHITE PEACH 0 SUGAR」+ 白桃片 + 冰块水珠 + 粉桃色调贯穿全片
- **海报高级感**：衬线大字 + 巨型半透「0」品牌签名 + `mix-blend-mode:multiply` 融图 + 莫兰迪粉桃配色，克制不廉价
- **平台适配**：9:16 抖音 / 小红书原生比例，字幕居中偏下避开 UI 安全区

---

## ⚙️ 依赖

- 百炼 CLI `bl`（已鉴权）— 国内 dashscope 端点，跑前确保代理走直连
- `ffmpeg`（后期合成）
- 系统 CJK 字体（海报截图，Noto Serif/Sans CJK SC）
