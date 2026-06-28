# PLAN.md — 一行指令做完一整条电商内容线

> **Workshop 现场作战计划** · 半天(2–3 小时) · 品类：**食品饮料** · 目标：**现场演示给观众看**
> 核心卖点：**一句自然语言指令 → 文案 + 主图 + 海报 + 配音 + 短视频成片，一整套电商内容自动产出。**

---

## 0. 今天要达成的「哇时刻」

观众看到的：你对 Claude Code 说**一句话**——

> 「用百炼给『白桃味0糖气泡水』做一整套电商内容：文案、主图、营销海报、口播配音，还有一条能直接发布的短视频成片。」

10 分钟后，桌面上多出一个文件夹，里面是**成品文案 + 商品图 + 海报 + 配音 + 短视频**。

背后真相（你心里清楚、待会儿讲给观众）：这一句话被翻译成了一串 `bl`（百炼 CLI）命令，按顺序把阿里全模态模型（qwen 文本 / qwen-image 图 / happyhorse 视频 / cosyvoice 语音）串成了一条流水线。

---

## 1. 环境检查清单（开场前必须全绿）

| 项 | 状态 | 处理 |
|---|---|---|
| `bl` 已安装 (v0.1.2) | ✅ | 已就绪 |
| `bl` 已鉴权 (api-key) | ✅ | `bl auth status` 已确认 |
| `ffmpeg`（合成成片用） | ❌ **未装** | `sudo apt update && sudo apt install -y ffmpeg`，装完 `ffmpeg -version` 验证 |
| 输出目录 | ⬜ | `mkdir -p output/{text,images,posters,audio,video}` |
| 演示产品已锁定 | ⬜ | 见第 2 节 |
| 网络通畅 / 不挂代理 | ⬜ | 视频生成是异步长任务，网络一定要稳 |

> ⚠️ **ffmpeg 是唯一的硬阻塞**：没有它，第⑥步「合成成片」做不了。第一件事就把它装上。

---

## 2. 演示产品（建议，可一键替换）

**主推：白桃味 0 糖气泡水**——理由：颜色讨喜（粉/桃）、出图出片效果稳、卖点清晰（0糖0卡、夏日、清爽），观众一看就懂。

| 字段 | 内容 |
|---|---|
| 产品 | 白桃味 0 糖气泡水（330ml 易拉罐） |
| 品牌调性 | 年轻、清爽、健康、夏日 |
| 核心卖点 | 0 糖 0 卡 / 真实白桃风味 / 畅快气泡 / 无负担 |
| 备选品类 | 精品冷萃咖啡液、每日坚果礼盒、海盐苏打水（换产品只改这一段 brief） |

> 演示时「换产品」本身就是一个加分动作——证明这是**模板化、可复用**的，不是一次性手工活。

---

## 3. 内容线 Pipeline（6 步串联）

```
一句话指令
   │
   ├─①  文案   bl text chat        → 标题 / 卖点 / 30秒口播脚本   → output/text/
   ├─②  主图   bl image generate   → 纯白背景商品主图            → output/images/
   ├─③  海报   bl image edit       → 营销海报（基于②主图改）     → output/posters/
   ├─④  配音   bl speech synthesize → 口播音频（念①的脚本）       → output/audio/
   ├─⑤  视频   bl video generate    → 图生视频，商品动起来（基于②）→ output/video/
   └─⑥  合成   ffmpeg              → 成片 = ⑤视频 + ④配音 (+BGM) → output/final.mp4
```

关键依赖：**②主图**是枢纽——③海报、⑤视频都基于它；**①文案**喂给**④配音**。所以①②必须先跑、且质量要稳。

---

## 4. 半天时间表（约 2.5 小时）

| 阶段 | 时长 | 做什么 | 产出 |
|---|---|---|---|
| **P0 准备** | 20 min | 装 ffmpeg、建目录、锁产品 brief | 环境全绿 |
| **P1 跑通单条链路** | 60 min | 第①→⑥步逐个手动跑通，确认每步都有满意输出 | 一套完整成品 |
| **P2 固化成「一行指令」** | 30 min | 串成可复用脚本 + 设计现场要说的那句话 | `make-ecom.sh` + 演示话术 |
| **P3 备份 + 彩排 + 话术** | 40 min | **预生成一份备份成品**、全流程彩排计时、准备讲解词 | 兜底素材 + 顺过的 demo |
| 机动 buffer | — | 视频生成慢/重试的缓冲 | — |

