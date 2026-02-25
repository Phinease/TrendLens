# NewsNow 数据来源建模文档

本文档对 NewsNow 项目所有数据来源进行系统建模，涵盖接口信息、鉴权方式、官方 API 状态及验证情况。

> 最后更新：2026-02-18

---

## 一、数据来源总览

| # | 源 ID | 平台 | 方式 | 鉴权 | 官方 API | 分类 | 验证 |
|---|-------|------|------|------|---------|------|------|
| 1 | `36kr-quick` | 36氪 | HTML | 无 | 无 | 科技 | ✅ |
| 2 | `36kr-renqi` | 36氪 | HTML | 无 | 无 | 科技 | ✅ |
| 3 | `baidu` | 百度 | 内嵌 JSON | 无 | 无 | 国内 | ✅ |
| 4 | `bilibili-hot-search` | B站 | JSON | 无 | 无 | 国内 | ✅ |
| 5 | `bilibili-hot-video` | B站 | JSON | 无 | 无 | 国内 | ✅ ^cf^ |
| 6 | `bilibili-ranking` | B站 | JSON | 无 | 无 | 国内 | ✅ ^cf^ |
| 7 | `cankaoxiaoxi` | 参考消息 | JSON | 无 | 无 | 国际 | ✅ |
| 8 | `chongbuluo-hot` | 虫部落 | HTML | 无 | 无 | 国内 | ✅ |
| 9 | `chongbuluo-latest` | 虫部落 | RSS | 无 | 无 | 国内 | ✅ |
| 10 | `cls-telegraph` | 财联社 | JSON | SHA1+MD5 签名 | 无 | 财经 | ⏳ |
| 11 | `cls-depth` | 财联社 | JSON | SHA1+MD5 签名 | 无 | 财经 | ⏳ |
| 12 | `cls-hot` | 财联社 | JSON | SHA1+MD5 签名 | 无 | 财经 | ⏳ |
| 13 | `coolapk` | 酷安 | JSON | MD5 签名 | 无 | 科技 | ⏳ |
| 14 | `douban` | 豆瓣 | JSON | Referer | 无 | 国内 | ✅ |
| 15 | `douyin` | 抖音 | JSON | Client Token | **官方** | 国内 | ✅ |
| 16 | `fastbull-express` | 法布财经 | HTML | 无 | **有官方付费** | 财经 | ✅ |
| 17 | `fastbull-news` | 法布财经 | HTML | 无 | **有官方付费** | 财经 | ✅ |
| 18 | `freebuf` | Freebuf | HTML | 无 | 无 | 国内 | ✅ |
| 19 | `gelonghui` | 格隆汇 | HTML | 无 | 无 | 财经 | ✅ |
| 20 | `github-trending-today` | GitHub | HTML | 无 | 无 | 科技 | ✅ |
| 21 | `hackernews` | Hacker News | JSON | 无 | **官方** | 科技 | ✅ |
| 22 | `hupu` | 虎扑 | HTML | 无 | 无 | 国内 | ✅ |
| 23 | `ifeng` | 凤凰网 | 内嵌 JS | 无 | 无 | 国内 | ✅ |
| 24 | `iqiyi-hot-ranklist` | 爱奇艺 | JSON | Referer | 无 | 国内 | ⏳ |
| 25 | `ithome` | IT之家 | HTML | 无 | 无 | 科技 | ✅ |
| 26 | `jin10` | 金十数据 | JS 解析 | 无 | **有官方付费** | 财经 | ✅ |
| 27 | `juejin` | 稀土掘金 | JSON | 无 | 无 | 科技 | ✅ |
| 28 | `kaopu` | 靠谱新闻 | JSON | 无 | 无 | 国际 | ✅ |
| 29 | `kuaishou` | 快手 | 内嵌 JS | 无 | 无 | 国内 | ✅ ^cf^ |
| 30 | `mktnews-flash` | MKTNews | JSON | 无 | 无 | 财经 | ✅ |
| 31 | `nowcoder` | 牛客 | JSON | 无 | 无 | 国内 | ✅ |
| 32 | `pcbeta-windows11` | 远景论坛 | RSS | 无 | 无 | 科技 | ✅ |
| 33 | `producthunt` | Product Hunt | GraphQL | Bearer Token | **官方已接入** | 科技 | ⏳ |
| 34 | `qqvideo-tv-hotsearch` | 腾讯视频 | POST | 无 | 无 | 国内 | ✅ |
| 35 | `solidot` | Solidot | HTML | 无 | 无 | 科技 | ✅ |
| 36 | `sputniknewscn` | 卫星通讯社 | HTML | 无 | 无 | 国际 | ✅ |
| 37 | `sspai` | 少数派 | JSON | 无 | 无 | 科技 | ✅ |
| 38 | `steam` | Steam | HTML | 无 | 有官方(数据不同) | 国际 | ✅ |
| 39 | `tencent-hot` | 腾讯新闻 | JSON | Referer | 无 | 国内 | ✅ |
| 40 | `thepaper` | 澎湃新闻 | JSON | 无 | 无 | 国内 | ✅ |
| 41 | `tieba` | 百度贴吧 | JSON | 无 | 半官方 | 国内 | ✅ |
| 42 | `toutiao` | 今日头条 | JSON | 无 | 无 | 国内 | ✅ |
| 43 | `v2ex-share` | V2EX | JSON | 无 | 无 | 科技 | ✅ |
| 44 | `wallstreetcn-quick` | 华尔街见闻 | JSON | 无 | 无 | 财经 | ✅ |
| 45 | `wallstreetcn-news` | 华尔街见闻 | JSON | 无 | 无 | 财经 | ✅ |
| 46 | `wallstreetcn-hot` | 华尔街见闻 | JSON | 无 | 无 | 财经 | ✅ |
| 47 | `weibo` | 微博 | HTML | Cookie（硬编码） | 无 | 国内 | ✅ |
| 48 | `xueqiu-hotstock` | 雪球 | JSON | Cookie 预获取 | 无 | 财经 | ⏳ |
| 49 | `zaobao` | 联合早报 | HTML | 无 | 无 | 国际 | ✅ |
| 50 | `zhihu` | 知乎 | JSON | 无 | 无 | 国内 | ✅ |
| 51 | `csdn-hot` | CSDN | JSON | x-ca-key（公开） | 无 | 科技 | ✅ |
| 52 | `acfun-rank` | Acfun | JSON | 无 | 无 | 国内 | ✅ |
| 53 | `weread` | 微信读书 | JSON | Cookie（登录） | 无 | 国内 | ⏳ |
| 54 | `apple-appstore` | Apple App Store | RSS | 无 | **官方** | 国际 | ✅ |
| 55 | `sina-news` | 新浪新闻 | JSON | 无 | 无 | 国内 | ✅ |
| 56 | `netease-music` | 网易云音乐 | POST | AES+RSA 加密 | 无 | 国内 | ⏳ |
| 57 | `apple-music` | Apple Music | JSON | Bearer Token | **官方** | 国际 | ⏳ |
| 58 | `netease-news` | 网易新闻 | JSON | 无 | 无 | 国内 | ✅ |
| 59 | `oschina` | 开源中国 | JSON | 无 | 无 | 科技 | ✅ |
| 60 | `cloud-tencent` | 腾讯云开发者 | POST | 无 | 无 | 科技 | ✅ |
| 61 | `yqq` | QQ音乐 | POST | 无 | 无 | 国内 | ✅ |

