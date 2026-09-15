# Guia de importacao de identidades OCI no Terraform

Este guia importa para `terraform.tfstate` os usuarios e grupos OCI que ja existem, mas ainda nao estao registrados no state do Terraform.

O procedimento e local ao Cloud Shell e nao envia credenciais, state ou saidas completas para terceiros.

## O que sera importado

Os enderecos Terraform definidos em `main.tf` e `modules/storage/main.tf` sao:

| Recurso OCI | Endereco Terraform | Nome OCI |
| --- | --- | --- |
| Usuario staging | `module.storage_staging.oci_identity_user.app` | `kiwibit-media-app-staging` |
| Usuario prod | `module.storage_prod.oci_identity_user.app` | `kiwibit-media-app-prod` |
| Grupo staging | `module.storage_staging.oci_identity_group.media_writers` | `kiwibit-media-writers-staging` |
| Grupo prod | `module.storage_prod.oci_identity_group.media_writers` | `kiwibit-media-writers-prod` |

O import nao cria recursos e nao executa `terraform apply`. Ele apenas associa recursos existentes ao state local.

## Por que o comando anterior ficou preso em `>`

O prompt `>` e o prompt de continuacao do Bash. Ele aparece quando o shell ainda espera fechar uma aspa, um parentesis ou uma substituicao de comando `$()`.

O filtro `jq` multilinha, quando colado com uma aspa extra ou com o bloco incompleto, deixa o Bash nesse modo. Uma linha isolada contendo apenas `"` tambem indica que uma aspa foi aberta sem fechamento correto.

Quando isso acontecer, pressione `Ctrl+C` e comece novamente. Nao tente corrigir adicionando aspas aleatoriamente no prompt `>`.

## Ponto importante: tenancy e compartment

O state contem o `compartment_id` da VCN. Esse valor e o compartment onde a rede foi criada; ele nao e necessariamente o OCID da tenancy raiz.

No modulo de storage, usuarios, grupos e policies usam a tenancy raiz como `compartment_id`. Portanto:

- `TF_VAR_compartment_ocid` pode ser obtido do state pela VCN;
- `TF_VAR_tenancy_ocid` deve vir da configuracao autenticada do OCI CLI ou ser confirmado no console;
- nao use automaticamente o `compartment_id` da VCN como `tenancy_ocid`.

O procedimento abaixo le o compartment do state e le a tenancy do perfil OCI local. Se o perfil nao tiver `tenancy=`, pare e obtenha esse OCID no OCI Console ou com o administrador da tenancy. Nao envie a credencial nem o state.

## Procedimento autorizado

1. Abra o Stack correspondente no **OCI Resource Manager** e confirme que ele aponta para esta revisao do repositorio.
2. Antes de qualquer importacao, obtenha autorizacao explicita dos mantenedores, confirme que nenhum outro Stack gerencia o objeto e salve um backup do state no proprio ambiente autoritativo.
3. Use o mecanismo de importacao/documentacao aprovado pelo Resource Manager para vincular cada objeto ao mesmo Stack. Nao crie, baixe, edite ou envie um `terraform.tfstate` local.
4. Gere um novo plan no Resource Manager, revise especialmente IAM, destruicoes e recriacoes, e somente entao autorize apply no console.

GitHub Actions continua limitado a `terraform init -backend=false` e `terraform validate`. Nao execute `terraform import`, `terraform plan` com state real nem `terraform apply` localmente.

## Seguranca

- Nunca envie state, backups, chaves privadas, Personal API Keys ou saidas completas.
- Nunca adicione state ao Git; `.gitignore` cobre `*.tfstate*` e `.env`.
- Um erro `404-NotAuthorizedOrNotFound` exige revisar permissoes; um `409 already exists` exige reconciliar/importar o state, nunca repetir apply.
