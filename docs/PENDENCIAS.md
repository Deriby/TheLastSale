# Pendências registradas pelo autor

## Largar a caixa — corrigido na 0.16.0

- **Relato original:** depois de pegar uma caixa, não era possível largá-la com Q.
- **Correção:** Q durante a pegada agenda a soltura; após a animação, a caixa pode ser apoiada numa superfície livre, em pé, com colisão reativada. A marca verde/vermelha mostra a possibilidade de colocação.
- **Proteções:** valida caminho, apoio nos quatro cantos e volume livre. Sem espaço, a caixa permanece com Deryk e um aviso aparece na tela.
- **Salvamento:** conserva a posição das caixas soltas e a caixa carregada pelo personagem inativo. Checkpoints da versão 1 continuam aceitos.
- **Validação:** testes de Q durante/depois da pegada, bloqueio por parede, nova coleta, troca segurando a caixa, salvamento e retomada. Registros em [gameplay_v016](gameplay_v016/README.md).

## Próximas etapas de mecânicas

- Campanha solicitada com sexta, sábado e domingo: pane de energia na primeira noite, terror crescente na segunda e fuga do assassino na terceira, com revelação e finais diferentes. [Proposta de trama, decisões e etapas](CAMPANHA_TRES_NOITES.md); sexta está implementada desde a 0.18.1. A 0.19.0 acrescenta a primeira versão jogável do sábado; domingo, perseguição e finais seguem pendentes.
- O autor aprovou a proposta de campanha e autorizou modelos provisórios para novos NPCs. A 0.18.1 inclui seis identidades adicionais de clientes, com visuais simples substituíveis; [cadastro, substituição e próximos papéis](ELENCO_PROVISORIO.md).
- Registro, quantidades, dinheiro/troco, entrega e recibos foram implementados na 0.17.0. Próximas formas de pagamento: cartão e Pix. [Validação e instruções](checkout_v017/README.md).
- Expandir estoque e reposição, comunicação da dupla e visitas de Bryan/Zirico.
- Fechamento cooperativo desde a 0.18.1; investigação, câmeras e decisões de sábado implementados na 0.19.0. Próximas etapas: gravação antiga, revelação, perseguição do domingo e esconderijos.
- O companheiro caminha até a calçada quando chamado no fechamento; mantém seu posto durante a pane. Busca de cobertura e respostas durante perseguição ficam para a etapa de perigo.
