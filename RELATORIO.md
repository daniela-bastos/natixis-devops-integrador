# Relatorio de evidencias - Trabalho Pratico Integrador 01-06

Nome: Daniela Bastos   Data: 24/11/2026
URL do repositorio Git: https://github.com/daniela-bastos/natixis-devops-integrador

## E01 - Ambiente (1 valor)

**Comandos executados:**

- `docker --version`
- `docker compose version`
- `git --version`
- `docker info`
- `ls -la`
- `ls -la tests`

**Resultados observados:**

- Docker: 29.9.2, build a82e528.
- Docker Compose: v5.6.1.
- Git: 2.55.0.windows.2.
- Docker Server: 29.9.2.
- Contexto: desktop-linux.
- Sistema operativo dos containers: Linux.
- Daemon Docker: operacional, com 8 containers existentes, dos quais 4 em execução.

**Identificação dos componentes:**

- API: `app.py`.
- Testes automatizados: `tests/test_app.py`.
- Docker Compose: `compose.yaml`.
- Pipeline de integração contínua: `Jenkinsfile`.

**Conclusão técnica:**

O ambiente encontra-se corretamente configurado e funcional. O comando `docker info` confirmou a comunicação entre o cliente e o daemon Docker, estando reunidas as condições necessárias para a execução do projeto.

## E02 - Dockerfile e container (3 valores)
## E02 - Dockerfile e container (3 valores)

**Comandos executados:**

- `docker build -t natixis-support:1.0 .`
- `docker run -d --name tp-api -p 127.0.0.1:18080:8000 natixis-support:1.0`
- `docker ps --filter name=tp-api`
- `curl -i http://127.0.0.1:18080/health`
- `docker logs --tail 15 tp-api`
- `docker exec tp-api id`
- `docker exec tp-api sh -c 'test -w /data && echo "Escrita em /data: OK"'`
- `docker rm -f tp-api`

**Resultados observados:**

- Imagem: `natixis-support:1.0`, construída com sucesso.
- Container: `tp-api`, em execução durante a validação.
- Mapeamento de portas: `127.0.0.1:18080 -> 8000/tcp`.
- Resposta HTTP: `HTTP/1.1 200 OK`.
- Resposta JSON: `{"status":"ok","service":"support-api","version":"1.0"}`.
- Log relevante: `"GET /health HTTP/1.1" 200 OK`.
- Utilizador efetivo: `uid=1000(appuser) gid=1000(appuser) groups=1000(appuser)`.
- Permissão de escrita: `Escrita em /data: OK`.

**Evidência complementar:**

`evidencias/E02_01_Container_Health_User.png`

**Conclusão técnica:**

A imagem Docker foi construída e executada com sucesso, tendo a API respondido com HTTP 200 e status="ok". A execução com um utilizador não privilegiado e a permissão de escrita em /data foram confirmadas, garantindo o cumprimento dos requisitos de segurança e funcionamento.

## E03 - Compose, DNS, healthcheck e volume (4 valores)

**Comandos executados:**

- `docker compose config --quiet`
- `docker compose up -d --build`
- `docker compose ps`
- `docker compose --profile diagnostico run --rm checker -fsS http://api:8000/health`
- `curl -sS http://127.0.0.1:18080/visits`
- `curl -sS -X POST http://127.0.0.1:18080/visits`
- `curl -sS http://127.0.0.1:18080/visits`
- `docker compose up -d --force-recreate --wait`
- `docker compose ps`
- `curl -sS http://127.0.0.1:18080/visits`

**Resultados observados:**

- Configuração Compose: OK.
- Imagem: `natixis-support:local`.
- Container: `natixis-integrador-api-1`.
- Estado do serviço: `healthy`.
- Rede criada: `natixis-integrador_default`.
- Volume nomeado: `natixis-integrador_app-data`, associado a `/data`.
- Dependência do checker: `service_healthy`.
- Teste DNS através de `http://api:8000/health`: `{"status":"ok","service":"support-api-integrador","version":"1.0"}`.
- Contador inicial: `{"visits":0}`.
- Contador após POST: `{"visits":1}`.
- Contador antes da recriação: `{"visits":1}`.
- Contador após a recriação: `{"visits":1}`.

**Evidências complementares:**

- `evidencias/E03_01_Compose_Healthcheck_DNS.png`
- `evidencias/E03_02_Persistencia_Volume.png`

**Conclusão técnica:**

A configuração Docker Compose foi validada com sucesso, incluindo o healthcheck e a comunicação entre serviços através do DNS interno. O checker aguardou que a API estivesse saudável antes de executar o pedido HTTP. O contador manteve o valor 1 após a recriação do container, uma vez que os dados estão armazenados num volume nomeado, cujo ciclo de vida é independente do container.

## E04 - Incidente Docker (3 valores)

### 1. Sintoma

Após a aplicação do ficheiro `incidente.yaml`, o container permaneceu em execução, mas passou ao estado `unhealthy`. O pedido HTTP externo ao endpoint `/health` devolveu o erro `curl: (52) Empty reply from server`.

### 2. Comandos de diagnóstico

- `curl -sS http://127.0.0.1:18080/visits`
- `docker compose -f compose.yaml -f incidente.yaml up -d --force-recreate`
- `docker compose -f compose.yaml -f incidente.yaml ps`
- `curl -i --max-time 5 http://127.0.0.1:18080/health`
- `docker compose -f compose.yaml -f incidente.yaml logs --tail 30 api`
- `docker compose -f compose.yaml -f incidente.yaml config`
- `docker compose -f compose.yaml -f incidente.yaml exec -T api python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8001/health').read().decode())"`

