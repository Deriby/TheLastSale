# Referências e decisões espaciais

Foram examinadas as sete fotografias internas e as sete capturas externas contidas em `reference_photos.zip`, além das **quatro novas fotos do balcão e da visão interna/externa enviadas na conversa** para a revisão 0.5.0. As capturas externas já mostram o Street View. A tentativa de acessar o link curto do Maps em 28/10/2026 recebeu HTTP 403 no túnel de conexão deste ambiente; não se afirma navegação interativa ou observação adicional no Maps.

## Elementos observados

- Exterior 1/2/6/7: fachada cinza com bloco principal alto de duas portas e anexo mais baixo à esquerda; letras JA claras dentro de ramos vermelhos, faixa “DEPÓSITO DE BEBIDAS”, “LOJA·2”, número 558, telefone comercial, pequena janela à direita e quatro pilares de proteção na calçada. Ao lado direito aparecem o comércio de gás CASSIANO e um sobrado.
- Exterior 3/4: casa cinza baixa com portão estreito e janela gradeada; casa amarela de telhado cerâmico; casa salmão atrás de muro baixo e portões claros; sobrado claro ao fundo e pequeno comércio verde no sentido de subida. Poste, fiação aérea e vegetação esparsa.
- Exterior 5: rua de bairro sem faixa central, remendos, calçadas irregulares e perspectiva de declive; cerca e vegetação ao lado do anexo, seguida por oficina cinza. Não há escala métrica confiável.
- Interior 1/2: gôndolas com bebidas e conveniência, geladeiras claras com faixas coloridas nas paredes, TV alta, teto metálico e iluminação com contraste entre corredores.
- Interior 3/4/6: piso cerâmico claro, paredes altas claras, treliças, luminárias pendentes, ilhas centrais e geladeiras ao fundo.
- Interior 5/7: equipamentos e produtos próximos à entrada, porta aberta e continuidade piso/calçada.
- Novas fotos 1/2: tampo de madeira, monitor com interface clara voltado ao funcionário, teclado preto, leitor vermelho, maquininha amarela, gaveta e nichos na face do funcionário, copos e aviso impresso sobre o tampo. Geladeiras e gôndolas permanecem visíveis a partir do caixa.
- Nova foto 3: visão de dentro para fora por dois vãos enquadrados na imagem, ferragens das portas, cilindros azuis junto ao pilar, calçada, carros em frente, casa cinza e comércio verde com nome **CASSIANO** legível.
- Nova foto 4 e instrução do usuário: funcionário junto à parede esquerda, bancada comprida acompanhando a profundidade do salão, bebidas expostas atrás dele e freezer vertical perto da entrada. Não foram reproduzidos os rostos das pessoas fotografadas.

## Aproximações explícitas

Adotou-se um salão de 12 × 11 m, estoque fictício de 12 × 5 m e altura em torno de 6 m. Esses números são decisões de layout, não medições das fotos. As dimensões preservam corredores transitáveis e escala humana.

O caixa foi corrigido na 0.5.0 conforme a instrução do usuário e as novas vistas: **lado esquerdo ao olhar da rua para o fundo**, com eixo comprido no sentido entrada/fundos e corredor do funcionário junto à parede. Sua posição anterior à direita era uma aproximação incorreta. Distâncias e dimensões seguem estimadas; as fotos não constituem uma planta medida. O estoque, o palete de devoluções, a divisória, a porta antiga e o evento sonoro são ficcionais. Casas não fotografadas, posição precisa dos postes e geometria distante são complementos estilizados.

As geladeiras e gôndolas usam marcas genéricas. A fachada reproduz o telefone comercial visível na referência e o número 558; mural e placas foram redesenhados como arte original. A placa genérica do mercado da 0.4.0 foi substituída por **CASSIANO**, agora legível na nova foto; o subtítulo é uma interpretação descritiva. Caixas de medição, grades, concertina e câmera sobre a porta são detalhes visuais; não se reproduziu um sistema de segurança funcional.

