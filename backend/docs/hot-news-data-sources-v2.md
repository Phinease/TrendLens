# TrendLens 热榜数据接口选型 v2

> **定位：** 后端实际使用的热榜数据接口规范（基于 data-sources-v1.md 调研筛选）
> **前置文档：** [data-sources-v1.md](data-sources-v1.md) — 全量数据源调研（61 个源）
> **配套文档：** [data-requirements.md](data-requirements.md) — 数据需求与字段映射
> **最后更新：** 2026-02-23

---

## 一、选型标准与内容策略

### 1.1 选型标准

1. **数据丰富度**：优先选择能直接提供标题 + 热度/排名 + 描述的接口
2. **内容可获取性**：可通过单一或串联接口获取话题正文内容
3. **接口稳定性**：data-sources-v1.md 验证通过（✅），无复杂鉴权
4. **品类覆盖**：国内综合、科技、财经、国际

### 1.2 两阶段内容获取策略

所有数据源统一采用 **列表 + 正文** 两阶段获取：

```
阶段 1（Fetch）：调用热榜 API → 获取标题、热度、排名、链接
阶段 2（Scrape）：跟踪链接 → 请求目标页面 → 解析提取正文内容
```

| 策略类型 | 说明 | 适用源 |
|---------|------|--------|
| **A - API 全量** | 单一 API 直接返回列表 + 内容 | wallstreetcn-quick, kaopu |
| **B - API + 页面抓取** | API 获取列表，跟踪 URL 抓取正文 | zhihu, baidu, toutiao, thepaper, hackernews |
| **C - 全量页面抓取** | 列表和内容均从 HTML 解析 | weibo, 36kr, ithome |
| **D - 关键词扩展** | 热搜关键词 → 搜索 API 获取相关内容 | douyin, bilibili-hot-search |

---

## 二、已选数据源总览

### 实施优先级

| 级别 | 说明 | 数量 | 目标 |
|------|------|------|------|
| **P0** | 核心源，Wave 1 | 7 源 / 8 端点 | 覆盖主流国内平台 |
| **P1** | 重要补充，Wave 2 | 6 源 | 扩展新闻 + 科技 |
| **P2** | 延伸覆盖，Wave 3 | 7 源 | 覆盖财经 + 国际 |

### 总览表

| # | 源 ID | 平台 | 分类 | 优先级 | 内容策略 | 鉴权 | 丰富度 |
|---|-------|------|------|--------|---------|------|--------|
| 1 | `zhihu` | 知乎 | 国内 | P0 | B | 无 | ★★★★★ |
| 2 | `baidu` | 百度 | 国内 | P0 | B | 无 | ★★★★ |
| 3 | `weibo` | 微博 | 国内 | P0 | C | Cookie | ★★★ |
| 4 | `bilibili-hot-search` | B站热搜 | 国内 | P0 | D | 无 | ★★★ |
| 5 | `bilibili-hot-video` | B站热门 | 国内 | P0 | A | 无 | ★★★★★ |
| 6 | `douyin` | 抖音 | 国内 | P0 | D | Client Token | ★★★ |
| 7 | `toutiao` | 今日头条 | 国内 | P0 | B | 无 | ★★★★ |
| 8 | `sina-news` | 新浪新闻 | 国内 | P1 | B | 无 | ★★★★ |
| 9 | `thepaper` | 澎湃新闻 | 国内 | P1 | B | 无 | ★★★ |
| 10 | `tencent-hot` | 腾讯新闻 | 国内 | P1 | B | Referer | ★★★★ |
| 11 | `hackernews` | Hacker News | 科技 | P1 | B | 无 | ★★★★ |
| 12 | `36kr-renqi` | 36氪 | 科技 | P1 | C | 无 | ★★★★ |
| 13 | `douban` | 豆瓣 | 国内 | P1 | B | Referer | ★★★ |
| 14 | `wallstreetcn-hot` | 华尔街见闻 | 财经 | P2 | A | 无 | ★★★★ |
| 15 | `cankaoxiaoxi` | 参考消息 | 国际 | P2 | B | 无 | ★★★ |
| 16 | `github-trending` | GitHub | 科技 | P2 | A | 无 | ★★★ |
| 17 | `netease-news` | 网易新闻 | 国内 | P2 | B | 无 | ★★★★ |
| 18 | `tieba` | 百度贴吧 | 国内 | P2 | B | 无 | ★★ |
| 19 | `ithome` | IT之家 | 科技 | P2 | C | 无 | ★★★ |
| 20 | `kaopu` | 靠谱新闻 | 国际 | P2 | A | 无 | ★★★★ |

