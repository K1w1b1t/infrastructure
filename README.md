# infrastructure

## CI/CD na Oracle Cloud - Passo a passo

Este guia descreve como configurar um pipeline de CI/CD na **Oracle Cloud Infrastructure (OCI)** para este repositório de infraestrutura, assumindo que você já possui conta na Oracle Cloud e acesso administrativo.

### Pré-requisitos
- Conta OCI com permissões para criar recursos (compartimento, Object Storage, DevOps)
- Chaves de API OCI (tenancy OCID, user OCID, fingerprint, private key)
- `oci` CLI instalado e configurado localmente (opcional para testes)
- `terraform` instalado localmente (para validar localmente)
- Repositório Git com os arquivos Terraform (`provider.tf`, `main.tf`, `variables.tf`, `outputs.tf`)

---

## 1. Preparar credenciais OCI
1. No Console OCI: crie um **grupo** para deploys (ex.: `devops` ou `terraform-deployers`) e, em seguida, crie um **usuário de serviço** (ex.: `terraform-bot`) usando um e‑mail do time; adicione esse usuário ao grupo criado. Não adicione o usuário ao grupo `Administrators`.
2. Gere uma API Key para o usuário de serviço (cole a *public key* no Console → Users → API Keys).
3. Anote: `tenancy OCID`, `user OCID`, `fingerprint` e salve a `private key` localmente (ou no OCI Vault/Secrets).
4. Opcional: configure `~/.oci/config` para uso com `oci` CLI:

```ini
[DEFAULT]
user=ocid1.user.oc1..aaaaaaa...
fingerprint=20:3b:97:13:...
tenancy=ocid1.tenancy.oc1..aaaaaaa...
region=sa-saopaulo-1
key_file=/home/you/.oci/oci_api_key.pem
```

---

## 2. Backend remoto do Terraform (recomendado)
1. No Console OCI, crie um bucket no Object Storage para armazenar o `terraform.tfstate`.
2. Configure um arquivo `backend.tf` ou adicione ao `provider.tf` algo como:

```hcl
terraform {
	backend "oci" {
		region           = "sa-saopaulo-1"
		bucket           = "meu-terraform-state-bucket"
		namespace        = "<seu-namespace>"
		key              = "infra/terraform.tfstate"
	}
}
```

3. Use políticas/perm configs para garantir que apenas usuários/automações autorizadas acessem o bucket.

---

## 3. Criar projeto e conexão no OCI DevOps
1. No Console OCI → DevOps → Projects: crie um `Project` para este repositório.
2. Em `Connections`, crie uma conexão com seu provedor Git (GitHub/GitLab) ou use o repositório interno do OCI Code.
3. Se usar GitHub, autorize a conexão e vincule o repositório deste projeto.

---

## 4. Criar pipeline de Build (rodar Terraform)
Recomendação: separar o pipeline em duas etapas — `plan` automático e `apply` manual (por segurança).

Exemplo de `buildspec` simples (usado no OCI DevOps Build):

```yaml
version: 1.0
steps:
	- name: install-terraform
		commands:
			- curl -fsSL https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip -o terraform.zip
			- unzip terraform.zip -d /usr/local/bin
			- terraform --version

	- name: terraform-init-plan
		commands:
			- export TF_VAR_region=${OCI_REGION}
			- terraform init -backend-config="bucket=${TFSTATE_BUCKET}" -backend-config="namespace=${TF_NAMESPACE}" -reconfigure
			- terraform plan -out=tfplan
			- terraform show -no-color tfplan > plan.txt
		artifacts:
			files:
				- plan.txt

	# stage 'apply' deve ser controlado manualmente ou por um gatilho seguro
```

Observações:
- No DevOps, configure variáveis de ambiente seguras (`OCI_REGION`, `TFSTATE_BUCKET`, `TF_NAMESPACE`) e segredos (chave privada API) usando Secrets/Vault.
- Opte por não executar `terraform apply` automaticamente em `main` sem revisão do `plan`.