As portas de venda estão abertas por se tratar do expediente, embora as capturas externas as mostrem fechadas. Na 0.5.0 o vão do anexo também fica aberto para permitir a visão da rua a partir do caixa esquerdo; a quantidade total de portas abertas no local real não é determinada pela foto interna recortada. O piso, altura do salão, estrutura metálica, repetição das geladeiras e disposição em corredores são os principais vínculos com o interior real.

## Modelos

Os originais GLB contêm uma malha/material principal cada, três imagens PBR de 4096², pose T e nenhum esqueleto. Alturas de importação no Blender: Dery 1,12056; Felps 1,11270; Enemy 1,12345 unidades. A conversão ajustou os três para cerca de 1,78 m, preservando proporções internas, UVs e aparência; originais não alterados. A escala humana exata fornecida não estava especificada.

Derivados: aproximadamente 12 mil triângulos por protagonista. Deryk e Felps usam 21 ossos e texturas de cor 1024² na revisão 0.3.1; Enemy mantém 19 ossos e 512². Os braços derivados receberam ajuste de proporção e encaixe das articulações conforme a referência do usuário; os uploads permanecem intactos. Materiais ásperos sem normal map/metal excessivo. O orçamento é mais alto que um personagem de PS1 real para preservar os rostos fornecidos; a direção retrô vem também da resolução interna, filtragem e cenário. `original_checksums.json` identifica os originais ativos; `rig_report.json` e `rig_validation.json` registram geometria e verificações. O Felps anterior foi arquivado integralmente em `assets/models/originals/archive/`; o novo upload está registrado em [characters_v03/source_history.json](characters_v03/source_history.json).

## Revisão 0.2

As referências foram revisitadas para reconstruir a arquitetura do salão, as fileiras de equipamentos, a variedade de gôndolas e a exposição da entrada. Veja [a comparação e os limites](depot_v02/README.md). Parede com 5,6 m e cobertura com cumeeira aproximada de 6 m; o piso usa módulo de 60 cm como estimativa. A planta exata, caixa e estoque continuam sem medição.

## Revisão 0.4.0

As sete capturas externas foram revisitadas para substituir a rua genérica. [Comparações e passeio](exterior_v04/README.md). O anexo frontal foi rebaixado, incluindo a parede lateral e a cobertura correspondentes; o salão dos fundos mantém a planta jogável anterior. A profundidade real desse anexo não foi medida.

O leito da rua tem 7,8 m, meios-fios de 14 cm com chanfro transitável e declive estimado de 4,5% fora do patamar frontal de 12 m. Esses valores foram escolhidos para a perspectiva e a circulação, não extraídos de levantamento. O trecho explorável termina aproximadamente a 28 m de cada lado do depósito, com continuidade visual além dos limites. Profundidades, fundos das casas, imóveis distantes, posição dos carros e iluminação noturna são interpretações. As capturas diurnas de QA servem para comparar volumes e cores com o Street View; o expediente do jogo continua à noite.

## Revisão 0.5.0

[Vistas do balcão, interior/rua e comparação de neblina](scene_v05/README.md). Bancada de aproximadamente 3 × 1 m, caixa esquerdo, parede de bebidas, freezer de gelo, exposição de copos e ferragens foram reconstruídos conforme as novas fotos. Conteúdo do sistema de caixa, marcas dos produtos e detalhes de teclado/maquininha são arte original aproximada. Monitor, leitor e maquininha são cenografia, sem simulação de pagamento.

Ventilador, parte dos conduítes, pequenos desgastes, caixas de serviço e sons de tráfego são complementos para dar vida ao cenário. A noite usa contraste entre loja e rua, cor mais contida, granulação leve e neblina de profundidade, seguindo a direção de terror cotidiano solicitada. Não se copiam mapas, interfaces ou áudio de Fears to Fathom.

A neblina começa a 22 m e fica opaca a 68 m da câmera; solo e volumes simplificados continuam muito além disso. Ela não amplia o trecho explorável e não cobre os corredores próximos. As posições dos dois carros foram aproximadas da frente da loja a partir da vista interna; não se afirma levantamento exato.

## Revisão 0.6.0

