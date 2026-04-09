---
name: lark-smart-meeting-assistant
version: 1.1.0
description: "智能会议助手：自动获取会议纪要、提取待办事项、创建任务、发送会议总结邮件，支持任务状态跟踪和会议提醒。基于飞书 CLI 1.0.7，支持从日历事件提取纪要文档令牌、send_as 邮件发送等新功能。适用于会议后处理自动化、任务管理、团队协作场景。"
metadata:
  category: "productivity"
  requires:
    bins: ["lark-cli"]
  tags: ["meeting", "task", "automation", "ai"]
---

# 智能会议助手

**CRITICAL — 开始前 MUST 先用 Read 工具读取 [`../lark-shared/SKILL.md`](../lark-shared/SKILL.md)，其中包含认证、权限处理**

## 适用场景

### 基础场景
- "帮我处理今天的会议纪要"
- "从会议中提取待办事项并创建任务"
- "自动发送会议总结邮件给参会人"
- "整理本周的会议内容并生成报告"
- "会议结束后自动跟进待办事项"

### 高级场景
- "监控待办事项的完成状态"
- "为即将到来的会议设置提醒"
- "批量处理多个会议的纪要"
- "按项目或团队分类整理会议记录"
- "生成会议数据分析报告"

## 核心价值

智能会议助手将会议后的手动工作自动化，实现：
- 🎥 自动获取会议纪要和逐字稿
- ✅ 智能提取待办事项并创建飞书任务
- 📧 自动发送会议总结邮件
- 📊 生成会议数据统计报告
- 🔄 完整的会议后处理工作流
- 🔔 会议提醒和任务状态跟踪
- 📈 会议数据分析和可视化

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

# 最小权限集（仅核心功能）
lark-cli auth login --scope "vc:meeting.search:read,vc:note:read,task:task:write"
```

### 3. 权限说明

| 功能域 | 所需 Scope | 用途 | 必要性 |
|--------|-----------|------|--------|
| vc | `vc:meeting.search:read` | 查询会议记录 | 必需 |
| vc | `vc:note:read` | 获取会议纪要 | 必需 |
| drive | `drive:drive.metadata:readonly` | 读取纪要文档内容 | 必需 |
| task | `task:task:write` | 创建任务 | 必需 |
| task | `task:tasklist:write` | 管理任务列表 | 可选 |
| mail | `mail:user_mailbox.message:send` | 发送会议总结邮件 | 可选 |
| doc | `docx:document:create` | 生成会议报告文档 | 可选 |
| contact | `contact:user:read` | 搜索用户信息 | 可选 |

### 4. 授权流程

**步骤 1：检查当前授权状态**

```bash
# 查看当前授权状态
lark-cli auth status

# 查看已授权的 scopes
lark-cli auth list
```

**步骤 2：根据需要添加权限**

```bash
# 添加单个权限域
lark-cli auth login --domain vc

# 添加多个权限域
lark-cli auth login --domain vc,drive,task

# 添加具体的 scopes
lark-cli auth login --scope "vc:meeting.search:read,vc:note:read,task:task:write"
```

**步骤 3：验证授权**

```bash
# 验证会议查询权限
lark-cli vc +search --start "2026-04-08" --end "2026-04-08" --format json

# 验证任务创建权限
lark-cli task +create --summary "测试任务" --assignee "<user_open_id>"
```

### 5. 权限问题排查

**常见权限错误**：

| 错误信息 | 原因 | 解决方案 |
|---------|------|----------|
| `permission_denied` | 缺少相应权限 | 运行 `lark-cli auth login` 添加缺失的权限 |
| `scope not found` | 权限 scope 不存在 | 检查 scope 名称是否正确 |
| `authorization expired` | 授权已过期 | 重新运行 `lark-cli auth login` 进行授权 |

**权限调试**：

```bash
# 启用详细日志查看权限错误
lark-cli --verbose vc +search --start "2026-04-08" --end "2026-04-08" --format json

