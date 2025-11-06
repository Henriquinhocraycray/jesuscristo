Setup do Sistema para Pentest

//Pré-requisitos
Git
Docker e Docker Compose
Portas 80 e 443 disponíveis

//Instalação
1. Clonar o repositório

2. Subir o ambiente

3. Verificar se subiu

4. Acessar o sistema
Abra o navegador em: http://localhost

Comandos úteis
Parar o sistema:

Ver logs:
bash
git clone https://github.com/gustavo17042/jesuscristo.git
cd jesuscristo

bash
docker-compose up -d

bash
docker-compose ps

bash
docker-compose down

bash

Resetar ambiente:

bash
docker-compose down -v
docker-compose up -d