---

## 三、P0 核心源详述

### 1. 知乎 `zhihu` — 热榜

**阶段 1：热榜列表**

```
GET https://www.zhihu.com/api/v3/feed/topstory/hot-list-web?limit=50&desktop=true
```

| 字段路径 | 说明 |
|---------|------|
| `data[].target.title_area.text` | 标题 |
| `data[].target.excerpt_area.text` | 摘要 |
| `data[].target.image_area.url` | 封面图 |
| `data[].target.metrics_area.text` | 热度文本（如 "2345 万热度"） |
| `data[].target.link.url` | 链接（`zhihu.com/question/xxx`） |

**阶段 2：正文抓取**

- **目标**：`data[].target.link.url`（知乎问题页）
- **方案 A（推荐）**：`GET https://www.zhihu.com/api/v4/questions/{id}/answers?limit=1&sort_by=default` → 获取 JSON 格式最佳答案，提取 `data[0].content`（HTML 富文本）
- **方案 B**：请求问题页 HTML → 解析 `div.RichContent-inner` 获取答案内容
- **图片提取**：从答案 HTML 中提取 `<img>` 标签的 `data-original` 属性

**字段映射**：

| TrendLens 字段 | 来源 | 阶段 | 处理 |
|---------------|------|------|------|
| title | `title_area.text` | 1 | 直接使用 |
| heatValue | `metrics_area.text` | 1 | 解析数字（"2345万" → 23450000） |
| rank | 列表索引 | 1 | `index + 1` |
| link | `link.url` | 1 | 直接使用 |
| description | `excerpt_area.text` | 1 | 直接使用 |
| content | 答案正文 | 2 | HTML → 纯文本 |
| imageURLs | `image_area.url` + 正文图片 | 1+2 | 合并去重 |
| tags | 问题标签 | 2 | 从问题页提取 |

---

### 2. 百度 `baidu` — 热搜

**阶段 1：热搜列表**

```
GET https://top.baidu.com/board?tab=realtime
```

- **解析方式**：正则提取 HTML 注释 `<!--s-data:...-->` 内嵌 JSON

| 字段路径 | 说明 |
|---------|------|
| `data.cards[0].content[].word` | 关键词/标题 |
| `data.cards[0].content[].desc` | 描述 |
| `data.cards[0].content[].rawUrl` | 原文链接 |
| `data.cards[0].content[].hotScore` | 热搜指数 |
| `data.cards[0].content[].img` | 图片 URL |
| `data.cards[0].content[].isTop` | 是否置顶（过滤用） |

**阶段 2：正文抓取**

- **目标**：`rawUrl` 字段指向的百度资讯聚合页
- **策略**：请求 `rawUrl` → 解析百度资讯页面，提取聚合内容或跳转到原始新闻页
- **备注**：百度热搜 `desc` 已提供较好的描述，很多场景阶段 1 数据即可满足

**字段映射**：

| TrendLens 字段 | 来源 | 阶段 | 处理 |
|---------------|------|------|------|
| title | `word` | 1 | 直接使用 |
| heatValue | `hotScore` | 1 | 直接使用（数字） |
| rank | 列表索引 | 1 | `index + 1`，过滤 `isTop` |
| link | `rawUrl` | 1 | 直接使用 |
| description | `desc` | 1 | 直接使用 |
| content | 聚合页正文 | 2 | 页面解析 |
| imageURLs | `img` | 1 | 直接使用 |

---

### 3. 微博 `weibo` — 热搜

**阶段 1：热搜列表**

```
GET https://s.weibo.com/top/summary?cate=realtimehot
Headers: Cookie: SUB=xxx; User-Agent: xxx; Referer: xxx
```

- **解析方式**：Cheerio 解析 `#pl_top_realtimehot table tbody tr`

| 字段路径 | 说明 |
|---------|------|
| `td.td-02 a` (text) | 热搜标题 |
| `td.td-02 a` (href) | 搜索链接（`/weibo?q=xxx`） |
| `td.td-02 span` | 热度数值 |
| `td.td-03 i` | 标记（新/热/爆/沸） |

