# Validação — revisão 0.14.0 — 29/10/2026

**132/132 verificações** passaram no projeto e no ZIP extraído com importação limpa. A galeria [lighting_v014](lighting_v014/README.md) registra oito vistas fixas do salão, caixa, geladeiras, fachada, rua, estoque e horizonte, com comparação da 0.13.0 à 0.14.0. Há capturas diretas sem pós-processamento para medir os brancos saturados da vista de entrada.

As verificações novas conferem luzes restritas às geladeiras, preservação de cinco luzes com sombras, captura única de reflexos, limites da névoa, desligamento/restauração de efeitos por qualidade e congelamento da deriva/variações durante a pausa. O fluxo completo de tarefas, clientes, câmera, portas e checkpoints continua passando.

A geometria e os materiais da 0.13.0 foram preservados. A revisão acrescenta luzes de pequeno alcance restritas aos equipamentos, duas luzes de parede para o neon e uma captura de reflexão. O atlas de reflexos tem 128 pixels e quatro posições; o reflexo é atualizado uma vez. Não foram adicionadas sombras em tempo real ou neblina volumétrica. O modo Econômica desliga os efeitos adicionais. Limite padrão de 30 FPS; FPS nativo no Windows/Radeon R7 permanece sem medição.

O problema de largar caixas permanece somente registrado em [PENDENCIAS.md](PENDENCIAS.md), para a etapa de jogabilidade. Integridade do download em [downloads/project](../downloads/project/README.md).

## Registro anterior — revisão 0.13.0 — 29/10/2026

**125/125 verificações** passaram no projeto e no ZIP extraído com importação limpa. A galeria [materials_v013](materials_v013/README.md) compara materiais usando as mesmas câmeras, luzes e enquadramentos da 0.12.0. Há bases CC0 da Poly Haven para madeira, reboco, asfalto e concreto, além de acabamentos procedurais e nova arte de embalagens.

As verificações novas conferem a diferença de rugosidade entre rótulo e vidro, metal exposto e pintura das latas, mipmaps das embalagens, verniz da bancada versus madeira crua e troca de qualidade nos materiais já instanciados. A suíte preserva o percurso completo de circulação, portas, animações, tarefas, clientes e checkpoints. Sem correção do problema de largar caixas nesta etapa.

As medidas de geometria e textura ficam na galeria. As luzes e a quantidade de triângulos foram preservadas. O limite padrão permanece em 30 FPS; não foi medido FPS nativo no Windows/Radeon R7. Mapas de acabamento e verniz são desligados no modo Econômica.

Fontes CC0 e originais para reprodução offline: [resources/material_sources](../resources/material_sources/LICENSE.md). Verificação do download: [downloads/project](../downloads/project/README.md).

## Registro anterior — revisão 0.12.0 — 29/10/2026

**119/119 verificações** passaram no projeto e no ZIP extraído com importação limpa. A galeria [layout_v012](layout_v012/README.md) registra os quatro pontos relatados: fiação sem sombras e remoção de autossombra do chão, cobertura baixa esquerda contínua, garrafas apoiadas em engradados e espaço para abrir as geladeiras. O corredor tem aproximadamente 2,10 m com as portas fechadas e 1,12 m livres com todas abertas.

A suíte usa raios físicos no teto, confere apoio geométrico de todas as garrafas, consulta o espaço de giro das sete portas dos fundos, abre as portas pela interação e atravessa o corredor com movimento real. Verifica a tecla E numa geladeira do fundo sem avançar tarefas. O fluxo completo existente de reposição, clientes e checkpoints continua passando. Duas falhas encontradas durante a revisão também foram corrigidas: o estado de variação de repouso após conversa e a consulta de foco em obstáculos sem metadados.

O problema de largar a caixa ficou **somente registrado** em [PENDENCIAS.md](PENDENCIAS.md). Não foi incluída correção desse comportamento.

Capturas em Linux/Mesa llvmpipe, Godot 4.4.1 Compatibility, Nítida sem granulação para inspeção. A opção padrão de 30 FPS e as otimizações da 0.11.0 foram mantidas. Desempenho nativo no PC com Radeon R7 não foi medido. Download e integridade: [downloads/project](../downloads/project/README.md).

## Registro anterior — revisão 0.11.0 — 29/10/2026

A revisão [optimization_v011](optimization_v011/README.md) reduz dados de geometria mantendo objetos, triângulos e iluminação. 109/109 verificações passaram no projeto. O cenário inicial é reaproveitado, estados de câmera são atualizados só quando mudam e o assassino oculto pausa sua animação. O padrão de limite é 30 FPS, configurável; o desempenho nativo na Radeon R7 permanece sem medição.

