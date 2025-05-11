

# 🛠️ Laboratório de Debug com `systemd`, `Sysbox` e `Docker`

## 📖 Sobre o projeto

Este laboratório cria um ambiente seguro e isolado para que você possa praticar técnicas reais de:

* Debug de serviços systemd,
* Identificação de processos zumbis e órfãos,
* Análise de vazamentos de file descriptors,
* Diagnóstico de problemas de rede TCP/UDP,
* Estudo de uso de recursos em containers.

Utilizamos o `Sysbox`, que permite a execução do `systemd` dentro de containers **sem precisar de modo privilegiado**, garantindo maior segurança.

Construi para ser utilizado nesse artigo - [Desvendando o systemd — recursos poderosos que poucos sysadmins utilizam (e você deveria conhecer) — Debugging de Units e PIDs — Parte 2](https://medium.com/@marcos.souza101907/desvendando-o-systemd-recursos-poderosos-que-poucos-sysadmins-utilizam-e-voc%C3%AA-deveria-conhecer-eb0f33a543ca)

---

## 🧱 Estrutura do Projeto

```
.
├── docker-compose.yaml         # Orquestra o laboratório
├── lab/
│   ├── Dockerfile               # Define o container do laboratório
│   ├── faulty.c                 # Código que simula problemas
│   ├── faulty.service           # Unit file para o serviço de problemas
│   ├── stress.service           # Serviço de carga
│   └── setup.sh                 # Script de inicialização
└── sysbox-setup.sh              # Script para instalar o Sysbox
```

---

## ⚙️ Pré-requisitos

Antes de começar, certifique-se de ter:

* Um sistema Linux de arquitetura `amd64` (x86\_64),
* Acesso root (`sudo`),
* Internet funcional,
* Docker instalado (o script oferece instalação automática se necessário).

> **Nota:** O uso do Sysbox é indispensável para este projeto.

---

## ✅ Testado com sucesso em

O laboratório foi testado e validado nas seguintes distribuições:

* Debian 10 (Buster)
* Debian 11 (Bullseye)
* Debian 12 (Bookworm)
* Ubuntu 22.04 LTS (Jammy Jellyfish)
* Ubuntu 22.10 (Kinetic Kudu)
* Ubuntu 23.04 (Lunar Lobster)
* Ubuntu 23.10 (Mantic Minotaur)

> **Importante:** outras distribuições ou versões podem funcionar, mas não foram oficialmente validadas até o momento.

---

## 🚀 Como Instalar e Rodar o Lab

### 1. Instalar Sysbox (ambiente obrigatório)

Execute o instalador:

```bash
chmod +x sysbox-setup.sh
sudo ./sysbox-setup.sh
```

Durante a execução:

* O script irá instalar dependências necessárias,
* Caso o Docker não esteja instalado, será oferecida a instalação,
* Você poderá escolher entre:

  * \[1] Última versão do Sysbox
  * \[2] Versão testada (`0.6.6`) **(recomendado, apenas pressione Enter)**.

Após a instalação, **recomendamos fortemente reiniciar o sistema** para garantir que o Sysbox funcione corretamente.

### 2. Subir o ambiente de laboratório

Após o reboot:

```bash
git clone <url-do-repositório>
cd <nome-do-repositório>
docker compose up -d
```

O ambiente será criado e o container estará pronto para testes.

### 3. Acessar o container

Para acessar:

```bash
docker exec -it lab-systemd bash
```

Dentro dele, você poderá:

* Analisar o status dos serviços:

  ```bash
  systemctl status faulty
  ```
* Visualizar os logs:

  ```bash
  journalctl -u faulty
  ```
* Monitorar processos:

  ```bash
  ps auxf
  top
  lsof
  ```

---

## 🛠️ Solução de possíveis dificuldades (resumo)

Se encontrar algum obstáculo, siga estas orientações:

| Situação                                        | O que fazer                                                                                                   |        |
| :---------------------------------------------- | :------------------------------------------------------------------------------------------------------------ | ------ |
| **Docker não encontrado**                       | Deixe o script instalar ou instale manualmente: \`curl -fsSL [https://get.docker.com](https://get.docker.com) | bash\` |
| **Erro ao usar Sysbox**                         | Certifique-se de ter reiniciado o sistema após a instalação.                                                  |        |
| **Problemas com systemctl dentro do container** | Verifique se o container foi iniciado com `runtime: sysbox-runc`.                                             |        |
| **Permissão negada para Docker**                | Adicione seu usuário ao grupo docker: `sudo usermod -aG docker $USER` e faça logout/login.                    |        |

---

## 📈 Explorando o Lab

Dentro do container, recomendamos que você experimente:

* Investigar processos zumbis e órfãos,
* Caçar vazamentos de descritores com `lsof`,
* Monitorar o impacto do serviço `stress` no sistema,

Tudo foi planejado para oferecer um ambiente prático e desafiador, mas controlado.

---

## 🧠 Observações finais

* Este ambiente foi projetado apenas para estudo e prática de debugging.
* Recomenda-se não modificar diretamente o `docker-compose.yaml` ou o `Dockerfile`, a menos que tenha experiência prévia.
* Toda configuração foi pensada para ser o mais próxima possível de um ambiente real de produção.

---

# 📢 Resumo rápido de comandos

```bash
# Instalar sysbox
chmod +x sysbox-setup.sh
sudo ./sysbox-setup.sh

# Reiniciar sistema (necessário!)

# Subir o lab
docker compose up -d

# Entrar no container
docker exec -it lab-systemd bash
```

---

Feito para tornar seu estudo de debugging mais prático, seguro e realista.