**阶段 2：正文抓取**

- **目标**：将搜索链接转换为 `https://s.weibo.com/weibo?q=xxx` → 抓取搜索结果页
- **替代方案**：使用移动端 API `https://m.weibo.cn/api/container/getIndex?containerid=100103type%3D1%26q%3D{keyword}` 获取 JSON 格式搜索结果
- **提取内容**：取前 3-5 条微博正文作为话题内容
- **风险**：Cookie 可能过期，需要维护更新机制

**字段映射**：

| TrendLens 字段 | 来源 | 阶段 | 处理 |
|---------------|------|------|------|
| title | `td.td-02 a` text | 1 | 直接使用 |
| heatValue | `td.td-02 span` | 1 | 解析数字 |
| rank | 列表索引 | 1 | `index + 1` |
| link | 搜索链接 | 1 | 拼接完整 URL |
| content | 搜索结果微博正文 | 2 | 合并前 N 条微博 |
| tags | 无 | — | AI 提取或标记字段 |

---

### 4. 哔哩哔哩热搜 `bilibili-hot-search`

**阶段 1：热搜列表**

```
GET https://s.search.bilibili.com/main/hotword?limit=30
```

| 字段路径 | 说明 |
|---------|------|
| `list[].keyword` | 热搜关键词 |
| `list[].show_name` | 显示名 |
| `list[].icon` | 标签图标（热/新等） |
| `list[].hot_id` | 热搜 ID |

**阶段 2：内容扩展（关键词 → 搜索结果）**

- **策略**：使用关键词调用搜索 API 获取相关视频
- **接口**：`GET https://api.bilibili.com/x/web-interface/wbi/search/type?search_type=video&keyword={keyword}&page=1&page_size=5`
- **提取**：取前 5 个搜索结果的标题、描述、播放量
- **注意**：搜索 API 可能需要 WBI 签名（MD5），参考 bilibili-API-collect 文档

**字段映射**：

| TrendLens 字段 | 来源 | 阶段 | 处理 |
|---------------|------|------|------|
| title | `keyword` | 1 | 直接使用 |
| heatValue | 列表位置估算 | 1 | 基于排名位置估算 |
| rank | 列表索引 | 1 | `index + 1` |
| content | 搜索结果聚合 | 2 | 合并前 N 条视频描述 |
| imageURLs | 搜索结果封面 | 2 | 提取视频封面 |
| link | 搜索链接 | 1 | 拼接 B 站搜索 URL |

---

### 5. 哔哩哔哩热门 `bilibili-hot-video`

**阶段 1：热门视频列表（内容策略 A - API 全量）**

```
GET https://api.bilibili.com/x/web-interface/popular?ps=20&pn=1
```

| 字段路径 | 说明 |
|---------|------|
| `data.list[].bvid` | BV 号 |
| `data.list[].title` | 视频标题 |
| `data.list[].desc` | 视频描述 |
| `data.list[].owner.name` | UP 主名 |
| `data.list[].stat.view` | 播放量 |
| `data.list[].stat.like` | 点赞数 |
| `data.list[].stat.danmaku` | 弹幕数 |
| `data.list[].pic` | 封面图 |

**阶段 2：无需二次抓取**

API 已直接返回视频描述、统计数据和封面图，数据充足。

**字段映射**：

| TrendLens 字段 | 来源 | 阶段 | 处理 |
|---------------|------|------|------|
| title | `title` | 1 | 直接使用 |
| heatValue | `stat.view` | 1 | 直接使用播放量 |
| rank | 列表索引 | 1 | `index + 1` |
| link | `https://www.bilibili.com/video/{bvid}` | 1 | 拼接 |
| description | `desc` | 1 | 直接使用 |
| content | `desc` + UP主信息 + 统计数据 | 1 | 组合格式化 |
| imageURLs | `[pic]` | 1 | 直接使用 |
| tags | UP 主名 | 1 | 作为标签使用 |

> **限制**：Cloudflare 环境不可用（`^cf^`）

---

### 6. 抖音 `douyin` — 热搜

**阶段 1：热搜列表（官方 API）**

```
# 先获取 Client Token
POST https://open.douyin.com/oauth/client_token/
Body: { "client_key": "xxx", "client_secret": "xxx", "grant_type": "client_credential" }

# 再获取热搜
GET https://open.douyin.com/hotsearch/trending/sentences/
Headers: Authorization: Bearer {client_token}
```

