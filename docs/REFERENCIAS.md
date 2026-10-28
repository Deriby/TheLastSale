# Referências e decisões espaciais

Foram examinadas as sete fotografias internas e as sete capturas externas contidas em `reference_photos.zip`. As capturas externas já mostram o Street View; o link curto não foi usado como fonte adicional nem se afirma navegação interativa no Maps.

## Elementos observados

- Exterior 1/2/6/7: fachada cinza com bloco principal alto de duas portas e anexo mais baixo à esquerda; letras JA claras dentro de ramos vermelhos, faixa “DEPÓSITO DE BEBIDAS”, “LOJA·2”, número 558, telefone comercial, pequena janela à direita e quatro pilares de proteção na calçada. Ao lado direito aparecem o comércio de gás CASSIANO e um sobrado.
- Exterior 3/4: casa cinza baixa com portão estreito e janela gradeada; casa amarela de telhado cerâmico; casa salmão atrás de muro baixo e portões claros; sobrado claro ao fundo e pequeno comércio verde no sentido de subida. Poste, fiação aérea e vegetação esparsa.
- Exterior 5: rua de bairro sem faixa central, remendos, calçadas irregulares e perspectiva de declive; cerca e vegetação ao lado do anexo, seguida por oficina cinza. Não há escala métrica confiável.
- Interior 1/2: gôndolas com bebidas e conveniência, geladeiras claras com faixas coloridas nas paredes, TV alta, teto metálico e iluminação com contraste entre corredores.
- Interior 3/4/6: piso cerâmico claro, paredes altas claras, treliças, luminárias pendentes, ilhas centrais e geladeiras ao fundo.
- Interior 5/7: equipamentos e produtos próximos à entrada, porta aberta e continuidade piso/calçada.

## Aproximações explícitas

Adotou-se um salão de 12 × 11 m, estoque fictício de 12 × 5 m e altura em torno de 6 m. Esses números são decisões de layout, não medições das fotos. As dimensões preservam corredores transitáveis e escala humana.

O caixa foi posicionado junto à entrada direita por plausibilidade e funcionamento do percurso; sua posição exata não é demonstrada claramente por todas as fotos. O estoque, o palete de devoluções, a divisória, a porta antiga e o evento sonoro são ficcionais. Casas não fotografadas, carros, posição precisa dos postes e geometria distante são complementos estilizados.

As geladeiras e gôndolas usam marcas genéricas. Na revisão 0.4.0, a fachada reproduz também o telefone comercial visível na referência e o número 558; o mural e as placas foram redesenhados como arte original de baixa resolução. O nome do pequeno mercado não é legível nas capturas, por isso a placa “MERCEARIA E QUITANDA” é descritiva e inventada. Caixas de medição, grades e silhueta da concertina são detalhes visuais; não se reproduziu um sistema de segurança real.

As portas de venda estão abertas por se tratar do expediente, embora as capturas externas as mostrem fechadas. O piso, altura do salão, estrutura metálica, repetição das geladeiras e disposição em corredores são os principais vínculos com o interior real.

## Modelos

Os originais GLB contêm uma malha/material principal cada, três imagens PBR de 4096², pose T e nenhum esqueleto. Alturas de importação no Blender: Dery 1,12056; Felps 1,11270; Enemy 1,12345 unidades. A conversão ajustou os três para cerca de 1,78 m, preservando proporções internas, UVs e aparência; originais não alterados. A escala humana exata fornecida não estava especificada.

Derivados: aproximadamente 12 mil triângulos por protagonista. Deryk e Felps usam 21 ossos e texturas de cor 1024² na revisão 0.3.1; Enemy mantém 19 ossos e 512². Os braços derivados receberam ajuste de proporção e encaixe das articulações conforme a referência do usuário; os uploads permanecem intactos. Materiais ásperos sem normal map/metal excessivo. O orçamento é mais alto que um personagem de PS1 real para preservar os rostos fornecidos; a direção retrô vem também da resolução interna, filtragem e cenário. `original_checksums.json` identifica os originais ativos; `rig_report.json` e `rig_validation.json` registram geometria e verificações. O Felps anterior foi arquivado integralmente em `assets/models/originals/archive/`; o novo upload está registrado em [characters_v03/source_history.json](characters_v03/source_history.json).

## Revisão 0.2

As referências foram revisitadas para reconstruir a arquitetura do salão, as fileiras de equipamentos, a variedade de gôndolas e a exposição da entrada. Veja [a comparação e os limites](depot_v02/README.md). Parede com 5,6 m e cobertura com cumeeira aproximada de 6 m; o piso usa módulo de 60 cm como estimativa. A planta exata, caixa e estoque continuam sem medição.

## Revisão 0.4.0

As sete capturas externas foram revisitadas para substituir a rua genérica. [Comparações e passeio](exterior_v04/README.md). O anexo frontal foi rebaixado, incluindo a parede lateral e a cobertura correspondentes; o salão dos fundos mantém a planta jogável anterior. A profundidade real desse anexo não foi medida.

O leito da rua tem 7,8 m, meios-fios de 14 cm com chanfro transitável e declive estimado de 4,5% fora do patamar frontal de 12 m. Esses valores foram escolhidos para a perspectiva e a circulação, não extraídos de levantamento. O trecho explorável termina aproximadamente a 28 m de cada lado do depósito, com continuidade visual além dos limites. Profundidades, fundos das casas, imóveis distantes, posição dos carros e iluminação noturna são interpretações. As capturas diurnas de QA servem para comparar volumes e cores com o Street View; o expediente do jogo continua à noite.
