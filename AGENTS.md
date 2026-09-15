# Instruções para agentes

## Arquitetura e responsáveis

- Este repositório é o módulo raiz Terraform da infraestrutura Kiwibit. Ele cria a
  rede, a VPS e os buckets de mídia isolados em `staging` e `prod`.
- O **OCI Resource Manager** é o ambiente autoritativo: armazena o state, executa
  `plan` e `apply`, e usa as credenciais OCI configuradas no próprio Stack. O
  conteúdo de `var.env` citado nos logs pertence ao Stack; não é um arquivo que
  deva ser criado ou versionado neste repositório.
- O Stack lê a configuração na raiz do repositório. Após merge na `main`, a
  integração do Stack identifica a revisão nova e executa o fluxo configurado na
  Oracle. Revise o plano produzido pelo **Resource Manager** antes de autorizar
  apply; esse é o único plano com o state real.
- GitHub Actions atende PRs para `main` e somente executa `terraform init
  -backend=false` e `terraform validate`. Ele não recebe credenciais OCI, não
  acessa state e nunca executa `terraform plan` remoto ou `apply`.
- Não crie workflow de `terraform apply` no GitHub Actions, não troque o backend
  e não execute apply localmente, salvo autorização explícita dos mantenedores.

## Identidade, grupos e permissões OCI

- Há duas camadas distintas: os papéis/grupos do **Identity Domain** controlam o
  acesso ao Console; as **IAM Policies** no tenancy/compartment autorizam ações
  sobre recursos OCI. Estar no grupo chamado `terraform`, por si só, não concede
  permissão alguma sem o papel/policy correspondente.
- O principal executor do Stack é a identidade cujas credenciais estão no Stack.
  Ele precisa ler e alterar os recursos gerenciados no state. Como o módulo de
  storage cria usuários, grupos, memberships, policies e customer secret keys,
  ele também precisa das permissões IAM de tenancy compatíveis com essas ações.
- O grupo `Administrators` resolve recuperação e diagnóstico, mas é privilégio
  amplo. Após recuperar acesso, prefira um principal de automação separado e
  policies de menor privilégio, revisadas para os recursos que o Stack de fato
  administra. Nunca remova o último administrador funcional da tenancy.
- `404-NotAuthorizedOrNotFound` para `Identity User` ou `Identity Group` no apply
  normalmente significa autorização insuficiente do executor (não uma limitação
  do Free Tier). `409 ... same userName/displayName already exists` significa que
  o objeto existe no OCI, mas não está vinculado ao state atual: não repita apply;
  investigue e importe ou reconcilie o state.
- Alterações recentes de grupos/policies podem levar alguns minutos para propagar.
  Não dispare vários applies concorrentes durante esse intervalo, para evitar
  rate limits e resultados difíceis de diagnosticar.

## State, drift e importação

- Trate o state, planos salvos e logs de importação como dados sensíveis: podem
  conter IDs, chaves SSH e segredos. Nunca envie state, API keys, private keys ou
  arquivos `.tfvars` para chat, Git ou artefatos públicos.
- Nunca edite JSON de state manualmente. Para drift, baixe uma cópia do state do
  Stack, confirme o endereço Terraform e o OCID do recurso, use `terraform
  import` somente com autorização, valide com `terraform state list` e suba o
  state corrigido de volta ao **mesmo Stack**. Mantenha backup e não rode apply
  local usando essa cópia.
- Cada objeto remoto deve ter um único endereço no state. Antes de importar,
  confirme que não está gerenciado por outro endereço/Stack. Importação apenas
  cria o vínculo state-objeto; ela não gera a configuração Terraform.
- Um plano que acusa objetos "changed outside of Terraform" deve ser lido como
  drift. Não aprove recriações de usuários, grupos, policies ou chaves sem antes
  decidir se o recurso foi realmente removido ou se falta importação.
- A imagem da VPS é resolvida somente na criação. Não remova
  `ignore_changes = [source_details[0].source_id]` sem planejar explicitamente a
  atualização/substituição da instância e preservar os dados.

## Variáveis, segredos e PostHog

- Toda variável deve ter `type` e `description`. Use `sensitive = true` para
  chaves, tokens e senhas; isso oculta a saída do Terraform, mas não torna o
  state inofensivo.
- Valores obrigatórios são declarados sem `default`; valores opcionais devem ter
  um default seguro. Use validação apenas quando houver restrições próprias do
  domínio, como os hosts US/EU do PostHog.
- Para aparecerem de forma clara em **Edit stack > Configure variables**, campos
  novos devem ser descritos no `schema.yaml` da raiz. Para cada campo, mantenha o
  nome e tipo compatíveis com o `variable` Terraform, defina título, descrição e
  se é obrigatório/sensível. O schema não contém valores reais.
- `posthog_api_key` é obrigatória e deve receber no Stack uma **Personal API Key**
  administrativa. Nunca use nem exponha a Project API Key (`phc_...`) dos SDKs
  frontend/backend. `posthog_host` escolhe `https://us.posthog.com` (padrão) ou
  `https://eu.posthog.com`; os SDKs de eventos usam seus hosts de ingestão
  (`*.i.posthog.com`), que são uma configuração diferente.
- Providers SaaS podem ser executados no mesmo Stack se o runner alcançar o
  Terraform Registry e a API HTTPS do serviço. Não cadastre credenciais OCI ou
  SaaS no GitHub Actions enquanto ele fizer apenas validação.

## Ciclo seguro de mudança

1. Preserve alterações não relacionadas já presentes no worktree.
2. Antes de propor alteração, execute `terraform fmt -check` nos arquivos `.tf`
   tocados, `terraform init -backend=false` e `terraform validate`.
3. Para mudanças de infraestrutura, abra PR e use o job do GitHub apenas como
   validação sintática. Após merge, gere e revise o plano do Resource Manager,
   confirmando especialmente `create`, `replace`, `destroy`, mudanças de IAM e
   qualquer custo fora do Always Free.
4. Nunca reutilize um plano antigo depois de mudar variáveis, credenciais ou
   recursos fora do Terraform. Gere novo plano no Stack imediatamente antes do
   apply e acompanhe o job até a conclusão.

## Dependências e arquivos versionados

- Defina restrições de versão explícitas para Terraform e providers. Para módulos
  raiz, prefira limites superior e inferior compatíveis; não faça upgrade de
  provider incidentalmente ao resolver outra tarefa.
- A prática Terraform é versionar `.terraform.lock.hcl`, pois ela fixa a seleção
  de providers revisada. Este repositório ainda a ignora: não remova essa regra
  nem adicione o lock file de modo oportunista. Faça uma mudança dedicada após
  testar a versão escolhida no OCI Resource Manager, revise o diff do lock e só
  então passe a versioná-lo.
- Nunca versione `.terraform/`, `*.tfstate*`, planos salvos, `.tfvars` reais,
  chaves PEM/SSH ou outros segredos. Revise `git status` antes de todo commit.