| 字段路径 | 说明 |
|---------|------|
| `data.active_time` | 热搜更新时间 |
| `data.list[].sentence` | 热搜词条 |
| `data.list[].hot_level` | 热度值 |
| `data.list[].label` | 标签（0=无,1=新,2=推荐,3=热,4=爆,5=首映） |

**阶段 2：内容扩展**

- **策略**：抖音官方 API 不提供搜索结果内容。使用热搜词条作为关键词：
  - 方案 A：抓取 `https://www.douyin.com/search/{keyword}` 页面，从内嵌 JSON（`RENDER_DATA`）提取视频列表
  - 方案 B：仅使用标题 + 热度，内容由 AI 生成摘要
- **推荐**：Phase 2 先用方案 B，后续优化为方案 A

**字段映射**：

| TrendLens 字段 | 来源 | 阶段 | 处理 |
|---------------|------|------|------|
| title | `sentence` | 1 | 直接使用 |
| heatValue | `hot_level` | 1 | 直接使用 |
| rank | 列表索引 | 1 | `index + 1` |
| link | 拼接搜索 URL | 1 | `https://www.douyin.com/search/{sentence}` |
| content | 搜索结果 / AI 生成 | 2 | 抓取或 AI |
| tags | `label` 文本映射 | 1 | 标签枚举转文字 |

---

### 7. 今日头条 `toutiao` — 热榜

**阶段 1：热榜列表**

```
GET https://www.toutiao.com/hot-event/hot-board/?origin=toutiao_pc
```

| 字段路径 | 说明 |
|---------|------|
| `data[].ClusterIdStr` | 事件 ID |
| `data[].Title` | 标题 |
| `data[].HotValue` | 热度值 |
| `data[].Image.url` | 图片 URL |
| `data[].LabelUri.url` | 标签图标 |
| `data[].Url` | 事件链接 |

**阶段 2：正文抓取**

- **目标**：`data[].Url` → 今日头条文章页
- **策略**：请求文章 URL → 从页面 `<script>` 中提取 `INITIAL_PROPS` 或 `articleInfo` JSON → 获取正文 `content`
- **备注**：头条文章页反爬较强，可能需要 User-Agent 伪装和 Cookie

**字段映射**：

| TrendLens 字段 | 来源 | 阶段 | 处理 |
|---------------|------|------|------|
| title | `Title` | 1 | 直接使用 |
| heatValue | `HotValue` | 1 | 直接使用 |
| rank | 列表索引 | 1 | `index + 1` |
| link | `Url` | 1 | 直接使用 |
| content | 文章正文 | 2 | 页面解析 |
| imageURLs | `[Image.url]` | 1 | 直接使用 |

---

## 四、P1 重要补充源

### 8. 新浪新闻 `sina-news`

- **列表**：`GET https://newsapp.sina.cn/api/hotlist`（使用 iPad UA）
- **字段**：标题、`hotValue`（热度值）、原文链接；支持 11 种子榜单（all/hotcmnt/minivideo/trend/ent/auto 等）
- **正文**：跟踪原文链接 → 解析新浪新闻文章页
- **优势**：11 种子榜单提供多维度热点，热度值可直接使用

### 9. 澎湃新闻 `thepaper`

- **列表**：`GET https://cache.thepaper.cn/contentapi/wwwIndex/rightSidebar`
- **字段**：`data.hotNews[].contId`（ID）、`name`（标题）、`pubTimeLong`（时间戳）
- **正文**：拼接 `https://www.thepaper.cn/newsDetail_forward_{contId}` → 解析文章页 `div.news_txt`
- **优势**：严肃新闻来源，内容质量高

### 10. 腾讯新闻 `tencent-hot`

- **列表**：`GET https://i.news.qq.com/web_backend/v2/getTagInfo?tagId=aEWqxLtdgmQ%3D`（需 Referer）
- **字段**：`data.tabs[0].articleList[].title`、`desc`、`link_info.url`
- **正文**：`desc` 已提供描述；跟踪 `link_info.url` 可获取完整文章
- **优势**：API 直接含描述，减少二次抓取依赖

### 11. Hacker News `hackernews`

