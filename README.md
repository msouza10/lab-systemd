# 🛠️ Laboratório de Debug com `systemd`, `Sysbox` e `Docker`

## 📖 Sobre o Projeto

Este laboratório cria um ambiente seguro e isolado para prática real de:

- Diagnóstico de serviços no `systemd`,
- Identificação de processos zumbis e órfãos,
- Análise de vazamentos de descritores de arquivo,
- Diagnóstico de problemas de rede TCP/UDP,
- Estudo de uso de recursos em containers.

Utilizamos o `Sysbox`, que permite a execução do `systemd` dentro de containers **sem o modo privilegiado**, garantindo maior segurança.

Este ambiente foi criado como suporte para o artigo:  
👉 [Desvendando o systemd — recursos poderosos que poucos sysadmins utilizam (e você deveria conhecer) — Debugging de Units e PIDs — Parte 2](https://medium.com/@marcos.souza101907/desvendando-o-systemd-recursos-poderosos-que-poucos-sysadmins-utilizam-e-voc%C3%AA-deveria-conhecer-eb0f33a543ca)

---

## 🧱 Estrutura do Projeto

```text
.
├── docker-compose.yaml         # Orquestra o ambiente do laboratório
├── lab/
│   ├── Dockerfile               # Define o container base
│   ├── faulty.c                 # Código que simula problemas reais
│   ├── faulty.service           # Unit file do serviço problemático
│   ├── stress.service           # Unit de estresse de sistema
│   └── setup.sh                 # Script de configuração inicial
└── sysbox-setup.sh              # Script de instalação do Sysbox
```

---

## ⚙️ Pré-requisitos

Antes de iniciar, certifique-se de ter:

- Um sistema Linux de arquitetura `amd64` (x86_64),
- Permissões de root (`sudo`),
- Conexão ativa com a internet,
- Docker instalado (o script oferece instalação automática, se necessário).

> **Nota:** O uso do Sysbox é obrigatório para o funcionamento correto deste laboratório.

---

## ✅ Testado com sucesso em:

- Debian 10 (Buster)
- Debian 11 (Bullseye)
- Debian 12 (Bookworm)
- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Ubuntu 22.10 (Kinetic Kudu)
- Ubuntu 23.04 (Lunar Lobster)
- Ubuntu 23.10 (Mantic Minotaur)

> **Observação:** outras distribuições podem funcionar, mas não foram validadas oficialmente.

---

## 🚀 Como Instalar e Rodar o Lab

### 1. Instalar Sysbox

Execute:

```bash
chmod +x sysbox-setup.sh
sudo ./sysbox-setup.sh
```

Durante a instalação:

- Dependências necessárias serão instaladas automaticamente,
- Caso o Docker não esteja presente, o script oferecerá a instalação,
- Você poderá optar por:

  - `[1]` Última versão do Sysbox
  - `[2]` Versão testada (`0.6.6`) **(recomendada — pressione Enter)**

Após a instalação, **reinicie o sistema** para aplicar as alterações corretamente.

---

### 2. Clonar o repositório e subir o ambiente

Após o reboot:

```bash
git clone <url-do-repositório>
cd <nome-do-repositório>
docker compose up -d
```

Isso criará e iniciará o ambiente do laboratório.

---

### 3. Iniciar os serviços dentro do container

Inicie os serviços simulados:

```bash
docker exec -it lab-systemd bash
systemctl start stress.service
systemctl start faulty.service
```

O laboratório estará pronto para uso.

---

### 4. Acessar e interagir com o laboratório

Com o container ativo:

- Verifique o status dos serviços:

  ```bash
  systemctl status faulty.service
  ```

- Visualize os logs em tempo real:

  ```bash
  journalctl -u faulty.service -f
  ```

- Monitore processos:

  ```bash
  ps auxf
  lsof
  top
  ```

---

## 🛠️ Solução de possíveis dificuldades

| Problema | Solução |
|:---|:---|
| **Docker não encontrado** | Permita que o script instale ou instale manualmente: `curl -fsSL https://get.docker.com | bash` |
| **Erro ao usar Sysbox** | Reinicie o sistema após a instalação do Sysbox. |
| **Systemctl não funciona no container** | Verifique se o `runtime: sysbox-runc` foi usado no `docker-compose.yaml`. |
| **Permissão negada ao usar Docker** | Adicione seu usuário ao grupo Docker: `sudo usermod -aG docker $USER` e faça logout/login. |

---

## 📈 Explorando o Laboratório

Dentro do ambiente, recomendamos que você:

- Investigue processos zumbis e órfãos,
- Analise vazamentos de descritores abertos com `lsof`,
- Observe o impacto do serviço `stress` na memória e CPU.

Todo o ambiente foi planejado para oferecer uma experiência prática e realista de troubleshooting.

---

## 🧐 Considerações Finais

- Este ambiente é destinado **exclusivamente para fins educacionais**.
- Alterações diretas no `docker-compose.yaml` ou `Dockerfile` são desencorajadas para usuários iniciantes.
- O ambiente foi modelado para simular comportamentos reais de sistemas em produção, dentro de uma margem de segurança controlada.

---

# 📣 Resumo Rápido de Comandos

```bash
# Instalar Sysbox
chmod +x sysbox-setup.sh
sudo ./sysbox-setup.sh

# Reiniciar o sistema

# Subir o laboratório
docker compose up -d

# Acessar o container
docker exec -it lab-systemd bash

# Iniciar serviços
systemctl start stress.service
systemctl start faulty.service
```

---

Feito para tornar seu estudo de debugging mais prático, seguro e próximo da realidade de produção.
