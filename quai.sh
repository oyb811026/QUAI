#!/bin/bash

# 定義下載和更新函數
download_and_update() {
  stop_and_remove_service
  stop_and_remove_stratum_service
  echo "刪除 /qdata 目錄內所有內容..."
  rm -rf qdata/*
  
  echo "創建並進入 qdata 目錄..."
  mkdir -p qdata
  cd qdata

  echo "下载压缩文件..."
  wget https://storage.googleapis.com/colosseum-db/goldenage_backups/quai-goldenage-backup.tgz
-O quai-goldenage-backup.tgz

  echo "解压缩文件..."
  tar -xvf quai-goldenage-backup.tgz

  echo "删除旧的 go-quai 目录..."
  rm -rf ~/.local/share/go-quai

  echo "将 go-quai 目录复制到指定位置..."
  cp -r quai-goldenage-backup ~/.local/share/go-quai

  echo "下載和更新完成。"
  create_and_start_services
}

resume_service(){
  create_and_start_services
}

update_node(){
  stop_and_remove_service
  stop_and_remove_stratum_service
  echo "删除旧的 Peer DB..."
  rm -rf ~/.local/share/go-quai/0xba33a6807db85d5de6f51ff95c4805feaa9b81951a57e43254117d489031e96f
  #download_node
  #rm -rf ~/go-quai/build/bin/go-quai
  #wget -P ~/go-quai/build/bin/  http://147.124.222.123:8080/go-quai
  #chmod u+x ~/go-quai/build/bin/go-quai
  #git fetch --tags 
  #git checkout v0.39.4 
  #make go-quai
  create_and_start_services
}

download_node()
{
  rm -rf ~/go-quai/build/bin/go-quai
  wget -P ~/go-quai/build/bin/  http://147.124.222.123:8080/go-quai
  chmod u+x ~/go-quai/build/bin/go-quai
}

view_height() {
tail -f ~/go-quai/nodelogs/* | grep Appended
}
# 定義創建和啟動 go-quai 和 go-quai-stratum 服務函數
create_and_start_services() {
  read -p "請輸入 quai-coinbases 地址: " quai_coinbases
  read -p "請輸入 qi-coinbases 地址: " qi_coinbases
  stop_and_remove_service
  stop_and_remove_stratum_service
  download_node
  # 創建 go-quai 服務文件
  SERVICE_FILE="/etc/systemd/system/go-quai.service"
  sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Go-Quai Node
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/go-quai
ExecStart=/bin/bash -c 'cd /root/go-quai && ./build/bin/go-quai start \\
  --node.slices "[0 0]" \\
  --node.genesis-nonce 6224362036655375007 \\
  --node.quai-coinbases "$quai_coinbases" \\
  --node.qi-coinbases "$qi_coinbases" \\
  --node.coinbase-lockup "0" \\
  --node.miner-preference "0"'
Restart=on-failure
StandardOutput=journal
StandardError=journal
Environment=GO_QUAI_LOG_DIR=/root/go-quai/build/bin/nodelogs

[Install]
WantedBy=multi-user.target
EOL

  echo "重新加載 systemd 配置..."
  sudo systemctl daemon-reload

  echo "啟動並啟用 go-quai 服務..."
  sudo systemctl start go-quai
  sudo systemctl enable go-quai

  echo "Go-Quai 服務已啟動並設置為開機自啟動。"

  # 創建 go-quai-stratum 服務文件
  SERVICE_FILE="/etc/systemd/system/go-quai-stratum.service"
  sudo bash -c "cat > $SERVICE_FILE" <<EOL
[Unit]
Description=Go-Quai Stratum
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/go-quai-stratum
ExecStart=/bin/bash -c 'cd /root/go-quai-stratum && ./build/bin/go-quai-stratum --region=cyprus --zone=cyprus1'
Restart=on-failure
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOL

  echo "重新加載 systemd 配置..."
  sudo systemctl daemon-reload

  echo "啟動並啟用 go-quai 和 go-quai-stratum 服務..."
  sudo systemctl start go-quai
  sudo systemctl enable go-quai
  sudo systemctl start go-quai-stratum
  sudo systemctl enable go-quai-stratum
  sudo systemctl restart systemd-journald 
  echo "Go-Quai 和 Go-Quai Stratum 服務已啟動並設置為開機自啟動。"
}

# 定義停止並刪除 go-quai 和 go-quai-stratum 服務函數
stop_and_remove_services() {
  echo "停止 go-quai 和 go-quai-stratum 服務..."
  sudo systemctl stop go-quai
  #sudo systemctl stop go-quai-stratum

  echo "禁用 go-quai 和 go-quai-stratum 服務..."
  sudo systemctl disable go-quai
  #sudo systemctl disable go-quai-stratum

  echo "刪除 go-quai 和 go-quai-stratum 服務文件..."
  sudo rm /etc/systemd/system/go-quai.service
  #sudo rm /etc/systemd/system/go-quai-stratum.service

  echo "重新加載 systemd 配置..."
  sudo systemctl daemon-reload

  echo "Go-Quai 和 Go-Quai Stratum 服務已停止並刪除。"
}

# 定義查看 go-quai 服務輸出函數
view_go_quai_logs() {
  echo "查看 go-quai 服務輸出..."
  sudo journalctl -u go-quai -f
}


# 定義停止並刪除 go-quai 服務函數
stop_and_remove_service() {
  echo "停止 go-quai 服務..."
  sudo systemctl stop go-quai

  echo "禁用 go-quai 服務..."
  sudo systemctl disable go-quai

  echo "刪除 go-quai 服務文件..."
  sudo rm /etc/systemd/system/go-quai.service

  echo "重新加載 systemd 配置..."
  sudo systemctl daemon-reload

  echo "go-quai 服務已停止並刪除。"
}

# 定義停止並刪除 go-quai-stratum 服務函數
stop_and_remove_stratum_service() {
  echo "停止 go-quai-stratum 服務..."
  sudo systemctl stop go-quai-stratum

  echo "禁用 go-quai-stratum 服務..."
  sudo systemctl disable go-quai-stratum

  echo "刪除 go-quai-stratum 服務文件..."
  sudo rm /etc/systemd/system/go-quai-stratum.service

  echo "重新加載 systemd 配置..."
  sudo systemctl daemon-reload

  echo "go-quai-stratum 服務已停止並刪除。"
}

view_wallet(){
cat /etc/systemd/system/go-quai.service
    echo -e "\n请核对节点绑定钱包，返回请按回车键..."
    read -r  # 等待用户按下回车
}

view_blocks(){
cat /etc/systemd/system/go-quai.service
sudo journalctl -u go-quai-stratum | grep "Miner submitted a block"
    echo -e "\n请核对节点爆块情况，返回请按回车键..."
    read -r  # 等待用户按下回车
    return
}

check_version(){
	if ~/go-quai/build/bin/go-quai -h| grep -q "coinbase-lockup"; then
    echo -e "\033[1;32m恭喜老板，当前go-quai节点版本是v0.39.4，无需升级，比特猎人伴您走向财富自由！！！！\033[0m"
	else
       echo -e "\033[1;31m当前go-quai节点低于版本v0.39.4版本，请立刻执行选项8进行一键升级，否则无法挖矿！！！！\033[0m"
	fi
	echo -e "\n请核对go-quai版本号，返回请按回车键..."
    read -r  # 等待用户按下回车
}

# 定義查看 go-quai-stratum 服務輸出函數
view_go_quai_stratum_logs() {
  echo "查看 go-quai-stratum 服務輸出..."
  sudo journalctl -u go-quai-stratum -f
}

# 顯示選單
while true; do
  echo "選單："
  echo "1) 一键部署quai节点"
  echo "2) 重启quai节点"
  echo "3) 查看 go-quai 节点服務輸出"
  echo "4) 查看 go-quai-stratum 服務輸出"
  echo "5) 查看区块高度"
  echo "6) 查看节点绑定钱包"
  echo "7) 查看爆块情况"
  echo "8) 一键更新节点至V0.39.4版本"
  echo "9) 检测当前节点版本号"
  echo "10) 退出"
  read -p "請選擇一個選項: " choice

  case $choice in
    1)
      download_and_update
      ;;
    2)
      resume_service
      ;;
    3)
      view_go_quai_logs
      ;;
    4)
      view_go_quai_stratum_logs
      ;;
	5)
      view_height
      ;;
	6)
      view_wallet
      ;;
	7)
      view_blocks
      ;;
	8)
     update_node
      ;;
    9)
     check_version
      ;;
    10)
      echo "退出程序。"
      break
      ;;
	  
    *)
      echo "無效選項，請重新選擇。"
      ;;
  esac
done