[Comparação da noite e caminhada](mood_v06/README.md). A disposição do balcão, fachadas e imóveis foi preservada da revisão anterior. A nova iluminação noturna é uma interpretação artística: as fontes das fotografias diurnas não determinam temperaturas, intensidades, janelas acesas ou intervalos dos postes. Há áreas iluminadas pelos postes e portas, sombras dos objetos e janelas com cortinas. O céu é um panorama original gerado, com horizonte de iluminação urbana e nuvens discretas.

Carros compactos receberam painéis inclinados e recortes das rodas; não reproduzem uma marca/modelo exatos. Folhas recortadas com movimento substituem volumes sólidos da copa. Reboco, piso cerâmico, asfalto e calçada usam nova arte procedural original. O bairro, proporções e trechos não fotografados continuam aproximados.

A neblina normal agora começa a 20 m e termina a 65 m, com intensificação lenta apenas à distância após o aviso narrativo existente. Uma luminária distante tem uma falha breve ocasional. Sons discretos de ar e reator elétrico são síntese original; os passos têm contatos diferentes dentro e fora da loja. A direção continua sendo terror cotidiano inspirado na referência pedida, com circulação e tarefas legíveis.

## Revisão 0.7.0

As cinco imagens de jogos enviadas nesta rodada orientam o contraste entre letreiros vermelhos/brancos, luz quente próxima ao chão, rua azulada e ar ligeiramente enevoado. São referências de acabamento, não uma mudança do depósito para uma pizzaria, posto ou loja de conveniência. O mural JA, as entradas, o balcão esquerdo e a sequência aproximada das casas permanecem vinculados às fotos do depósito. Não houve nova observação interativa do Maps.

[Imagens e caminhada da revisão](finish_v07/README.md). O filete vermelho, as luminárias brancas, o pequeno letreiro ABERTO e a promoção de bebida gelada são interpretações para o expediente noturno. A reflexão local dos carros vem de uma sonda estática da vizinhança; o halo é um efeito de câmera compatível com OpenGL, sem renderização volumétrica.

Sedã e hatch são modelos originais genéricos feitos no Blender, com carroceria curva, recortes dos para-lamas, envidraçamento, cabine, faróis e rodas. Não são reproduções medidas dos veículos fotografados. Fontes editáveis em `tools/vehicle_sources`, geração em `tools/model_neighborhood_cars.py` e medidas aproximadas em [vehicle_report.json](vehicle_report.json).

A névoa de profundidade passa a 8–85 m com uma curva suave, somada a seis planos de opacidade baixa na rua, recortados antes do interior. Não se usa neblina volumétrica; o chão continua até ±160 m. A visibilidade próxima permanece suficiente para reconhecer os carros e atravessar a calçada.

O anexo baixo à esquerda recebeu fechamentos no encontro lateral e traseiro com o telhado alto. As coberturas agora têm espessura, rufos, cumeeira, calha e colisão; os caibros e luminárias seguem a altura correspondente. O salão mantém cumeeira de cerca de 6 m e anexo a 4,48 m; os topos das paredes laterais foram ajustados a 5,42 m para acompanhar o beiral. Telhas curvas das casas, extintor, carvão e detalhes elétricos complementam o cenário sem constituir um levantamento do local real.

## Revisão 0.8.0 — materiais

[Comparações de materiais no jogo](materials_v08/README.md). A observação de `interno4.jpg` orienta o piso cinza com variações suaves e brilho acetinado, o reboco claro e o acabamento das gôndolas. As fotos do balcão enviadas na conversa orientam a madeira marrom envernizada e seu desgaste discreto. As capturas externas orientam a cor e a escala do asfalto, do cimento e da pintura das fachadas. As novas texturas são arte procedural original; os pixels das fotografias não foram incorporados ao jogo.

São 12 conjuntos com albedo, normal e acabamento ORM: madeira, cerâmica, parede interna, reboco externo, asfalto, cimento, metal pintado, aço, plástico, borracha, pintura automotiva e vidro. O pacote contém 36 mapas, com mipmaps. A madeira usa 2048 × 1024; as cinco superfícies arquitetônicas, 1024²; os outros seis conjuntos, 512². Escalas e intervalos em [surface_report.json](surface_report.json). As intensidades de rugosidade e os relevos são estimativas artísticas, não medições físicas do local.