O download atual é o projeto Godot 0.11.0 em ZIP, com os hashes e registros em [downloads/project](../downloads/project/README.md).

## Registro anterior — revisão 0.10.0 — 29/10/2026

O novo elenco usa os FBX com rig enviados pelo autor. Os registros em [cast_v010](cast_v010/README.md) confirmam **106/106 testes** no projeto e **106/106** no pacote Linux, além das revisões de renderização dos modelos e do cenário. Normal maps dos materiais importados: nove ativos em Nítida e zero em Econômica. A prévia de movimento tem 12 segundos.

O download atual é o **projeto Godot em ZIP**, disponível em [downloads/project](../downloads/project/README.md). O pacote contém os recursos derivados usados no jogo e não depende dos originais FBX para abrir no editor. A verificação do arquivo distribuído, incluindo abertura de uma extração limpa, fica em `downloads/project/release_verification.json`.

Os registros abaixo preservam a validação das entregas anteriores. Os binários Windows não receberam teste nativo nesta máquina Linux; desempenho na Radeon R7 não foi medido.

## Registro anterior — revisão 0.9.0 — 29/10/2026

## Ambiente

Godot **4.4.1.stable.official.49a5bc7b6**, Linux x86_64. Runtime Compatibility / OpenGL 4.5 por Mesa llvmpipe em display virtual Xorg. Blender 4.3.2, renderização Cycles CPU. O editor e os templates oficiais foram conferidos contra os SHA-512 publicados no release Godot 4.4.1.

Esta revisão diferencia os imóveis secundários da rua, modela detalhes residenciais/comerciais e acrescenta rampas e fechamentos de vãos. Comparações e registros em [neighborhood_v09](neighborhood_v09/README.md). Os materiais da etapa anterior estão em [materials_v08](materials_v08/README.md); a cobertura e os carros em [finish_v07](finish_v07/README.md).

## Integração

Suíte `res://tests/integration.tscn`, também executada por `./tools/test.sh`: **92/92 verificações passaram**, saída 0. O preset Linux QA exportado também executou **92/92**, saída 0, iniciado fora da pasta do projeto com `--main-pack` apontando ao PCK exportado. As duas execuções usam saves temporários e percorrem o fluxo real com física, sem erros de GDScript ou objetos retidos na finalização.

Cobertura:

- Cena principal, chão físico, seis rigs importados, materiais e texturas.
- Duas rampas modeladas com colisão e altura de navegação; passagem real sobre a rampa oposta com contato no piso, ajuste de checkpoint e bloqueio do vão entre oficinas.
- Declive contínuo por raycasts físicos, colisão dos pilares frontais e movimento real do jogador descendo um meio-fio e subindo o outro sem ficar preso ou cair pelo chão.
- 23 clipes de Deryk importados, expansão da caixa torácica em repouso, base dos pés mais estreita e novo Felps com cabeça separada; cotovelos baixos, punhos abaixo do quadril e cintura/peito superior movendo-se separadamente.
- Entrada WASD, corrida, aceleração e colisão reduzida no agachamento.
- Roda e movimento de mouse encaminhados à viewport.
- SpringArm junto à parede, recolhimento lateral do ombro, volume da lente fora da parede e transição entre terceira/primeira pessoa com corpo visível.
- Interação sobre o balcão e gestos de Felps enquanto fala.
- Porta bloqueando e liberando passagem física.
- Rejeição de alcance a caixas distantes; alcance inicial antes da fixação, transporte junto aos punhos, reposição visível e colocação persistente no palete.
- Rejeição de caixa errada e bloqueio do aviso antes das condições narrativas.
- Clientes atravessando rua/loja, escolhendo bebida, pagando e saindo; observação dos sete estados sem pular waypoints.
- Aviso, diálogo, ruído e inspeção final condicionados à progressão.
- Gravação/restauração de checkpoint, posição, caixas e produtos; pausa do relógio narrativo.
- Checkpoint antigo na calçada exterior ajustado à nova altura do terreno.
- Movimento físico pelo espaço antes ocupado pelo caixa da direita, atendimento de todos os clientes junto ao balcão esquerdo e restauração de checkpoint dentro da área dos móveis novos, com consulta física confirmando que o personagem fica livre de interseções.
- Cobertura esquerda atingida fisicamente por raycasts nos dois níveis; fechamentos lateral e traseiro do desnível bloqueando raios horizontais. Dois veículos GLB instanciados, com geometria detalhada, nomes e dimensões dentro dos limites esperados.
- Passos no piso cerâmico e troca para contato de exterior após movimento real do jogador; cabeça em modo apenas de sombra na primeira pessoa, com retorno ao desenho normal ao afastar a câmera.

