---
name: lark-smart-meeting-assistant
version: 1.0.0
description: "智能会议助手：自动获取会议纪要、提取待办事项、创建任务、发送会议总结邮件。适用于会议后处理自动化、任务管理、团队协作场景。"
metadata:
  category: "productivity"
  requires:
    bins: ["lark-cli"]
---

# 智能会议助手

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lark-shared/SKILL.md`](../lark-shared/SKILL.md)，其中包含认证、权限处理**

## 适用场景

- "帮我处理今天的会议纪要"
- "从会议中提取待办事项并创建任务"
- "自动发送会议总结邮件给参会人"
- "整理本周的会议内容并生成报告"
- "会议结束后自动跟进待办事项"

## 核心价值

智能会议助手将会议后的手动工作自动化，实现：
- 🎥 自动获取会议纪要和逐字稿
- ✅ 智能提取待办事项并创建飞书任务
- 📧 自动发送会议总结邮件
- 📊 生成会议数据统计报告
- 🔄 完整的会议后处理工作流

## 前置条件

### 1. 身份要求

仅支持 **user 身份**，因为需要访问用户的会议记录、日历和任务。

### 2. 权限授权

执行前确保已授权以下权限：

```bash
# 基础权限（查询会议和纪要）
lark-cli auth login --domain vc

# 完整权限（含创建任务、发送邮件、生成文档）
lark-cli auth login --domain vc,drive,task,mail,doc
```

### 3. 权限说明

| 功能域 | 所需 Scope | 用途 |
|--------|-----------|------|
| vc | `vc:meeting.search:read`, `vc:note:read` | 查询会议记录和纪要 |
| drive | `drive:drive.metadata:readonly` | 读取纪要文档内容 |
| task | `task:task:write`, `task:tasklist:write` | 创建和管理任务 |
| mail | `mail:user_mailbox.message:send` | 发送会议总结邮件 |
| doc | `docx:document:create` | 生成会议报告文档 |

## 工作流程

```
会议结束
    │
    ▼
查询会议记录 (vc +search)
    │
    ▼
获取会议纪要 (vc +notes)
    │
    ▼
提取待办事项 (AI 分析)
    │
    ▼
创建飞书任务 (task +create)
    │
    ▼
发送会议总结 (mail +send)
    │
    ▼
生成报告文档 (docs +create)
```

## 核心功能

### 1. 查询会议记录

查询指定时间范围内的会议记录。

```bash
# 查询今天的会议
lark-cli vc +search --start "2026-04-08" --end "2026-04-08" --format json

# 查询本周的会议
lark-cli vc +search --start "2026-04-07" --end "2026-04-13" --format json

# 查询指定时间范围的会议（最多 30 条）
lark-cli vc +search --start "<YYYY-MM-DD>" --end "<YYYY-MM-DD>" --format json --page-size 30
```

**重要提示**：
- 时间范围最大为 1 个月，超过需分批查询
- `--end` 为包含当天的日期
- 有 `page_token` 时必须继续翻页
- 使用 `--format json` 便于 AI 解析

### 2. 获取会议纪要

获取会议关联的纪要文档和逐字稿。

```bash
# 获取单个会议的纪要
lark-cli vc +notes --meeting-ids "<meeting_id>"

# 批量获取多个会议的纪要（最多 50 个）
lark-cli vc +notes --meeting-ids "id1,id2,id3"
```

**返回信息**：
- `note_doc_token`: 纪要文档 Token
- `verbatim_doc_token`: 逐字稿文档 Token
- 部分会议可能返回 "no notes available"

### 3. 读取纪要文档内容

获取纪要文档的详细内容。

```bash
# 先查看参数结构
lark-cli schema drive.metas.batch_query

# 批量获取纪要文档链接（一次最多 10 个）
lark-cli drive metas batch_query --data '{
  "request_docs": [
    {"doc_type": "docx", "doc_token": "<note_doc_token>"}
  ],
  "with_url": true
}'

# 获取文档内容
lark-cli docs +fetch --doc "<doc_url_or_token>"
```

### 4. 提取待办事项

从纪要文档中智能提取待办事项。

**识别模式**：
- 任务描述（以动词开头）
- 负责人（@提及或姓名）
- 截止时间（日期或时间表达）
- 优先级（紧急/重要/普通）

**示例提取**：
```
原文：@张三 需要在周五前完成需求文档
提取：
- 任务：完成需求文档
- 负责人：张三
- 截止时间：本周五
- 优先级：普通
```

### 5. 创建飞书任务

将提取的待办事项创建为飞书任务。

```bash
# 创建单个任务
lark-cli task +create \
  --summary "完成需求文档" \
  --assignee "<user_open_id>" \
  --due "2026-04-11" \
  --description "会议纪要中提到的待办事项"

