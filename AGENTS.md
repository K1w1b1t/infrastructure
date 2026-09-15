# Instruções para agentes

## Fluxo de deploy

- O ambiente autoritativo deste repositório é um Stack do OCI Resource Manager.
- O OCI Resource Manager lê o módulo Terraform a partir da raiz deste repositório.
- Após o merge na branch `main`, a integração do Stack identifica a nova revisão e
  executa o fluxo de deploy configurado na própria Oracle.
- Não crie um workflow de `terraform apply` no GitHub Actions. O apply e o state
  permanecem no OCI Resource Manager, salvo decisão explícita dos mantenedores.
- O workflow `.github/workflows/terraform-plan.yml` atende pull requests para a
  `main`; ele valida e gera o plano, mas não é o responsável pelo deploy.

## Providers externos

- Providers SaaS, como o PostHog, podem ser executados no mesmo Stack. O runner do
  OCI Resource Manager precisa conseguir baixar o provider do Terraform Registry e
  acessar a API pública do serviço por HTTPS.
- Declare credenciais como variáveis Terraform com `sensitive = true` e cadastre os
  valores diretamente nas variáveis do Stack do OCI Resource Manager.
- Nunca adicione credenciais, arquivos `.tfvars` com valores reais ou Personal API
  Keys ao Git.
- Variáveis obrigatórias novas também precisam ser disponibilizadas aos jobs de PR
  que executam `terraform plan`, preferencialmente por GitHub Secrets.

## Validação e segurança

- Antes de propor alterações, execute `terraform fmt -check` nos arquivos tocados,
  `terraform init -backend=false` e `terraform validate`.
- Revise o plano antes do merge, especialmente recursos que podem sair do Free Tier.
- Não execute `terraform apply` localmente nem altere o backend/state sem autorização
  explícita.
- Preserve alterações não relacionadas que já estiverem no worktree.
