# The Last Sale — projeto Godot 0.37.0

1. Extraia este ZIP em uma pasta nova.
2. No Godot **4.7**, clique em **Importar** e escolha `project.godot`.
3. Aguarde a importação dos modelos e texturas.
4. Pressione **F5** e escolha **Iniciar expediente** para testar a rotina completa.

Modelos animados, cenários, sons, texturas, código, testes e ferramentas estão incluídos. Blender não é necessário para jogar. O renderizador é Compatibility / OpenGL.

## Música da abertura e do menu / Godot 4.7 — 0.37.0

Uncanny Valley, enviada pelo autor, toca durante a intro e continua no menu sem reiniciar. Pular a intro ou abrir as configurações mantém a reprodução. A faixa completa repete ao terminar, entra gradualmente e sai suavemente ao iniciar ou continuar o expediente. Ajuste-a em Música / rádio; sons de fita, botões e ambiente continuam em Efeitos e ambiente. A pausa do expediente conserva o áudio do jogo e não reinicia a abertura.

O MP3 original está incluído, sem recodificação. Os dados originais dos modelos, texturas e animações permanecem; os metadados de importação receberam apenas campos padrão do Godot 4.7. GodotPhysics3D é escolhido explicitamente para manter o backend anterior. As sete capturas históricas de sexta 0.18 ficam na galeria do GitHub; todos os arquivos usados pelo jogo estão no projeto. Consulte `docs/music_v037/README.md`.

## Revisão da campanha — 0.36.0

Configurações fechadas com Esc agora salvam volume, sensibilidade, FOV e os demais valores. Na confirmação de fuga, uma cópia carregada pelo irmão que ficou no depósito não aparece como já preservada pelo personagem que vai sair. A corrida deixa de alternar entre gasto e regeneração de fôlego a cada quadro perto da exaustão: depois de esgotar, é preciso recuperar uma pequena reserva antes de voltar a correr. Velocidades, acelerações, colisões, controles, modelos e curvas das animações permanecem.

A revisão acrescenta 12 regressões de menus e fôlego, e uma rota contínua desde uma campanha nova até o epílogo, com 29 verificações e cinco retomadas. A rota movimenta os personagens pela física, usa os botões por teclado e não preenche objetivos, dinheiro ou posições. O relógio do teste corre a 4×, com 60 passos de física por segundo de jogo; diálogos são adiantados. O teste renderizado do piso PS1 também é executado no pacote extraído. Consulte `docs/review_v036/README.md` e a verificação da distribuição no GitHub. Não foi medida a placa de vídeo do jogador.

## Orientação pelo cenário — 0.35.0

Na sexta-feira, etiquetas R1/R2, G1 e P1 ficam presas aos objetos. Uma lista no balcão pode ser lida com E para ouvir uma orientação curta sobre a tarefa que falta, a caixa carregada ou o gerador. A conversa de abertura usa referências do depósito e J conserva o objetivo completo, o checklist e os controles.

O HUD discreto tira as setas e as confirmações repetidas da reposição. A preferência já salva é respeitada; desative “HUD discreto / orientação pelo cenário [J]” para manter as indicações completas. Pedidos dos clientes continuam assistidos e erros de destino continuam explicados. Consultar a lista não conclui tarefas nem acrescenta requisitos. O sistema de computador da 0.34.0 permanece, assim como modelos, animações, câmera/rodinha, física, energia e saves v5. Consulte `docs/guidance_v035/README.md`.

## O computador do depósito — 0.34.0

Câmeras e recuperação de arquivos usam uma área de trabalho inspirada no XP, com barras azuis, botão Iniciar, ícones originais, janelas com relevo e tipografia própria. Abertura e troca de página têm animações curtas. Os menus, os atalhos da área de trabalho e a barra de tarefas permitem abrir, minimizar, restaurar e maximizar; a barra azul permite arrastar a janela sem perder os controles.

O CCTV conserva um único canal renderizado por vez. A troca mostra uma sincronização breve e a identificação do canal. Minimizar, ler outra página ou abrir um documento sobre a imagem suspende a renderização e a observação do feed. Os eventos antigos continuam claramente identificados como registros escritos, separados do vídeo recuperado no domingo.

