# Validação — revisão 0.6.0 — 28/10/2026

## Ambiente

Godot **4.4.1.stable.official.49a5bc7b6**, Linux x86_64. Runtime Compatibility / OpenGL 4.5 por Mesa llvmpipe em display virtual Xorg. Blender 4.3.2, renderização Cycles CPU. O editor e os templates oficiais foram conferidos contra os SHA-512 publicados no release Godot 4.4.1.

Esta revisão trabalha a iluminação noturna, sombras, céu, materiais da rua, carros e folhagem, além de áudio espacial e passos. Imagens e caminhada com controle real em [mood_v06](mood_v06/README.md). O registro do balcão está em [scene_v05](scene_v05/README.md), e o exterior anterior em [exterior_v04](exterior_v04/README.md). Os rigs e a correção dos equipamentos da revisão 0.3.1 foram mantidos; seu registro está em [fixes_v031](fixes_v031/README.md). O registro do novo Felps está em [characters_v03](characters_v03/README.md), e a reconstrução do interior em [depot_v02](depot_v02/README.md).

## Integração

`./tools/test.sh`: **83/83 verificações passaram**, saída 0. O preset Linux QA exportado também executou **83/83**, saída 0, iniciado fora da pasta do projeto com `--main-pack` apontando ao PCK exportado. As duas execuções usam saves temporários e percorrem o fluxo real com física, sem erros de GDScript ou objetos retidos na finalização.

Cobertura:

- Cena principal, chão físico, seis rigs importados, materiais e texturas.
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
- Passos no piso cerâmico e troca para contato de exterior após movimento real do jogador; cabeça em modo apenas de sombra na primeira pessoa, com retorno ao desenho normal ao afastar a câmera.

Os clientes são simulados com tempo acelerado no teste; a velocidade normal permanece no jogo. A câmera foi conferida por física e por capturas. Isso não substitui um playtest extensivo de cada canto do mapa.

## Rigs e movimentos

Os assets de personagens não foram alterados na 0.6.0. A cabeça de Deryk usa desenho apenas na sombra em primeira pessoa, para preservar a sombra completa sem aparecer dentro da câmera; a visibilidade normal retorna em terceira pessoa. Felps mantém o clipe de trabalho existente e a orientação ao balcão esquerdo. Os testes de integração acima foram repetidos; as medições Blender e gravações desta seção são o registro da revisão 0.3.1.

`tools/rig_characters.py` deriva Deryk e Felps a partir dos originais, mantendo UVs e a identidade dos modelos. Os dois têm 21 ossos, com cintura e peito superior articulados, pesos normalizados sem vértices sem influência, duas malhas de renderização (cabeça/corpo), aproximadamente 12 mil triângulos e texturas de cor 1024². Enemy e os três clientes mantêm os assets anteriores.

`tools/validate_rigs.py` reimporta os GLBs, verifica deformações finitas e limites de volume e renderiza repouso, caminhada, corrida, agachamento e transporte. As folhas finais foram inspecionadas para Deryk, Felps e Enemy. Dados: `rig_report.json` e `rig_validation.json`. `tools/review_anatomy.py` também mede os braços exportados e produz a comparação com os ossos reais em `fixes_v031/anatomy_bones.png`.

`tools/measure_motion.py` amostra 41 instantes de 13 clipes em cada um dos dois protagonistas: 1.066 poses. Todas as deformações amostradas são finitas. A maior penetração da sola foi 7,4 mm; o maior afastamento do piso durante apoio amostrado foi 11,2 mm. O limite de regressão de penetração é 12 mm. São medidas em piso plano, sem certificar todo giro ou terreno. Resultados por clipe em `characters_v03/motion_metrics.json`.

`tests/motion_review.tscn` gravou 38 segundos do controlador real, com os modelos se deslocando sobre piso marcado. A revisão também capturou Felps no caixa, transporte, primeira pessoa e corredor no jogo completo. Vídeo e GIFs atuais estão em `fixes_v031`; a execução gráfica final não apresentou erros de script.

SHA-256 dos originais ativos em `original_checksums.json`. Deryk e Enemy permanecem idênticos aos uploads anteriores. O novo Felps é idêntico ao upload desta revisão; o Felps substituído permanece integralmente arquivado. Histórico em `characters_v03/source_history.json`.

## Renderização dos equipamentos

O relato do usuário é em Windows 7 / Radeon R7 200 series. As malhas estáticas agrupadas substituem MultiMesh em todas as geladeiras, gôndolas, produtos e demais lotes de cenário. São renderizadas sem interpolação física, com limites de visibilidade calculados pela geometria final. Repor bebidas atualiza apenas o grupo que mudou.

`tests/retail_render_review.tscn` compara o cenário renderizado com malhas individuais, incluindo pausa e recarga. Na 0.6.0 foi repetido no pacote Linux exportado, a 144 quadros por segundo de simulação, com **4.083 malhas independentes**. Em resolução Nítida foram 16 pixels diferentes em 921.600 (**0,00174%**); em Retrô, 4 em 230.400 (**0,00174%**). Ambos ficam abaixo do limite de 1% com diferença de cor acima de 20/255. Registros em [mood_v06](mood_v06/README.md). Os resultados anteriores estão preservados em `fixes_v031`, `exterior_v04` e `scene_v05`. As capturas foram inspecionadas; os equipamentos aparecem completos. Não se trata de uma medição de desempenho da R7.

