# Referências e decisões espaciais

Foram examinadas as sete fotografias internas e as sete capturas externas contidas em `reference_photos.zip`. As capturas externas já mostram o Street View; o link curto não foi usado como fonte adicional nem se afirma navegação interativa no Maps.

## Elementos observados

- Exterior 1/2/6/7: fachada cinza, marca JA com motivo circular, texto Loja 2, três portas metálicas e pequenos pilares de proteção na calçada.
- Exterior 3/4: casas baixas do outro lado, muros, telhado cerâmico, poste e fiação aérea.
- Exterior 5: continuidade de rua de bairro e perspectiva de declive, sem escala métrica confiável.
- Interior 1/2: gôndolas com bebidas e conveniência, geladeiras claras com faixas coloridas nas paredes, TV alta, teto metálico e iluminação com contraste entre corredores.
- Interior 3/4/6: piso cerâmico claro, paredes altas claras, treliças, luminárias pendentes, ilhas centrais e geladeiras ao fundo.
- Interior 5/7: equipamentos e produtos próximos à entrada, porta aberta e continuidade piso/calçada.

## Aproximações explícitas

Adotou-se um salão de 12 × 11 m, estoque fictício de 12 × 5 m e altura em torno de 6 m. Esses números são decisões de layout, não medições das fotos. As dimensões preservam corredores transitáveis e escala humana.

O caixa foi posicionado junto à entrada direita por plausibilidade e funcionamento do percurso; sua posição exata não é demonstrada claramente por todas as fotos. O estoque, o palete de devoluções, a divisória, a porta antiga e o evento sonoro são ficcionais. Casas não fotografadas, carros, posição precisa dos postes e geometria distante são complementos estilizados.

As geladeiras e gôndolas usam marcas genéricas; a fachada mantém apenas os elementos visuais centrais observados. Telefones, detalhes pessoais e dispositivos reais de segurança foram omitidos. Não se reproduziu um sistema de segurança real.

As portas de venda estão abertas por se tratar do expediente, embora as capturas externas as mostrem fechadas. O piso, altura do salão, estrutura metálica, repetição das geladeiras e disposição em corredores são os principais vínculos com o interior real.

## Modelos

Os originais GLB contêm uma malha/material principal cada, três imagens PBR de 4096², pose T e nenhum esqueleto. Alturas de importação no Blender: Dery 1,12056; Felps 1,11270; Enemy 1,12345 unidades. A conversão ajustou os três para cerca de 1,78 m, preservando proporções internas, UVs e aparência; originais não alterados. A escala humana exata fornecida não estava especificada.

Derivados: aproximadamente 12 mil triângulos por protagonista e 19 ossos. Deryk e Felps usam texturas de cor 1024² na revisão 0.3; Enemy mantém 512². Materiais ásperos sem normal map/metal excessivo. O orçamento é mais alto que um personagem de PS1 real para preservar os rostos fornecidos; a direção retrô vem também da resolução interna, filtragem e cenário. `original_checksums.json` identifica os originais ativos; `rig_report.json` e `rig_validation.json` registram geometria e verificações. O Felps anterior foi arquivado integralmente em `assets/models/originals/archive/`; o novo upload está registrado em [characters_v03/source_history.json](characters_v03/source_history.json).

## Revisão 0.2

As referências foram revisitadas para reconstruir a arquitetura do salão, as fileiras de equipamentos, a variedade de gôndolas e a exposição da entrada. Veja [a comparação e os limites](depot_v02/README.md). Parede com 5,6 m e cobertura com cumeeira aproximada de 6 m; o piso usa módulo de 60 cm como estimativa. A planta exata, caixa e estoque continuam sem medição.
