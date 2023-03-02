#!/bin/bash

#
# getリクエストをリンクに対して飛ばし、レスポンスのjsonをjqで解析する関数です。
#
function get() {
  local response
  response=$(curl --request "GET" "$1" | tr -d "[:cntrl:]")
  local result
  result=$(parse_json "$response" "$2")
  echo "$result"
}

#
# jqを使用してjsonをパースする関数です。
#
function parse_json() {
  local result
  result=$(echo "$1" | jq -r "$2")
  echo "$result"
}

#
# Velocityの最新バージョンをダウンロードし、proxy.jarという名前で保存する関数です。
#
function setup_velocity() {
  local version
  version=$(get "https://api.papermc.io/v2/projects/velocity" ".versions[-1]")
  local latest_build
  latest_build=$(get "https://api.papermc.io/v2/projects/velocity/versions/${version}/builds" ".builds[-1]")
  local build_number
  build_number=$(parse_json "$latest_build" ".build")
  local file_name
  file_name=$(parse_json "$latest_build" ".downloads.application.name")
  local download_link
  download_link="https://api.papermc.io/v2/projects/velocity/versions/${version}/builds/$build_number/downloads/$file_name"
  curl "$download_link" --output proxy.jar
  echo "downloaded the latest velocity proxy."
}

#
# Velocityの今フィルファイルを生成する関数です。
#
function generate_velocity_config() {
  java -jar /tmp/vcb.jar \
  --bind "${BIND:-"0.0.0.0:25577"}" \
  --motd "${MOTD:-"&#09add3A Velocity Server"}" \
  --show_max_players "${SHOW_MAX_PLAYERS:-"500"}" \
  --online_mode "${ONLINE_MODE:-"true"}" \
  --prevent_client_proxy_connections "${PREVENT_CLIENT_PROXY_CONNECTIONS:-"false"}" \
  --player_info_forwarding_mode "${PLAYER_INFO_FORWARDING_MODE:-"none"}" \
  --forwarding_secret "${FORWARDING_SECRET:-""}" \
  --announce_forge "${ANNOUNCE_FORGE:-"false"}" \
  --kick_existing_players "${KICK_EXISTING_PLAYERS:-"true"}" \
  --ping_passthrough "${ping_passthrough:-"disabled"}" \
  --servers "${SERVERS:-"lobby=127.0.0.1:25566"}" \
  --try "${TRY:-"lobby"}" \
  --forced_hosts "${FORCED_HOSTS:-"lobby.example.com=lobby"}" \
  --compression_threshold "${COMPRESSION_THRESHOLD:-"256"}" \
  --compression_level "${COMPRESSION_LEVEL:-"6"}" \
  --login_ratelimit "${LOGIN_RATELIMIT:-"3000"}" \
  --connection_timeout "${CONNECTION_TIMEOUT:-"5000"}" \
  --read_timeout "${READ_TIMEOUT:-"30000"}" \
  --haproxy_protocol "${HAPROXY_PROTOCOL:-"false"}" \
  --tcp_fast_open "${TCP_FAST_OPEN:-"false"}" \
  --bungee_plugin_message "${BUNGEE_PLUGIN_MESSAGE:-"true"}" \
  --show_ping_requests "${SHOW_PING_REQUESTS:-"false"}" \
  --failover_on_unexpected_server_disconnect "${FAILOVER_ON_UNEXPECTED_SERVER_DISCONNECT:-"true"}" \
  --announce_proxy_commands "${ANNOUNCE_PROXY_COMMANDS:-"true"}" \
  --log_command_executions "${LOG_COMMAND_EXECUTIONS:-"false"}" \
  --query_enabled "${QUERY_ENABLED:-"true"}" \
  --query_port "${QUERY_PORT:-"25577"}" \
  --query_map "${QUERY_MAP:-"Velocity"}" \
  --query_show_plugins "${QUERY_SHOW_PLUGINS:-"false"}" \
  --output "velocity.toml"
  echo "generated velocity configuration"
}

#
# start a velocity server
#
function start_velocity_server() {
  java -jar -XX:+UseG1GC -XX:G1HeapRegionSize=4M -XX:+UnlockExperimentalVMOptions -XX:+ParallelRefProcEnabled -XX:+AlwaysPreTouch -XX:MaxInlineLevel=15 proxy.jar nogui
}

#
# LuckPermsの最新バージョンをダウンロード
#
function download_latest_luckperms() {
  local download_link
  download_link=$(get "https://metadata.luckperms.net/data/all" ".downloads.velocity")
  mkdir -p plugins
  curl "$download_link" --output ./plugins/luckperms.jar
}

#
# ViaVersionの最新バージョンをダウンロード
#
function download_latest_viaversion() {
  local download_link
  download_link=https://api.spiget.org/v2/resources/19254/download
  mkdir -p plugins
  curl "$download_link" --output ./plugins/viaversion.jar
}

setup_velocity
generate_velocity_config
download_latest_luckperms
start_velocity_server