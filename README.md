# 🥝 Kiwibit - Repositório Base de Infraestrutura

Bem-vindo ao repositório central de infraestrutura da **Kiwibit**. 

Este repositório tem como objetivo centralizar, gerenciar via código (Infrastructure as Code - IaC) e versionar **toda infraestrutura** necessária para os projetos do ecossistema Kiwibit. *Qualquer novo projeto ou serviço que requisite recursos em nuvem, ferramentas de rede, ou instâncias computacionais terá sua fundação mantida e orquestrada por aqui.*

---

<div align="center">
  <img src="https://img.shields.io/badge/Oracle_Cloud-F80000?style=for-the-badge&logo=oracle&logoColor=white" alt="Oracle Cloud" />
  <img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform v1.5.7" />
  <img src="https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white" alt="GitHub Actions" />
  <img src="https://img.shields.io/badge/SonarQube-4E9BCD?style=for-the-badge&logo=sonarqube&logoColor=white" alt="SonarQube" />
  <img src="https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white" alt="Ubuntu 22.04" />
</div>

<br/>

## 🏗️ O que está implementado atualmente?

O nosso primeiro objetivo (já provisionado de forma autônoma via OCI) foi montar a base e a VPS para rodar o nosso **Bot de Bug Bounty**.
A arquitetura base utiliza o plano *Always Free* da **Oracle Cloud Infrastructure (OCI)**.

**Recursos Provisionados (`infra/terraform`):**
- **VCN (Virtual Cloud Network):** Rede com bloco `10.0.0.0/16`.
- **Internet Gateway e Route Tables:** Para garantir acesso externo.
- **Security List (Firewall):** Restrigido para permitir acesso via SSH (Porta 22) e ICMP (Ping), mantendo regras restritas e seguras contra tráfego indesejado.
- **Subnet Pública:** Sub-rede `10.0.1.0/24` onde os bots rodam.
- **Compute Instance (VPS Minimal):** Uma máquina virtual (shape: `VM.Standard.E2.1.Micro`, 1 OCPU, 1GB RAM) rodando **Ubuntu 22.04**.
- **Autenticação Automática SSH:** Injeção de chave pública via *metadata* durante o provisionamento.

**Pipelines (CI/CD) Implementadas (`.github/workflows`):**
A automação ocorre através do GitHub Actions para toda PR criada na `main`:
1. **SonarQube Quality Gate:** O código passa por análises de vulnerabilidades/code-smell de forma assíncrona; e atua como Gate (barrando commits não seguros antes do deploy).
2. **Terraform Plan:** Se a qualidade passar, o provider simula a nova infra validando contra a conta OCI dinamicamente (injeção via chaves efêmeras).

---

## ⚙️ Pré-requisitos para novos desenvolvedores

Para interagir com este repositório, você precisa configurar os segredos requeridos para as pipelines funcionarem e interagir com o estado do Terraform no Cloud de forma remota. 

---

## 🔑 Tutorial: Configurando e Gerando sua Chave SSH

Para que você consiga entrar na VPS que for gerada pelo Terraform, é mandatório enviar uma **Chave SSH Pública** para ser instalada na OCI dentro do ambiente Ubuntu. O acesso por senha padrão é desabilitado por segurança.

### Passo 1: Como gerar o par de chaves (Linux, Mac ou WSL)
No seu terminal local (no seu computador, e não na VPS), digite:

```bash
ssh-keygen -t rsa -b 4096 -C "seu-email-kiwibit@exemplo.com"
```

O sistema vai perguntar onde deseja salvar:
```text
Enter file in which to save the key (/home/user/.ssh/id_rsa): 
```
Apenas aperte `ENTER` para aceitar o caminho padrão. Se quiser criar uma senha (passphrase) local para proteção dupla, pode digitar ou dar `ENTER` vazio.

### Passo 2: Copiar a sua "Chave Pública"
Duas chaves foram criadas: uma particular sua (que **nunca** deve ser enviada para ninguém) chamada `id_rsa`, e uma destrancadora chamada `id_rsa.pub`. 

Leia e copie APENAS o conteúdo da pública:
```bash
cat ~/.ssh/id_rsa.pub
```
O output parecerá com isso (começando com `ssh-rsa` ou `ssh-ed25519`):
*`ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQ... seu-email-kiwibit@exemplo.com`*

> **⚠️ Atenção:** Não adicione cabeçalhos como `-----BEGIN PUBLIC KEY-----` ou aspas em volta da chave. Copie apenas o texto cru exatamente como sai do comando `cat`.

### Passo 3: Inserindo no GitHub Secrets
1. Acesse seu repositório da Kiwibit no GitHub.
2. Vá em **Settings** > **Secrets and variables** > **Actions**.
3. Crie um novo Repository Secret chamado `SSH_PUBLIC_KEY`.
4. Em "Secret value", cole exatamente o output inteiro do Passo 2 (começando em `ssh-rsa...`).

### Passo 4: Acessar sua VPS na Oracle
Sempre que uma nova mudança passar no *Terraform Apply*, verifique a saída ("Outputs") do plano, que conterá o IP Público da máquina recém criada. Para entrar nela, abra o terminal e digite:
```bash
ssh ubuntu@<IP_GERADO>
```

---

*Repositório mantido com IaC sob os rigoros padrões Always Free. Leia os arquivos Terraform `.tf` internos de cada módulo antes de propor mudanças de arquitetura para evitar faturamentos acidentais.*
