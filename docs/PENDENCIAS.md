# Pendências registradas pelo autor

## Largar a caixa — corrigido na 0.16.0

- **Relato original:** depois de pegar uma caixa, não era possível largá-la com Q.
- **Correção:** Q durante a pegada agenda a soltura; após a animação, a caixa pode ser apoiada numa superfície livre, em pé, com colisão reativada. A marca verde/vermelha mostra a possibilidade de colocação.
- **Proteções:** valida caminho, apoio nos quatro cantos e volume livre. Sem espaço, a caixa permanece com Deryk e um aviso aparece na tela.
- **Salvamento:** conserva a posição das caixas soltas e a caixa carregada pelo personagem inativo. Checkpoints da versão 1 continuam aceitos.
- **Validação:** testes de Q durante/depois da pegada, bloqueio por parede, nova coleta, troca segurando a caixa, salvamento e retomada. Registros em [gameplay_v016](gameplay_v016/README.md).

## Próximas etapas de mecânicas

- Campanha solicitada com sexta, sábado e domingo: pane de energia na primeira noite, terror crescente na segunda e fuga do assassino na terceira, com revelação e finais diferentes. [Proposta de trama, decisões e etapas](CAMPANHA_TRES_NOITES.md); sexta está implementada desde a 0.18.1. A 0.20.0 completa a primeira versão jogável das três noites, com domingo, perseguição, coberturas e três finais.
- O autor aprovou a proposta de campanha e autorizou modelos provisórios para novos NPCs. A 0.18.1 inclui seis identidades adicionais de clientes, com visuais simples substituíveis; [cadastro, substituição e próximos papéis](ELENCO_PROVISORIO.md).
- Registro, quantidades, dinheiro/troco, entrega e recibos foram implementados na 0.17.0. Próximas formas de pagamento: cartão e Pix. [Validação e instruções](checkout_v017/README.md).
- Expandir estoque e reposição, comunicação da dupla e visitas de Bryan/Zirico.
- Fechamento cooperativo desde a 0.18.1; investigação, câmeras e decisões de sábado implementados na 0.19.0. Gravação antiga, revelação, perseguição do domingo e coberturas implementadas na 0.20.0; acabamento de animação, ritmo e balanceamento continuam pendentes.
- O companheiro caminha até a calçada quando chamado no fechamento; mantém seu posto durante a pane. No domingo, H alterna acompanhar/aguardar e o companheiro procura cobertura física. Refinar decisões de rota e comportamento sob pressão com playtests.

## Reposição e caixas de venda — corrigido na 0.21.0

G1 recebe R1/R2, P1 recebe R3 como reposição extra, pedidos recebem caixas laranja numeradas e o palete recebe cascos vazios. A reposição não fica bloqueada pela conversa inicial. Placas mostram o que falta e o HUD aponta para caixa/destino; caixas erradas não são consumidas. A área de entrega no balcão libera a cobrança de Felps uma única vez. [Guia e validação](supplies_v021/README.md).