Os clientes são simulados com tempo acelerado no teste; a velocidade normal permanece no jogo. A câmera foi conferida por física e por capturas. Isso não substitui um playtest extensivo de cada canto do mapa.

## Rigs e movimentos

Os assets de personagens não foram alterados na 0.9.0. A cabeça de Deryk usa desenho apenas na sombra em primeira pessoa, para preservar a sombra completa sem aparecer dentro da câmera; a visibilidade normal retorna em terceira pessoa. Felps mantém o clipe de trabalho existente e a orientação ao balcão esquerdo. Os testes de integração acima foram repetidos; as medições Blender e gravações desta seção são o registro da revisão 0.3.1.

`tools/rig_characters.py` deriva Deryk e Felps a partir dos originais, mantendo UVs e a identidade dos modelos. Os dois têm 21 ossos, com cintura e peito superior articulados, pesos normalizados sem vértices sem influência, duas malhas de renderização (cabeça/corpo), aproximadamente 12 mil triângulos e texturas de cor 1024². Enemy e os três clientes mantêm os assets anteriores.

`tools/validate_rigs.py` reimporta os GLBs, verifica deformações finitas e limites de volume e renderiza repouso, caminhada, corrida, agachamento e transporte. As folhas finais foram inspecionadas para Deryk, Felps e Enemy. Dados: `rig_report.json` e `rig_validation.json`. `tools/review_anatomy.py` também mede os braços exportados e produz a comparação com os ossos reais em `fixes_v031/anatomy_bones.png`.

`tools/measure_motion.py` amostra 41 instantes de 13 clipes em cada um dos dois protagonistas: 1.066 poses. Todas as deformações amostradas são finitas. A maior penetração da sola foi 7,4 mm; o maior afastamento do piso durante apoio amostrado foi 11,2 mm. O limite de regressão de penetração é 12 mm. São medidas em piso plano, sem certificar todo giro ou terreno. Resultados por clipe em `characters_v03/motion_metrics.json`.

`tests/motion_review.tscn` gravou 38 segundos do controlador real, com os modelos se deslocando sobre piso marcado. A revisão também capturou Felps no caixa, transporte, primeira pessoa e corredor no jogo completo. Vídeo e GIFs atuais estão em `fixes_v031`; a execução gráfica final não apresentou erros de script.

SHA-256 dos originais ativos em `original_checksums.json`. Deryk e Enemy permanecem idênticos aos uploads anteriores. O novo Felps é idêntico ao upload desta revisão; o Felps substituído permanece integralmente arquivado. Histórico em `characters_v03/source_history.json`.

## Renderização dos equipamentos

O relato do usuário é em Windows 7 / Radeon R7 200 series. As malhas estáticas agrupadas substituem MultiMesh em todas as geladeiras, gôndolas, produtos e demais lotes de cenário. São renderizadas sem interpolação física, com limites de visibilidade calculados pela geometria final. Repor bebidas atualiza apenas o grupo que mudou.

`tests/retail_render_review.tscn` compara o cenário renderizado com malhas individuais, incluindo pausa e recarga. Na 0.9.0 foi repetido no pacote Linux exportado, a 144 quadros por segundo de simulação, com **8.491 malhas independentes**. Em Nítida foram 20 pixels diferentes em 921.600 (**0,00217%**); em Retrô, 3 em 230.400 (**0,00130%**). Ambos ficam abaixo do limite de 1% com diferença de cor acima de 20/255. Registros em [neighborhood_v09](neighborhood_v09/README.md). As capturas foram inspecionadas; os equipamentos e a rua aparecem completos. Não se trata de uma medição de desempenho da R7.

A falha integral da captura enviada não foi reproduzida em Mesa llvmpipe. A correção retira o caminho de instancing dos objetos afetados. O pacote Windows continua sem execução em Windows real; não se certifica compatibilidade oficial com Windows 7.

## Exterior

`tests/exterior_review.tscn` capturou seis vistas do pacote Linux: fachada e casas em frente à noite; fachada, casas, descida e subida com iluminação diurna de comparação. `tests/exterior_walkthrough.tscn` gravou 32 segundos com câmera de revisão no cenário noturno exportado. A ferramenta diurna não altera a cena normal do jogo. Os registros e as imagens estão em `exterior_v04`.