---

## 5. 「一行指令」的两层实现（演示时都展示）

### 层 A — Claude Code 编排（最有冲击力）
现场你**只说一句话**，由我（Claude Code）实时把它拆成 `bl` 命令链执行。这就是观众看到的「自然语言 → 全套内容」。
> 演示词见第 7 节。

### 层 B — 可复用脚本（证明可固化）
把链路写死成一个脚本，换产品只改一个变量：
```bash
./make-ecom.sh "白桃味0糖气泡水" "年轻清爽健康"
```
脚本骨架（P2 阶段产出，放 `make-ecom.sh`）：
```bash
#!/usr/bin/env bash
set -e
PRODUCT="$1"; TONE="$2"; OUT=output
mkdir -p $OUT/{text,images,posters,audio,video}

# ① 文案
bl text chat --system "资深电商内容运营" \
  --message "为『$PRODUCT』写：5个标题、6条卖点、1段30秒口播脚本。调性：$TONE" \
  --output json --quiet > $OUT/text/copy.json

# ② 主图
bl image generate --prompt "电商主图，一罐$PRODUCT，纯白背景，棚拍布光，水珠，高级质感，4K产品摄影" \
  --size 1:1 --out-dir $OUT/images/

# ③ 海报（取②的产物）
IMG=$(ls -t $OUT/images/*.png | head -1)
bl image edit --image "$IMG" --prompt "做成促销海报：加大字标题与价格标签，活力渐变背景，电商风" \
  --size 3:4 --out-dir $OUT/posters/

# ④ 配音（口播脚本另存为 vo.txt 后）
bl speech synthesize --text-file $OUT/text/vo.txt --voice longyumi_v3 --out $OUT/audio/vo.mp3

# ⑤ 图生视频
bl video generate --image "$IMG" --prompt "镜头缓推，水珠滑落，气泡上升，唯美产品广告" \
  --resolution 720P --duration 5 --download $OUT/video/clip1.mp4

# ⑥ 合成
ffmpeg -y -i $OUT/video/clip1.mp4 -i $OUT/audio/vo.mp3 \
  -c:v copy -c:a aac -map 0:v -map 1:a -shortest $OUT/final.mp4
echo "✅ 成片: $OUT/final.mp4"
```

---

## 6. 命令速查表（已填好白桃气泡水，可直接复制）

**① 文案**
```bash
bl text chat \
  --system "你是资深电商内容运营，擅长写高转化商品文案" \
  --message "为一款『白桃味0糖气泡水』写电商内容：1)5个商品标题(含搜索关键词) 2)6条核心卖点 3)一段30秒短视频口播脚本(口语化、有节奏感)。品牌调性：年轻、清爽、健康、夏日。" \
  --output json --quiet
```

**② 主图**
```bash
bl image generate \
  --prompt "电商商品主图，一罐白桃味0糖气泡水易拉罐，纯白背景，柔和棚拍布光，罐身挂水珠，旁边点缀新鲜白桃与薄荷叶，高级质感，4K产品摄影" \
  --size 1:1 --out-dir ./output/images/
```

**③ 海报**（把 `<主图>` 换成②生成的文件名）
```bash
bl image edit \
  --image ./output/images/<主图>.png \
  --prompt "把这张商品图做成电商促销海报：顶部加大字标题『0糖0卡 真实白桃』，底部加『夏日尝鲜价 ¥9.9』标签，活力粉桃色渐变背景" \
  --size 3:4 --out-dir ./output/posters/
```

**④ 配音**（先 `--list-voices` 选音色；把口播脚本存成 `output/text/vo.txt`）
```bash
bl speech synthesize --list-voices --model cosyvoice-v3-flash   # 先看有哪些音色
bl speech synthesize \
  --text "夏天的第一口气泡，是白桃的甜。0糖0卡，畅快无负担，这个夏天就喝它！" \
  --voice longyumi_v3 --out ./output/audio/vo.mp3
```

