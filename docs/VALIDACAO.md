# Validação — 28/10/2026

## Ambiente

Godot **4.4.1.stable.official.49a5bc7b6**, Linux x86_64. Runtime Compatibility / OpenGL 4.5 por Mesa llvmpipe em display virtual Xorg. Blender 4.3.2, renderização Cycles CPU. O arquivo do editor e os templates oficiais foram conferidos contra os SHA-512 publicados no release Godot 4.4.1; TLS permaneceu habilitado.

Revisão 0.2: cenário reconstruído, 60 verificações e imagens comparativas em [depot_v02](depot_v02/README.md).

## Integração executada

Comando: `./tools/test.sh`. Resultado da revisão final do projeto: **60/60 verificações passaram**, saída 0, sem erro de GDScript ou avisos de objetos de áudio retidos na finalização. O teste roda em save isolado e percorre o fluxo real, não apenas a existência de arquivos.

Cobertura:

- Cena principal e física do chão; seis rigs importados, materiais e texturas dos três protagonistas.
- Entrada WASD, corrida comparada à caminhada, agachamento e colisão reduzida.
- Eventos de roda e movimento de mouse encaminhados à viewport; não só atribuição de distância em script.
- SpringArm bloqueado por parede e transição contínua até primeira pessoa/volta.
- Alvo acessível sobre o balcão e tecla E iniciando o diálogo com Felps.
- Porta bloqueando/desbloqueando passagem física.
- Caixas presas ao ponto de transporte, duas reposições e colocação persistente no palete.
- Rejeição de caixa errada e bloqueio do aviso antes das condições narrativas.
- Clientes atravessando a rua/loja com física, seleção, caixa, pagamento e saída; os sete estados do ciclo são observados, sem pular waypoints.
- Aviso posterior às tarefas e às duas primeiras compras, diálogo, ruído e inspeção final.
- Gravação/restauração do checkpoint, posição, caixas consumidas e pausa do relógio.

Os clientes foram simulados com tempo acelerado no teste; a velocidade normal permanece no jogo. A geometria de câmera foi conferida por física e imagens; isso não substitui um playtest extensivo de todos os cantos do mapa.

## Revisão dos assets

`tools/validate_rigs.py` reimportou os GLBs exportados no Blender, aplicou idle, caminhada, corrida, agachamento e transporte, verificou coordenadas finitas e limites de deformação e gerou folhas de poses. As folhas foram inspecionadas visualmente para os três protagonistas. Pesos sem vértices não vinculados: zero. A revisão não certifica todas as poses possíveis nem todos os clipes solicitados para a campanha; animações procedurais ainda pedem acabamento e contato fino dos pés/mãos.

SHA-256 dos três GLBs originais comparado com os uploads: arquivos idênticos, registrados em `original_checksums.json`. As fotografias e o briefing também foram preservados.

Capturas reais desta versão em `screens/`: menu, entrada, área de vendas, vista da frente, estoque e clientes. `screens/rig_Dery.png`, `rig_Felps.png` e `rig_Enemy.png` mostram, da esquerda para a direita, idle, caminhada, corrida, agachamento e transporte.

## Exportação

Preset **Windows Desktop**, Godot 4.4.1, x86_64: exportação release de `.exe` + `.pck`. O PCK inclui `resources/warning.json`, cenas, scripts, modelos, texturas e sons; ferramentas, testes e originais de alta resolução ficam fora do pacote Windows.

Um segundo preset **Linux QA** inclui a suíte de integração para conferir os recursos empacotados, além da execução a partir do projeto. O resultado dessa execução é registrado em `packed_test_result.txt`.

O executável Windows **não foi executado** nesta máquina Linux. Não foram medidos FPS de hardware real, validada compatibilidade Windows 7/8 ou realizada publicação do ambiente. O driver virtual emitiu aviso de ausência de controle de V-Sync; isso não é erro de GDScript. A importação headless inicial também emitiu avisos de thumbnails do renderer dummy; a revisão gráfica posterior carregou os assets.

## Repetição e registros

`tools/setup_cloud.sh` foi executado após a instalação e novamente usado para preparar as exportações. A importação é repetível; não regenera nem sobrescreve modelos originais. `tools/test.sh` guarda saves apenas em um diretório temporário removido ao final. Nenhuma credencial extra é necessária.

Registros da execução final do projeto em `test_result.txt`; da exportação Linux em `packed_test_result.txt`; informações quantitativas dos rigs em `rig_report.json` e `rig_validation.json`.