O player de domingo reproduz o Theora original, com pausa, retomada e progresso real até o fim. Minimizar pausa a reprodução e restaurar respeita a pausa escolhida pelo jogador. O cadastro abre como uma segunda janela de documento. Operações de prova mantêm seus efeitos e recebem confirmação visual. ESC fecha primeiro o documento; ESC/C sai do computador e TAB continua trocando de personagem. As janelas permanecem nítidas nos modos PS1.

Modelos, animações, controles dos protagonistas, energia, campanha e saves v5 permanecem. Consulte `docs/desktop_v034/README.md`.

## O clímax de domingo — 0.33.0

A investigação mantém o ar da rua e os equipamentos reais, com espaço entre os acontecimentos. Uma única oportunidade de cabeça entre as caixas fica disponível após recuperar o módulo e um período de rotina; não é necessário esperar nem percebê-la para concluir a noite. A câmera permanece livre. A aparição se recolhe antes de o perseguidor existente ficar visível, sem criar outro homem andando pelo salão.

Os passos do assassino acompanham seu deslocamento físico e são abafados por paredes e portas. Perder a dupla faz o perseguidor chegar ao último ponto conhecido, olhar em volta e verificar até três pontos alcançáveis próximos. A busca tem limite e não lê a posição de alguém escondido. Pose da cabeça, oportunidades consumidas, memória, etapa de busca e intervalos ficam salvos no formato v5.

No HUD discreto, o jogo deixa o movimento e o som indicarem a detecção. O HUD completo mantém os avisos de ajuda. O disjuntor e a trava continuam físicos, com diálogo curto de coordenação. As decisões de sábado, o gerador, os circuitos e as rotas da dupla permanecem disponíveis.

Depois da confirmação da saída, a ameaça para e o ambiente da rua acompanha alguns segundos antes do epílogo entrar suavemente. Enter ou o botão de leitura pode adiantar esse instante; o save conserva a etapa e não repete o respiro já concluído. Sobreviventes, provas e três finais continuam seguindo as condições originais. Consulte `docs/climax_v033/README.md`.

## Vestígios no sábado — 0.32.0

O sábado recebe marcas discretas nos fundos, dois passos no pátio e um ruído de tecido atrás da porta antiga. Depois de inspecionada, a caixa pode mudar ligeiramente quando ninguém está próximo ou olhando; sua marca no pó permanece no lugar. O objeto e a navegação mudam juntos. Não há nova pista obrigatória, anotação automática ou fala confirmando os novos acontecimentos.

Depois de um período de silêncio, uma única oportunidade opcional pode revelar o assassino original dentro do sedã já estacionado. A janela precisa estar fora da vista para preparar o momento; o jogador vira a própria câmera e pode perder o rosto. O modelo se abaixa atrás da carroceria, sem atravessar a loja. Posição, tempo e oportunidade consumida ficam salvos. As falas automáticas do começo e do fim da investigação foram reduzidas: o movimento da maçaneta continua físico, sem legenda explicando a ameaça.

As quatro pistas de sábado, as decisões e o fechamento continuam disponíveis. Modelos, texturas, onze bibliotecas de animação, circuitos, física dos protagonistas e rodinha permanecem preservados. Quinze suítes incluem 40 verificações novas. Consulte `docs/unease_v032/README.md` e a verificação da distribuição no GitHub.

## Ser observado sem confirmação — 0.31.0

O assassino original agora pode espiar com a cabeça por cantos e por cima de gôndolas e caixas, em oportunidades espaçadas durante a sexta e o sábado. O modelo inteiro continua atrás da cobertura: uma pose própria de espiar ou se abaixar é aplicada só a esse ator, sem alterar as bibliotecas de animação publicadas. Corpo encoberto, espaço livre, chão, distância, pessoas próximas e olhar direto de outros personagens são verificados antes de mostrar a cabeça.

O tempo não espera o jogador perceber. As oportunidades também acontecem quando a câmera está voltada para outro lado; muitas podem passar despercebidas. Não há música de susto, aviso, fala ou nota de percepção para confirmá-las. A antiga aparição narrada do gerador deixa de iniciar em partidas novas; observações já salvas continuam preservadas. Os eventos do estoque, Bryan e a campanha permanecem disponíveis.

O save conserva a sequência, o tempo, a pose da oportunidade em andamento e o limite por noite, sem repetir uma oportunidade concluída ao carregar. Domingo usa a ameaça existente. A câmera continua livre e a rodinha mantém terceira pessoa. Veja `docs/watching_v031/README.md`.