- **列表**：`GET https://hacker-news.firebaseio.com/v0/topstories.json`（返回 ID 数组）→ 逐条 `GET /v0/item/{id}.json`
- **字段**：`title`、`url`（外部链接）、`score`（评分）、`by`（作者）、`descendants`（评论数）
- **正文**：跟踪 `url` → 解析目标文章页（通用文章提取器）
- **优势**：官方免费 API，无速率限制，国际科技热点

### 12. 36氪 `36kr-renqi` — 人气榜

- **列表**：`GET https://36kr.com/hot-list/renqi/{YYYY-MM-DD}/1` → Cheerio 解析 `.article-item-info`
- **字段**：标题、作者、热度分值、摘要
- **正文**：跟踪文章链接 → 解析 36 氪文章页
- **优势**：自带摘要，科技财经内容质量高

### 13. 豆瓣 `douban` — 热门电影

- **列表**：`GET https://m.douban.com/rexxar/api/v2/subject/recent_hot/movie`（需 `Referer: https://m.douban.com/`）
- **字段**：`items[].title`、`card_subtitle`（导演/演员/年份）、`pic.large`（封面）
- **正文**：`GET https://m.douban.com/rexxar/api/v2/movie/{id}` 获取详细信息（简介、评分、演职员表）
- **优势**：娱乐品类独家来源，数据结构化

---

## 五、P2 延伸覆盖源

### 14. 华尔街见闻 `wallstreetcn-hot`

- **列表**：`GET https://api-one.wallstcn.com/apiv1/content/articles/hot?period=all`
- **正文**：使用 `wallstreetcn-quick` 的 `content_text` 字段（API 直接返回内容）
- **品类**：财经

### 15. 参考消息 `cankaoxiaoxi`

- **列表**：3 频道并行 GET（中国/观点/国际），按时间合并排序
- **正文**：跟踪 `url` → 解析参考消息文章页
- **品类**：国际

### 16. GitHub Trending `github-trending`

- **列表**：`GET https://github.com/trending` → Cheerio 解析 `article` 元素
- **字段**：仓库名、star 数、描述
- **正文**：API 已含描述；可选跟踪仓库链接提取 README
- **品类**：科技

### 17. 网易新闻 `netease-news`

- **列表**：4 端点并行（热搜/热闻/热议/话题）
- **正文**：跟踪各条目链接 → 解析新闻页
- **品类**：国内（综合覆盖）

### 18. 百度贴吧 `tieba`

- **列表**：`GET https://tieba.baidu.com/hottopic/browse/topicList`
- **正文**：跟踪 `topic_url` → 解析帖子主楼内容
- **品类**：国内社区

### 19. IT之家 `ithome`

- **列表**：`GET https://www.ithome.com/list/` → Cheerio 解析
- **正文**：跟踪文章链接 → 解析 IT 之家文章页 `div.post_content`
- **品类**：科技

### 20. 靠谱新闻 `kaopu`

- **列表**：`GET https://kaopustorage.blob.core.windows.net/news-prod/news_list_hans_0.json`
- **字段**：`title`、`link`、`publisher`、`description`（API 直接含描述）
- **正文**：`description` 已充足；可选跟踪 `link` 获取全文
- **品类**：国际

---

## 六、鉴权汇总

| 源 ID | 鉴权类型 | 凭据 | 风险 |
|-------|---------|------|------|
| `weibo` | Cookie | 硬编码 SUB Cookie | **高** — Cookie 会过期，需维护更新 |
| `douyin` | OAuth Client Token | client_key + client_secret | **低** — 官方 API，Token 自动刷新 |
| `tencent-hot` | Header | Referer 头 | **低** — 简单固定值 |
| `douban` | Header | Referer 头 | **低** — 简单固定值 |
| 其余 16 个 | 无 | — | **无** |

---

## 七、数据源字段覆盖矩阵

✅ = API 直接提供 | 🔗 = 阶段 2 抓取 | ⚙️ = 需计算/转换 | 🤖 = AI 生成 | ❌ = 不可获取

