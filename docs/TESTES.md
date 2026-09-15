# Validação do MVP

## Mercado, carteira e menu compacto

`tests/market.spec.luau` adiciona 14 cenários: migração de perfis antigos; rejeição de dados inválidos; taxas de compra/venda; cotação vencida; payload adulterado; saldo e posse insuficientes; venda parcial com custo médio; patrimônio a mercado; histórico limitado; cotações iguais entre servidores; estabilidade entre atualizações; duração dos eventos; multiplicador na renda; dimensões de menu em telefone, paisagem, tablet e desktop.

A suíte `Validate Luau` no GitHub compila todos os arquivos e executa as suítes de economia e mercado. Aqui, Luau voltou a receber acesso negado; a validação remota está separada da validação do motor Roblox.

Checklist adicional no Studio: entrar com menu fechado; abrir/fechar via toque e B; girar a tela com o menu aberto; verificar os gráficos e a contagem do evento; comprar e vender os três lotes; aguardar mudança de cotação; conferir resultado e histórico; reconectar para verificar carteira persistida. Eventos de mercado podem mudar os valores de renda esperados no roteiro inicial abaixo.

## Instalador Windows

`tests/test_installer.py` tem nove testes: sequência completa, opção sem Studio, interrupção quando Python falha, instalação parcial quando Studio falha, opção inválida, sintaxe do comando PowerShell e verificação de integridade/extração dos ZIPs. Os fluxos de instalação usam downloads e comandos simulados em diretórios temporários, incluindo caminho com espaços e `&`; nenhum binário das ferramentas é executado por essa suíte.

Validação feita nesta alteração: **9/9 testes passaram**. Também foram executados o download real do Python portátil 3.14.7 com conferência de SHA-256 e `Instalar.bat --sem-studio --sem-pausa`: Python portátil iniciou as ferramentas e o build foi concluído, com nove scripts completos no arquivo do jogo. Esse fluxo reutilizou as cópias de Rojo/Luau já presentes neste PC. A instalação real do Studio e uma instalação completa em uma máquina limpa permanecem sem validação.

Comando: `scripts\run-python.cmd tests\test_installer.py`.

## Automatizada

Dez testes em `tests/economy.spec.luau` verificam:

1. Novo perfil com $1 e nenhuma renda.
2. Cinco trabalhos, compra, renda, upgrade e segundo negócio.
3. Recusa de compra duplicada, id inválido e salto de desbloqueio.
4. Todos os quinze negócios até o nível máximo.
5. Recusa de perfis corrompidos, NaN, infinito e versões desconhecidas.
6. Recusa de crédito inválido e intervalo de renda adulterado.
7. Cópia de perfil preserva valores e não compartilha tabelas internas.
8. Política de sessão impede posse simultânea e permite recuperação após expiração.
9. Rajada e reposição do limitador de remotes.
10. Formatação numérica, arredondamento e sufixos até Dc.

O build é analisado como XML para confirmar Script, LocalScript e ModuleScripts com código não vazio. Esses testes não provam o funcionamento de APIs do motor ou do serviço de DataStore. O teste de cópia de perfil não é um teste de persistência na nuvem.

## Testes manuais no Studio — pendentes

O Studio não pôde ser instalado porque as conexões com Roblox expiraram. Não foi executado Play, emulação mobile, teste multicliente ou persistência real.

### Fluxo individual

- F5: verificar terreno, spawn acima do chão, HUD e $1.
- Trabalhar cinco vezes: saldo $11; comprar água: saldo $1, renda $1/s.
- Esperar seis segundos: comprar o primeiro upgrade por $6; renda passa a $1,40/s.
- Comprar carrinho por $80; conferir prédio, coleção e patrimônio.
- Verificar botão de retorno à base e respawn.
- Alternar movimento reduzido e observar notificações.
- Conferir Output sem erros vermelhos.

### Multicliente

- Iniciar servidor local com dois jogadores: terrenos diferentes e ranking atualizado.
- Comprar com um jogador: saldo e inventário do outro permanecem iguais.
- Sair: terreno é liberado para outro jogador.
- Repetir requisições de trabalho rapidamente: recompensa limitada pelo cooldown do servidor.
- Solicitar compra com id inexistente, tabela em vez de id ou upgrade sem posse: nenhuma alteração na economia.

### Mobile

- Emular telefone em retrato e paisagem e tablet.
- Verificar leitura de saldo, toque, rolagem das 15 empresas e fechamento do painel.
- Conferir compatibilidade com joystick, pulo e área segura da tela.
- Explorar oito terrenos preenchidos para medir desempenho real no dispositivo.

### Persistência

- Seguir o README para habilitar apenas o ambiente de teste.
- Comprar, aguardar confirmação de salvamento e voltar: conferir perfil restaurado.
- Encerrar antes do autosave: confirmar gravação na saída.
- Desabilitar acesso a APIs com modo temporário desligado: confirmar recusa de entrada, sem criação de perfil substituto.
- Em uma experiência de teste, validar reconexão e exclusão entre servidores. Os testes unitários verificam a política de sessão, não a latência/consistência real de DataStore.