## Uma presença breve nos fundos — 0.30.2

A figura não atravessa mais o salão. O modelo original do assassino aparece parcialmente atrás do batente do estoque, durante uma olhada periférica, e recua fisicamente para trás da parede. O ponto precisa estar fora da vista dos outros personagens e clientes; pessoas próximas também bloqueiam a aparição. Não há piscada de iluminação, batida de porta ou conversa automática para explicá-la. Se o jogador não percebe, não ganha uma anotação de algo que não viu. As conversas opcionais e a memória do sábado mantêm a dúvida.

A posição e o progresso do vulto retomam pelo save. Checkpoints antigos da travessia são consumidos sem recriar um homem exposto no salão e sem apagar observações ou tarefas já salvas. Câmera, rodinha, energia e perseguição de domingo continuam disponíveis. Veja `docs/subtle_v0302/README.md`.

## Assassino na aparição — 0.30.1

A figura da volta do gerador usa agora o assassino original, com o mesmo `Enemy.glb` e a mesma biblioteca de animação usados na perseguição de domingo. O cliente que representava essa aparição na 0.30 foi substituído. Os arquivos do modelo e das animações permanecem originais.

A cena conserva deslocamento físico, passagem pelas portas e sua posição ao salvar e continuar. A câmera continua livre e a rodinha mantém terceira pessoa. A perseguição de domingo conserva o funcionamento existente. Veja `docs/killer_v0301/README.md`.

## Terror e sustos — 0.30.0

A primeira noite inclui arrasto e maçaneta na porta antiga, Bryan batendo na vitrine e uma pessoa atravessando o salão depois que Deryk volta do gerador. Eles dependem de posição, percepção e progresso, com intervalos de calma. A câmera continua livre e a rodinha mantém primeira e terceira pessoa. Não há tarefas novas obrigatórias.

O arrasto para ao se aproximar. Bryan chega caminhando à vitrine; conversar com ele traz o alívio depois da brincadeira. A figura começa fora da visão desobstruída e usa corpo físico, colisões e navegação para seguir pelo estoque ao pátio. A porta só bate depois que ela e os protagonistas ficam fora da área de giro. Felps só comenta a travessia se Deryk a percebeu.

A luz comercial baixa por alguns segundos e se recupera; geladeiras e gerador continuam funcionando. Salvar no meio conserva maçaneta, rota de Bryan, percurso da figura e progresso. Caderno J e pausa congelam os eventos. O fechamento e o sábado reconhecem a ameaça percebida. Sons originais e ferramentas de síntese estão incluídos; não é necessário instalar ferramentas extras para jogar.

Veja `docs/scares_v030/README.md`. Modelos, texturas, bibliotecas de animação, física dos protagonistas, caixas, troco, circuitos e finais continuam preservados. Saves anteriores são aceitos.

## Primeira noite e memória dos irmãos — 0.29.0

Ao escolher Iniciar, Deryk e Felps conversam sobre a mãe e voltar para casa depois do trabalho. Espaço avança; a câmera e a rodinha continuam livres. A conversa no balcão inicia as tarefas como antes. Continuar não repete a chegada.

Os clientes e conhecidos têm falas próprias. A pergunta do cliente de boné só vira anotação quando é ouvida. Conversar com o irmão depois de perceber a pessoa na rua, o sino, passos ou o carro traz reações específicas, sem repetir em cada interação. As falas do aviso também reconhecem o que você viu.

No fechamento, reúna os dois pela operação habitual. A dupla ouve passos no salão vazio; Espaço ou o avanço normal terminam a conversa e as portas baixam. O relato aparece no resumo e no caderno, e a abertura de sábado retoma as observações. Não há uma pista nova obrigatória. Saves anteriores continuam aceitos e não recebem acontecimentos inventados.

Veja `docs/friday_story_v029/README.md`. Modelos, texturas, bibliotecas de animação, física, caixas, troco, energia, PS1 e câmera permanecem preservados.

## Apresentação e rotina — 0.28.0

A câmera começa em primeira pessoa. **RODA para baixo** afasta até terceira pessoa; **RODA para cima** retorna à primeira. Cada personagem conserva sua escolha ao alternar por Tab e salvar. Checkpoints anteriores recebem a nova câmera uma vez; posição, inventário, dinheiro e campanha são mantidos. As próximas gravações preservam a escolha da rodinha.