**已禁用数据源：**

| # | 源 ID | 平台 | 方式 | 分类 | 禁用原因 |
|---|-------|------|------|------|---------|
| 62 | `ghxi` | 果核剥壳 | HTML | 国内 | 全局禁用 |
| 63 | `linuxdo-latest` | LINUX DO | JSON | 科技 | 全局禁用 |
| 64 | `linuxdo-hot` | LINUX DO | JSON | 科技 | 全局禁用 |
| 65 | `pcbeta-windows` | 远景论坛 | RSS | 科技 | 全局禁用 |
| 66 | `smzdm` | 什么值得买 | HTML | 国内 | 全局禁用 |

> **标注说明：**
> - **方式**：JSON = JSON API (GET)；POST = JSON API (POST)；HTML = Cheerio 页面解析；内嵌 JSON/JS = 从页面中提取嵌入数据；JS 解析 = 解析 JavaScript 文件；RSS = RSS 订阅；GraphQL = GraphQL API
> - **官方 API**：`官方` = 采用官方接口；`官方已接入` = 同上；`有官方付费` = 存在付费官方接口；`有官方(数据不同)` = 官方接口存在但数据维度不同；`半官方` = 半公开接口；`无` = 无可用官方接口
> - **验证**：✅ = 2026-02-18 验证通过；⏳ = 需鉴权/签名或待连通性验证
> - **^cf^**：Cloudflare Pages 环境下不可用

### 验证统计

| 状态 | 数量 | 占比 |
|------|------|------|
| ✅ 已验证通过 | 48 | 79% |
| ⏳ 待验证 | 8 | 13% |
| 已禁用 | 5 | 8% |
| ❌ 验证失败 | 0 | 0% |

---

## 二、接口详述

### 36氪 `[科技]`

**`36kr-quick`** — 快讯
- **接口**：`GET https://www.36kr.com/newsflashes`
- **内容**：科技快讯列表
- **解析**：Cheerio 解析 `.newsflash-item`，提取 `.item-title`（标题）、`.time`（时间）
- **关键字段**：标题、链接、相对时间

**`36kr-renqi`** — 人气榜
- **接口**：`GET https://36kr.com/hot-list/renqi/{YYYY-MM-DD}/1`
- **内容**：每日人气文章排行
- **解析**：Cheerio 解析 `.article-item-info`，提取标题、作者、热度分值、描述
- **关键字段**：标题、链接、作者、热度值、摘要

---

### 百度热搜 `baidu` `[国内]`

- **接口**：`GET https://top.baidu.com/board?tab=realtime`
- **内容**：实时热搜榜
- **解析**：正则提取 HTML 注释中 `<!--s-data:...-->` 内嵌 JSON
- **关键字段**：`data.cards[0].content[].word`（关键词）、`rawUrl`（链接）、`desc`（描述）、`isTop`（是否置顶，过滤用）

---

### 哔哩哔哩 `[国内]`

**`bilibili-hot-search`** — 热搜
- **接口**：`GET https://s.search.bilibili.com/main/hotword?limit=30`
- **内容**：搜索热词 Top 30
- **关键字段**：`list[].keyword`、`show_name`、`icon`

**`bilibili-hot-video`** — 热门视频
- **接口**：`GET https://api.bilibili.com/x/web-interface/popular`
- **内容**：热门视频详情（BV 号、UP 主、播放量、点赞数）
- **关键字段**：`data.list[].bvid`、`title`、`owner.name`、`stat.view`、`stat.like`、`desc`、`pic`
- **限制**：Cloudflare 环境不可用

