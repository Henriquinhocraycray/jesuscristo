<<<<<<< HEAD

=======
﻿# ?? Desafio de Segurança IoT

## ?? Descrição
Sistema IoT com Mosquitto MQTT, sensor de temperatura e dashboard Node-RED.
**Objetivo**: Encontrar e documentar todas as vulnerabilidades de segurança.

## ??? Arquitetura
- **Mosquitto MQTT Broker**: Gerenciador de mensagens (portas 1883 e 8883)
- **Sensor IoT**: Publica dados de temperatura a cada 5 segundos
- **Node-RED**: Dashboard de visualização em tempo real

## ?? Como Executar

### Pré-requisitos
- Docker Desktop instalado
- Git (opcional)

### Passo 1: Baixar o Projeto
```bash
# Opção A: Clonar do repositório
git clone https://github.com/otaviano1704/jesuscristo.git
cd jesuscristo

# Opção B: Baixar ZIP e extrair
```

### Passo 2: Configurar Senhas
```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar com suas senhas (Windows)
notepad .env

# Ou usar senhas de exemplo (NÃO RECOMENDADO)
```

### Passo 3: Gerar Arquivo de Senhas do Mosquitto
```powershell
# Windows PowerShell
docker run -d --name pass-gen eclipse-mosquitto:2.0
Start-Sleep -Seconds 2

docker exec pass-gen mosquitto_passwd -c -b /tmp/passwd sensor_user "sua_senha_sensor"
docker exec pass-gen mosquitto_passwd -b /tmp/passwd nodered_user "sua_senha_nodered"
docker exec pass-gen mosquitto_passwd -b /tmp/passwd admin_user "sua_senha_admin"

docker cp pass-gen:/tmp/passwd mosquitto/config/passwd
docker stop pass-gen
docker rm pass-gen
```

### Passo 4: Iniciar o Sistema
```bash
docker compose up -d
```

### Passo 5: Acessar
- **Dashboard Node-RED**: http://localhost:1880/ui
- **Editor Node-RED**: http://localhost:1880
- **MQTT (sem TLS)**: localhost:1883
- **MQTT (com TLS)**: localhost:8883

## ?? Desafio de Segurança

### Objetivo
Você foi contratado como pentester para avaliar a segurança deste sistema IoT.
Encontre o máximo de vulnerabilidades possível!

### Regras
? **Permitido**:
- Análise de portas e serviços
- Testes de autenticação
- Análise de configuração
- Busca por dados sensíveis
- Testes de criptografia
- Análise de logs

? **Proibido**:
- Ataques DDoS
- Ataques a sistemas externos
- Dano aos dados ou sistema
- Violação de leis

### Categorias de Vulnerabilidades

#### ?? Críticas (10 pontos)
- Credenciais expostas
- Portas sem autenticação
- Dados sem criptografia
- Execução remota de código

#### ?? Altas (7 pontos)
- Configurações inseguras
- Certificados inválidos
- Logs sensíveis
- Ausência de rate limiting

#### ?? Médias (4 pontos)
- Versões desatualizadas
- Configurações default
- Falta de hardening

#### ?? Baixas (2 pontos)
- Information disclosure
- Configurações subótimas

### Entregáveis
Crie um relatório contendo:

1. **Executive Summary**: Resumo das descobertas
2. **Metodologia**: Como você testou
3. **Vulnerabilidades Encontradas**:
   - Descrição
   - Impacto
   - Evidências (prints/logs)
   - Classificação (Crítica/Alta/Média/Baixa)
   - PoC (Proof of Concept)
4. **Recomendações**: Como corrigir cada vulnerabilidade

## ??? Ferramentas Sugeridas
- **nmap**: Scan de portas
- **wireshark**: Análise de tráfego
- **mosquitto_sub**: Cliente MQTT
- **curl**: Testes HTTP
- **openssl**: Análise de certificados
- **docker inspect**: Análise de containers

## ?? Comandos Úteis

### Verificar Status
```bash
docker compose ps
docker compose logs
```

### Testar MQTT
```bash
# Sem autenticação (deve falhar)
docker exec -it mqtt-broker mosquitto_sub -h localhost -t "#"

# Com autenticação
docker exec -it mqtt-broker mosquitto_sub -h localhost -t "#" -u admin_user -P "senha"
```

### Analisar Certificados
```bash
openssl s_client -connect localhost:8883 -showcerts
```

### Inspecionar Containers
```bash
docker inspect mqtt-broker
docker exec -it mqtt-broker sh
```

## ?? Avisos Importantes
- Este sistema contém vulnerabilidades **PROPOSITAIS** para fins educacionais
- **NÃO** use em produção sem correções
- **NÃO** exponha na internet sem hardening

## ?? Pontuação
- Vulnerabilidade Crítica: 10 pontos
- Vulnerabilidade Alta: 7 pontos
- Vulnerabilidade Média: 4 pontos
- Vulnerabilidade Baixa: 2 pontos
- Relatório bem documentado: +10 pontos

**Boa sorte! ????**

---

## ?? Suporte
Em caso de dúvidas técnicas (não sobre as vulnerabilidades!):
- Abra uma issue no GitHub
- Contate o instrutor


## ?? Configuração de Segurança

Este sistema está configurado para usar **APENAS TLS/SSL**:
- Porta 8883: MQTT com TLS ? (ÚNICA porta disponível)
- Porta 1883: REMOVIDA (não há comunicação sem criptografia)

**Todas as conexões DEVEM usar TLS!**

>>>>>>> 6e94558 (Adiciona scripts de configuração automática do Node-RED)