Foram conferidos o anexo baixo, as duas entradas principais, a continuidade de parede/cobertura, o mural e os imóveis distintos dos dois lados da rua. Texturas distantes usam mipmaps, mantendo o filtro de baixa resolução. Postes, fios e detalhes arquitetônicos usam malhas estáticas agrupadas por material, sem MultiMesh. As dimensões e partes não fotografadas são aproximações descritas em [REFERENCIAS.md](REFERENCIAS.md).

Na 0.5.0, `tests/scene_review.tscn` captura 13 vistas do pacote: balcão do cliente/funcionário, tampo, gaveta, interior/rua, salão, fachada, subida/descida e comparação com/sem neblina junto ao limite. A neblina é de profundidade em Compatibility, de 22 a 68 m; o chão continua até ±160 m, além do trecho explorável. A comparação foi inspecionada para verificar o desaparecimento gradual dos volumes distantes.

`tests/scene_walkthrough.tscn` grava 30 segundos do cenário em execução com câmera de revisão, ventilador, rotina de Felps e sons ambientes originais. O vídeo não simula entrada do jogador. A qualidade inicial usa a resolução da janela; os modos Retrô e Econômica continuam selecionáveis, e configurações anteriores são preservadas. Detalhes, imagens e fontes em `scene_v05`.

## Registro anterior: iluminação e caminhada — 0.7.0

`tests/scene_review.tscn` capturou 19 vistas do pacote 0.7.0, incluindo carro, varanda e casas opostas. A mesma cena foi repetida em Econômica: cinco luzes com sombras em Nítida e zero em Econômica, conforme os registros. O modo Econômica também desliga o halo de câmera. Nítida usa MSAA 2×; Retrô e Econômica não usam MSAA. A geometria exterior usa uma camada de iluminação separada da luz de preenchimento interna; a transição das áreas iluminadas no asfalto foi inspecionada. Materiais da rua e céu usam arte original, com mipmaps nas superfícies e folhas.

`tests/mood_walkthrough.tscn` dirige o controlador real por entradas de movimento durante 34 segundos, usando sua câmera de primeira pessoa e áudio espacial. A verificação cobre saída sobre os meios-fios, descida até aproximadamente x=-12 m, retorno e aproximação da entrada: **4/4 pontos passaram**. Não há câmera livre, salto de waypoint ou teletransporte durante o trajeto. É um percurso automatizado, não um playtest manual. Registro e vídeo em `finish_v07`.

A copa usa folhas recortadas e movimento leve que respeita a pausa. Os novos carros têm carroceria curva, cabine, bancos, volante, vidro transparente, retrovisores, limpadores, faróis e rodas detalhadas. Sedã: 56.580 triângulos; hatch: 56.372; dez grupos de materiais cada, com LODs gerados na importação. São dois veículos estáticos, com colisão e área reservada na navegação. Fonte Blender e medidas em [vehicle_report.json](vehicle_report.json).

Uma sonda de reflexão estática captura rua e fachada, excluindo carros e personagens para evitar autorreflexos. A luz dos postes alcança a camada dos carros. As novas luzes vermelhas usam apenas as camadas de rua e veículos, evitando disputar o limite de luzes dos objetos internos em Compatibility. A névoa local usa seis planos transparentes com recorte espacial antes do interior; a névoa de profundidade vai de 8 a 85 m. Não há MultiMesh ou neblina volumétrica. Sombras, letreiro ABERTO, luz vermelha/branca, telhas curvas e os fechamentos da cobertura foram inspecionados nas capturas. As luzes noturnas são interpretação artística; não houve medição fotométrica do local.

## Materiais — 0.8.0 e ampliação 0.9.0

A revisão 0.8.0 introduziu 12 conjuntos autorais com 36 mapas. Na 0.9.0, `tools/make_surface_materials.py` acrescenta tijolo, azulejo e casca de árvore, totalizando 15 conjuntos e 45 mapas. Albedo descreve a cor da superfície; normal descreve o relevo fino; ORM reúne oclusão em R, rugosidade em G e metalização em B. Mipmaps são gerados em todos eles, e os mapas normais têm importação própria. Dados de tamanho, escala e rugosidade em [surface_report.json](surface_report.json).