---

## 5. Segredos e permissões (boas práticas)
- Use o OCI Vault ou os Secrets do DevOps para armazenar a chave privada e qualquer credencial sensível.
- Não comite `terraform.tfstate`, `*.tfvars` ou chaves privadas. Estes já estão no `.gitignore` deste repositório.
- Considere usar Instance Principals quando for executar ações a partir de uma VM na OCI.

---

## 6. Triggers e políticas de execução
1. No DevOps Pipelines, configure trigger para executar o job `plan` em push para `main` (ou branch protegida).
2. Configure revisão humana (approval) antes do stage `apply`.

---

## 7. Testar e validar
1. Faça um commit com uma alteração mínima no Terraform e `git push` para o branch configurado.
2. No Console OCI DevOps, verifique o Run do pipeline, veja o `plan.txt` gerado.
3. Se o `plan` estiver ok, aprove (ou execute manualmente) o `apply` e valide que a VPS (Compute) foi criada.
4. Pegue o IP público e teste acesso SSH:

```bash
ssh -i /path/to/private_key opc@IP_PUBLICO
```

---

## Checklist rápido
- [ ] Backend remoto criado (Object Storage)
- [ ] DevOps Project e Connection configurados
- [ ] Build pipeline (plan) implementado
- [ ] Secrets/Vault configurado
- [ ] Trigger e Approval configurados
- [ ] Teste SSH validado

---

## Notas de segurança
- Nunca publique `terraform.tfstate` nem `*.tfvars` com credenciais.
- Prefira `apply` manual em ambientes de produção.
- Use Vault/Secrets do OCI para gerenciar chaves e tokens.

---

## Usando GitHub Secrets (GitHub Actions)
Se o repositório for público, jamais comite chaves ou arquivos com credenciais. Use os GitHub Secrets para injetar credenciais no pipeline.

1. Vá em *Settings → Secrets and variables → Actions* no repositório e crie os seguintes secrets (nomes sugeridos):
	- `OCI_TENANCY_OCID`
	- `OCI_USER_OCID`
	- `OCI_FINGERPRINT`
	- `OCI_REGION`
	- `OCI_PRIVATE_KEY` (o conteúdo PEM da private key; pode ser multiline)
	- `TFSTATE_BUCKET`
	- `TF_NAMESPACE`

2. Exemplo de comportamento seguro no workflow (arquivo: `.github/workflows/terraform-plan.yml`): o workflow escreve a chave privada em `~/.oci/oci_api_key.pem` a partir do `OCI_PRIVATE_KEY`, cria o arquivo `~/.oci/config` com os OCIDs e region, executa `terraform init` com backend usando os secrets e produz `plan.txt` como artifact.

3. Se preferir evitar multiline secrets, você pode armazenar a chave como Base64:

```bash
base64 -w0 oci_api_key.pem | xclip -selection clipboard
```

No workflow, faça `echo "$SECRET" | base64 -d > ~/.oci/oci_api_key.pem`.

4. Permissões e rotação:
	- Use um usuário de serviço com permissões mínimas (grupo `devops`/`terraform-deployers`).
	- Rotacione a chave periodicamente e atualize o Secret.

5. Localização do exemplo de workflow adicionado: `.github/workflows/terraform-plan.yml` (gera `plan.txt` como artifact para revisão antes do `apply`).

---

---

Se quiser, eu posso:
- adicionar um exemplo de `buildspec.yml` completo com variáveis substituíveis;
- gerar um exemplo de pipeline no formato JSON/OCI CLI para importar no DevOps;
- ou aplicar essas mudanças como arquivos no repositório (por exemplo `ci/buildspec.yml`).

---
Mantive o foco em um fluxo seguro e reproduzível para deploy via Terraform usando OCI DevOps. Quer que eu crie o `buildspec.yml` e adicione ao repositório agora?