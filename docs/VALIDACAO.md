# Validação — revisão 0.3.1 — 28/10/2026

## Ambiente

Godot **4.4.1.stable.official.49a5bc7b6**, Linux x86_64. Runtime Compatibility / OpenGL 4.5 por Mesa llvmpipe em display virtual Xorg. Blender 4.3.2, renderização Cycles CPU. O editor e os templates oficiais foram conferidos contra os SHA-512 publicados no release Godot 4.4.1.

Esta revisão corrige braços e pesos conforme a referência do usuário, acrescenta articulações no tronco e substitui o desenho por instâncias das geladeiras/prateleiras por malhas estáticas comuns. Imagens e gravações em [fixes_v031](fixes_v031/README.md). O registro anterior do novo Felps está em [characters_v03](characters_v03/README.md). A reconstrução anterior do cenário está em [depot_v02](depot_v02/README.md).

## Integração

`./tools/test.sh`: **73/73 verificações passaram**, saída 0. O preset Linux QA exportado também executou **73/73**, saída 0. As duas execuções usam saves temporários e percorrem o fluxo real com física, sem erros de GDScript ou objetos retidos na finalização.

Cobertura:

- Cena principal, chão físico, seis rigs importados, materiais e texturas.
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

Os clientes são simulados com tempo acelerado no teste; a velocidade normal permanece no jogo. A câmera foi conferida por física e por capturas. Isso não substitui um playtest extensivo de cada canto do mapa.

## Rigs e movimentos

`tools/rig_characters.py` deriva Deryk e Felps a partir dos originais, mantendo UVs e a identidade dos modelos. Os dois têm 21 ossos, com cintura e peito superior articulados, pesos normalizados sem vértices sem influência, duas malhas de renderização (cabeça/corpo), aproximadamente 12 mil triângulos e texturas de cor 1024². Enemy e os três clientes mantêm os assets anteriores.

`tools/validate_rigs.py` reimporta os GLBs, verifica deformações finitas e limites de volume e renderiza repouso, caminhada, corrida, agachamento e transporte. As folhas finais foram inspecionadas para Deryk, Felps e Enemy. Dados: `rig_report.json` e `rig_validation.json`. `tools/review_anatomy.py` também mede os braços exportados e produz a comparação com os ossos reais em `fixes_v031/anatomy_bones.png`.

`tools/measure_motion.py` amostra 41 instantes de 13 clipes em cada um dos dois protagonistas: 1.066 poses. Todas as deformações amostradas são finitas. A maior penetração da sola foi 7,4 mm; o maior afastamento do piso durante apoio amostrado foi 11,2 mm. O limite de regressão de penetração é 12 mm. São medidas em piso plano, sem certificar todo giro ou terreno. Resultados por clipe em `characters_v03/motion_metrics.json`.

`tests/motion_review.tscn` gravou 38 segundos do controlador real, com os modelos se deslocando sobre piso marcado. A revisão também capturou Felps no caixa, transporte, primeira pessoa e corredor no jogo completo. Vídeo e GIFs atuais estão em `fixes_v031`; a execução gráfica final não apresentou erros de script.

SHA-256 dos originais ativos em `original_checksums.json`. Deryk e Enemy permanecem idênticos aos uploads anteriores. O novo Felps é idêntico ao upload desta revisão; o Felps substituído permanece integralmente arquivado. Histórico em `characters_v03/source_history.json`.

## Renderização dos equipamentos

O relato do usuário é em Windows 7 / Radeon R7 200 series. As malhas estáticas agrupadas substituem MultiMesh em todas as geladeiras, gôndolas, produtos e demais lotes de cenário. São renderizadas sem interpolação física, com limites de visibilidade calculados pela geometria final. Repor bebidas atualiza apenas o grupo que mudou.

`tests/retail_render_review.tscn` compara o cenário renderizado com uma referência de 2.030 malhas individuais, a 30 e 144 quadros por segundo de simulação, incluindo pausa e recarga. O limite é 1% dos pixels com diferença de cor acima de 20/255. Os registros finais em `fixes_v031` informam os resultados. As capturas foram inspecionadas; o cenário aparece completo. Não se trata de uma medição de desempenho da R7.

A falha integral da captura enviada não foi reproduzida em Mesa llvmpipe. A correção retira o caminho de instancing dos objetos afetados. O pacote Windows continua sem execução em Windows real; não se certifica compatibilidade oficial com Windows 7.

## Exportação e repetição

Preset Windows Desktop, Godot 4.4.1, x86_64: release de `.exe` + `.pck`. O pacote inclui recursos de movimento e diálogo, cenas, scripts, modelos, texturas e sons. Ferramentas, testes, documentos e originais de alta resolução ficam fora do Windows.

O preset Linux QA inclui a suíte para verificar os recursos empacotados. Registros finais: `test_result.txt` (projeto) e `packed_test_result.txt` (Linux exportado). O ZIP Windows e seu SHA-256 estão em `downloads/windows`.

O executável Windows **não foi executado nesta máquina Linux**. Não foram medidos FPS de hardware real ou validados Windows 7/8. O display virtual avisa que não permite controlar V-Sync. No sandbox, o editor headless também registra falha ao abrir seus listeners de depuração; a exportação termina e o pacote Linux passa na integração. Esses registros não são erros de GDScript do jogo.

`tools/setup_cloud.sh` prepara importação e templates; não regenera originais. `tools/test.sh` remove os saves temporários ao terminar. As animações são procedurais e ainda pedem acabamento artístico em dedos, giros, contatos e atendimento; não há rig facial ou captura de movimento.
