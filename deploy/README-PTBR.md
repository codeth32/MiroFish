# MiroFish online — Render + OpenAI + Zep

Este deploy publica uma única URL HTTPS protegida por autenticação HTTP Basic, com
o frontend Vue estático por Nginx e a API Flask disponível apenas dentro do contêiner.

## Antes de começar

- Uma conta [Render](https://dashboard.render.com/) conectada ao GitHub `codeth32`.
- Uma chave da API da [OpenAI](https://platform.openai.com/api-keys), com faturamento de API habilitado.
- Uma chave da [Zep Cloud](https://app.getzep.com/).
- Escolha uma senha exclusiva e forte (mínimo de 12 caracteres) para acessar o site.
- **Não coloque as chaves em arquivos, issues, commits, README ou mensagens.**

O MiroFish usa bastante processamento e pode gerar cobranças por tokens, Zep, computação
e armazenamento. O Blueprint escolhe **Render 1 CPU/2 GB + disco persistente de 5 GB**
(ambos pagos). Verifique o preço total exibido na Render antes de confirmar.
O plano pode precisar de mais RAM, dependendo do tamanho das simulações; comece
com poucos agentes/rodadas.

## Publicar

1. Depois que o PR for revisado e mesclado na `main`, abra
   [Render New Blueprint](https://dashboard.render.com/select-repo?type=blueprint).
2. Autorize o acesso da Render ao repositório **codeth32/MiroFish**.
3. Selecione o arquivo `render.yaml` na raiz e revise os recursos/cobranças.
4. Preencha os *secret inputs* solicitados pela Render, **diretamente no painel**:
   - `LLM_API_KEY`: chave secreta da OpenAI.
   - `ZEP_API_KEY`: chave secreta da Zep Cloud.
   - `APP_AUTH_PASSWORD`: senha exclusiva do site, com 12+ caracteres.
5. Confirme o deploy apenas se estiver de acordo com o plano cobrado.
6. Aguarde o build. A Render gerará uma URL do tipo `https://...onrender.com`.
7. Acesse essa URL via HTTPS e informe usuário `admin` e a sua senha do site.
8. Verifique em **Render > Logs** se o contêiner iniciou e em **Events**
   se o health check `/health` está aprovado. Teste inicialmente uma
   simulação pequena.

## Variáveis utilizadas

| Nome | Onde fica | Observação |
|---|---|---|
| `LLM_API_KEY` | Render secret | Nunca no Git |
| `ZEP_API_KEY` | Render secret | Nunca no Git |
| `APP_AUTH_PASSWORD` | Render secret | Protege site e API |
| `APP_AUTH_USERNAME` | Render variable | Padrão `admin` |
| `SECRET_KEY` | Gerada pela Render | Segredo de aplicação |
| `LLM_BASE_URL` | render.yaml | `https://api.openai.com/v1` |
| `LLM_MODEL_NAME` | render.yaml | `gpt-4.1-mini` |
| `OASIS_DEFAULT_MAX_ROUNDS` | render.yaml | Inicialmente 10 |

## Segurança e manutenção

- GitHub Actions Secrets **não** são transferidos automaticamente para a Render.
  Os segredos do deploy precisam ser preenchidos na própria Render.
- O arquivo `.env` continua ignorado pelo Git e não entra no build Docker.
- O backend roda em `127.0.0.1:5001` (não fica público); somente a
  porta `10000` é exposta via Nginx.
- `/health` é público apenas para monitoramento, sem dados de usuário.
- O volume `/app/backend/uploads` preserva uploads e resultados gravados
  nesse caminho entre reinicializações. O estado **em memória** de tarefas
  ainda pode ser perdido em reinícios ou deploys.
- Uma nova senha do site pode ser aplicada pelo painel da Render.
  Para rotacionar uma chave, atualize seu valor no painel da Render.
- Limite gastos no painel da OpenAI e acompanhe uso no Zep.
- A autenticação HTTP Basic é uma barreira mínima para uso pessoal,
  não um sistema multiusuário. Não disponibilize o acesso publicamente.
- Para interromper custos de hospedagem, remova o serviço e o disco
  após realizar backup dos dados importantes, conferindo a cobrança.
- Se o build falhar ou houver erro de memória, verifique os logs antes
  de aumentar os recursos.

## Verificação técnica

- `GET /health` deve retornar status HTTP 200 sem senha **somente após**
  o backend iniciar.
- `GET /` e `GET /api/simulation/list` sem autenticação devem retornar
  HTTP 401.
- Após autenticar, a interface deve carregar e enviar chamadas para
  `/api/...` no mesmo domínio.
- Não exponha o backend em uma segunda porta pública.
