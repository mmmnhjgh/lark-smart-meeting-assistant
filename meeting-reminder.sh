#!/bin/bash

# 智能会议助手 - 会议提醒脚本
# 功能：为即将到来的会议设置提醒，跟踪任务状态

# 配置文件路径
CONFIG_FILE="./config.json"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
  echo "⚠️  配置文件不存在，使用默认配置"
  if [ -f "./config.example.json" ]; then
    cp ./config.example.json $CONFIG_FILE
    echo "✅ 已从 config.example.json 创建配置文件"
  else
    echo "❌ 未找到配置文件，使用硬编码默认值"
  fi
 fi

# 函数：获取即将到来的会议
function get_upcoming_meetings() {
  local days=${1:-7}  # 默认查询未来7天的会议
  local end_date=$(date -d "+$days days" +%Y-%m-%d)
  local start_date=$(date +%Y-%m-%d)
  
  echo "🔍 查询 $start_date 到 $end_date 的即将到来的会议..."
  lark-cli vc +search --start "$start_date" --end "$end_date" --status upcoming --format json
}

# 函数：为会议创建提醒任务
function create_meeting_reminder() {
  local meeting_id=$1
  local meeting_title=$2
  local meeting_time=$3
  local lead_time=${4:-30}  # 默认提前30分钟提醒
  
  # 计算提醒时间
  reminder_time=$(date -d "$meeting_time - $lead_time minutes" +%Y-%m-%d)
  
  echo "⏰ 为会议 '$meeting_title' 创建提醒任务..."
  lark-cli task +create \
    --summary "[会议提醒] $meeting_title" \
    --assignee "$(lark-cli auth status --format json | jq -r '.data.user.open_id')" \
    --due "$reminder_time" \
    --description "会议时间：$meeting_time\n会议 ID：$meeting_id\n请提前准备会议材料"
}

# 函数：跟踪任务状态
function track_task_status() {
  echo "📋 跟踪任务状态..."
  
  # 获取所有待处理任务
  tasks=$(lark-cli task +get-my-tasks --status in_progress --format json)
  task_count=$(echo "$tasks" | jq '.data.tasks | length')
  
  echo "当前待处理任务：$task_count 项"
  
  # 检查即将到期的任务
  echo "\n⏳ 即将到期的任务："
  today=$(date +%Y-%m-%d)
  upcoming_tasks=$(echo "$tasks" | jq -r ".data.tasks[] | select(.due_date != null and .due_date <= \"$today\") | \"任务: \(.summary)，截止日期: \(.due_date)\"")
  
  if [ -z "$upcoming_tasks" ]; then
    echo "✅ 没有即将到期的任务"
  else
    echo "$upcoming_tasks"
  fi
}

# 主函数
function main() {
  echo "🚀 智能会议助手 - 会议提醒脚本"
  echo "================================"
  
  # 选项处理
  while getopts "r:t" opt; do
    case $opt in
      r) 
        # 创建会议提醒
        meetings=$(get_upcoming_meetings 7)
        meeting_count=$(echo "$meetings" | jq '.data.meeting_records | length')
        
        echo "\n📅 发现 $meeting_count 个即将到来的会议："
        
        # 为每个会议创建提醒
        echo "$meetings" | jq -r '.data.meeting_records[] | @json' | while read -r meeting; do
          meeting_id=$(echo "$meeting" | jq -r '.id')
          meeting_title=$(echo "$meeting" | jq -r '.title')
          meeting_time=$(echo "$meeting" | jq -r '.start_time')
          
          echo "\n处理会议：$meeting_title"
          create_meeting_reminder "$meeting_id" "$meeting_title" "$meeting_time"
        done
        ;;
      t) 
        # 跟踪任务状态
        track_task_status
        ;;
      *) 
        echo "使用方法："
        echo "  -r: 创建会议提醒"
        echo "  -t: 跟踪任务状态"
        echo "示例："
        echo "  ./meeting-reminder.sh -r  # 创建会议提醒"
        echo "  ./meeting-reminder.sh -t  # 跟踪任务状态"
        exit 1
        ;;
    esac
  done
  
  # 如果没有提供选项，显示帮助
  if [ $OPTIND -eq 1 ]; then
    echo "使用方法："
    echo "  -r: 创建会议提醒"
    echo "  -t: 跟踪任务状态"
    echo "示例："
    echo "  ./meeting-reminder.sh -r  # 创建会议提醒"
    echo "  ./meeting-reminder.sh -t  # 跟踪任务状态"
    exit 1
  fi
}

# 执行主函数
main "$@"
