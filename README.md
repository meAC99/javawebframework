# 南坡小炒 · 20 课项目全集

《Java Web 框架》课程每一课结束时的**完整可运行项目**，一课一个目录，从第 1 课的 Hello World 一路长到第 20 课的 MCP Server。

- 每一课都是独立可运行的项目（源码 + pom + 配置 + 该课讲义），不是零散代码片段
- 想跟哪一课、想回看哪一步，直接进对应目录
- 想比较两课改了什么：`git diff --no-index lesson-01/src lesson-02/src`

## 课程索引

| 课 | 标题 | 目录 | 存档 tag | 日期 |
|---|---|---|---|---|
| 01 | 南坡小炒开业 | [lesson-01](lesson-01/) | `lesson-01` | 2026-09-06 |
| 02 | 服务员接第一单 | [lesson-02](lesson-02/) | `lesson-02` | 2026-09-06 |
| 03 | 招入墩子和厨师 | [lesson-03](lesson-03/) | `lesson-03` | 2026-09-06 |
| 04 | 员工由总部委派 | [lesson-04](lesson-04/) | `lesson-04` | 2026-09-06 |
| 05 | 全店统一小票 | [lesson-05](lesson-05/) | `lesson-05` | 2026-09-06 |
| 06 | 统一客诉处理台 | [lesson-06](lesson-06/) | `lesson-06` | 2026-09-06 |
| 07 | 开店建账H2 | [lesson-07](lesson-07/) | `lesson-07` | 2026-09-06 |
| 08 | 菜单上账 | [lesson-08](lesson-08/) | `lesson-08` | 2026-09-06 |
| 09 | 订单落库 | [lesson-09](lesson-09/) | `lesson-09` | 2026-09-06 |
| 10 | 小票与账本分离 | [lesson-10](lesson-10/) | `lesson-10` | 2026-09-06 |
| 11 | 要么全成要么全不成 | [lesson-11](lesson-11/) | `lesson-11` | 2026-09-06 |
| 12 | 翻账本 | [lesson-12](lesson-12/) | `lesson-12` | 2026-09-06 |
| 13 | 菜品拍照上架 | [lesson-13](lesson-13/) | `lesson-13` | 2026-09-06 |
| 14 | 照片上墙 | [lesson-14](lesson-14/) | `lesson-14` | 2026-09-06 |
| 15 | 办会员卡 | [lesson-15](lesson-15/) | `lesson-15` | 2026-09-06 |
| 16 | 查票与续卡 | [lesson-16](lesson-16/) | `lesson-16` | 2026-09-06 |
| 17 | AI服务员上岗 | [lesson-17](lesson-17/) | `lesson-17` | 2026-09-06 |
| 18 | AI会下单 | [lesson-18](lesson-18/) | `lesson-18` | 2026-09-06 |
| 19 | 连锁开店 | [lesson-19](lesson-19/) | `lesson-19` | 2026-09-07 |
| 20 | AI客户端来点菜 | [lesson-20](lesson-20/) | `lesson-20` | 2026-09-07 |

## 怎么用

```bash
cd lesson-09          # 进入想看的课
./mvnw spring-boot:run
```

然后打开 <http://localhost:8080>。第 7 课起有 H2 控制台（`/h2-console`），第 19 课起可 `docker compose up` 一键开店。

## 重新生成

```powershell
# 全部重新导出（覆盖已有目录）
powershell -ExecutionPolicy Bypass -File .\tools\export-lessons.ps1 -Force

# 只补某一课
powershell -ExecutionPolicy Bypass -File .\tools\export-lessons.ps1 -Lessons 21
```

脚本从课程源仓库的 `lesson-NN` tag 导出快照，并复制对应讲义、重写本索引。

## 说明

- 讲义全文（含全部课程文档）在课程主仓库的 `docs/` 下；本仓库每课只带该课的 3 篇讲义。
- 密钥不落盘：`NANPO_AI_KEY`、`NANPO_JWT_SECRET` 走环境变量，仓库里只有占位默认值。