#!/bin/bash

DEVICE_IP=${DEVICE_IP:-$(ip addr show | grep inet | grep -v inet6 | awk '{print $2}' | cut -d/ -f1 | grep -v '127.0.0.1' | head -n 1)}
DEVICE_IP=${DEVICE_IP:-"未知"}
echo "当前设备IP: $DEVICE_IP"

DEVICE_NAME=${DEVICE_NAME:-"未知"}
echo "当前设备名称: $DEVICE_NAME"

if [[ -n "$DEVICE_NAME" ]]; then
    SERVER_NAME="$DEVICE_IP【$DEVICE_NAME】"
else
    SERVER_NAME="$DEVICE_IP"
fi
echo "当前服务器名称: $SERVER_NAME"

# 你的飞书 Webhook URL
FEISHU_WEBHOOK=${FEISHU_WEBHOOK:-""}
echo "飞书 Webhook URL: $FEISHU_WEBHOOK"

docker events --filter 'type=container' --format '{{.Time}} {{.Action}} {{.Actor.Attributes.name}} {{.Actor.Attributes.image}}' | while read timestamp action name image
do
  # 时间格式转换
  readable_time=$(date -d @"$timestamp" +"%Y-%m-%d %H:%M:%S")

  echo "容器事件: $readable_time $action $name $hostname"

  case "$action" in
    "start")
      TITLE="容器启动通知"
      COLOR="green"
      ;;
    "die")
      TITLE="容器退出警告"
      COLOR="red"
      ;;
    *)
       TITLE=""
      ;;
  esac

  if [[ -n "$TITLE" && "$FEISHU_WEBHOOK" ]]; then
    curl -X POST -H "Content-Type: application/json" -d '{
      "msg_type": "interactive",
      "card": {
        "config": {
            "update_multi": true
        },
        "card_link": {
            "url": ""
        },
        "i18n_elements": {
            "zh_cn": [
                {
                    "tag": "markdown",
                    "content": "'"**服务器**: $SERVER_NAME"'",
                    "text_align": "left",
                    "text_size": "normal",
                    "icon": {
                        "tag": "standard_icon",
                        "token": "computer_outlined",
                        "color": "grey"
                    }
                },
                {
                    "tag": "markdown",
                    "content": "'"**容器**: $name"'",
                    "text_align": "left",
                    "text_size": "normal",
                    "icon": {
                        "tag": "standard_icon",
                        "token": "lan_outlined",
                        "color": "grey"
                    }
                },
                {
                    "tag": "markdown",
                    "content": "'"**镜像**: $image"'",
                    "text_align": "left",
                    "text_size": "normal",
                    "icon": {
                        "tag": "standard_icon",
                        "token": "ram_outlined",
                        "color": "grey"
                    }
                },
                {
                    "tag": "markdown",
                    "content": "'"**时间**:  $readable_time $IP"'",
                    "text_align": "left",
                    "text_size": "normal",
                    "icon": {
                        "tag": "standard_icon",
                        "token": "time_outlined",
                        "color": "grey"
                    }
                }
            ]
        },
        "i18n_header": {
            "zh_cn": {
                "title": {
                    "tag": "plain_text",
                    "content": "'"$TITLE"'"
                },
                "subtitle": {
                    "tag": "plain_text",
                    "content": ""
                },
                "template": "'"$COLOR"'",
                "ud_icon": {
                    "tag": "standard_icon",
                    "token": "alarm_outlined"
                }
            }
        }
      }
    }' "$FEISHU_WEBHOOK"
  fi
done