# 创建任务并添加到任务列表
lark-cli task +create \
  --summary "任务描述" \
  --assignee "<user_open_id>" \
  --tasklist "<tasklist_id>"
```

**参数说明**：
- `--summary`: 任务标题（必需）
- `--assignee`: 负责人的 open_id
- `--due`: 截止日期（YYYY-MM-DD 格式）
- `--description`: 任务详细描述
- `--tasklist`: 任务列表 ID（可选）

### 6. 发送会议总结邮件

将会议总结发送给参会人。

```bash
# 发送会议总结邮件
lark-cli mail +send \
  --to "<email1>,<email2>" \
  --subject "【会议总结】项目进度评审会" \
  --body "会议时间：2026-04-08 14:00-15:00
参会人员：张三、李四、王五
会议要点：
1. 项目进度汇报
2. 问题讨论
3. 下一步计划

待办事项：
- @张三 完成需求文档（截止：4月11日）
- @李四 完成技术方案（截止：4月12日）

会议纪要：[纪要链接]
逐字稿：[逐字稿链接]"
```

### 7. 生成会议报告文档

创建结构化的会议报告文档。

```bash
# 创建会议报告
lark-cli docs +create \
  --title "会议周报 (2026-04-01 - 2026-04-07)" \
  --markdown "# 会议周报

## 概览统计
- 会议总数：5 场
- 总时长：7.5 小时
- 待办事项：12 项
- 已完成：8 项

## 会议列表

### 1. 项目进度评审会
- 时间：2026-04-08 14:00-15:00
- 参会人：张三、李四、王五
- 待办事项：3 项
- [纪要链接](url)
- [逐字稿链接](url)

### 2. 技术方案讨论会
- 时间：2026-04-07 10:00-11:30
- 参会人：李四、王五、赵六
- 待办事项：2 项
- [纪要链接](url)

## 待办事项汇总

| 任务 | 负责人 | 截止时间 | 状态 |
|------|--------|----------|------|
| 完成需求文档 | 张三 | 2026-04-11 | 进行中 |
| 完成技术方案 | 李四 | 2026-04-12 | 未开始 |
"
```

## 完整使用示例

### 示例 1：处理今天的会议

```bash
# 1. 查询今天的会议
lark-cli vc +search --start "2026-04-08" --end "2026-04-08" --format json

# 2. 获取会议纪要（假设 meeting_id 为 xxx）
lark-cli vc +notes --meeting-ids "xxx"

# 3. 读取纪要内容
lark-cli docs +fetch --doc "<note_doc_token>"

# 4. 创建任务
lark-cli task +create --summary "完成需求文档" --assignee "<user_id>"

# 5. 发送总结邮件
lark-cli mail +send --to "<email>" --subject "会议总结" --body "<内容>"
```

### 示例 2：生成本周会议报告

```bash
# 1. 查询本周会议
lark-cli vc +search --start "2026-04-07" --end "2026-04-13" --format json

# 2. 批量获取纪要
lark-cli vc +notes --meeting-ids "id1,id2,id3"

# 3. 生成报告文档
lark-cli docs +create --title "本周会议报告" --markdown "<报告内容>"
```

## 错误处理

### 权限不足

如果遇到权限错误：

```bash
# 查看错误信息中的缺失 scope
# 然后补充授权
lark-cli auth login --scope "<missing_scope>"
```

### 会议无纪要

部分会议可能没有纪要，在输出中标注"无纪要"即可，继续处理其他会议。

### 用户不存在

创建任务时，如果负责人不存在：
- 先搜索用户：`lark-cli contact search-user --query "姓名"`
- 使用返回的 open_id 创建任务

## 最佳实践

1. **分批处理**：会议数量较多时，分批查询和处理
2. **错误容忍**：单个会议失败不影响其他会议的处理
3. **用户确认**：创建任务和发送邮件前，先展示摘要让用户确认
4. **日志记录**：记录处理过程，便于排查问题
5. **增量更新**：支持只处理新增的会议，避免重复处理

## 参考资源

- [lark-shared](../lark-shared/SKILL.md) — 认证、权限处理（必读）
- [lark-vc](../lark-vc/SKILL.md) — 会议记录和纪要操作
- [lark-task](../lark-task/SKILL.md) — 任务创建和管理
- [lark-mail](../lark-mail/SKILL.md) — 邮件发送
- [lark-doc](../lark-doc/SKILL.md) — 文档创建和读取
- [lark-contact](../lark-contact/SKILL.md) — 用户搜索

## 技术架构

本 Skill 基于飞书 CLI 的以下能力：
- **vc**: 会议记录查询、纪要获取
- **drive**: 文档元数据查询
- **docs**: 文档内容读取和创建
- **task**: 任务创建和管理
- **mail**: 邮件发送
- **contact**: 用户信息查询

通过组合这些能力，实现完整的会议后处理自动化工作流。