**J** abre o caderno com o objetivo completo, destinos das caixas, controles e observações percebidas. J ou Esc fecham. A leitura pausa o mundo. O HUD é discreto por padrão, e Configurações permite manter as instruções persistentes. C continua abrindo as câmeras e as decisões de investigação no posto de Felps.

A rotina agora antecede o aviso por pelo menos cinco minutos: continuam chegando vendas comuns até que tempo, reposição, organização e atendimentos permitam avançar. Sons posicionais, luz de comércio, rádio abafado no estoque, conversas curtas e acontecimentos sutis dão ambiente ao expediente. Acontecimentos e anotações são únicos e retomam pelo save. A refrigeração acompanha a energia e continua ligada quando só o salão é apagado.

Modelos, texturas, pesos e as onze bibliotecas de animação foram preservados, incluindo a corrida da 0.27.0. Intro Two Brothers Lab, menu retrô, física de movimento, caixas, troco, circuitos, investigação, perseguição e saves continuam presentes. Veja `docs/everyday_v028/README.md`. Não é necessário instalar Blender ou Python para jogar.

## Passada dos protagonistas — 0.27.0

Deryk e Felps têm novas curvas de caminhada e corrida, com apoio regular, recuperação do pé, balanço contido do quadril e braços próprios de corrida. A perna no ar não abaixa o corpo inteiro. A troca caminhada/corrida usa velocidades diferentes para entrar e sair; a corrida não prende os pés em âncoras de caminhada. As bibliotecas são prontas e não exigem Blender ou Python para jogar.

Modelos, materiais, texturas, pesos, física, câmera, inventário, energia, saves, intro, menu e bibliotecas dos outros personagens foram preservados. Veja `docs/sprint_v027/README.md`. Extraia o ZIP em uma pasta nova para testar esta versão.

## Animações refeitas — 0.26.0

A base de caminhada, corrida, repouso, agachamento e conversa usa animações de Quaternius (CC0), adaptadas aos 11 rigs sem modificar suas malhas, texturas ou pesos. O apoio dos pés segue o contato de cada referência, e os clientes modulares receberam o pivô correto da manga. Protagonistas, garotas, homens, Zirico e Bryan têm variações próprias. As ações de caixas conservam seus tempos e controles. Veja `docs/motion_v026/README.md` e a licença em `tools/motion_reference/`.

As bibliotecas prontas são usadas pelo jogo. Não é necessário baixar referências, instalar scipy ou executar Blender. Para regenerar, execute `tools/bake_natural_motion.tscn` no Godot 4.4.1.

## Movimento dos personagens — 0.25.0

Há perfis próprios para Deryk e Felps, garotas, homens, senhora, Zirico bêbado e Bryan inquieto. Os 11 rigs têm bibliotecas de movimento medidas; as malhas, texturas e os pesos dos modelos não foram alterados. Os clientes homens e o cliente do aviso também usam esse controlador.

A passada acompanha a distância realmente percorrida, para quando o corpo está bloqueado e volta quando o caminho abre. Gestos de repouso são finitos; Bryan tem gestos mais frequentes, enquanto Zirico usa base mais larga e braços de equilíbrio. As transições limpam apoios antigos e suavizam a estabilização horizontal dos pés. Ações de pegar, colocar, largar caixas e atacar conservam os clipes e tempos originais.

Perfis ficam em `resources/locomotion_profiles.json`; as bibliotecas prontas estão em `resources/motion/`. Não é necessário Blender nem regenerar animações para jogar. Para refazer as bibliotecas, execute a cena `tools/bake_natural_motion.tscn` no Godot 4.4.1. Veja `docs/motion_v025/README.md`. Prévias em vídeo ficam no GitHub para manter o ZIP abaixo de 100 MiB.

## Intro retrô e menu de suspense — 0.24.2

Ao abrir o jogo, uma sequência de fita apresenta o estúdio **Two Brothers Lab** e o depósito em Franca às 21:40. Espaço, Enter, Esc ou clique pulam a intro e mostram o menu. O depósito vazio, a tipografia de terror dos anos 80 e a atmosfera sonora criam o fundo do menu. Configurações e continuar o checkpoint ficam disponíveis antes de iniciar a partida. A pausa não repete a intro.

