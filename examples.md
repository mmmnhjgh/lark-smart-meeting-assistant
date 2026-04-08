# 智能会议助手 - 使用示例

本文档提供了智能会议助手的详细使用示例，帮助您快速上手。

## 📋 目录

- [基础示例](#基础示例)
- [进阶示例](#进阶示例)
- [完整工作流](#完整工作流)
- [错误处理](#错误处理)

---

## 基础示例

### 示例 1：查询今天的会议

```bash
# 查询今天的所有会议
lark-cli vc +search --start "2026-04-08" --end "2026-04-08" --format json
```

**预期输出**：
```json
{
  "data": {
    "meeting_records": [
      {
        "id": "71234567890123456789",
        "title": "项目进度评审会",
        "start_time": "2026-04-08T14:00:00+08:00",
        "end_time": "2026-04-08T15:00:00+08:00",
        "status": "ended"
      }
    ]
  }
}
```

### 示例 2：获取会议纪要

```bash
# 获取单个会议的纪要信息
lark-cli vc +notes --meeting-ids "71234567890123456789"
```

**预期输出**：
```json
{
  "data": {
    "notes": [
      {
        "meeting_id": "71234567890123456789",
        "note_doc_token": "doxcnxxxxxxxxxxxx",
        "verbatim_doc_token": "doxcnxxxxxxxxxxxx"
      }
    ]
  }
}
```

### 示例 3：读取纪要文档内容

```bash
# 获取纪要文档的详细内容
lark-cli docs +fetch --doc "doxcnxxxxxxxxxxxx"
```

**预期输出**：
```markdown
# 项目进度评审会

## 参会人员
张三、李四、王五

## 会议要点

### 1. 项目进度汇报
- 前端开发进度：80%
- 后端开发进度：70%
- 测试进度：30%

### 2. 问题讨论
- 接口联调遇到跨域问题
- 需要协调运维团队支持

### 3. 下一步计划
- @张三 需要在周五前完成需求文档
- @李四 需要在下周一前完成技术方案
- @王五 需要在下周三前完成测试用例
```

---

## 进阶示例

### 示例 4：创建飞书任务

```bash
# 创建单个任务
lark-cli task +create \
  --summary "完成需求文档" \
  --assignee "ou_e47efa3f7bec0d546112535c781f73d1" \
  --due "2026-04-11" \
  --description "会议纪要中提到的待办事项：需要在周五前完成需求文档"
```

**预期输出**：
```json
{
  "data": {
    "task": {
      "task_id": "task_xxxxxxxxxxxxx",
      "summary": "完成需求文档",
      "status": "in_progress"
    }
  }
}
```

### 示例 5：批量创建任务

```bash
# 创建多个任务
lark-cli task +create --summary "完成需求文档" --assignee "ou_xxx" --due "2026-04-11"
lark-cli task +create --summary "完成技术方案" --assignee "ou_yyy" --due "2026-04-12"
lark-cli task +create --summary "完成测试用例" --assignee "ou_zzz" --due "2026-04-14"
```

### 示例 6：发送会议总结邮件

```bash
# 发送会议总结邮件
lark-cli mail +send \
  --to "zhangsan@example.com,lisi@example.com,wangwu@example.com" \
  --subject "【会议总结】项目进度评审会" \
  --body "会议时间：2026-04-08 14:00-15:00
参会人员：张三、李四、王五

会议要点：
1. 项目进度汇报
   - 前端开发进度：80%
   - 后端开发进度：70%
   - 测试进度：30%

2. 问题讨论
   - 接口联调遇到跨域问题
   - 需要协调运维团队支持

3. 下一步计划
   - @张三 需要在周五前完成需求文档
   - @李四 需要在下周一前完成技术方案
   - @王五 需要在下周三前完成测试用例

待办事项：
- 张三：完成需求文档（截止：4月11日）
- 李四：完成技术方案（截止：4月12日）
- 王五：完成测试用例（截止：4月14日）

会议纪要：https://example.feishu.cn/docx/doxcnxxxxxxxxxxxx
逐字稿：https://example.feishu.cn/docx/doxcnxxxxxxxxxxxx"
```

---

## 完整工作流

### 示例 7：处理今天的会议（完整流程）

```bash
#!/bin/bash

# 步骤 1：查询今天的会议
echo "步骤 1：查询今天的会议..."
MEETINGS=$(lark-cli vc +search --start "2026-04-08" --end "2026-04-08" --format json)
echo "$MEETINGS"

# 步骤 2：提取会议 ID
echo "步骤 2：提取会议 ID..."
MEETING_IDS=$(echo "$MEETINGS" | jq -r '.data.meeting_records[].id' | paste -sd ',')
echo "会议 IDs: $MEETING_IDS"

# 步骤 3：获取会议纪要
echo "步骤 3：获取会议纪要..."
NOTES=$(lark-cli vc +notes --meeting-ids "$MEETING_IDS")
echo "$NOTES"

# 步骤 4：提取纪要文档 Token
echo "步骤 4：提取纪要文档 Token..."
NOTE_TOKENS=$(echo "$NOTES" | jq -r '.data.notes[].note_doc_token')
echo "纪要 Tokens: $NOTE_TOKENS"

# 步骤 5：读取纪要内容
echo "步骤 5：读取纪要内容..."
for TOKEN in $NOTE_TOKENS; do
  echo "读取纪要: $TOKEN"
  lark-cli docs +fetch --doc "$TOKEN"
done

# 步骤 6：创建任务（示例）
echo "步骤 6：创建任务..."
lark-cli task +create \
  --summary "完成需求文档" \
  --assignee "ou_e47efa3f7bec0d546112535c781f73d1" \
  --due "2026-04-11"

# 步骤 7：发送会议总结邮件
echo "步骤 7：发送会议总结邮件..."
lark-cli mail +send \
  --to "zhangsan@example.com" \
  --subject "【会议总结】今日会议处理完成" \
  --body "今日的会议纪要已处理完成，待办事项已创建。"

echo "✅ 所有步骤完成！"
```

### 示例 8：生成本周会议报告

```bash
#!/bin/bash

# 步骤 1：查询本周会议
echo "步骤 1：查询本周会议..."
MEETINGS=$(lark-cli vc +search --start "2026-04-07" --end "2026-04-13" --format json)

# 步骤 2：统计会议信息
echo "步骤 2：统计会议信息..."
MEETING_COUNT=$(echo "$MEETINGS" | jq '.data.meeting_records | length')
TOTAL_DURATION=$(echo "$MEETINGS" | jq '[.data.meeting_records[] | (.end_time | fromdateiso) - (.start_time | fromdateiso)] | add / 3600')

# 步骤 3：生成报告内容
echo "步骤 3：生成报告内容..."
REPORT="# 会议周报 (2026-04-07 - 2026-04-13)

## 概览统计
- 会议总数：$MEETING_COUNT 场
- 总时长：$(printf "%.1f" $TOTAL_DURATION) 小时

## 会议列表
"

# 步骤 4：添加每个会议的详细信息
echo "$MEETINGS" | jq -r '.data.meeting_records[] | @json' | while read -r MEETING; do
  TITLE=$(echo "$MEETING" | jq -r '.title')
  START=$(echo "$MEETING" | jq -r '.start_time' | cut -d'T' -f2 | cut -d'+' -f1)
  END=$(echo "$MEETING" | jq -r '.end_time' | cut -d'T' -f2 | cut -d'+' -f1)
  
  REPORT="$REPORT
### $TITLE
- 时间：$START - $END
"
done

# 步骤 5：创建报告文档
echo "步骤 5：创建报告文档..."
lark-cli docs +create \
  --title "会议周报 (2026-04-07 - 2026-04-13)" \
  --markdown "$REPORT"

echo "✅ 会议周报生成完成！"
```

---

## 错误处理

### 示例 9：处理权限不足错误

```bash
#!/bin/bash

# 尝试查询会议
RESULT=$(lark-cli vc +search --start "2026-04-08" --end "2026-04-08" --format json 2>&1)

# 检查是否有权限错误
if echo "$RESULT" | grep -q "permission_denied"; then
  echo "❌ 权限不足，正在补充授权..."
  
  # 提取缺失的 scope

  MISSING_SCOPES=$(echo "$RESULT" | jq -r '.error.permission_violations[].scope' | paste -sd ' ')
  
  # 补充授权
  lark-cli auth login --scope "$MISSING_SCOPES"
  
  echo "✅ 授权完成，请重新运行命令"
  exit 1
fi

echo "$RESULT"
```

### 示例 10：处理会议无纪要的情况

```bash
#!/bin/bash

# 获取会议纪要
NOTES=$(lark-cli vc +notes --meeting-ids "71234567890123456789")

# 检查是否有纪要
if echo "$NOTES" | grep -q "no notes available"; then
  echo "⚠️  该会议没有纪要，跳过处理"
  exit 0
fi

# 继续处理纪要
echo "✅ 找到纪要，继续处理..."
```

---

## AI Agent 使用示例

### 在 OpenCode/Claude Code 中使用

#### 场景 1：处理今天的会议

```
用户：帮我处理今天的会议纪要

AI Agent 会自动执行：
1. 查询今天的会议记录
2. 获取每个会议的纪要
3. 读取纪要内容
4. 提取待办事项
5. 创建飞书任务
6. 发送会议总结邮件
```

#### 场景 2：生成本周会议报告

```
用户：帮我整理本周的会议内容，生成一份会议周报

AI Agent 会自动执行：
1. 查询本周的会议记录
2. 统计会议数量和时长
3. 获取每个会议的纪要
4. 生成结构化的报告内容
5. 创建飞书文档
```

#### 场景 3：从会议中提取待办事项

```
用户：从昨天的会议中提取待办事项并创建任务

AI Agent 会自动执行：
1. 查询昨天的会议
2. 获取会议纪要
3. 读取纪要内容
4. 使用 AI 分析提取待办事项
5. 识别负责人和截止时间
6. 创建飞书任务并分配
```

---

## 💡 最佳实践

1. **使用 JSON 格式输出**：便于 AI Agent 解析和处理
2. **错误容忍**：单个会议失败不影响其他会议
3. **分批处理**：大量数据时分批查询和处理
4. **日志记录**：记录处理过程，便于排查问题
5. **用户确认**：重要操作前先展示摘要让用户确认

---

## 📚 更多资源

- [SKILL.md](./SKILL.md) - 详细的 Skill 使用说明
- [README.md](./README.md) - 项目介绍和快速开始
- [飞书 CLI 官方文档](https://github.com/larksuite/cli)
