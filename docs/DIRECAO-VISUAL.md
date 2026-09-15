# Direção visual e experiência

## Identidade desta etapa

Cidade de negócios estilizada, com formas simples, calçadas claras, vegetação verde e metal escuro. Cada empresa usa a cor definida em `GameConfig`. A iluminação de fim de tarde cria contraste sem depender de texturas externas ou partículas.

Os modelos são originais e montados por `BusinessBlueprint` e `BusinessVisual`:

- Água: bancada, toldo listrado, garrafas e caixa de gelo.
- Comida: carrinho com rodas, chapa e bandeja.
- Limonada: jarra e frutas no balcão.
- Café: vitrine, marquise e xícara no teto.
- Mercado e restaurante: fachadas comerciais, sinalização e detalhes próprios.
- Fábrica: galpão, doca, escritório e chaminés.
- Empresas e bancos: pódio, lobby, faixas de vidro e coroamento.
- Empresa espacial: observatório e antena.

São no máximo 30 peças por negócio, além da placa do terreno. Os níveis alteram a faixa de progresso na base e, nos edifícios, a altura em estágios. O servidor substitui apenas o negócio que mudou de nível; o cofre atualiza separadamente. Todos os modelos ficam ancorados.

## Fluxo de quem começa

1. Aparecer olhando para dentro do próprio terreno.
2. Ver um guia de três marcos: primeira barraca, primeiro upgrade e carrinho de comida.
3. Usar o botão do guia para trabalhar ou realizar a próxima ação quando houver saldo.
4. Consultar miniaturas 3D, renda, preço ou quanto falta para comprar.
5. Expandir: o catálogo prioriza o próximo negócio e permite abrir a lista completa.

O guia desaparece quando os três marcos forem concluídos. Pode ser ocultado em Ajustes durante a sessão e não aparece sobre a área de jogo em telas muito baixas. O terminal físico do terreno abre o menu com F, controle ou toque; propriedade do terreno e distância são verificadas no servidor.

Na carteira, uma confirmação mostra setor, quantidade, preço por cota, taxa e total com centavos. A confirmação fica inválida se a cotação mudar. As miniaturas mantêm no máximo quatro modelos ativos e deixam de renderizar quando o menu fecha.

## Mesh IA

Não é necessária para esta versão: os modelos são peças nativas do Roblox e não exigem download de assets. Uma ferramenta de meshes pode ser útil mais tarde para veículos ou objetos de destaque que precisem de formas mais complexas.

Para substituir um modelo futuramente, mantenha uma área de até **22 × 22 studs**, com o pivô no centro da base e a fachada voltada para **-Z**. A integração fica em `BusinessVisual.build`; o restante do sistema usa apenas o ID do negócio. O projeto ainda não inclui um importador automático de meshes.

## Validação visual pendente

Esta etapa tem testes das dimensões e orçamento de peças, e compilação em CI. Ainda falta conferir dentro do Studio: enquadramento das miniaturas, iluminação, contraste no celular, distância dos prompts, colisões e desempenho em dispositivo real. O código não substitui essa revisão visual.