# 查看错误详情
lark-cli auth status --detail
```

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

# 按会议状态过滤（如已结束的会议）
lark-cli vc +search --start "2026-04-01" --end "2026-04-30" --status ended --format json
```

**重要提示**：
- 时间范围最大为 1 个月，超过需分批查询
- `--end` 为包含当天的日期
- 有 `page_token` 时必须继续翻页
- 使用 `--format json` 便于 AI 解析
- 支持按会议状态、类型等条件过滤

### 2. 获取会议纪要

获取会议关联的纪要文档和逐字稿。

```bash
# 方式 1：通过会议 ID 获取纪要（推荐）
lark-cli vc +notes --meeting-ids "<meeting_id>"

# 方式 2：通过日历事件关系 API 提取纪要文档令牌（飞书 CLI 1.0.7+ 新功能）
# 这种方式可以更灵活地从日历事件中获取会议纪要
# 具体使用方法见飞书 CLI 官方文档

# 批量获取多个会议的纪要（最多 50 个）
lark-cli vc +notes --meeting-ids "id1,id2,id3"
```

**返回信息**：
- `note_doc_token`: 纪要文档 Token
- `verbatim_doc_token`: 逐字稿文档 Token
- 部分会议可能返回 "no notes available"

**飞书 CLI 1.0.7 新功能提示**：
- VC 模块现在支持从日历事件关系 API 中提取纪要文档令牌
- 这为获取会议纪要提供了更灵活的方式

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
# 方式 1：使用默认发送者发送会议总结邮件
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

# 方式 2：使用 send_as 别名发送（飞书 CLI 1.0.7+ 新功能）
# 首先发现可用的发送者/邮箱
lark-cli mail +discover-senders

# 然后使用 send_as 别名发送
lark-cli mail +send \
  --to "<email1>,<email2>" \
  --send-as "meeting-bot@company.com" \
  --subject "【会议总结】项目进度评审会" \
  --body "<邮件内容>"
```

**飞书 CLI 1.0.7 新功能**：
- 支持 `send_as` 别名，使用指定的邮箱地址发送邮件
- 新增 `mail +discover-senders` 命令，用于发现可用的发送者/邮箱
- 新增邮箱/发送者发现 API 和邮件规则 API
- 这些功能让会议总结邮件发送更加灵活和专业

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

### 8. 任务状态跟踪

监控和跟踪任务的完成状态。

```bash
# 获取我的任务列表
lark-cli task +get-my-tasks --status in_progress --format json

# 检查任务状态
lark-cli task +get --task-id "task_xxxxxxxxxxxxx"

# 批量更新任务状态
lark-cli task +complete --task-id "task_xxxxxxxxxxxxx"
lark-cli task +reopen --task-id "task_xxxxxxxxxxxxx"
```

### 9. 会议提醒

为即将到来的会议设置提醒。

```bash
# 查询即将到来的会议
lark-cli vc +search --start "2026-04-09" --end "2026-04-16" --status upcoming --format json

# 为会议创建提醒任务
lark-cli task +create \
  --summary "准备项目评审会议" \
  --assignee "ou_e47efa3f7bec0d546112535c781f73d1" \
  --due "2026-04-10" \
  --description "准备会议材料和演示文稿"
```

### 10. 会议数据分析

分析会议数据，生成可视化报告。

```bash
# 查询本月会议数据
lark-cli vc +search --start "2026-04-01" --end "2026-04-30" --format json

# 生成数据分析报告
lark-cli docs +create \
  --title "会议数据分析报告 (2026-04)" \
  --markdown "# 会议数据分析报告

## 数据概览
- 总会议数：20 场
- 总时长：30 小时
- 平均每场会议时长：1.5 小时
- 周会议分布：周一 4 场，周二 5 场，周三 6 场，周四 3 场，周五 2 场

## 会议类型分析
- 项目评审：8 场 (40%)
- 技术讨论：6 场 (30%)
- 团队同步：4 场 (20%)
- 其他：2 场 (10%)

