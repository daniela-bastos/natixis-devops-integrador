# Relatório de evidências — Trabalho Prático Integrador 01-06

**Nome:** Daniela Bastos  
**Data:** 24/11/2026  
**Repositório Git:** https://github.com/daniela-bastos/natixis-devops-integrador

## E01 - Ambiente (1 valor)

**Comandos executados:**

```bash
docker --version
docker compose version
git --version
docker info
ls -la
ls -la tests
```

**Resultados observados:**

- Docker: 29.9.2.
- Docker Compose: v5.6.1.
- Git: 2.55.0.windows.2.
- Docker Server: 29.9.2.
- Contexto: `desktop-linux`.
- Daemon Docker operacional, com containers Linux.

**Identificação dos componentes:**

| Componente | Ficheiro |
|---|---|
| API | `app.py` |
| Testes | `tests/test_app.py` |
| Docker Compose | `compose.yaml` |
| Pipeline | `Jenkinsfile` |

**Conclusão técnica:** O ambiente encontra-se funcional e o comando `docker info` confirmou a comunicação entre o cliente e o daemon Docker. Foram identificados os quatro componentes principais do projeto.

## E02 - Dockerfile e container (3 valores)

**Comandos executados:**

```bash
docker build -t natixis-support:1.0 .
docker run -d --name tp-api -p 127.0.0.1:18080:8000 natixis-support:1.0
docker ps --filter name=tp-api
curl -i http://127.0.0.1:18080/health
docker logs --tail 15 tp-api
docker exec tp-api id
docker exec tp-api sh -c 'test -w /data && echo "Escrita em /data: OK"'
docker rm -f tp-api
```

**Resultados observados:**

```text
Imagem: natixis-support:1.0
Container: tp-api
Portas: 127.0.0.1:18080->8000/tcp
HTTP/1.1 200 OK
{"status":"ok","service":"support-api","version":"1.0"}
uid=1000(appuser) gid=1000(appuser) groups=1000(appuser)
Escrita em /data: OK
```

**Conclusão técnica:** A imagem foi construída e executada com sucesso, tendo a API respondido com HTTP 200. Foi confirmada a execução com um utilizador não privilegiado e a permissão de escrita em `/data`.

**Evidência complementar:** [Container, health e utilizador](evidencias/E02_01_Container_Health_User.png).

## E03 - Compose, DNS, healthcheck e volume (4 valores)

**Comandos executados:**

```bash
docker compose config --quiet
docker compose up -d --build
docker compose ps
docker compose --profile diagnostico run --rm checker -fsS http://api:8000/health
curl -sS http://127.0.0.1:18080/visits
curl -sS -X POST http://127.0.0.1:18080/visits
curl -sS http://127.0.0.1:18080/visits
docker compose up -d --force-recreate --wait
docker compose ps
curl -sS http://127.0.0.1:18080/visits
```

**Resultados observados:**

- Configuração Compose: OK.
- Imagem: `natixis-support:local`.
- Container: `natixis-integrador-api-1`.
- Estado: `healthy`.
- Rede: `natixis-integrador_default`.
- Volume: `natixis-integrador_app-data`, associado a `/data`.
- Dependência do checker: `service_healthy`.

```text
Teste DNS checker -> api:
{"status":"ok","service":"support-api-integrador","version":"1.0"}

Contador inicial:          {"visits":0}
Contador após POST:        {"visits":1}
Antes da recriação:        {"visits":1}
Após a recriação:          {"visits":1}
```

**Conclusão técnica:** O healthcheck e a comunicação entre serviços através do DNS interno foram validados, tendo o checker aguardado pelo estado saudável da API. A manutenção do contador após a recriação do container confirmou a persistência dos dados através do volume nomeado.

**Evidências complementares:**

- [Compose, healthcheck e DNS](evidencias/E03_01_Compose_Healthcheck_DNS.png).
- [Persistência do volume](evidencias/E03_02_Persistencia_Volume.png).

## E04 - Incidente Docker (3 valores)

**Comandos de reprodução e diagnóstico:**

```bash
curl -sS http://127.0.0.1:18080/visits
docker compose -f compose.yaml -f incidente.yaml up -d --force-recreate
docker compose -f compose.yaml -f incidente.yaml ps
curl -i --max-time 5 http://127.0.0.1:18080/health
docker compose -f compose.yaml -f incidente.yaml logs --tail 30 api
docker compose -f compose.yaml -f incidente.yaml config
docker compose -f compose.yaml -f incidente.yaml exec -T api python -c "import urllib.request; print(urllib.request.urlopen('http://127.0.0.1:8001/health').read().decode())"
```

