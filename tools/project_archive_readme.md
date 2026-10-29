# The Last Sale — projeto Godot 0.10.0

1. Extraia este ZIP em uma pasta nova.
2. No Godot **4.4.1**, clique em **Importar** e escolha `project.godot`.
3. Aguarde a importação dos modelos e texturas.
4. Pressione **F5** e escolha **Iniciar expediente**.

Os modelos animados, cenários, sons, texturas, código, testes e ferramentas estão incluídos. Blender não é necessário para abrir ou jogar o projeto. O renderizador é Compatibility / OpenGL.

O novo elenco inclui Dery, Felps, Killer, Bryan, Zirico, Garota 1, Garota 2 e Velha 1. Carro 1 substitui o hatch estacionado. Os FBX de origem completos podem ser obtidos no [pacote fornecido pelo autor](https://drive.google.com/file/d/1qogHQIpLHR2YuTVj_vi3I2FP-i-Qapxe/view); só são necessários para refazer a conversão das malhas e animações.

O ZIP contém as derivações prontas para Godot. Os arquivos de origem das versões antigas, fotografias e galerias históricas permanecem no [repositório GitHub](https://github.com/Deriby/TheLastSale). A revisão atual, a prévia de movimento e os relatórios estão em `docs/cast_v010`.

## Controles

- WASD e mouse: mover e olhar.
- Shift: correr. Ctrl: agachar.
- Roda do mouse: aproximar até primeira pessoa ou afastar.
- E: interagir. Q: soltar caixa. Espaço: avançar diálogo.
- Esc: pausar e configurar. F: lanterna após o aviso narrativo.

Converse com Felps no balcão esquerdo para iniciar as tarefas. Reponha duas caixas, guarde a caixa solta e acompanhe as visitas e o ruído no estoque. Bryan e Zirico têm conversas opcionais.

## Validação e edição

106/106 testes passaram em Linux no projeto e no pacote exportado. Em Linux, `./tools/test.sh` roda a suíte; `./tools/godot.sh` usa a Godot instalada no ambiente de desenvolvimento. Em outra máquina, abra o projeto pelo editor ou defina `GODOT_BIN` com o caminho do motor.

A Godot 4.4 tem Windows 10 como requisito oficial mínimo. Windows 7/Radeon R7 não foram validados nativamente. Em uma máquina compatível, o modo **Econômica** reduz a resolução, as sombras e os mapas normais.

O arquivo `PROJETO_MANIFESTO.json` registra o SHA-256 dos arquivos deste ZIP. Caches `.godot`, saves, arquivos Git e exportações para Windows não fazem parte deste pacote.
