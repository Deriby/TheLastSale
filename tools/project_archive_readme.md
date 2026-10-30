# The Last Sale — projeto Godot 0.22.0

1. Extraia este ZIP em uma pasta nova.
2. No Godot **4.4.1**, clique em **Importar** e escolha `project.godot`.
3. Aguarde a importação dos modelos e texturas.
4. Pressione **F5** e escolha **Iniciar expediente** para testar a rotina completa.

Modelos animados, cenários, sons, texturas, código, testes e ferramentas estão incluídos. Blender não é necessário para jogar. O renderizador é Compatibility / OpenGL.

## Movimento e acabamento do cenário

A 0.22.0 inclui bibliotecas de animação medidas para cada rig: caminhada, corrida, transporte, agachamento, repouso e gestos comuns. Os pés levantam menos, a cadência acompanha o deslocamento e o tronco reage à aceleração e às curvas. Os modelos e as texturas recebidos foram preservados. Ferramentas, papéis, tapete e relógio detalham o depósito; lixeira, sarjeta e marcas de uso complementam a rua. Veja `docs/natural_v022/README.md` e o vídeo comparativo incluído.

## Reposição e pedidos: como identificar as caixas

- **R1/R2, verdes:** pegue no estoque e leve à geladeira **G1** da parede esquerda. E abre; E novamente repõe. A placa mostra quantas caixas faltam.
- **R3, verde:** salgadinhos para a prateleira **P1**, primeira gôndola à esquerda. E repõe; é uma tarefa extra.
- **VENDA #NNN, laranja:** caixa fechada daquele pedido. Deryk leva à marca **ENTREGA DE PEDIDOS** no balcão e usa E. Tab volta a Felps para registrar e concluir o pagamento.
- **CASCOS VAZIOS:** vão ao palete **DEVOLUÇÕES**. Não abastecem os móveis nem completam uma venda.

O marcador aponta para a caixa ou o destino atual. Caixas erradas mostram o destino correto e continuam nas mãos. Reposição antes da conversa com Felps funciona e fica registrada. Sábado/domingo não recriam caixas das tarefas concluídas da sexta. [Guia](docs/supplies_v021/README.md).

## Sexta-feira: apagão e fechamento

Depois do aviso e da saída do cliente, a energia cai. Use F para a lanterna. Com Felps, use E no posto do caixa para suspender o atendimento. Com Deryk, abra o estoque e recolha a chave no suporte junto à entrada, pelo lado interno. Abra a porta do pátio no fundo do estoque e ligue o gerador. Uma venda interrompida conserva dinheiro e troco parcial.

Conclua o último atendimento. Felps confere o caixa por E; Deryk examina a porta antiga nos fundos. Use o quadro da chave para apagar o salão. Na calçada, E no comando das portas à direita da entrada chama o companheiro, que vem andando. Com os dois fora, E novamente baixa as portas e conclui a sexta.

O resumo salva a sexta e permite começar sábado. Veja `docs/friday_v018/README.md`.

## Sábado: câmeras e pistas

Converse com Felps, atenda os dois pedidos e aguarde o cliente de boné sair. Com Felps no caixa, **C** abre as câmeras da fachada, estoque e pátio. O cenário é mostrado ao vivo; **Eventos do DVR** contém registros escritos, sem reprodução de vídeo arquivado. Anote o evento, separe o recibo e confira o canal do pátio.

Com Deryk e mãos livres, abra o estoque e examine a porta antiga e a caixa deslocada. Depois, volte a Felps e use **Caderno / decisões**. Escolha copiar os registros/recibo ou deixá-los no gravador; avisar o responsável ou esperar. Você pode rever essas duas escolhas antes de sair do monitor. Prepare a saída por E no comando das portas, à direita da entrada, ou escolha seguir sem preparar no caderno. Bryan e Zirico são opcionais.

Depois das três decisões, alguém força a porta do pátio. Feche o caixa com Felps, confira o estoque com Deryk, apague o salão no quadro e reúna a dupla na calçada para baixar as portas. A cópia efetiva dos registros e recibos, as pistas e as escolhas ficam salvas. Domingo continua a investigação e conclui a primeira versão jogável da campanha. Veja `docs/saturday_v019/README.md`.

## Domingo: gravação, revelação e fuga

Converse no balcão. Deryk abre a porta antiga no fundo do estoque, recolhe o módulo na sala de manutenção e leva-o fisicamente ao balcão. Com Felps, C abre a recuperação: reproduza o vídeo de quarta-feira e analise o trecho. O cadastro e as imagens revelam a ligação do cliente com o acesso antigo.

Antes de conferir o quadro do estoque, Felps pode copiar o fragmento para levar consigo e avisar o contato de confiança. Enviar a prova para fora preserva-a mesmo que o gravador seja destruído. Estas oportunidades continuam disponíveis se você não preparou ajuda no sábado.

