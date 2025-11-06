#!/usr/bin/env pwsh
# ═══════════════════════════════════════════════════════════════════
#  SETUP AUTOMÁTICO DO NODE-RED PARA DESAFIO DE SEGURANÇA IoT
# ═══════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🔧 CONFIGURAÇÃO AUTOMÁTICA DO NODE-RED                      ║
║                                                               ║
║   Este script vai configurar automaticamente:                ║
║   • Flow do Node-RED com conexão MQTT                        ║
║   • Dashboard com gráfico de temperatura                     ║
║   • Credenciais do MQTT                                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# PASSO 1: VERIFICAR DOCKER
Write-Host "`n[1/5] Verificando Docker..." -ForegroundColor Yellow

if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker não encontrado! Instale o Docker Desktop primeiro." -ForegroundColor Red
    Write-Host "   Download: https://www.docker.com/products/docker-desktop" -ForegroundColor Cyan
    exit 1
}

try {
    docker ps > $null 2>&1
    Write-Host "✅ Docker está rodando!" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Desktop não está rodando!" -ForegroundColor Red
    Write-Host "   Abra o Docker Desktop e tente novamente." -ForegroundColor Yellow
    exit 1
}

# PASSO 2: VERIFICAR .ENV
Write-Host "`n[2/5] Verificando arquivo .env..." -ForegroundColor Yellow

if (!(Test-Path ".env")) {
    Write-Host "⚠️  Arquivo .env não encontrado!" -ForegroundColor Yellow
    Write-Host "   Criando .env com senhas padrão (MUDE DEPOIS!)..." -ForegroundColor Cyan
    
    @"
MQTT_SENSOR_PASSWORD=sensor123
MQTT_NODERED_PASSWORD=nodered123
MQTT_ADMIN_PASSWORD=admin123
BASTION_PASSWORD=bastion123
NODERED_CREDENTIAL_SECRET=my-secret-key-123
"@ | Out-File -FilePath ".env" -Encoding ASCII -Force

    Write-Host "✅ Arquivo .env criado com senhas padrão" -ForegroundColor Green
    Write-Host "⚠️  IMPORTANTE: Mude as senhas depois!" -ForegroundColor Yellow
}

# Ler senhas
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.+)$') {
        Set-Variable -Name $matches[1] -Value $matches[2] -Scope Script
    }
}

Write-Host "✅ Senhas carregadas do .env" -ForegroundColor Green

# PASSO 3: GERAR SENHAS DO MOSQUITTO
Write-Host "`n[3/5] Gerando arquivo de senhas do Mosquitto..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "mosquitto/config" -Force | Out-Null

docker run --rm eclipse-mosquitto:2.0 sh -c "mosquitto_passwd -c -b /tmp/passwd sensor_user '$MQTT_SENSOR_PASSWORD' && mosquitto_passwd -b /tmp/passwd nodered_user '$MQTT_NODERED_PASSWORD' && mosquitto_passwd -b /tmp/passwd admin_user '$MQTT_ADMIN_PASSWORD' && cat /tmp/passwd" 2>$null | Out-File -FilePath "mosquitto/config/passwd" -Encoding ASCII -Force

Write-Host "✅ Arquivo de senhas criado!" -ForegroundColor Green

# PASSO 4: SUBIR SISTEMA
Write-Host "`n[4/5] Iniciando sistema Docker..." -ForegroundColor Yellow

docker compose down 2>$null | Out-Null
docker compose up -d

Write-Host "✅ Sistema iniciado!" -ForegroundColor Green
Write-Host "   Aguardando Node-RED inicializar..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# PASSO 4.5: INSTALAR NODE-RED-DASHBOARD
Write-Host "`n[4.5/5] Instalando node-red-dashboard..." -ForegroundColor Yellow
docker exec nodered-dashboard sh -c "cd /data && npm install node-red-dashboard" 2>&1 | Out-Null
Write-Host "✅ node-red-dashboard instalado!" -ForegroundColor Green