| 源 ID | title | heat | rank | desc | content | image | tags | link |
|-------|-------|------|------|------|---------|-------|------|------|
| zhihu | ✅ | ⚙️ | ⚙️ | ✅ | 🔗 | ✅ | 🔗 | ✅ |
| baidu | ✅ | ✅ | ⚙️ | ✅ | 🔗 | ✅ | ❌ | ✅ |
| weibo | ✅ | ✅ | ⚙️ | ❌ | 🔗 | ❌ | ✅ | ✅ |
| bilibili-hs | ✅ | ⚙️ | ⚙️ | ❌ | 🔗 | 🔗 | ❌ | ⚙️ |
| bilibili-hv | ✅ | ✅ | ⚙️ | ✅ | ✅ | ✅ | ✅ | ⚙️ |
| douyin | ✅ | ✅ | ⚙️ | ❌ | 🔗/🤖 | ❌ | ✅ | ⚙️ |
| toutiao | ✅ | ✅ | ⚙️ | ❌ | 🔗 | ✅ | ❌ | ✅ |
| sina-news | ✅ | ✅ | ⚙️ | ❌ | 🔗 | ❌ | ❌ | ✅ |
| thepaper | ✅ | ❌ | ⚙️ | ❌ | 🔗 | ❌ | ❌ | ⚙️ |
| tencent-hot | ✅ | ❌ | ⚙️ | ✅ | 🔗 | ❌ | ❌ | ✅ |
| hackernews | ✅ | ✅ | ⚙️ | ❌ | 🔗 | ❌ | ❌ | ✅ |
| 36kr-renqi | ✅ | ✅ | ⚙️ | ✅ | 🔗 | ❌ | ❌ | ✅ |
| douban | ✅ | ❌ | ⚙️ | ✅ | 🔗 | ✅ | ❌ | ⚙️ |
| wallstreetcn | ✅ | ❌ | ⚙️ | ✅ | ✅ | ❌ | ❌ | ✅ |
| cankaoxiaoxi | ✅ | ❌ | ⚙️ | ❌ | 🔗 | ❌ | ❌ | ✅ |
| github | ✅ | ✅ | ⚙️ | ✅ | ✅ | ❌ | ❌ | ✅ |
| netease-news | ✅ | ✅ | ⚙️ | ❌ | 🔗 | ❌ | ❌ | ✅ |
| tieba | ✅ | ❌ | ⚙️ | ❌ | 🔗 | ❌ | ❌ | ✅ |
| ithome | ✅ | ❌ | ⚙️ | ❌ | 🔗 | ❌ | ❌ | ✅ |
| kaopu | ✅ | ❌ | ⚙️ | ✅ | ✅ | ❌ | ❌ | ✅ |

**统计**：
- title：20/20（100%）
- heat：10/20（50%）— 无热度值的源通过排名位置估算
- content：4 个 API 直接含内容 + 15 个需阶段 2 抓取 + 1 个需 AI 生成
- image：6/20（30%）— 其余可通过阶段 2 页面抓取补充

---

## 八、实施路线图

### Wave 1（P0，预计 2 周）
1. 搭建 Python 后端基础框架
2. 实现 7 个 P0 源的阶段 1 采集器
3. 实现通用页面正文提取器
4. 各源阶段 2 抓取器
5. 数据存入 Supabase
6. 基础调度（每 15 分钟采集一次）

### Wave 2（P1，预计 1 周）
1. 实现 6 个 P1 源
2. 抖音 Client Token 自动刷新
3. 微博 Cookie 维护机制

### Wave 3（P2，预计 1 周）
1. 实现 7 个 P2 源
2. 全量数据质量验证
3. 采集频率和策略优化

---

## 九、与当前 iOS 平台枚举的对应关系

当前 iOS 端 `Platform` 枚举包含 6 个平台：

| iOS Platform | 对应数据源 | 覆盖状态 |
|-------------|-----------|---------|
| `.weibo` | `weibo` | ✅ 可用（Cookie 风险） |
| `.xiaohongshu` | — | ❌ 无可用数据源（API 返回 406） |
| `.bilibili` | `bilibili-hot-search` + `bilibili-hot-video` | ✅ 双源覆盖 |
| `.douyin` | `douyin` | ✅ 官方 API |
| `.x` | — | ❌ 不在数据源范围内 |
| `.zhihu` | `zhihu` | ✅ 可用 |

> **备注**：小红书和 X 暂无可靠数据源。后续 iOS 端的 `Platform` 枚举将根据实际可用数据源进行调整，可能新增百度、今日头条等平台，移除暂不可用的平台。此调整属于后续任务，不影响当前后端开发。