**Resultados do diagnóstico:**

```text
Estado: unhealthy
curl: (52) Empty reply from server
Uvicorn running on http://0.0.0.0:8001
Mapeamento: 127.0.0.1:18080->8000/tcp
Healthcheck: http://127.0.0.1:8000/health

Teste interno na porta 8001:
{"status":"ok","service":"support-api-integrador","version":"1.0"}
```

**Causa-raiz:** O ficheiro `incidente.yaml` alterou a porta de execução da API para 8001, mantendo o mapeamento de portas e o healthcheck na porta 8000.

**Correção e validação:**

```bash
docker compose up -d --force-recreate --wait api
docker compose ps
curl -i http://127.0.0.1:18080/health
docker compose logs --tail 10 api
curl -sS http://127.0.0.1:18080/visits
```

**Resultados após recuperação:**

```text
Estado: healthy
Uvicorn running on http://0.0.0.0:8000
HTTP/1.1 200 OK
{"status":"ok","service":"support-api-integrador","version":"1.0"}

Contador antes do incidente: {"visits":1}
Contador após recuperação:   {"visits":1}
```

**Conclusão técnica:** O incidente foi diagnosticado através dos logs, da configuração efetiva e dos testes HTTP. A reposição da configuração base, sem aplicar `incidente.yaml`, recuperou o serviço e preservou os dados do volume nomeado.

**Evidências complementares:**

- [Sintoma do incidente](evidencias/E04_01_Incidente_Sintoma.png).
- [Diagnóstico e causa-raiz](evidencias/E04_02_Diagnostico_Causa_Raiz.png).
- [Recuperação e persistência](evidencias/E04_03_Recuperacao_Persistencia.png).

## E05 - Git (3 valores)

**Comandos executados:**

```bash
git init -b main
git check-ignore -v .venv/teste .env __pycache__/app.pyc .pytest_cache/teste evidencias/teste.png
git add .
git commit -m "feat: ambiente integrador funcional"
git switch -c fix/health-info
```

Na branch `fix/health-info`, foi acrescentado o campo `"team": "support"` ao endpoint `/health` e a respetiva asserção ao teste `test_health`.

**Execução dos testes:**

```bash
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$(pwd -W):/workspace" \
  -w /workspace \
  python:3.13-slim \
  sh -c "pip install --no-cache-dir -r requirements.txt -r requirements-dev.txt && python -m pytest -q"
```

**Versionamento e publicação:**

```bash
git add app.py tests/test_app.py
git commit -m "fix: acrescentar identificacao no health"
git switch main
git merge --no-ff fix/health-info -m "merge: integrar fix/health-info"
git tag -a v1.0.0 -m "Release integrador 1.0.0"
git remote set-url origin https://github.com/daniela-bastos/natixis-devops-integrador.git
git push -u origin main
git push origin fix/health-info
git push origin v1.0.0
git log --oneline --graph --decorate --all -6
git branch --merged main
git ls-remote --heads origin
git ls-remote --tags origin
git status
```

**Resultados observados:**

```text
2 passed, 1 warning in 1.92s

*   e2a81b9 (HEAD -> main, tag: v1.0.0) merge: integrar fix/health-info
|\
| * f749cb6 (fix/health-info) fix: acrescentar identificacao no health
|/
* d46fb03 feat: ambiente integrador funcional
```

- Branches `main` e `fix/health-info` publicadas.
- Tag anotada `v1.0.0` publicada.
- Branch `main` sincronizada com `origin/main`.
- Working tree sem alterações pendentes após a publicação.

**Conclusão técnica:** A alteração ao endpoint `/health` foi desenvolvida e testada numa branch independente antes da integração na `main` através de um merge sem fast-forward. A publicação das branches e da tag anotada assegurou a rastreabilidade do histórico e da release.

**Evidências complementares:**

- [Histórico Git, merge e tag](evidencias/E05_01_Git_Historico_Merge_Tag.png).
- [Publicação no repositório remoto](evidencias/E05_02_Git_Publicacao_Remota.png).

## E06 - Jenkins SUCCESS (4 valores)

**Identificação da pipeline:**

- Job: `natixis-devops-integrador`.
- Tipo: Pipeline from SCM.
- Branch: `main`.
- Script Path: `Jenkinsfile`.
- Agente: `ci-python-docker`.
- Build: `#1`.
- URL: http://localhost:8080/job/natixis-devops-integrador/1/
- Commit: `dd4d20e`.