A falha integral da captura enviada não foi reproduzida em Mesa llvmpipe. A correção retira o caminho de instancing dos objetos afetados. O pacote Windows continua sem execução em Windows real; não se certifica compatibilidade oficial com Windows 7.

## Exterior

`tests/exterior_review.tscn` capturou seis vistas do pacote Linux: fachada e casas em frente à noite; fachada, casas, descida e subida com iluminação diurna de comparação. `tests/exterior_walkthrough.tscn` gravou 32 segundos com câmera de revisão no cenário noturno exportado. A ferramenta diurna não altera a cena normal do jogo. Os registros e as imagens estão em `exterior_v04`.

Foram conferidos o anexo baixo, as duas entradas principais, a continuidade de parede/cobertura, o mural e os imóveis distintos dos dois lados da rua. Texturas distantes usam mipmaps, mantendo o filtro de baixa resolução. Postes, fios e detalhes arquitetônicos usam malhas estáticas agrupadas por material, sem MultiMesh. As dimensões e partes não fotografadas são aproximações descritas em [REFERENCIAS.md](REFERENCIAS.md).

Na 0.5.0, `tests/scene_review.tscn` captura 13 vistas do pacote: balcão do cliente/funcionário, tampo, gaveta, interior/rua, salão, fachada, subida/descida e comparação com/sem neblina junto ao limite. A neblina é de profundidade em Compatibility, de 22 a 68 m; o chão continua até ±160 m, além do trecho explorável. A comparação foi inspecionada para verificar o desaparecimento gradual dos volumes distantes.

`tests/scene_walkthrough.tscn` grava 30 segundos do cenário em execução com câmera de revisão, ventilador, rotina de Felps e sons ambientes originais. O vídeo não simula entrada do jogador. A qualidade inicial usa a resolução da janela; os modos Retrô e Econômica continuam selecionáveis, e configurações anteriores são preservadas. Detalhes, imagens e fontes em `scene_v05`.

## Iluminação e caminhada — 0.6.0

`tests/scene_review.tscn` capturou 16 vistas do pacote atual, incluindo carro, varanda e casas opostas. A mesma cena foi repetida em Econômica: cinco luzes com sombras em Nítida e zero em Econômica, conforme os registros. O modo Econômica também desliga o halo de câmera. A geometria exterior usa uma camada de iluminação separada da luz de preenchimento interna; a transição das áreas iluminadas no asfalto foi inspecionada. Materiais da rua e céu usam arte original, com mipmaps nas superfícies e folhas.

`tests/mood_walkthrough.tscn` dirige o controlador real por entradas de movimento durante 34 segundos, usando sua câmera de primeira pessoa e áudio espacial. A verificação cobre saída sobre os meios-fios, descida até aproximadamente x=-12 m, retorno e aproximação da entrada: **4/4 pontos passaram**. Não há câmera livre, salto de waypoint ou teletransporte durante o trajeto. É um percurso automatizado, não um playtest manual. Registro e vídeo em `mood_v06`.

A copa usa folhas recortadas e movimento leve que respeita a pausa. Os carros têm carroceria inclinada e recortes das rodas. Sombras de postes e loja, janelas iluminadas, neblina e halos foram verificados nas capturas e no vídeo. As luzes noturnas são interpretação artística das referências diurnas; não houve medição fotométrica do local.

## Exportação e repetição

Preset Windows Desktop, Godot 4.4.1, x86_64: release de `.exe` + `.pck`. O pacote inclui recursos de movimento e diálogo, cenas, scripts, modelos, texturas e sons. Ferramentas, testes, documentos e originais de alta resolução ficam fora do Windows.

O preset Linux QA inclui a suíte para verificar os recursos empacotados. Registros finais: `test_result.txt` (projeto) e `packed_test_result.txt` (Linux exportado). O ZIP Windows e seu SHA-256 estão em `downloads/windows`.

O executável Windows **não foi executado nesta máquina Linux**. Não foram medidos FPS de hardware real ou validados Windows 7/8. O display virtual avisa que não permite controlar V-Sync. No sandbox, o editor headless também registra falha ao abrir seus listeners de depuração; a exportação termina e o pacote Linux passa na integração. Esses registros não são erros de GDScript do jogo.

O log de integração do projeto contém avisos de interpolação em caixas e na dobradiça de uma geladeira durante atualizações/cargas fora do passo físico. Posições persistentes, portas e restante do fluxo passaram; os avisos não são falhas de script. Não se atribuem esses avisos ao defeito visual relatado na R7.

`tools/setup_cloud.sh` prepara importação e templates; não regenera originais. `tools/test.sh` remove os saves temporários ao terminar. As animações são procedurais e ainda pedem acabamento artístico em dedos, giros, contatos e atendimento; não há rig facial ou captura de movimento.