# PASSO 5: CONFIGURAR NODE-RED
Write-Host "`n[5/5] Configurando Node-RED automaticamente..." -ForegroundColor Yellow

$flow = '[{"id":"mqtt_broker","type":"mqtt-broker","name":"Mosquitto","broker":"mosquitto","port":"8883","tls":"tls_config","clientid":"","autoConnect":true,"usetls":true,"protocolVersion":"4","keepalive":"60","cleansession":true},{"id":"tls_config","type":"tls-config","name":"TLS Config","cert":"","key":"","ca":"","verifyservercert":false},{"id":"ui_tab","type":"ui_tab","name":"Dashboard IoT","icon":"dashboard","order":1},{"id":"ui_group","type":"ui_group","name":"Temperatura","tab":"ui_tab","order":1,"disp":true,"width":"6"},{"id":"flow1","type":"tab","label":"IoT Temperature"},{"id":"mqtt_in","z":"flow1","type":"mqtt in","name":"MQTT Sensor","topic":"factory/sensors/#","qos":"0","datatype":"auto-detect","broker":"mqtt_broker","x":130,"y":100,"wires":[["json_parse"]]},{"id":"json_parse","z":"flow1","type":"json","name":"Parse JSON","property":"payload","action":"obj","x":310,"y":100,"wires":[["extract_temp","debug"]]},{"id":"extract_temp","z":"flow1","type":"function","name":"Extrair Temp","func":"msg.payload = msg.payload.temperature;\nmsg.topic = ''Temperatura'';\nreturn msg;","x":510,"y":100,"wires":[["chart_temp","gauge_temp"]]},{"id":"chart_temp","z":"flow1","type":"ui_chart","name":"Gráfico","group":"ui_group","order":1,"label":"Temperatura (°C)","chartType":"line","xformat":"HH:mm:ss","nodata":"Aguardando dados...","ymin":"15","ymax":"35","removeOlder":"10","removeOlderUnit":"60","colors":["#1f77b4"],"x":720,"y":80,"wires":[[]]},{"id":"gauge_temp","z":"flow1","type":"ui_gauge","name":"Medidor","group":"ui_group","order":2,"title":"Temperatura Atual","label":"°C","format":"{{value}}","min":"15","max":"35","colors":["#00b500","#e6e600","#ca3838"],"seg1":"20","seg2":"28","x":720,"y":120,"wires":[]},{"id":"debug","z":"flow1","type":"debug","name":"Debug","x":510,"y":160,"wires":[]}]'

$credentials = @"
{
    "mqtt_broker": {
        "user": "nodered_user",
        "password": "$MQTT_NODERED_PASSWORD"
    }
}
"@

$flow | Out-File -FilePath "flows.json" -Encoding UTF8 -Force
$credentials | Out-File -FilePath "flows_cred.json" -Encoding UTF8 -Force

docker cp flows.json nodered-dashboard:/data/flows.json
docker cp flows_cred.json nodered-dashboard:/data/flows_cred.json

Remove-Item flows.json, flows_cred.json -Force

docker restart nodered-dashboard | Out-Null
Start-Sleep -Seconds 8

Write-Host "✅ Node-RED configurado!" -ForegroundColor Green

Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ✅ CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

📊 ACESSE O DASHBOARD:
   http://localhost:1880/ui

🔧 EDITOR NODE-RED:
   http://localhost:1880

"@ -ForegroundColor Green

docker compose ps

Write-Host @"

📝 PRÓXIMOS PASSOS:
   1. Acesse o dashboard: http://localhost:1880/ui
   2. Verifique se o gráfico está atualizando
   3. Explore o sistema e encontre vulnerabilidades!

"@ -ForegroundColor Cyan

Start-Process "http://localhost:1880/ui"

Write-Host "Pressione ENTER para sair..." -ForegroundColor Yellow
Read-Host