**⑤ 短视频（图生视频）**
```bash
bl video generate \
  --image ./output/images/<主图>.png \
  --prompt "镜头缓慢推进，气泡水罐身水珠滑落，气泡上升，光线流动，唯美产品广告镜头" \
  --resolution 720P --duration 5 \
  --download ./output/video/clip1.mp4
```

**⑥ 合成成片**
```bash
ffmpeg -y -i ./output/video/clip1.mp4 -i ./output/audio/vo.mp3 \
  -c:v copy -c:a aac -map 0:v -map 1:a -shortest ./output/final.mp4
```

> 多片段拼接（可选，让成片更丰富）：`bl video generate` 多跑几条不同镜头，再用 `ffmpeg -f concat` 拼起来，最后叠配音。

---

## 7. 现场演示流程 + 讲解话术

**开场（30 秒）**
> 「电商一条内容线，过去要文案、设计、摄影、剪辑四个工种几天时间。今天我用一句话，10 分钟做完。」

**执行（一边跑一边讲）**
1. 输入那句话 → 我开始派 `bl` 命令。
2. 趁文案/图在生成，讲**双层 AI**：「Claude 负责听懂我、调度工具；百炼的 qwen、happyhorse 模型负责真正生成内容。」
3. 主图出来 → 讲**自动上传**：「这张本地图要喂给视频模型，`bl` 自动帮我上传，不用碰 OSS。」
4. 视频生成时（最慢）→ 讲**pipeline 串联**：前一步的图，是后一步视频的输入。
5. `ffmpeg` 合成 → 打开 `final.mp4`，收尾。

**收尾（金句）**
> 「这不是一次性手工活——换个产品名，同一条指令，立刻出下一套。这就是『一行指令做完一整条电商内容线』。」

**讲解备忘**：双层 AI / 本地文件自动上传 / 全模态打包成命令 / 可固化可复用。

---

## 8. 风险与兜底（现场 demo 的重点，别省）

| 风险 | 概率 | 兜底方案 |
|---|---|---|
| **视频生成慢/超时**（异步长任务，最大风险） | 高 | **P3 预生成一份完整备份成品**；现场若卡住，直接切到备份，嘴上不停讲解 |
| 生成质量不稳（图/文不达预期） | 中 | 关键步骤**固定 `--seed`**；预存 2–3 个满意版本备选 |
| 内容审核/敏感词拦截 | 低 | 文案避免绝对化用语（「最」「第一」）；提前跑通确认不被拦 |
| 网络抖动 | 中 | 不挂代理；`bl video generate` 加 `--no-wait` 拿 task-id，再 `bl video task get` 轮询 |
| 音色 id 不对导致配音报错 | 中 | **现场前先 `--list-voices` 确认音色 id**，写进脚本 |
| ffmpeg 没装 | — | P0 第一件事解决 |

> **黄金法则**：现场跑的每一步，**P3 彩排时都已经成功跑过一遍**，并留好产物。现场是「重演 + 讲解」，不是「首演」。

---

## 9. 验收清单（结束前自检）

- [ ] ffmpeg 已装、`final.mp4` 能正常播放（画面 + 配音都在）
- [ ] `output/` 里五类产物齐全：文案 / 主图 / 海报 / 配音 / 视频
- [ ] `make-ecom.sh` 能换产品名重跑
- [ ] 备份成品已生成、随时可切
- [ ] 音色 id 已确认、文案无审核风险
- [ ] 全流程彩排过一遍、计过时（控制在观众耐心内）
- [ ] 讲解话术顺过、金句记牢

---

## 下一步（现在就能做）
1. 我帮你**装 ffmpeg + 建目录** → 环境一键就绪
2. 我帮你**真跑一遍 ①文案 + ②主图** 做冒烟测试，确认链路通、看实际效果与耗时
3. 跑通后**固化成 `make-ecom.sh`**，并**预生成一份备份成品**

需要我从哪一步开始？（建议先 1 → 2）