## 任务完成率
- 已完成任务：45 项
- 总任务数：60 项
- 完成率：75%
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

### 示例 3：任务状态跟踪和提醒

```bash
#!/bin/bash

# 步骤 1：查询待处理任务
echo "步骤 1：查询待处理任务..."
TASKS=$(lark-cli task +get-my-tasks --status in_progress --format json)
echo "待处理任务：$(echo "$TASKS" | jq '.data.tasks | length') 项"

# 步骤 2：检查任务截止日期
echo "步骤 2：检查任务截止日期..."
echo "$TASKS" | jq -r '.data.tasks[] | select(.due_date != null) | "任务: \(.summary)，截止日期: \(.due_date)"'

# 步骤 3：为即将到期的任务创建提醒
echo "步骤 3：为即将到期的任务创建提醒..."
# 这里可以添加逻辑，为即将到期的任务创建提醒

# 步骤 4：更新已完成的任务
echo "步骤 4：更新已完成的任务..."
# 示例：lark-cli task +complete --task-id "task_xxxxxxxxxxxxx"

echo "✅ 任务状态跟踪完成！"
```

### 示例 4：会议数据分析

```bash
#!/bin/bash

# 步骤 1：查询本月会议数据
echo "步骤 1：查询本月会议数据..."
MEETINGS=$(lark-cli vc +search --start "2026-04-01" --end "2026-04-30" --format json)

# 步骤 2：统计会议信息
echo "步骤 2：统计会议信息..."
MEETING_COUNT=$(echo "$MEETINGS" | jq '.data.meeting_records | length')

# 步骤 3：分析会议时长
echo "步骤 3：分析会议时长..."
TOTAL_DURATION=0
for MEETING in $(echo "$MEETINGS" | jq -r '.data.meeting_records[] | @json'); do
  START=$(echo "$MEETING" | jq -r '.start_time' | date -d "$(sed 's/\+08:00//')" +%s 2>/dev/null || echo 0)
  END=$(echo "$MEETING" | jq -r '.end_time' | date -d "$(sed 's/\+08:00//')" +%s 2>/dev/null || echo 0)
  if [ "$START" -gt 0 ] && [ "$END" -gt 0 ]; then
    DURATION=$((END - START))
    TOTAL_DURATION=$((TOTAL_DURATION + DURATION))
  fi
done

# 步骤 4：生成分析报告
echo "步骤 4：生成分析报告..."
AVERAGE_DURATION=$((TOTAL_DURATION / MEETING_COUNT / 60))

REPORT="# 会议数据分析报告 (2026-04)

## 数据概览
- 总会议数：$MEETING_COUNT 场
- 总时长：$((TOTAL_DURATION / 3600)) 小时 $(((TOTAL_DURATION % 3600) / 60)) 分钟
- 平均每场会议时长：$AVERAGE_DURATION 分钟

## 会议分布
- 本月共召开 $MEETING_COUNT 场会议
"

# 步骤 5：创建分析报告文档
lark-cli docs +create \
  --title "会议数据分析报告 (2026-04)" \
  --markdown "$REPORT"

echo "✅ 会议数据分析完成！"
```

## 错误处理

### 1. 权限不足

如果遇到权限错误：

```bash
# 查看错误信息中的缺失 scope
# 然后补充授权
lark-cli auth login --scope "<missing_scope>"

# 完整授权（包含所有需要的权限）
lark-cli auth login --domain vc,drive,task,mail,doc
```

**常见权限错误及解决方案**：
- `vc:meeting.search:read` - 缺少会议查询权限：`lark-cli auth login --scope "vc:meeting.search:read"`
- `task:task:write` - 缺少任务创建权限：`lark-cli auth login --scope "task:task:write"`
- `mail:user_mailbox.message:send` - 缺少邮件发送权限：`lark-cli auth login --scope "mail:user_mailbox.message:send"`