**Resultados relevantes:**

- Estado do container: `unhealthy`.
- Log: `Uvicorn running on http://0.0.0.0:8001`.
- Mapeamento de portas: `127.0.0.1:18080->8000/tcp`.
- Healthcheck: `http://127.0.0.1:8000/health`.
- Teste interno na porta 8001: `{"status":"ok","service":"support-api-integrador","version":"1.0"}`.

### 3. Causa-raiz

O ficheiro `incidente.yaml` alterou a porta de execução da aplicação de 8000 para 8001, mantendo o mapeamento de portas e o healthcheck na porta 8000. Esta incompatibilidade impediu o acesso externo à API e provocou a falha do healthcheck, apesar de o processo Uvicorn continuar em execução.

### 4. Correção

Foi reposta a configuração base, deixando de aplicar o ficheiro `incidente.yaml` e recriando apenas o serviço `api`, sem remover o volume nomeado.

**Comando executado:**

`docker compose up -d --force-recreate --wait api`

### 5. Validação

**Comandos executados:**

- `docker compose ps`
- `curl -i http://127.0.0.1:18080/health`
- `docker compose logs --tail 10 api`
- `curl -sS http://127.0.0.1:18080/visits`

**Resultados observados:**

- Estado do container: `healthy`.
- Log: `Uvicorn running on http://0.0.0.0:8000`.
- Resposta HTTP: `HTTP/1.1 200 OK`.
- Resposta JSON: `{"status":"ok","service":"support-api-integrador","version":"1.0"}`.
- Contador antes do incidente: `{"visits":1}`.
- Contador após recuperação: `{"visits":1}`.

**Evidências complementares:**

- `evidencias/E04_01_Incidente_Sintoma.png`
- `evidencias/E04_02_Diagnostico_Causa_Raiz.png`
- `evidencias/E04_03_Recuperacao_Persistencia.png`

**Conclusão técnica:**

O incidente foi diagnosticado através da análise dos logs, da configuração efetiva e dos testes HTTP. A reposição da configuração base permitiu recuperar o serviço, mantendo a integridade dos dados armazenados no volume nomeado.

## E05 - Git (3 valores)

**Repositório remoto:**

https://github.com/daniela-bastos/natixis-devops-integrador

**Comandos executados:**

- `git init -b main`
- `git check-ignore -v .venv/teste .env __pycache__/app.pyc .pytest_cache/teste evidencias/teste.png`
- `git add .`
- `git commit -m "feat: ambiente integrador funcional"`
- `git switch -c fix/health-info`
- `git add app.py tests/test_app.py`
- `git commit -m "fix: acrescentar identificacao no health"`
- `git switch main`
- `git merge --no-ff fix/health-info -m "merge: integrar fix/health-info"`
- `git tag -a v1.0.0 -m "Release integrador 1.0.0"`
- `git log --oneline --graph --decorate --all -6`
- `git branch --merged main`
- `git remote -v`
- `git push -u origin main`
- `git push origin fix/health-info`
- `git push origin v1.0.0`
- `git ls-remote --heads origin`
- `git ls-remote --tags origin`
- `git status`

**Alterações realizadas:**

- Criação da branch `fix/health-info`.
- Inclusão do campo `"team": "support"` na resposta do endpoint `/health`.
- Inclusão da asserção `assert response.json()["team"] == "support"` no teste `test_health`.
- Execução dos testes automatizados num container temporário com Python 3.13, através de `python -m pytest -q`.

**Resultados observados:**

- Testes: `2 passed, 1 warning in 1.92s`.
- Commit inicial: `d46fb03` — feat: ambiente integrador funcional.
- Commit de correção: `f749cb6` — fix: acrescentar identificacao no health.
- Commit de merge: `e2a81b9` — merge: integrar fix/health-info.
- Branch principal: `main`.
- Branch de correção: `fix/health-info`, integrada na main.
- Tag anotada: `v1.0.0`, com a mensagem "Release integrador 1.0.0".
- Publicação das duas branches e da tag confirmada no repositório remoto.
- Estado final: `Your branch is up to date with 'origin/main'.`
- Working tree: `nothing to commit, working tree clean`.

**Evidências complementares:**

- `evidencias/E05_01_Git_Historico_Merge_Tag.png`
- `evidencias/E05_02_Git_Publicacao_Remota.png`

**Conclusão técnica:**

A aplicação foi versionada com Git, tendo a alteração ao endpoint /health sido desenvolvida e testada numa branch independente antes da sua integração na branch principal. A criação da tag anotada v1.0.0 e a publicação do histórico no GitHub garantem a rastreabilidade das alterações e da release.

## E06 - Jenkins SUCCESS (4 valores)
URL/numero do build, etapas e identificador da imagem construida:

## E07 - Jenkins FAILURE e recuperacao (2 valores)
Build FAILURE, etapa que falhou e excerto relevante do log; build SUCCESS apos correcao:

## Verificacao final
[ ] Dockerfile [ ] compose.yaml [ ] app.py [ ] tests/ [ ] Jenkinsfile
[ ] Historico Git [ ] Tag v1.0.0 [ ] Evidencias E01-E07
