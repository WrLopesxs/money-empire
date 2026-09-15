# MONEY EMPIRE — From $1 to Billionaire

Primeira entrega: **MVP em Luau**, conforme a última instrução do briefing. Código completo em `src/` e arquivo de Studio em `build/MoneyEmpire.rbxlx`.

## Usar uma cópia do GitHub

O arquivo `build/MoneyEmpire.rbxlx` está incluído no repositório e pode ser aberto diretamente no Roblox Studio. Os executáveis de ferramentas em `.tools/` não são enviados ao GitHub.

Para desenvolver em outro PC Windows com Python instalado, execute `Instalar-ferramentas.cmd` na pasta do projeto. Ele baixa as ferramentas oficiais para a própria pasta, sem solicitar administrador. Depois use `Jogar.cmd` para gerar e abrir o jogo atualizado, ou `Testar.cmd` para executar os testes. A execução das ferramentas depende das permissões de segurança do computador.

## Abrir e jogar

1. Com o Roblox Studio instalado, abra **Jogar.cmd**. Ele gera o arquivo atualizado e abre o editor. Também é possível abrir `build/MoneyEmpire.rbxlx` pelo Studio.
2. Entre na sua conta Roblox no editor.
3. Clique em **Play / Jogar** ou pressione **F5**.
4. Você começa com **$1**. Use **TRABALHAR +$2** cinco vezes; no teclado, também pode usar **E**.
5. Compre **Água gelada por $10**. Ela gera **$1/s**, depositado automaticamente.
6. Faça upgrades, compre o carrinho e siga expandindo. **B** abre/fecha o painel; **Meu terreno** leva à base.

O mapa aparece ao iniciar a simulação. No modo de edição, o Workspace ainda não contém a cidade porque ela é construída pelo servidor.

## Situação da instalação neste PC

- Rojo **7.7.0** e Luau **0.738** estão em `.tools/`, dentro desta pasta. Não exigem administrador.
- Python já estava instalado e executa os atalhos. Nenhuma dependência pip é necessária.
- O download do Studio **não foi concluído**: os dois endereços oficiais de instalação, o serviço de versões e `create.roblox.com` expiraram durante a conexão TLS. Diagnóstico em [docs/network-diagnostics.json](docs/network-diagnostics.json).
- Quando o acesso estiver disponível, **Instalar-ferramentas.cmd** tenta novamente e verifica a assinatura digital Roblox antes de executar o instalador na conta atual.
- O Trend Micro mostrou um alerta de programa novo para `luau-compile.exe`; uma repetição com `luau.exe` terminou com acesso negado. O ZIP baixado tem SHA-256 idêntico ao publicado na release oficial. Isso confirma a integridade do download, não uma garantia absoluta de segurança. O compilador não é mais chamado pelo atalho padrão, mas os testes de economia ainda precisam de `luau.exe` autorizado pelo ambiente. Não foram alteradas configurações do antivírus ou políticas do Windows.

## O que está implementado

- Oito terrenos exclusivos, mapa original construído com peças ancoradas e skyline.
- Saldo inicial de $1, trabalho com cooldown validado no servidor e renda automática gratuita.
- Quinze negócios, da água à empresa espacial; desbloqueios em sequência e dez níveis por negócio.
- Preço, renda, categoria, raridade, modelo, variante e valor investido centralizados em módulos.
- Prédios que crescem, cofre com ouro e títulos por patrimônio.
- HUD adaptável, compra, upgrade, coleção, ranking do servidor, movimento reduzido e notificações.
- Patrimônio calculado como saldo + 70% do capital aplicado. O MVP não oferece venda de negócios.
- Coleção registra descobertas; entradas desconhecidas ficam ocultas.
- Oito placeholders de som nomeados. `SoundId` vazio intencionalmente; não há áudio licenciado incorporado.
- DataStore com `UpdateAsync`, bloqueio por sessão, autosave, tentativas com `pcall`, fechamento e recusa de dados inválidos.
- Limite de chamadas remotas e cálculo de dinheiro, preços e recompensas exclusivamente no servidor.

As raridades do catálogo são fixas nesta etapa. Os multiplicadores das variantes estão configurados, mas os negócios comprados no MVP são `Normal`; não há sorteios pagos ou gratuitos implementados.

## Salvamento: teste local e persistência real

**O padrão no Studio é temporário.** O HUD informa isso e o saldo reinicia ao parar a simulação. Assim é possível testar sem publicar nem habilitar APIs.

Para verificar persistência de verdade:

1. Publique uma experiência **de teste** na sua conta pelo Studio.
2. Em **Experience Settings / Game Settings → Security**, habilite **Enable Studio Access to API Services**.
3. Em `src/shared/GameConfig.luau`, altere `StudioTemporaryData = false` e gere/abra novamente o arquivo usando `Jogar.cmd`. Publique a versão atualizada se for testar pelo aplicativo Roblox.
4. Jogue, compre e faça um upgrade, espere o HUD mostrar **Salvo**, pare e entre novamente.
5. Confira saldo, nível e coleção. Teste também sair antes do próximo autosave.

O Studio usa `MoneyEmpire_TEST_v1`; servidores publicados usam `MoneyEmpire_v1`. O modo temporário nunca é usado em servidores Roblox publicados. Configure **Maximum Players = 8** na experiência, de acordo com o número de terrenos.

Se os dados reais não puderem ser carregados ou forem inválidos, o servidor recusa a entrada. Ele não substitui o registro por um perfil vazio. Uma sessão perde o direito de alterar/gravar dados ao expirar sua concessão de 180 segundos. A ausência de conexão até o fechamento pode impedir o último salvamento; progresso ainda não confirmado pode ser perdido.

## Testes

Abra **Testar.cmd** ou execute:

```text
python scripts/tools.py test
```

Os testes executam o módulo real da economia no interpretador oficial Luau e verificam o build gerado pelo Rojo. Não simulam o motor Roblox nem uma conexão real com DataStore.

Verificação adicional de sintaxe, somente em ambiente onde o compilador tenha execução autorizada:

```text
python scripts/tools.py test --compile
```

Veja [docs/TESTES.md](docs/TESTES.md) para cenários manuais e limitações. Os resultados automatizados ficam em `docs/test-results.json`.

## Organização

| Caminho | Local no Studio | Tipo / responsabilidade |
|---|---|---|
| `src/shared/GameConfig.luau` | `ReplicatedStorage/Modules/GameConfig` | ModuleScript: configurações e catálogo |
| `src/shared/Economy.luau` | `ReplicatedStorage/Modules/Economy` | ModuleScript: regras determinísticas |
| `src/shared/NumberFormatter.luau` | `ReplicatedStorage/Modules/NumberFormatter` | ModuleScript: $1, K, M, B até Dc |
| `src/server/Main.server.luau` | `ServerScriptService/MoneyEmpire/Main` | Script: entrada, remotes, renda e autosave |
| `src/server/DataManager.luau` | `ServerScriptService/MoneyEmpire/DataManager` | ModuleScript: DataStore e sessões |
| `src/server/SessionPolicy.luau` | `ServerScriptService/MoneyEmpire/SessionPolicy` | ModuleScript: posse e prazo da sessão |
| `src/server/RateLimiter.luau` | `ServerScriptService/MoneyEmpire/RateLimiter` | ModuleScript: limite de requisições |
| `src/server/WorldManager.luau` | `ServerScriptService/MoneyEmpire/WorldManager` | ModuleScript: mapa, terrenos, prédios e títulos |
| `src/client/Main.client.luau` | `StarterPlayer/StarterPlayerScripts/MoneyEmpireClient` | LocalScript: interface e entradas |

`default.project.json` define todos esses locais; não é preciso colar scripts manualmente.

### Objetos criados automaticamente

- `Workspace/MoneyEmpireWorld`: chão, avenida, SpawnLocation, skyline e oito terrenos.
- `ReplicatedStorage/Remotes/EmpireAction`: cliente pede `Work`, `Buy(id)`, `Upgrade(id)`, `Home`, `Sync` ou `ReducedMotion(boolean)`.
- `ReplicatedStorage/Remotes/EmpireState`: servidor envia o estado ao jogador.
- `ReplicatedStorage/Remotes/EmpireFeedback`: servidor envia resultados de ações.
- `PlayerGui/MoneyEmpireUI`: interface criada pelo LocalScript.
- `SoundService/MoneyEmpireSounds`: placeholders Purchase, Cash, LevelUp, Event, Rare, Prestige, Error e Success.

### Próximas etapas do briefing — ainda não implementadas

Mercado global e eventos, investimentos e gráficos, prestígio, funcionários, missões, recompensas diárias, recompensas de coleção, veículos, mansões, leilões, trocas, ranking global e monetização. Essa separação segue a instrução de começar pelo MVP. Não há Gamepasses ou Developer Products ativos.

## Fontes das ferramentas e APIs

- [Instalação oficial do Studio](https://create.roblox.com/docs/studio/setup)
- [Documentação oficial de DataStores](https://create.roblox.com/docs/cloud-services/data-stores)
- [Rojo 7.7.0](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.0)
- [Luau 0.738](https://github.com/luau-lang/luau/releases/tag/0.738)