### 2. 会议无纪要

部分会议可能没有纪要，在输出中标注"无纪要"即可，继续处理其他会议。

```bash
#!/bin/bash

# 获取会议纪要
NOTES=$(lark-cli vc +notes --meeting-ids "<meeting_id>")

# 检查是否有纪要
if echo "$NOTES" | grep -q "no notes available"; then
  echo "⚠️  该会议没有纪要，跳过处理"
  # 可以选择创建一个提醒任务，让用户手动添加纪要
  lark-cli task +create \
    --summary "为会议添加纪要" \
    --assignee "<user_open_id>" \
    --description "会议 ID: <meeting_id> 缺少纪要，需要手动添加"
  exit 0
fi

# 继续处理纪要
echo "✅ 找到纪要，继续处理..."
```

### 3. 用户不存在

创建任务时，如果负责人不存在：
- 先搜索用户：`lark-cli contact search-user --query "姓名"`
- 使用返回的 open_id 创建任务

```bash
#!/bin/bash

# 搜索用户
USER=$(lark-cli contact search-user --query "张三" --format json)

# 检查是否找到用户
USER_COUNT=$(echo "$USER" | jq '.data.items | length')

if [ "$USER_COUNT" -eq 0 ]; then
  echo "❌ 未找到用户 '张三'"
  exit 1
fi

# 获取用户 open_id
USER_OPEN_ID=$(echo "$USER" | jq -r '.data.items[0].open_id')

# 创建任务
lark-cli task +create \
  --summary "完成需求文档" \
  --assignee "$USER_OPEN_ID" \
  --due "2026-04-11"
```

### 4. 网络错误

处理网络连接问题：

```bash
#!/bin/bash

# 重试机制
max_retries=3
retry_count=0

success=false
while [ $retry_count -lt $max_retries ] && [ "$success" = false ]; do
  echo "尝试连接... (${retry_count}/${max_retries})"
  RESULT=$(lark-cli vc +search --start "2026-04-08" --end "2026-04-08" --format json 2>&1)
  
  if echo "$RESULT" | grep -q "connection error"; then
    echo "网络连接失败，重试中..."
    retry_count=$((retry_count + 1))
    sleep 2
  else
    success=true
    echo "$RESULT"
  fi
done

if [ "$success" = false ]; then
  echo "❌ 网络连接失败，已达到最大重试次数"
  exit 1
fi
```

### 5. 任务创建失败

处理任务创建失败的情况：

```bash
#!/bin/bash

# 创建任务
RESULT=$(lark-cli task +create \
  --summary "完成需求文档" \
  --assignee "<user_open_id>" \
  --due "2026-04-11" 2>&1)

# 检查是否成功
if echo "$RESULT" | grep -q "error"; then
  echo "❌ 任务创建失败: $RESULT"
  # 可以选择降级处理，如创建一个本地待办事项
  echo "⚠️  已记录待办事项到本地文件"
  echo "- 完成需求文档 (负责人: <user_open_id>, 截止: 2026-04-11)" >> todo.txt
else
  echo "✅ 任务创建成功"
  echo "$RESULT"
fi
```

### 6. 批量处理错误

在批量处理多个会议时，确保单个会议失败不影响其他会议的处理：

```bash
#!/bin/bash

# 会议 ID 列表
MEETING_IDS=("id1" "id2" "id3")

# 批量处理
for MEETING_ID in "${MEETING_IDS[@]}"; do
  echo "处理会议: $MEETING_ID"
  
  # 尝试获取纪要
  NOTES=$(lark-cli vc +notes --meeting-ids "$MEETING_ID" 2>&1)
  
  if echo "$NOTES" | grep -q "error"; then
    echo "⚠️  获取纪要失败: $NOTES"
    continue  # 跳过当前会议，处理下一个
  fi
  
  # 继续处理...
  echo "✅ 处理成功"
done

echo "🎉 批量处理完成"
```

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