O título usa Bebas Neue em duas linhas, com creme e vermelho queimado; as opções usam Special Elite e o visor usa VT323. O menu entra em etapas, a seleção responde suavemente e a câmera se aproxima devagar. O título menor e o espaço entre as opções deixam a fachada respirar. O letreiro apresenta falhas discretas e a luz ao fundo aparece ocasionalmente, com restauração completa antes da partida. Há sons distantes de carro, cachorro, metal e zumbido elétrico; todos respeitam Efeitos. Continuar informa a noite e o horário do checkpoint sem carregar a campanha. Ao iniciar, o menu se apaga com um estalo de fita e o controle só é entregue quando a transição cobre a troca de câmera. As três fontes estão incluídas com suas licenças em `assets/fonts/title/retro/`.

Fontes, sons originais e código estão prontos no pacote: não é necessário instalar ferramentas extras para jogar. As opções de volume controlam a apresentação. Modelos, animações, física, energia, HUD e a correção do piso da 0.23.1 foram preservados. Veja `docs/title_v0242/README.md`.

## Piso estável ao mover a câmera — 0.23.1

Corrige o deslizamento das texturas do piso em PS1 e PS1/2. Materiais com projeção triplanar mantêm o mapeamento preso ao cenário/objeto. A interpolação afim das texturas UV recebeu limites suaves e trata corretamente vértices atrás da câmera. As escolhas Desligada/Suave/Marcada, a precisão de vértices e a resolução continuam disponíveis. Veja `docs/psx_v0231/README.md`.

## Efeitos PS1 / PS1/2 — 0.23.0

Em Configurações, selecione PS1 (320×240) ou PS1/2 (640×480). Precisão de vértices PS1 e Texturas afins PS1 podem ser Desligada, Suave ou Marcada, independentemente. Suave é o padrão. As escolhas ficam salvas e só afetam esses dois modos. HUD e menus permanecem em resolução plena. Os modelos, animações, colisões, saves e circuitos de energia foram preservados. Veja `docs/psx_v023/README.md`.

## Movimento e acabamento do cenário — 0.22.0

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
- J: abrir/fechar o caderno do expediente e pausar a rotina durante a leitura.

Converse com Felps para iniciar. Reponha as duas caixas na geladeira e organize a caixa solta. A caixa fechada de um pedido tem identificação própria. Bryan e Zirico têm conversas opcionais.

O limite padrão é 30 FPS. Em Configurações, escolha 30 FPS, 60 FPS ou Sem limite. A estabilidade no PC alvo precisa de teste; veja `docs/optimization_v011`.

PS1 em 320×240 e PS1/2 em 640×480 ficam em **Configurações → Resolução interna / qualidade**. Ambos mantêm a janela grande e os menus em resolução normal. Mantenha a resolução global do projeto em 1280×720.

Os modelos e texturas foram preservados. A energia agora controla luzes e equipamentos. Créditos CC0 em `resources/material_sources/LICENSE.md`. O histórico do bug de largar caixas, corrigido na 0.16.0, e as próximas mecânicas ficam em `docs/PENDENCIAS.md`.

O elenco inclui Dery, Felps, Killer, Bryan, Zirico, Garota 1, Garota 2 e Velha 1. Os FBX originais ficam no [pacote fornecido pelo autor](https://drive.google.com/file/d/1qogHQIpLHR2YuTVj_vi3I2FP-i-Qapxe/view); as derivações necessárias para jogar já estão incluídas. Galerias históricas permanecem no [GitHub](https://github.com/Deriby/TheLastSale).

## Validação

A versão 0.37.0 roda vinte e uma suítes de integração (1.000 verificações) com `./tools/test.sh`. A verificação renderizada `tests/psx_motion_integration.tscn` acrescenta 48 casos e requer uma tela OpenGL. O relatório de distribuição no GitHub registra os resultados do ZIP extraído, a captura real e avisos de importação ou encerramento. A validação histórica renderizada de câmera PS1 permanece no relatório anterior; shaders, câmera, colisões e velocidades permanecem; o controle de recuperação de fôlego foi corrigido. Veja `docs/music_v037/validation.json`.

A Godot 4.4 tem Windows 10 como requisito oficial mínimo. Windows 7/Radeon R7 não foram validados nativamente. O modo Econômica reduz resolução, sombras e acabamento dos materiais.

`PROJETO_MANIFESTO.json` registra o SHA-256 dos arquivos. Caches `.godot`, saves, Git e exportações para Windows não fazem parte deste pacote.
