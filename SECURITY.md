# Security Guidelines

Este documento descreve as práticas de segurança adotadas neste projeto e recomendações para um ambiente de produção.

---

## 1. Gerenciamento de Segredos

### Abordagem adotada neste projeto
- Variáveis sensíveis (como `APP_ENV`) são injetadas via **Kubernetes Secrets**, nunca hardcoded nos manifestos ou no código.
- O arquivo `k8s/namespace-and-secret.yaml` existe apenas como referência de estrutura — em produção, o Secret seria criado via pipeline ou ferramenta dedicada.

### Recomendações para produção
- Utilizar **HashiCorp Vault** ou **AWS Secrets Manager** para armazenar e rotacionar segredos.
- Integrar com o **External Secrets Operator** no Kubernetes para sincronizar segredos do Vault/AWS diretamente como Kubernetes Secrets.
- Nunca versionar segredos reais no Git — usar `.gitignore` e pré-commit hooks para prevenir isso.

---

## 2. Prevenção de Exposição de Credenciais

- O repositório possui um arquivo `.gitignore` que exclui arquivos como `.env`, `*.tfvars`, `terraform.tfstate` e quaisquer arquivos com credenciais.
- Recomenda-se configurar o **GitHub Secret Scanning** e o **Dependabot** no repositório.
- Ferramentas como **git-secrets** ou **truffleHog** podem ser integradas ao pipeline para escanear commits em busca de credenciais acidentalmente expostas.
- As credenciais AWS usadas pelo Terraform devem ser fornecidas via **IAM Roles** (em CI/CD com OIDC) ou variáveis de ambiente temporárias — nunca como chaves estáticas em arquivos.

---

## 3. Segurança da Imagem Docker

### Medidas já aplicadas
| Medida | Detalhe |
|---|---|
| Multi-stage build | Reduz a superfície de ataque eliminando ferramentas de build da imagem final |
| Usuário não-root | O container executa como `appuser` (UID 1000) |
| Imagem base slim | `python:3.12-slim` em vez de `python:3.12` — menos pacotes = menos CVEs |
| `readOnlyRootFilesystem` | Definido no manifesto Kubernetes, impedindo escrita no filesystem do container |
| Capabilities dropped | `capabilities.drop: [ALL]` no SecurityContext do Kubernetes |

### Melhorias recomendadas para produção
- Utilizar imagens **distroless** (ex: `gcr.io/distroless/python3`) para eliminar shell e utilitários desnecessários.
- Fixar versões de dependências (`pip install flask==3.0.3`) e usar `pip-audit` para checar vulnerabilidades nos pacotes.
- Executar o **Trivy** no pipeline (já configurado) e bloquear o deploy caso CVEs CRITICAL/HIGH sejam encontrados.
- Assinar imagens com **Cosign** (Sigstore) para garantir integridade na cadeia de supply chain.

---

## 4. Boas Práticas de Acesso em Ambientes Cloud

### Princípio do menor privilégio
- Cada serviço/workload deve ter uma **IAM Role** com apenas as permissões mínimas necessárias.
- No Kubernetes, usar **ServiceAccounts** com anotações IRSA (IAM Roles for Service Accounts) na AWS.

### Rede
- Definir **NetworkPolicies** no Kubernetes para restringir comunicação entre pods — por padrão, nenhum pod deve conseguir falar com outro a não ser que seja explicitamente permitido.
- Usar **Private Subnets** para workloads; apenas o Load Balancer/Ingress fica em subnets públicas.
- Habilitar **VPC Flow Logs** para auditoria de tráfego.

### Auditoria e Observabilidade
- Habilitar **CloudTrail** (AWS) ou equivalente para registrar todas as ações na conta cloud.
- Configurar alertas para ações sensíveis (ex: mudanças em IAM, acesso a secrets).
- Habilitar **audit logs** no Kubernetes (`kube-apiserver --audit-log-path`).

### CI/CD
- Usar **OIDC** para autenticação do GitHub Actions com a cloud, eliminando a necessidade de chaves de acesso estáticas.
- Restringir quais branches podem fazer deploy em produção (ex: apenas `main` após aprovação de PR).