A bancada tem coordenadas UV na escala de 2,4 × 1,2 m, com os veios seguindo seu comprimento. O atlas cerâmico cobre 2,4 × 2,4 m com 16 peças de cerca de 60 cm. As outras superfícies usam projeção em coordenadas do mundo para conservar a escala ao agrupar malhas. As dimensões e colisões do mobiliário foram preservadas.

A pintura dos carros recebeu verniz e metalização mais contidos; pneus, aros e vidro têm respostas próprias. Os modelos GLB não foram remodelados. Nítida e Retrô usam relevo fino e oclusão das texturas. Econômica desliga esses dois efeitos e a filtragem anisotrópica dos novos materiais; cor, rugosidade e metalização permanecem. A troca é aplicada aos materiais existentes durante a partida.

## Revisão 0.9.0 — variedade da rua

As capturas externas fornecidas foram revisitadas, incluindo a vista das casas cinza, salmão e amarela em frente ao depósito. A disposição desses imóveis, do JA, do CASSIANO e do sobrado foi conservada. [Comparações e detalhes](neighborhood_v09/README.md).

Os seis imóveis secundários que repetiam fachadas genéricas receberam projetos autorais distintos, compatíveis com a escala aproximada da rua de Franca: garagem com tijolo aparente, casa com jardim frontal, comércio fechado com toldo, frente com azulejos, quintal recuado e anexo de oficina. As partes pouco legíveis nas capturas continuam sendo interpretação artística. O pequeno comércio de consertos e os números dos imóveis novos são fictícios; não se afirma reprodução desses estabelecimentos ou endereços reais.

Medidores, interfone, caixa de correspondência e descida de água têm posições ajustadas às paredes/pilares de cada frente. Antenas, duas parabólicas, uma caixa-d'água apoiada, bicicleta e gaiola de botijões complementam a cena. A bicicleta acompanha a inclinação da rua; vasos junto à calçada e a gaiola são apoiados na altura local do terreno. As copas variam em altura/largura, usando o movimento de vento já existente. Uma árvore foi retirada da interseção com uma garagem e reposicionada no vão lateral.

As duas rampas de garagem são aproximações de cenografia com colisão: lado oposto em x≈−10,1 m e lado do depósito em x≈23,2 m. A altura de navegação/checkpoints acompanha o topo dessas rampas, com transição lateral. Fechamentos visíveis protegem os vãos junto ao limite do piso das calçadas. O trecho explorável conserva os limites anteriores; os lotes distantes têm quatro variações simplificadas de volume/cobertura para compor a perspectiva.

Tijolo, azulejo e casca de árvore acrescentam três conjuntos de materiais originais ao gerador, totalizando 15 conjuntos e 45 mapas. A iluminação e a névoa mantêm a direção noturna existente; as novas janelas usam acabamento luminoso, sem acrescentar focos de luz à rua. Dimensões, materiais e detalhes não foram levantados fisicamente no local.

A revisão das imagens identificou uma faixa de claridade na borda da sonda local dos carros. Sua máscara de influência foi limitada aos veículos, mantendo a captura de fachadas/rua para os reflexos. Isso corrige a transição de iluminação dos imóveis sem acrescentar luminárias.

## Revisão 0.13.0 — acabamento dos materiais

As fotos do depósito e do balcão orientam a madeira marrom envernizada, o piso claro acetinado, as gôndolas pintadas e a diferença de brilho entre vidro, PET, rótulos e embalagens. Madeira, reboco externo, asfalto e concreto usam bases CC0 da Poly Haven, com paleta e escala adaptadas; créditos, arquivos de origem e hashes estão em `resources/material_sources`. As fotografias do autor não foram recortadas para texturas. Os demais acabamentos e a arte das embalagens são procedurais/originais. A comparação preserva as mesmas luzes e câmeras da 0.12.0. [Galeria e dados](materials_v013/README.md).