`SurfaceMaterials` mantém escala e acabamento por perfil, com cores independentes. A bancada recebeu UVs métricas e tangentes recalculadas, conservando suas dimensões e colisões. As outras superfícies usam projeção no espaço do mundo, que permanece coerente entre as malhas agrupadas e as referências independentes. A comparação gráfica abaixo verifica esse caminho.

`tests/material_review.tscn` captura 11 enquadramentos: madeira, cerâmica, parede, asfalto e calçada próximos, visão do balcão para a rua, fachada, carro e três vistas diurnas de comparação. A versão anterior foi capturada antes de aplicar os materiais, com as mesmas câmeras e luzes. As capturas atuais vêm do pacote Linux exportado. O teste em Econômica começa em Nítida e emite o sinal real de mudança de preferência depois de construir o cenário, verificando a troca nos materiais existentes. Nítida registra 60 materiais próprios, com 57 normal maps ativos e cinco luzes com sombras; após a troca, os normal maps ativos e as luzes com sombras passam a zero. Registros em `materials_v08`.

A gravação de caminhada em `finish_v07` é o registro da 0.7.0; não foi regravada na 0.8.0/0.9.0. Os controles, a rotina dos clientes, o contato com o terreno e o restante do fluxo foram novamente exercitados pela integração da 0.9.0.

## Rua — 0.9.0

`NeighborhoodFrontages` constrói seis fachadas secundárias com paredes segmentadas, aberturas recuadas, coberturas distintas, portões com cinco desenhos e pisos de quintal. A largura física do anexo de oficina foi ajustada ao lote de 5,5 m, substituindo o volume anterior de 9 m. Os imóveis próximos reconhecíveis nas referências foram preservados. `NeighborhoodServices` ajusta os acessórios a cada frente, e `NeighborhoodProps` modela bicicleta, antenas, parabólicas, tanque, vasos e botijões.

Obstáculos novos na calçada registram sua projeção de colisão na navegação; pisos/rampas continuam transitáveis. `Street.surface_height` descreve as transições das rampas e é compartilhado pela navegação e pela restauração de posições. A integração percorre uma das rampas pelo controlador real, amostrando o contato do personagem com o piso, e confere fisicamente o fechamento entre oficinas.

`tests/neighborhood_review.tscn` registra 20 vistas noturnas/diurnas do pacote, incluindo os novos lotes, portões, bicicleta, oficina, comércio de gás, vista do balcão e casas fotografadas. A revisão Econômica repete três vistas representativas. As capturas diurnas usam a luz de comparação da ferramenta; o jogo permanece à noite. As imagens de antes são da 0.8.0 com as mesmas câmeras. Fontes e aproximações em [REFERENCIAS.md](REFERENCIAS.md).

A geometria estática permanece em malhas comuns agrupadas por material, sem MultiMesh. Os lotes distantes usam geometria simplificada; as árvores reutilizam o shader de folhas e o movimento que respeita a pausa. Não foram adicionadas luzes de rua nesta revisão. A sonda de reflexão local passou a usar `reflection_mask=8`, influenciando apenas os carros; a máscara de captura continua em 6. A revisão diurna/noturna confirmou o desaparecimento da faixa de ambientação nas fachadas.

## Exportação e repetição

Preset Windows Desktop, Godot 4.4.1, x86_64: release de `.exe` + `.pck`. O pacote inclui recursos de movimento e diálogo, cenas, scripts, modelos, texturas e sons. Ferramentas, testes, documentos e originais de alta resolução ficam fora do Windows.

O preset Linux QA inclui a suíte para verificar os recursos empacotados. Registros finais: `test_result.txt` (projeto) e `packed_test_result.txt` (Linux exportado). O ZIP Windows e seu SHA-256 estão em `downloads/windows`.

O executável Windows **não foi executado nesta máquina Linux**. Não foram medidos FPS de hardware real ou validados Windows 7/8. O display virtual avisa que não permite controlar V-Sync. As exportações e execuções atuais não apresentaram erros de GDScript ou recursos ausentes.

Os logs contêm avisos de interpolação durante construção/recarga da cena e restauração de objetos, incluindo caixas, equipamentos e detalhes estáticos. Posições persistentes, portas e restante do fluxo passaram; os avisos não são falhas de script. Não se atribuem esses avisos ao defeito visual relatado na R7.

`tools/setup_cloud.sh` prepara importação e templates; não regenera originais. `tools/test.sh` remove os saves temporários ao terminar. As animações são procedurais e ainda pedem acabamento artístico em dedos, giros, contatos e atendimento; não há rig facial ou captura de movimento.
