# The Last Sale — projeto Godot 0.16.0

1. Extraia este ZIP em uma pasta nova.
2. No Godot **4.4.1**, clique em **Importar** e escolha `project.godot`.
3. Aguarde a importação dos modelos e texturas.
4. Pressione **F5** e escolha **Iniciar expediente**.

Os modelos animados, cenários, sons, texturas, código, testes e ferramentas estão incluídos. Blender não é necessário para abrir ou jogar o projeto. O renderizador é Compatibility / OpenGL.

O padrão é 30 FPS. Em Configurações, escolha 30 FPS, 60 FPS ou Sem limite. A otimização da geometria está descrita em `docs/optimization_v011`. A estabilidade de 30 FPS precisa de teste no PC alvo.

Para o visual retrô, abra **Configurações → Resolução interna / qualidade** e escolha **PS1 — 320×240 (4:3)** ou **PS1/2 — 640×480 (4:3)**. A janela continua grande e os menus mantêm a resolução normal. Na janela de 1280×720, ambos ocupam 960×720 com barras laterais. A opção PS1/2 aumenta a definição sem diminuir a imagem. A escolha fica salva. Veja as instruções gráficas da 0.15.1 no GitHub; os modos continuam presentes.

**Tab** alterna entre **Deryk** (caixas/reposição) e **Felps** (balcão). Os dois mantêm posição, câmera e objetos. O personagem inativo conserva suas animações. A troca aguarda o fim de conversas e ações de movimentar caixas.

**Q** apoia a caixa na marca verde; uma marca vermelha indica falta de apoio ou espaço. Apertar Q durante a pegada agenda a soltura. A caixa permanece no cenário, em pé, com colisão, e pode ser pega novamente. O salvamento conserva as caixas soltas e carregadas, inclusive com o outro personagem ativo.

O cliente aguarda **Felps usar E no balcão**. Deryk continua responsável pela reposição. Este atendimento inicial usa as compras e conversas existentes; dinheiro/troco, cartão e Pix ficam para a próxima etapa. Veja `docs/gameplay_v016`.

O painel de Configurações tem altura limitada e rolagem. A iluminação da 0.14.0 e os materiais da 0.13.0 continuam presentes. Os créditos das bases CC0 ficam em `resources/material_sources/LICENSE.md`.

As correções da 0.12.0 foram preservadas: fiação sem sombras, teto baixo até os fundos, engradados apoiados e passagem diante das geladeiras. Use E para abrir e fechar as portas.

O relato de não conseguir largar a caixa foi corrigido nesta etapa. O histórico e as próximas mecânicas ficam em `docs/PENDENCIAS.md`.

O novo elenco inclui Dery, Felps, Killer, Bryan, Zirico, Garota 1, Garota 2 e Velha 1. Carro 1 substitui o hatch estacionado. Os FBX de origem completos podem ser obtidos no [pacote fornecido pelo autor](https://drive.google.com/file/d/1qogHQIpLHR2YuTVj_vi3I2FP-i-Qapxe/view); só são necessários para refazer a conversão das malhas e animações.

O ZIP contém as derivações prontas para Godot, a galeria de jogabilidade e o relatório de otimização. Os arquivos de origem das versões antigas, fotografias, galerias históricas e a prévia de movimento do elenco permanecem no [repositório GitHub](https://github.com/Deriby/TheLastSale). Todos os modelos usados no jogo estão incluídos.

## Controles

- WASD e mouse: mover e olhar.
- Shift: correr. Ctrl: agachar.
- Roda do mouse: aproximar até primeira pessoa ou afastar.
- E: interagir/atender com Felps. Q: apoiar caixa. Tab: trocar Felps/Deryk. Espaço: avançar diálogo.
- Esc: pausar e configurar. F: lanterna após o aviso narrativo.

Converse com Felps no balcão esquerdo para iniciar as tarefas. Reponha duas caixas, guarde a caixa solta e acompanhe as visitas e o ruído no estoque. Bryan e Zirico têm conversas opcionais.

## Validação e edição

168/168 testes passaram em Linux no projeto e no ZIP extraído. Em Linux, `./tools/test.sh` roda a suíte; `./tools/godot.sh` usa a Godot instalada no ambiente de desenvolvimento. Em outra máquina, abra o projeto pelo editor ou defina `GODOT_BIN` com o caminho do motor.

A Godot 4.4 tem Windows 10 como requisito oficial mínimo. Windows 7/Radeon R7 não foram validados nativamente. Em uma máquina compatível, o modo **Econômica** reduz a resolução, as sombras e os mapas normais.

O arquivo `PROJETO_MANIFESTO.json` registra o SHA-256 dos arquivos deste ZIP. Caches `.godot`, saves, arquivos Git e exportações para Windows não fazem parte deste pacote.