Com Felps no terminal, Deryk confere o quadro. Durante a separação, Deryk abre o pátio e seleciona **ESTOQUE** no gerador. Alterne para Felps e use **C → DESTRAVAR ESTOQUE** no terminal energizado; também existe um comando junto à porta. **H** manda o companheiro acompanhar ou aguardar em cobertura. Os dois caminham pelo cenário. O assassino vê, ouve, investiga e procura no último ponto conhecido; trocar de personagem não apaga sua memória.

Apague a lanterna com F, agache e quebre a linha de visão. **Ctrl + E** junto às coberturas do balcão, armário do estoque ou freezer abaixa o corpo; mover-se ou usar E sai da cobertura. No comando manual à direita da entrada, E começa a abertura; fique perto até terminar. A preparação de sábado reduz a espera. O gerador também pode alimentar o SALÃO, reduzindo o tempo de abertura sem preparo.

Leve os dois ao mesmo encontro na calçada à direita. A ajuda avisada espera no primeiro ponto; a rota até o vizinho continua disponível mais adiante. E abre uma confirmação: fugir juntos com prova, fugir juntos sem prova ou confirmar sair sem o companheiro leva a três epílogos distintos. Cancelar permite voltar para resgatar. Ser alcançado abre **Retomar checkpoint da fuga**, sem registrar derrota como final permanente.

O save versão 5 conserva campanha, portas, circuito, prova, posições, coberturas e memória do perseguidor. Durante a fuga há salvamento a cada cinco segundos; o checkpoint de tentativa permanece separado. Formatos 1–4 continuam aceitos. Veja `docs/sunday_v020/README.md`.

## Atendimento

**Tab** alterna Deryk/Felps. Deryk cuida das caixas e reposição; Felps atende no balcão por **E**. **Espaço** avança as falas. Na frente de caixa, registre produtos/quantidades, receba o dinheiro, separe o troco e entregue a compra. **Esc** fecha a tela e **Tab** permite chamar Deryk. O pagamento usa dinheiro; cartão e Pix são próximas etapas.

Alguns pedidos exigem uma caixa fechada do estoque. Use **Chamar Deryk**, pegue a caixa do pedido, leve-a ao balcão e entregue com E. Volte a Felps para concluir a venda. Os produtos e valores aparecem no pedido e o total é calculado automaticamente.

O salvamento conserva pedido, cliente, registro, dinheiro recebido e troco parcial, além dos dois personagens e caixas. Checkpoints versões 1, 2 e 3 continuam aceitos. O monitor, a gaveta e os sons acompanham as etapas. Recibos e receita são registrados uma vez por compra concluída. Veja `docs/friday_v018`.

## Controles e configurações

- WASD e mouse: mover/olhar. Shift: correr. Ctrl: agachar.
- Tab: trocar entre Felps e Deryk. E: interagir e atender. C: câmeras/caderno/DVR, com Felps no caixa. H: acompanhar/aguardar no domingo.
- Q: apoiar caixa na marca verde; a marca vermelha indica bloqueio. Q durante a pegada agenda a soltura.
- Roda do mouse: aproximar até primeira pessoa ou afastar.
- Espaço: avançar diálogo. Esc: fechar monitor/caixa ou pausar. F: lanterna após o aviso narrativo.

Converse com Felps para iniciar. Reponha as duas caixas na geladeira e organize a caixa solta. A caixa fechada de um pedido tem identificação própria. Bryan e Zirico têm conversas opcionais.

O limite padrão é 30 FPS. Em Configurações, escolha 30 FPS, 60 FPS ou Sem limite. A estabilidade no PC alvo precisa de teste; veja `docs/optimization_v011`.

PS1 em 320×240 e PS1/2 em 640×480 ficam em **Configurações → Resolução interna / qualidade**. Ambos mantêm a janela grande e os menus em resolução normal. Mantenha a resolução global do projeto em 1280×720.

Os modelos e texturas foram preservados. A energia agora controla luzes e equipamentos. Créditos CC0 em `resources/material_sources/LICENSE.md`. O histórico do bug de largar caixas, corrigido na 0.16.0, e as próximas mecânicas ficam em `docs/PENDENCIAS.md`.

O elenco inclui Dery, Felps, Killer, Bryan, Zirico, Garota 1, Garota 2 e Velha 1. Os FBX originais ficam no [pacote fornecido pelo autor](https://drive.google.com/file/d/1qogHQIpLHR2YuTVj_vi3I2FP-i-Qapxe/view); as derivações necessárias para jogar já estão incluídas. Galerias históricas permanecem no [GitHub](https://github.com/Deriby/TheLastSale).

## Validação

Os resultados das seis suítes e a verificação da extração limpa ficam em `docs/natural_v022/validation.json` e na verificação de distribuição no GitHub. `./tools/test.sh` roda a suíte; em outra máquina, abra pelo editor ou defina `GODOT_BIN` com o caminho do motor.

A Godot 4.4 tem Windows 10 como requisito oficial mínimo. Windows 7/Radeon R7 não foram validados nativamente. O modo Econômica reduz resolução, sombras e acabamento dos materiais.

`PROJETO_MANIFESTO.json` registra o SHA-256 dos arquivos. Caches `.godot`, saves, Git e exportações para Windows não fazem parte deste pacote.