**Comandos de publicação da pipeline:**

```bash
git add Jenkinsfile RELATORIO.md
git commit -m "ci: implementar pipeline Jenkins"
git push origin main
```

**Comandos principais executados pela pipeline:**

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt -r requirements-dev.txt
.venv/bin/python -m pytest -q
docker build -t "natixis-support:ci-${BUILD_NUMBER}" .
docker image inspect "natixis-support:ci-${BUILD_NUMBER}" --format '{{.Id}}'
```

**Resultados observados:**

| Etapa | Resultado |
|---|---|
| Checkout | SUCCESS |
| Tests | SUCCESS |
| Docker Build | SUCCESS |

```text
2 passed, 1 warning in 1.03s
Imagem: natixis-support:ci-1
sha256:73f4f178ca2db2029d0a91318fd22d81e4657f8eefba7698fd2aaae6f1983588
Finished: SUCCESS
```

**Conclusão técnica:** A pipeline automatizou a obtenção do código, a execução dos testes e a construção da imagem Docker. A imagem foi construída após a aprovação dos testes, utilizando uma tag dinâmica baseada no número do build (`BUILD_NUMBER`), e identificada através do respetivo SHA256.

**Evidências complementares:**

- [Build SUCCESS](evidencias/E06_01_Jenkins_Build_SUCCESS.png).
- [Etapas da pipeline](evidencias/E06_02_Jenkins_Pipeline_Stages.png).
- [Resultados dos testes](evidencias/E06_03_Jenkins_Test_Results.png).
- [Construção e identificação da imagem](evidencias/E06_04_Jenkins_Docker_Build.png).

## E07 - Jenkins FAILURE e recuperação (2 valores)

**Falha controlada:**

Foi alterado intencionalmente o valor esperado do campo `team` no ficheiro `tests/test_app.py`:

```python
assert response.json()["team"] == "invalid-team"
```

**Comandos executados:**

```bash
git add tests/test_app.py
git commit -m "test: introduzir falha controlada"
git push origin main
```

- Build: `#2`.
- URL: http://localhost:8080/job/natixis-devops-integrador/2/
- Commit: `bd8a8d5`.
- Etapa que falhou: `Tests`.

**Excerto do resultado:**

```text
AssertionError: assert 'support' == 'invalid-team'
1 failed, 1 passed, 1 warning in 0.74s
Stage "Docker Build" skipped due to earlier failure(s)
ERROR: script returned exit code 1
Finished: FAILURE
```

**Correção e recuperação:**

Foi reposto o valor correto na asserção:

```python
assert response.json()["team"] == "support"
```

```bash
git add tests/test_app.py
git commit -m "fix: corrigir falha controlada no teste health"
git push origin main
```

- Build: `#3`.
- URL: http://localhost:8080/job/natixis-devops-integrador/3/
- Commit: `a48cded`.

```text
2 passed, 1 warning in 0.63s
Imagem: natixis-support:ci-3
Finished: SUCCESS
```

**Histórico dos builds:**

| Build | Checkout | Tests | Docker Build | Resultado |
|---|---|---|---|---|
| #1 | SUCCESS | SUCCESS | SUCCESS | SUCCESS |
| #2 | SUCCESS | FAILURE | SKIPPED | FAILURE |
| #3 | SUCCESS | SUCCESS | SUCCESS | SUCCESS |

**Conclusão técnica:** A falha controlada demonstrou que a pipeline impede a construção da imagem Docker quando os testes falham. Após a correção, todas as etapas foram executadas com sucesso, confirmando a recuperação da pipeline.

**Evidências complementares:**

- [Build FAILURE](evidencias/E07_01_Jenkins_Build_FAILURE.png).
- [Falha na etapa Tests](evidencias/E07_02_Jenkins_Pipeline_Failure.png).
- [Excerto do erro](evidencias/E07_03_Jenkins_Assertion_Error.png).
- [Pipeline após recuperação](evidencias/E07_04_Jenkins_Recovery_SUCCESS.png).
- [Console Output da recuperação](evidencias/E07_05_Jenkins_Recovery_Console.png).
- [Histórico dos três builds](evidencias/E07_06_Jenkins_Build_History.png).

## Verificação final

- [x] Dockerfile
- [x] compose.yaml
- [x] app.py
- [x] tests/
- [x] Jenkinsfile
- [x] Histórico Git
- [x] Tag v1.0.0
- [x] Evidências E01-E07