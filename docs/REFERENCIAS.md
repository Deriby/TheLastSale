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
