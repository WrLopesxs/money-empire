# MONEY EMPIRE — From $1 to Billionaire

Primeira entrega: **MVP em Luau**, conforme a última instrução do briefing. Código completo em `src/` e arquivo de Studio em `build/MoneyEmpire.rbxlx`.

## Atualização de UX e modelos 3D

- Negócios com modelos originais de peças Roblox: toldos, vitrines, chaminés, fachadas e observatório espacial.
- Avenida com calçadas, árvores e postes; entradas dos terrenos voltadas para a rua e spawn voltado para os negócios.
- Guia de três passos, miniaturas 3D e catálogo que prioriza o próximo desbloqueio. Botões indicam quanto falta para comprar.
- Terminal físico para abrir o menu: **F** ou toque, dentro do próprio terreno.
- Confirmação de investimentos com preço, taxa e total em centavos; cotações alteradas exigem uma nova conferência.
- Prédios e cofre atualizados separadamente; no máximo quatro miniaturas ativas no menu.

Detalhes, limites de geometria e orientação para futuras meshes: [direção visual](docs/DIRECAO-VISUAL.md). Os modelos não dependem de Mesh IA ou assets externos. A conferência visual dentro do Studio continua pendente.

## Atualização: menu compacto, mercado e investimentos

O menu agora **começa fechado**. O HUD fica no canto superior esquerdo, com no máximo 384 px de largura; **Menu [B]** abre um painel lateral de até 360 px. O tamanho considera a área segura da tela, incluindo o espaço reservado pelo Roblox. Feche pelo **×** ou pela tecla **B**. O ranking reutiliza suas linhas, preservando a rolagem durante as atualizações.

- **Mercado:** sete setores, cotações a cada 15 segundos e gráfico com 24 pontos. Eventos duram 3 minutos em ciclos de 8 minutos e alteram temporariamente a renda dos negócios e os preços.
- **Investir:** selecione lotes de 1, 10 ou 100 cotas; compre, venda e consulte resultado aberto, resultado realizado e as últimas 20 operações. Os valores nos botões já incluem a **taxa de 2%** de cada operação.
- Cotações e eventos são uma simulação calculada pelo horário UTC, igual entre servidores. Não usam preços financeiros reais, dinheiro real ou dados externos.
- A carteira entra no patrimônio pelo preço atual. O resultado aberto inclui a taxa de compra, mas é mostrado antes da taxa de uma futura venda.
- O servidor decide o preço e rejeita cotações antigas, saldo insuficiente, quantidades inválidas e vendas acima da posse. Cotas, custo e histórico são salvos; perfis anteriores recebem apenas os novos campos, sem apagar o progresso.

