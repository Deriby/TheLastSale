# Pendências registradas pelo autor

## Largar a caixa — corrigido na 0.16.0

- **Relato original:** depois de pegar uma caixa, não era possível largá-la com Q.
- **Correção:** Q durante a pegada agenda a soltura; após a animação, a caixa pode ser apoiada numa superfície livre, em pé, com colisão reativada. A marca verde/vermelha mostra a possibilidade de colocação.
- **Proteções:** valida caminho, apoio nos quatro cantos e volume livre. Sem espaço, a caixa permanece com Deryk e um aviso aparece na tela.
- **Salvamento:** conserva a posição das caixas soltas e a caixa carregada pelo personagem inativo. Checkpoints da versão 1 continuam aceitos.
- **Validação:** testes de Q durante/depois da pegada, bloqueio por parede, nova coleta, troca segurando a caixa, salvamento e retomada. Registros em [gameplay_v016](gameplay_v016/README.md).

## Próximas etapas de mecânicas

- Detalhar o atendimento: lista de produtos, quantidades, registro, dinheiro/troco, cartão e Pix. A 0.16.0 inclui atendimento básico com Felps por E, usando as conversas e animações existentes.
- Expandir estoque e reposição, comunicação da dupla e visitas de Bryan/Zirico.
- Implementar tarefas de fechamento e, depois, investigação, perseguição e esconderijos.
- Definir o comportamento do companheiro durante situações de perigo. Nesta etapa, ele mantém sua posição e animações enquanto está fora do controle.
