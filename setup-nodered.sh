#!/bin/bash
set -e

cat << "EOF"

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🔧 CONFIGURAÇÃO AUTOMÁTICA DO NODE-RED                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

EOF

echo -e "\n\033[1;33m[1/5] Verificando Docker...\033[0m"

if ! command -v docker &> /dev/null; then
    echo -e "\033[1;31m❌ Docker não encontrado!\033[0m"
    exit 1
fi

if ! docker ps &> /dev/null; then
    echo -e "\033[1;31m❌ Docker não está rodando!\033[0m"
    exit 1
fi

echo -e "\033[1;32m✅ Docker está rodando!\033[0m"

echo -e "\n\033[1;33m[2/5] Verificando arquivo .env...\033[0m"

if [ ! -f ".env" ]; then
    cat > .env << 'ENVEOF'
MQTT_SENSOR_PASSWORD=sensor123
MQTT_NODERED_PASSWORD=nodered123
MQTT_ADMIN_PASSWORD=admin123
BASTION_PASSWORD=bastion123
NODERED_CREDENTIAL_SECRET=my-secret-key-123
ENVEOF
    echo -e "\033[1;32m✅ Arquivo .env criado\033[0m"
fi

export $(cat .env | xargs)

echo -e "\033[1;33m[3/5] Gerando arquivo de senhas do Mosquitto...\033[0m"

mkdir -p mosquitto/config

docker run --rm eclipse-mosquitto:2.0 sh -c "mosquitto_passwd -c -b /tmp/passwd sensor_user '$MQTT_SENSOR_PASSWORD' && mosquitto_passwd -b /tmp/passwd nodered_user '$MQTT_NODERED_PASSWORD' && mosquitto_passwd -b /tmp/passwd admin_user '$MQTT_ADMIN_PASSWORD' && cat /tmp/passwd" > mosquitto/config/passwd 2>/dev/null

echo -e "\033[1;32m✅ Arquivo de senhas criado!\033[0m"

echo -e "\n\033[1;33m[4/5] Iniciando sistema Docker...\033[0m"

docker compose down 2>/dev/null || true
docker compose up -d

echo -e "\033[1;32m✅ Sistema iniciado!\033[0m"
sleep 10

echo -e "\n\033[1;33m[5/5] Configurando Node-RED...\033[0m"

cat > flows.json << 'FLOWEOF'
[{"id":"mqtt_broker","type":"mqtt-broker","name":"Mosquitto","broker":"mosquitto","port":"8883","tls":"tls_config","clientid":"","autoConnect":true,"usetls":true,"protocolVersion":"4","keepalive":"60","cleansession":true},{"id":"tls_config","type":"tls-config","name":"TLS Config","cert":"","key":"","ca":"","verifyservercert":false},{"id":"ui_tab","type":"ui_tab","name":"Dashboard IoT","icon":"dashboard","order":1},{"id":"ui_group","type":"ui_group","name":"Temperatura","tab":"ui_tab","order":1,"disp":true,"width":"6"},{"id":"flow1","type":"tab","label":"IoT Temperature"},{"id":"mqtt_in","z":"flow1","type":"mqtt in","name":"MQTT Sensor","topic":"factory/sensors/#","qos":"0","datatype":"auto-detect","broker":"mqtt_broker","x":130,"y":100,"wires":[["json_parse"]]},{"id":"json_parse","z":"flow1","type":"json","name":"Parse JSON","property":"payload","action":"obj","x":310,"y":100,"wires":[["extract_temp","debug"]]},{"id":"extract_temp","z":"flow1","type":"function","name":"Extrair Temp","func":"msg.payload = msg.payload.temperature;\nmsg.topic = 'Temperatura';\nreturn msg;","x":510,"y":100,"wires":[["chart_temp","gauge_temp"]]},{"id":"chart_temp","z":"flow1","type":"ui_chart","name":"Gráfico","group":"ui_group","order":1,"label":"Temperatura (°C)","chartType":"line","xformat":"HH:mm:ss","nodata":"Aguardando dados...","ymin":"15","ymax":"35","removeOlder":"10","removeOlderUnit":"60","colors":["#1f77b4"],"x":720,"y":80,"wires":[[]]},{"id":"gauge_temp","z":"flow1","type":"ui_gauge","name":"Medidor","group":"ui_group","order":2,"title":"Temperatura Atual","label":"°C","format":"{{value}}","min":"15","max":"35","colors":["#00b500","#e6e600","#ca3838"],"seg1":"20","seg2":"28","x":720,"y":120,"wires":[]},{"id":"debug","z":"flow1","type":"debug","name":"Debug","x":510,"y":160,"wires":[]}]
FLOWEOF

cat > flows_cred.json << CREDEOF
{
    "mqtt_broker": {
        "user": "nodered_user",
        "password": "$MQTT_NODERED_PASSWORD"
    }
}
CREDEOF

docker cp flows.json nodered-dashboard:/data/flows.json
docker cp flows_cred.json nodered-dashboard:/data/flows_cred.json

rm flows.json flows_cred.json

docker restart nodered-dashboard > /dev/null
sleep 8

echo -e "\033[1;32m✅ Node-RED configurado!\033[0m"

cat << "EOF"

╔═══════════════════════════════════════════════════════════════╗
║   ✅ CONFIGURAÇÃO CONCLUÍDA!                                  ║
╚═══════════════════════════════════════════════════════════════╝

📊 Dashboard: http://localhost:1880/ui

EOF

docker compose ps

if command -v xdg-open &> /dev/null; then
    xdg-open "http://localhost:1880/ui" 2>/dev/null &
elif command -v open &> /dev/null; then
    open "http://localhost:1880/ui" 2>/dev/null &
fi