**`bilibili-ranking`** — 排行榜
- **接口**：`GET https://api.bilibili.com/x/web-interface/ranking/v2`
- **内容**：综合排行榜视频
- **关键字段**：同 hot-video
- **限制**：Cloudflare 环境不可用

---

### 参考消息 `cankaoxiaoxi` `[国际]`

- **接口**：GET，三频道并行请求
  - `https://china.cankaoxiaoxi.com/json/channel/zhongguo/list.json`
  - `https://china.cankaoxiaoxi.com/json/channel/guandian/list.json`
  - `https://china.cankaoxiaoxi.com/json/channel/gj/list.json`
- **内容**：中国、观点、国际三频道新闻合并，按时间排序
- **关键字段**：`list[].data.id`、`title`、`url`、`publishTime`

---

### 虫部落 `[国内]`

**`chongbuluo-hot`** — 最热
- **接口**：`GET https://www.chongbuluo.com/forum.php?mod=guide&view=hot`
- **解析**：Cheerio 解析帖子列表 `.common .xst`

**`chongbuluo-latest`** — 最新
- **接口**：RSS `https://www.chongbuluo.com/forum.php?mod=rss&view=newthread`

---

### 财联社 `[财经]`

- **鉴权**：所有子源均需自定义签名——通过 `cls/utils.ts` 生成 SHA-1 + MD5 签名查询参数（app name、OS、version、hash）

**`cls-telegraph`** — 电报
- **接口**：`GET https://www.cls.cn/nodeapi/updateTelegraphList` + 签名参数
- **内容**：实时财经电报，过滤广告（`is_ad`）
- **关键字段**：`data.roll_data[].id`、`title`、`brief`、`ctime`、`shareurl`

**`cls-depth`** — 深度
- **接口**：`GET https://www.cls.cn/v3/depth/home/assembled/1000` + 签名参数
- **关键字段**：`data.depth_list[].id`、`title`、`shareurl`

**`cls-hot`** — 热门
- **接口**：`GET https://www.cls.cn/v2/article/hot/list` + 签名参数
- **关键字段**：`data[].id`、`title`、`shareurl`

---

### 酷安 `coolapk` `[科技]`

- **接口**：`GET https://api.coolapk.com/v6/page/dataList?url=...&title=今日热门&page=1`
- **鉴权**：模拟 Android 客户端，通过 `genHeaders()` 生成 MD5 签名的 `X-App-Token`，携带 `X-App-Id`、`X-App-Device` 等自定义头
- **内容**：今日最热帖子
- **关键字段**：`data[].id`、`editor_title`（标题）、`message`（内容）、`url`、`targetRow.subTitle`（热度）

---

### 豆瓣 `douban` `[国内]`

- **接口**：`GET https://m.douban.com/rexxar/api/v2/subject/recent_hot/movie`
- **鉴权**：需携带 `Referer: https://m.douban.com/` 和 `Accept` 头
- **内容**：热门电影
- **关键字段**：`items[].id`、`title`、`card_subtitle`（导演/演员/年份）、`pic.large`（封面）

---

### 抖音 `douyin` `[国内]`