Os testes de código também executam automaticamente no [GitHub Actions](https://github.com/WrLopesxs/money-empire/actions). A execução visual no Studio e o salvamento na nuvem ainda precisam de validação em um computador com acesso ao Roblox.

## Usar uma cópia do GitHub

O arquivo `build/MoneyEmpire.rbxlx` está incluído no repositório e pode ser aberto diretamente no Roblox Studio. Os executáveis de ferramentas em `.tools/` não são enviados ao GitHub.

### Instalação do zero — sem administrador

1. No GitHub, clique em **Code → Download ZIP** e extraia a pasta inteira para um local onde você possa gravar, como sua Área de Trabalho.
2. Abra **[Instalar.bat](Instalar.bat)** com dois cliques. Não é necessário ter Python, Git ou ferramentas de desenvolvimento instalados.
3. Aguarde as etapas: **Python portátil 3.14.7 → Rojo e Luau → geração do jogo → Roblox Studio**.
4. Quando concluir, abra **Jogar.cmd**, entre na sua conta Roblox no Studio e pressione **F5**.

Requisitos: **Windows 10/11 x64 (Intel/AMD)**, internet e permissão para executar os programas. Python, Rojo e Luau ficam em `.tools/`, dentro do projeto. Não há alteração de PATH, instalação global ou dependências `pip`. O Python portátil é dedicado às ferramentas deste projeto; não inclui `pip`. Os atalhos encontram essa cópia automaticamente, mesmo sem Python no sistema. O Studio usa seu instalador oficial na conta atual.

Os downloads de Python, Rojo e Luau têm SHA-256 verificado antes da extração. A configuração do antivírus e as políticas do computador são preservadas; um bloqueio de execução ou de rede pode exigir ajuda do responsável pelo PC. Se o Studio não puder ser instalado, o instalador informa **instalação parcial** e mantém as etapas já concluídas para uma nova tentativa.

O atalho antigo **Instalar-ferramentas.cmd** também inicia a instalação completa. Para preparar somente as ferramentas e gerar o jogo:

```bat
Instalar.bat --sem-studio
```

Use `--sem-pausa` em execução automatizada e `--ajuda` para ver as opções. Depois, `Testar.cmd` executa os testes de economia; eles são separados da instalação e dependem de permissão para executar Luau.

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
- Python já estava instalado no PC de desenvolvimento. Em um computador novo, `Instalar.bat` prepara sua própria cópia portátil. Nenhuma dependência pip é necessária.
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
- Patrimônio calculado como saldo + 70% do capital dos negócios + valor atual dos investimentos. O MVP não oferece venda de negócios.
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
scripts\run-python.cmd scripts\tools.py test
```

Os testes executam o módulo real da economia no interpretador oficial Luau e verificam o build gerado pelo Rojo. Não simulam o motor Roblox nem uma conexão real com DataStore.

Verificação adicional de sintaxe, somente em ambiente onde o compilador tenha execução autorizada:

```text
scripts\run-python.cmd scripts\tools.py test --compile
```

Veja [docs/TESTES.md](docs/TESTES.md) para cenários manuais e limitações. Os resultados automatizados ficam em `docs/test-results.json`.

Para verificar o instalador, sem reinstalar programas nem executar Luau:

```bat
scripts\run-python.cmd tests\test_installer.py
```

## Organização

| Caminho | Local no Studio | Tipo / responsabilidade |
|---|---|---|
| `src/shared/GameConfig.luau` | `ReplicatedStorage/Modules/GameConfig` | ModuleScript: configurações e catálogo |
| `src/shared/Economy.luau` | `ReplicatedStorage/Modules/Economy` | ModuleScript: regras determinísticas |
| `src/shared/NumberFormatter.luau` | `ReplicatedStorage/Modules/NumberFormatter` | ModuleScript: $1, K, M, B até Dc |
| `src/shared/UILayout.luau` | `ReplicatedStorage/Modules/UILayout` | ModuleScript: dimensões do HUD e painel lateral |
| `src/shared/UXModel.luau` | `ReplicatedStorage/Modules/UXModel` | ModuleScript: guia inicial e prioridade de catálogo |
| `src/shared/BusinessBlueprint.luau` | `ReplicatedStorage/Modules/BusinessBlueprint` | ModuleScript: geometria original, em dados |
| `src/shared/BusinessVisual.luau` | `ReplicatedStorage/Modules/BusinessVisual` | ModuleScript: instancia os modelos no mapa e nas miniaturas |
| `src/shared/MarketConfig.luau` | `ReplicatedStorage/Modules/MarketConfig` | ModuleScript: setores, eventos, lotes e taxa |
| `src/shared/MarketModel.luau` | `ReplicatedStorage/Modules/MarketModel` | ModuleScript: cotações, gráficos e multiplicadores |
| `src/shared/InvestmentModel.luau` | `ReplicatedStorage/Modules/InvestmentModel` | ModuleScript: carteira, operações e validação |
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
- Para investimentos, o mesmo remoto aceita `InvestBuy` e `InvestSell` com `{ Sector, Units, Revision }`. A revisão identifica a cotação vista; o preço é consultado exclusivamente no servidor.
- `ReplicatedStorage/Remotes/EmpireState`: servidor envia o estado ao jogador.
- `ReplicatedStorage/Remotes/EmpireFeedback`: servidor envia resultados de ações.
- `PlayerGui/MoneyEmpireUI`: interface criada pelo LocalScript.
- `SoundService/MoneyEmpireSounds`: placeholders Purchase, Cash, LevelUp, Event, Rare, Prestige, Error e Success.

### Próximas etapas do briefing — ainda não implementadas

Prestígio, funcionários, missões, recompensas diárias, recompensas de coleção, variantes sorteadas, veículos, mansões, leilões, trocas, ranking global e monetização. Eventos com NPCs, leilões e variantes Cosmic também continuam pendentes. Não há Gamepasses ou Developer Products ativos.

## Fontes das ferramentas e APIs

- [Instalação oficial do Studio](https://create.roblox.com/docs/studio/setup)
- [Documentação oficial de DataStores](https://create.roblox.com/docs/cloud-services/data-stores)
- [Rojo 7.7.0](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.0)
- [Luau 0.738](https://github.com/luau-lang/luau/releases/tag/0.738)
- [Python portátil: documentação oficial](https://docs.python.org/3/using/windows.html#the-embeddable-package)
- [Python 3.14.7: arquivos oficiais](https://www.python.org/ftp/python/3.14.7/)