- **接口**：`GET https://open.douyin.com/hotsearch/trending/sentences/`
- **鉴权**：Client Token（通过 `/oauth/client_token/` 获取，无需用户授权）
- **费用**：免费
- **内容**：实时热搜词条
- **关键字段**：`data[].sentence`（热搜词）、`hot_level`（热度值）、`label`（标签：0=无、1=新、2=推荐、3=热、4=爆、5=首映）
- **文档**：[developer.open-douyin.com](https://developer.open-douyin.com)

---

### 法布财经 `[财经]`

**`fastbull-express`** — 快讯
- **接口**：`GET https://www.fastbull.com/cn/express-news`
- **解析**：Cheerio 解析 `.news-list`，从 `【标题】` 格式提取标题，`data-date` 属性取时间

**`fastbull-news`** — 头条
- **接口**：`GET https://www.fastbull.com/cn/news`
- **解析**：Cheerio 解析 `.trending_type`，提取 `.title_name`

**官方付费 API：**[solution.fastbull.com/data](https://solution.fastbull.com/data)，含行情、快讯、日历、分析文章，支持多语言 SDK，需付费订阅。

---

### Freebuf `freebuf` `[国内]`

- **接口**：`GET https://www.freebuf.com`
- **鉴权**：自定义 User-Agent、Referer、Accept
- **解析**：Cheerio 解析 `.article-item`，提取标题、作者、阅读量、收藏数、分类
- **内容**：网络安全资讯

---

### 格隆汇 `gelonghui` `[财经]`

- **接口**：`GET https://www.gelonghui.com/news/`
- **解析**：Cheerio 解析 `.article-content` → `.detail-right > a`（标题链接）、`.time > span`（时间）
- **内容**：财经事件

---

### GitHub Trending `github-trending-today` `[科技]`

- **接口**：`GET https://github.com/trending?spoken_language_code=`
- **解析**：Cheerio 解析 `article` 元素，提取 `h2 a`（仓库名）、`[href$=stargazers]`（star 数）、`p`（描述）
- **内容**：今日趋势仓库
- **备注**：GitHub 官方 REST/GraphQL API 无 trending 端点，HTML 抓取是获取趋势数据的唯一方式

---

### Hacker News `hackernews` `[科技]`

- **接口**：`GET https://hacker-news.firebaseio.com/v0/topstories.json`（返回 Top 500 story ID 数组），逐条 `GET /v0/item/{id}.json` 获取详情
- **鉴权**：无需注册，无速率限制
- **费用**：完全免费
- **内容**：Top 500 热门帖子
- **关键字段**：`id`、`title`（标题）、`url`（链接）、`score`（评分）、`by`（作者）、`time`（时间戳）、`descendants`（评论数）
- **文档**：[github.com/HackerNews/API](https://github.com/HackerNews/API)

---

### 虎扑 `hupu` `[国内]`

- **接口**：`GET https://bbs.hupu.com/topic-daily-hot`
- **解析**：正则匹配 `.bbs-sl-web-post-body` → `a.p-title`（标题、链接）
- **内容**：主干道每日热帖

---

### 凤凰网 `ifeng` `[国内]`

- **接口**：`GET https://www.ifeng.com/`
- **解析**：正则提取页面中 `var allData = {...}` 变量，取 `hotNews1` 数组
- **关键字段**：`hotNews1[].url`、`title`、`newsTime`

---

### 爱奇艺 `iqiyi-hot-ranklist` `[国内]`

- **接口**：`GET https://mesh.if.iqiyi.com/portal/lw/v7/channel/card/videoTab?channelName=recommend&data_source=v7_rec_sec_hot_rank_list&tempId=85&count=30&block_id=hot_ranklist&device=14a4b5ba98e790dce6dc07482447cf48&from=webapp`
- **鉴权**：需携带 `Referer` 头
- **内容**：热播榜 Top 30
- **关键字段**：`items[0].video[0].data[].entity_id`、`title`、`page_url`、`desc`、`description`、`tag`

---

### IT之家 `ithome` `[科技]`

- **接口**：`GET https://www.ithome.com/list/`
- **解析**：Cheerio 解析 `#list > div.fl > ul > li` → `a.t`（标题链接）、`i`（日期）
- **内容**：新闻列表，排除广告（通过 URL 和标题关键词判断）
- **特殊处理**：相对时间解析（"3分钟前"/"昨天"等转为时间戳）

---

### 金十数据 `jin10` `[财经]`

**当前实现（免费非官方）：**
- **接口**：`GET https://www.jin10.com/flash_newest.js?t={timestamp}`
- **解析**：返回 JS 变量赋值，解析为 JSON 数组
- **关键字段**：`[].id`、`time`、`data.title`、`data.content`、`data.source_link`、`important`（重要性标记）、`channel`

**官方付费 API：**
- **门户**：[open.jin10.com](https://open.jin10.com)
- **费用**：15 天试用；2000 元/年起
- **内容**：持牌金融信息服务，4 类数据产品

---

### 稀土掘金 `juejin` `[科技]`

- **接口**：`GET https://api.juejin.cn/content_api/v1/content/article_rank?category_id=1&type=hot&spider=0`
- **内容**：热门文章排行
- **关键字段**：`data[].content.content_id`、`content.title`

---

### 靠谱新闻 `kaopu` `[国际]`

- **接口**：`GET https://kaopustorage.blob.core.windows.net/news-prod/news_list_hans_0.json`（Azure Blob Storage）
- **内容**：新闻列表，排除"财新"和"公视"来源
- **关键字段**：`[].title`、`link`、`pub_date`、`publisher`（出版社）、`description`

---

### 快手 `kuaishou` `[国内]`

- **接口**：`GET https://www.kuaishou.com/?isHome=1`
- **解析**：正则提取 `window.__APOLLO_STATE__ = {...}` 变量，从中读取 `visionHotRank` 数据
- **内容**：热门视频，过滤置顶
- **关键字段**：`items[].name`（标题）、`iconUrl`
- **限制**：Cloudflare 环境不可用

---

### MKTNews `mktnews-flash` `[财经]`

- **接口**：`GET https://api.mktnews.net/api/flash?type=0&limit=50`
- **内容**：财经快讯 50 条
- **关键字段**：`data[].id`、`time`、`important`（重要性）、`data.title`、`data.content`、`data.pic`、`hot`

---

### 牛客 `nowcoder` `[国内]`

- **接口**：`GET https://gw-c.nowcoder.com/api/sparta/hot-search/top-hot-pc?size=20&_={timestamp}&t=`
- **内容**：热搜 Top 20，根据内容类型（帖子/讨论）生成不同 URL
- **关键字段**：`data.result[].id`、`title`、`type`、`uuid`

---

### 远景论坛 `[科技]`

**`pcbeta-windows11`** — Win11 板块
- **接口**：RSS `https://bbs.pcbeta.com/forum.php?mod=rss&fid=563&auth=0`
- **工厂**：`defineRSSSource()`

**`pcbeta-windows`** — Windows 资源（已禁用）
- **接口**：RSS `https://bbs.pcbeta.com/forum.php?mod=rss&fid=521&auth=0`

---

### Product Hunt `producthunt` `[科技]`

- **接口**：`POST https://api.producthunt.com/v2/api/graphql`
- **鉴权**：`Authorization: Bearer {PRODUCTHUNT_API_TOKEN}`（需环境变量 `PRODUCTHUNT_API_TOKEN`）
- **请求体**：GraphQL query，查询当日 posts，按 `votesCount` 排序，取前 30
- **内容**：当日热门产品
- **关键字段**：`data.posts.edges[].node.id`、`name`、`tagline`、`votesCount`、`url`、`slug`
- **接口性质**：**官方 API**，免费用于非商业用途；速率限制：每 15 分钟 450 次请求 / 6250 复杂度点
- **文档**：[api.producthunt.com/v2/docs](https://api.producthunt.com/v2/docs)

---

### 腾讯视频 `qqvideo-tv-hotsearch` `[国内]`

- **接口**：`POST https://pbaccess.video.qq.com/trpc.vector_layout.page_view.PageService/getCard?video_appid=3000010&vversion_platform=2`
- **鉴权**：需携带 `Referer` 头
- **请求体**：JSON，含 `page_params`（rank_channel_id、tab_name、page_id 等）
- **内容**：电视剧热搜榜
- **关键字段**：`data.card.children_list.list.cards[].id`、`params.title`、`params.publish_date`、`params.sub_title`

---

### Solidot `solidot` `[科技]`

- **接口**：`GET https://www.solidot.org`
- **解析**：Cheerio 解析 `.block_m` → `.bg_htit a`（标题）、`.talk_time`（中文日期）
- **内容**：科技资讯

---

### 卫星通讯社 `sputniknewscn` `[国际]`

- **接口**：`GET https://sputniknews.cn/services/widget/lenta/`
- **解析**：Cheerio 解析 `.lenta__item`，提取 `a`（标题链接）、`.lenta__item-date`（`data-unixtime` 属性）
- **内容**：俄罗斯卫星通讯社中文版
- **特殊处理**：Cloudflare 环境下通过 `proxySource()` 经由 Vercel 实例代理

---

### 少数派 `sspai` `[科技]`

- **接口**：`GET https://sspai.com/api/v1/article/tag/page/get?limit=30&offset=0&created_at={timestamp}&tag=热门文章&released=false`
- **内容**：热门文章 Top 30
- **关键字段**：`data[].id`、`title`

---

### Steam `steam` `[国际]`

- **接口**：`GET https://store.steampowered.com/stats/stats/`
- **解析**：Cheerio 解析 `#detailStats tr.player_count_row` → `a.gameLink`（游戏名/链接）、`.currentServers`（当前在线人数）
- **内容**：游戏实时在线人数排行
- **备注**：Steam 官方 API (`ISteamChartsService/GetMostPlayedGames/v1/`) 仅返回 `appid` + `peak_in_game`（峰值人数），不含游戏名称和实时在线人数，数据维度不同，不适合替代

---

### 腾讯新闻 `tencent-hot` `[国内]`

- **接口**：`GET https://i.news.qq.com/web_backend/v2/getTagInfo?tagId=aEWqxLtdgmQ%3D`
- **鉴权**：需携带 `Referer` 头
- **内容**：综合早报文章列表
- **关键字段**：`data.tabs[0].articleList[].id`、`title`、`link_info.url`、`desc`

---

### 澎湃新闻 `thepaper` `[国内]`

- **接口**：`GET https://cache.thepaper.cn/contentapi/wwwIndex/rightSidebar`
- **内容**：热榜文章，同时提供 PC 和移动端链接
- **关键字段**：`data.hotNews[].contId`、`name`（标题）、`pubTimeLong`

---

### 百度贴吧 `tieba` `[国内]`

- **接口**：`GET https://tieba.baidu.com/hottopic/browse/topicList`
- **接口性质**：半官方（百度公开端点，有半官方文档页面）
- **内容**：热议话题列表
- **关键字段**：`data.bang_topic.topic_list[].topic_id`、`topic_name`、`create_time`、`topic_url`

---

### 今日头条 `toutiao` `[国内]`

- **接口**：`GET https://www.toutiao.com/hot-event/hot-board/?origin=toutiao_pc`
- **内容**：热点事件榜
- **关键字段**：`data[].ClusterIdStr`（ID）、`Title`、`HotValue`、`Image.url`、`LabelUri?.url`（标签图标）

---

### V2EX `v2ex-share` `[科技]`

- **接口**：GET，4 个板块并行请求
  - `https://www.v2ex.com/feed/create.json`
  - `https://www.v2ex.com/feed/ideas.json`
  - `https://www.v2ex.com/feed/programmer.json`
  - `https://www.v2ex.com/feed/share.json`
- **内容**：4 个板块最新帖子合并后按时间排序
- **关键字段**：`items[].id`、`title`、`date_modified`、`date_published`、`url`

---

### 华尔街见闻 `[财经]`

**`wallstreetcn-quick`** — 快讯
- **接口**：`GET https://api-one.wallstcn.com/apiv1/content/lives?channel=global-channel&limit=30`
- **内容**：实时财经快讯
- **关键字段**：`data.items[].id`、`title`、`content_text`、`content_short`、`display_time`、`uri`

**`wallstreetcn-news`** — 最新
- **接口**：`GET https://api-one.wallstcn.com/apiv1/content/information-flow?channel=global-channel&accept=article&limit=30`
- **内容**：最新文章
- **关键字段**：同上
- **特殊过滤**：排除广告（`is_ad`）和主题类内容

**`wallstreetcn-hot`** — 最热
- **接口**：`GET https://api-one.wallstcn.com/apiv1/content/articles/hot?period=all`
- **内容**：热门文章
- **关键字段**：`data.day_items[].id`、`title`、`uri`

---

### 微博 `weibo` `[国内]`

- **接口**：`GET https://s.weibo.com/top/summary?cate=realtimehot`
- **鉴权**：硬编码 SUB Cookie + User-Agent + Referer
- **解析**：Cheerio 解析 `#pl_top_realtimehot table tbody tr` → `td.td-02 a`（标题/搜索链接）、`td.td-03`（标记图标：新/热/爆）
- **内容**：实时热搜榜
- **风险**：硬编码 Cookie 可能过期

---

### 雪球 `xueqiu-hotstock` `[财经]`

- **接口**：`GET https://stock.xueqiu.com/v5/stock/hot_stock/list.json?size=30&_type=10&type=10`
- **鉴权**：先访问 `https://xueqiu.com/hq` 获取 `xq_a_token` Cookie，再携带请求
- **内容**：热门股票 Top 30
- **关键字段**：`data.items[].code`（股票代码）、`name`、`percent`（涨跌幅）、`exchange`（交易所）、`ad`（是否广告）

---

### 联合早报 `zaobao` `[国际]`

- **接口**：`GET https://www.zaochenbao.com/realtime/`（第三方站点"早晨报"，非联合早报官方）
- **解析**：Cheerio 解析 `div.list-block > a.item` → `.eps`（标题）、`.pdt10`（日期）
- **特殊处理**：响应为 ArrayBuffer，需 iconv-lite 做 GB2312 → UTF-8 编码转换
- **内容**：实时新闻列表

---

### 知乎 `zhihu` `[国内]`

- **接口**：`GET https://www.zhihu.com/api/v3/feed/topstory/hot-list-web?limit=20&desktop=true`
- **内容**：热榜 Top 20
- **关键字段**：`data[].target.title_area.text`（标题）、`target.excerpt_area.text`（摘要）、`target.image_area.url`（图片）、`target.metrics_area.text`（热度）、`target.link.url`（链接）

---

### CSDN `csdn-hot` `[科技]`

- **接口**：`GET https://blog.csdn.net/phoenix/web/blog/hot-rank`（全站热榜）
- **鉴权**：部分接口需 `x-ca-key: 203930474` 请求头（公开硬编码 API Key）
- **内容**：技术文章热榜（25 条）、作者排行
- **关键字段**：文章标题、热度分/阅读量、文章链接
- **扩展端点**：作者排行 `GET /phoenix/web/v2/rank?rankType={type}`（周/月/总/年/新人榜）、领军人物 `GET /community-cloud/v1/rank/community`，共 11 个子接口

---

### Acfun `acfun-rank` `[国内]`

- **接口**：`GET https://www.acfun.cn/rest/pc-direct/rank/channel`
- **参数**：`channelId`、`subChannelId` 区分分类
- **内容**：视频排行榜，支持 82 种分类（综合、番剧、动画、娱乐、生活、音乐、游戏、科技等）
- **关键字段**：`contentTitle`（标题）、`viewCount`（播放量）、视频链接、投稿时间
- **备注**：每次返回 30 条，日榜数据

---

### 微信读书 `weread` `[国内]`

- **接口**：`GET https://weread.qq.com/web/bookListInCategory/{category}`
- **鉴权**：需登录 Cookie（`wr_skey`/`wr_vid`），无 Cookie 时 API 返回 200 但数据为空
- **内容**：7 种榜单——飙升榜（surge）、热搜榜（hotSearch）、新书榜（newBook）、小说榜（novel）、总榜 Top 200（overall）、神作榜（special）、神作潜力榜（specialPotential）
- **关键字段**：书名、在读人数（readingCount）、书籍链接
- **特殊处理**：`bookId` 需通过 MD5 + 进制转换为微信读书专用 ID 格式

---

### Apple App Store `apple-appstore` `[国际]`

- **接口**：`GET https://itunes.apple.com/{country}/rss/{type}/limit={limit}/genre={genre}/json`
- **接口性质**：**官方 RSS Feed**
- **鉴权**：无需鉴权
- **内容**：应用排行（免费/付费/畅销），支持多国家（CN/US/JP/KR/TW/HK）和多分类
- **关键字段**：应用名、应用链接

---

### 新浪新闻 `sina-news` `[国内]`

- **接口**：`GET https://newsapp.sina.cn/api/hotlist`
- **鉴权**：无需鉴权，使用 iPad User-Agent
- **内容**：11 种榜单——综合热榜（all）、热议（hotcmnt）、视频（minivideo）、潮流（trend）、娱乐（ent）、汽车（auto）、育儿（mother）、时尚（fashion）、旅游（travel）、AI（ai）、ESG（esg）
- **关键字段**：新闻标题、热度值（hotValue）、原文链接

---

### 网易云音乐 `netease-music` `[国内]`

- **接口**：`POST https://music.163.com/weapi/v6/playlist/detail`
- **鉴权**：无需登录 Token，但请求体需 **AES-128-CBC + RSA 双重加密**
  1. 第一层 AES-128-CBC 加密（固定密钥）
  2. 生成随机密钥进行第二层 AES 加密
  3. RSA 加密第二层密钥
- **内容**：62 种音乐榜单（飙升榜、新歌榜、热歌榜、原创榜、说唱榜、古典榜、电音榜、ACG榜、韩语榜、Billboard、Oricon、KTV唛榜等）
- **关键字段**：歌曲名（name）、歌曲链接、发布时间

---

### Apple Music `apple-music` `[国际]`

- **接口**：`GET https://amp-api.music.apple.com/v1/catalog/{country}/charts`
- **接口性质**：**官方 API**
- **鉴权**：`Authorization: Bearer {JWT}`（硬编码 JWT，存在过期风险）
- **内容**：每日热门歌曲排行
- **关键字段**：歌曲名+歌手、专辑封面图（thumbnail）、歌曲链接
- **支持地区**：CN、US、JP、KR、TW、HK

---

### 网易新闻 `netease-news` `[国内]`

- **接口**：4 个端点并行请求
  - 热搜：`GET https://gw.m.163.com/search/api/v1/pc-wap/hot-word`
  - 热闻：`GET https://gw.m.163.com/nc-main/api/v1/hqc/no-repeat-hot-list?cityCode=110000`
  - 热议：`GET https://gw.m.163.com/gentie-web/api/v2/products/.../rankDocs/all/list`
  - 话题：`GET https://gw.m.163.com/nc/api/v1/feed/dynamic/topic/hotList`
- **鉴权**：无需鉴权
- **内容**：热搜词（11 条）、热门新闻（30 条）、热议文章、热门话题
- **关键字段**：`hotWordList[].hotWord`（热搜词）、`items[].title`（新闻标题）、`hotValue`（热度）、原文链接

---

### 开源中国 `oschina` `[科技]`

- **接口**：5 个端点
  - 阅读榜：`GET https://www.oschina.net/ApiHomeNew/homeListByRankWeek`
  - 博客热门：`GET https://www.oschina.net/ApiHomeNew/homeListByBlogHot`
  - 头条推荐：`GET https://apiv1.oschina.net/oschinapi/home/headline`
  - 热门话题：`GET https://apiv1.oschina.net/oschinapi/tweet/topic/hot`
  - 专区文章：`GET https://apiv1.oschina.net/oschinapi/circle/contentNewestList`
- **鉴权**：无需鉴权
- **内容**：技术文章/话题，含热度分、阅读量、评论数
- **关键字段**：`result[].title`、`heat`（热度）、`id`、`comment_count`

---

### 腾讯云开发者 `cloud-tencent` `[科技]`

- **接口**：3 个端点
  - 文章列表：`POST https://cloud.tencent.com/developer/api/home/article-list`
  - 作者排行：`POST https://cloud.tencent.com/developer/api/rank/list`
  - 技术专区：`POST https://cloud.tencent.com/developer/api/zone/getObjList`
- **鉴权**：无需鉴权
- **内容**：技术文章（20 条/页）、作者排行、技术专区
- **关键字段**：`list[].articleId`、`title`、`columnId`、创建时间

---

### QQ音乐 `yqq` `[国内]`

- **接口**：`POST https://u.y.qq.com/cgi-bin/musicu.fcg`
- **鉴权**：无需鉴权，无需签名（此前认为需 SHA1 签名，实测直接可用）
- **请求体**：JSON，通过 `module`/`method`/`param` 指定查询类型
- **内容**：榜单列表（飙升榜、热歌榜、新歌榜等数十个榜单）+ 各榜单歌曲详情
- **关键字段**：`topList.data.group[].toplist[].topId`（榜单 ID）、`title`（榜单名）；歌曲 `title`、`singer[].name`
- **扩展端点**：排行详情 `POST https://u6.y.qq.com/cgi-bin/musics.fcg`

---

### 已禁用数据源

**果核剥壳** `ghxi` `[国内]`
- **接口**：`GET https://www.ghxi.com/category/all`（HTML 解析）
- **代理**：Cloudflare 环境通过 Vercel 代理
- **禁用原因**：全局禁用

**LINUX DO** `[科技]`
- `linuxdo-latest`：`GET https://linux.do/latest.json?order=created`
- `linuxdo-hot`：`GET https://linux.do/top/daily.json`
- **关键字段**：`topic_list.topics[].id`、`title`、`created_at`
- **禁用原因**：全局禁用

**什么值得买** `smzdm` `[国内]`
- **接口**：`GET https://post.smzdm.com/hot_1/`（HTML 解析）
- **禁用原因**：全局禁用

---

## 三、补充信息

### 3.1 关键发现

1. **3 个来源已采用官方 API**：Product Hunt（GraphQL V2）、Hacker News（Firebase API）、抖音（开放平台热搜 API）
2. **抖音是唯一提供免费官方热搜 API 的中国平台**，其他中国互联网平台（知乎、B站、百度、快手、豆瓣等）均不提供热搜/热榜数据 API
3. **Steam 官方 API 与页面抓取数据维度不同**：官方仅返回 `appid` + 峰值人数，不含游戏名和实时在线人数，不适合替代
4. **金十数据和法布财经有官方付费 API**，当前使用的是绕过付费墙的非官方接口
5. **GitHub 官方 API 无 trending 端点**，HTML 抓取是获取趋势仓库数据的唯一方式

### 3.2 无官方热搜/数据 API 的主要平台

| 平台 | 开发者门户 | 说明 |
|------|-----------|------|
| 知乎 | 无公开门户 | 历史上有 API，现已关闭公开注册 |
| 百度 | [developer.baidu.com](https://developer.baidu.com) | 侧重 AI/ML 服务，无热搜数据 API |
| 快手 | [open.kuaishou.com](https://open.kuaishou.com) | 企业内测，无个人开发者注册 |
| 豆瓣 | 已关闭 | 官方 API 已停止服务 |
| 今日头条 | [open.mp.toutiao.com](https://open.mp.toutiao.com) | 面向头条号作者，无数据消费 API |
| 酷安 | [developer.coolapk.com](https://developer.coolapk.com) | 仅应用商店入口，无数据 API |
| 雪球 | 无 | 无公开开发者项目 |
| 虎扑 | 无 | 无开发者门户 |
| 华尔街见闻 | 无 | 无公开 API |
| 财联社 | 无 | 无公开 API |
| 36氪 | 无 | 无公开 API |
| 格隆汇 | 无 | 无公开 API |
| 少数派 | 无 | 无公开 API |
| 掘金 | 无 | 无公开 API |
| IT之家 | 无 | 无公开 API |
| 澎湃新闻 | 无 | 有澎湃号开放平台（发布用），无数据 API |
| 凤凰网 | 无 | 无公开 API |
| B站 | [open.bilibili.com](https://open.bilibili.com) | 侧重登录/发布/直播，无热搜接口 |
| 微博 | [open.weibo.com](https://open.weibo.com) | Search API 需企业审批，热搜数据不对外开放 |

### 3.3 未采纳的官方付费 API

| 来源 | 官方 API | 费用 | 不采纳原因 |
|------|---------|------|-----------|
| 金十数据 `jin10` | [open.jin10.com](https://open.jin10.com) | 2000 元/年起 | 成本过高 |
| 法布财经 `fastbull` | [solution.fastbull.com](https://solution.fastbull.com/data) | 付费订阅 | 成本过高 |

### 3.4 第三方聚合服务

如需降低维护多个逆向接口的负担，可考虑以下第三方聚合服务：

| 服务 | 地址 | 说明 |
|------|------|------|
| DailyHotApi | [github.com/imsyy/DailyHotApi](https://github.com/imsyy/DailyHotApi) | 开源热搜聚合，覆盖多数国内平台 |
| TianAPI | [tianapi.com](https://www.tianapi.com/) | 付费综合数据接口 |
| TopHub | [tophubdata.com](https://www.tophubdata.com/) | 热榜聚合服务 |
| bilibili-API-collect | [github.com/SocialSisterYi/bilibili-API-collect](https://github.com/SocialSisterYi/bilibili-API-collect) | B站非官方 API 社区文档 |

### 3.5 合规风险评估

| 风险等级 | 来源 | 原因 |
|----------|------|------|
| **高** | 酷安 `coolapk` | 逆向私有移动端签名算法，伪造设备身份 |
| **高** | 财联社 `cls` | 逆向请求签名机制，付费新闻平台 |
| **高** | 雪球 `xueqiu` | 金融数据平台，Cookie 绕过认证 |
| **高** | 金十数据 `jin10` | 明确声明禁止未授权使用 |
| **高** | 知乎 `zhihu` | 用户协议禁止爬虫 |
| **中** | 华尔街见闻 `wallstreetcn` | 商业金融平台，使用内部 API |
| **中** | 格隆汇 `gelonghui` | 商业金融平台 |
| **中** | 36氪 `36kr` | NASDAQ 上市媒体公司 |
| **中** | B站 `bilibili` | ToS 禁止未授权爬取 |
| **低** | GitHub Trending | 公开页面 |
| **低** | Steam | 公开统计页面 |
| **极低** | Product Hunt | 官方 API，合规使用 |
| **极低** | Hacker News | 官方 Firebase API，完全免费无限制 |
| **极低** | 抖音 `douyin` | 官方开放平台 API |
| **极低** | 远景论坛 / 虫部落 | 公开 RSS 订阅 |

### 3.6 待鉴权验证接口

以下 5 个接口因需要特殊鉴权机制，无法直接通过 curl 验证：

| 源 ID | 所需凭据 | 说明 |
|-------|---------|------|
| `xueqiu-hotstock` | Cookie | 需先访问 `xueqiu.com/hq` 获取 `xq_a_token` |
| `coolapk` | MD5 签名 | 需 `genHeaders()` 生成 X-App-Token |
| `cls-*` (3个) | SHA1+MD5 签名 | 需 `getSearchParams()` 生成签名参数 |
| `producthunt` | Bearer Token | 需配置 `PRODUCTHUNT_API_TOKEN` 环境变量 |
| `iqiyi-hot-ranklist` | Referer + device 参数 | 需特定 device ID 和 Referer 头 |

### 3.7 现有数据源可扩展端点

以下已接入平台存在更多可用端点，可扩展数据覆盖范围：

| 平台 | 当前端点数 | 可扩展端点 | 说明 |
|------|-----------|-----------|------|
| 知乎 `zhihu` | 1 | +5 | 知乎日报 `daily.zhihu.com/api/4/news/latest`（✅ 200）、每周必看（✅ 200）、错过热议、创作热榜、潜力问题 |
| 豆瓣 `douban` | 1 | +5 | 电视剧/图书实时热门、华语口碑剧集、全球剧集、国内外综艺、口碑电影 |
| 掘金 `juejin` | 1 | +4 | 文章收藏榜、专栏榜（✅ 200）、收藏集（✅ 200）、作者榜；支持 9 类领域筛选 |
| IT之家 `ithome` | 1 | +8 | 阅读榜/最热榜/打分榜 × 日/周/月，共 9 种组合 |
| 哔哩哔哩 `bilibili` | 3 | +2 | 入站必刷（✅ 200, 98 条）、22 种分区排行榜；需 WBI 请求签名（MD5） |
| 凤凰新闻 `ifeng` | 1 | 替代 | 可用 `POST https://nine.ifeng.com/hotspotlistv2` 替代首页抓取（✅ 200, 28 条） |

### 3.8 已发现但暂不可用的数据源

以下平台有接入价值，但当前接口需特殊鉴权，2026-02-18 验证未通过：

| 平台 | 接口 | 状态 | 备注 |
|------|------|------|------|
| 小红书 | `GET https://edith.xiaohongshu.com/api/sns/v1/search/hot_list` | 406 | 需 `xy-common-params`/`xy-platform-info`/`shield` 等多重设备指纹鉴权头，硬编码 Token 已过期 |
| MSN | `GET https://assets.msn.cn/service/news/feed/pages/weblayout` | 401 | 需 `apikey` 参数，硬编码 Key 已失效（"App authentication info not found in the security db"） |

> **已验证并删除的失效接口：**
> - ~~阿里云开发者社区~~ — API 返回 404，端点已下线
> - ~~历史上的今天（百度百科）~~ — API 返回 302 → 错误页面，端点已失效
