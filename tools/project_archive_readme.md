# The Last Sale — projeto Godot 0.17.0

1. Extraia este ZIP em uma pasta nova.
2. No Godot **4.4.1**, clique em **Importar** e escolha `project.godot`.
3. Aguarde a importação dos modelos e texturas.
4. Pressione **F5** e escolha **Iniciar expediente** para testar a rotina completa.

Modelos animados, cenários, sons, texturas, código, testes e ferramentas estão incluídos. Blender não é necessário para jogar. O renderizador é Compatibility / OpenGL.

## Atendimento

**Tab** alterna Deryk/Felps. Deryk cuida das caixas e reposição; Felps atende no balcão por **E**. **Espaço** avança as falas. Na frente de caixa, registre produtos/quantidades, receba o dinheiro, separe o troco e entregue a compra. **Esc** fecha a tela e **Tab** permite chamar Deryk. O pagamento usa dinheiro; cartão e Pix são próximas etapas.

Alguns pedidos exigem uma caixa fechada do estoque. Use **Chamar Deryk**, pegue a caixa do pedido, leve-a ao balcão e entregue com E. Volte a Felps para concluir a venda. Os produtos e valores aparecem no pedido e o total é calculado automaticamente.

O salvamento conserva pedido, cliente, registro, dinheiro recebido e troco parcial, além dos dois personagens e caixas. Checkpoints versões 1 e 2 continuam aceitos. O monitor, a gaveta e os sons acompanham as etapas. Recibos e receita são registrados uma vez por compra concluída. Veja `docs/checkout_v017`.

## Controles e configurações

- WASD e mouse: mover/olhar. Shift: correr. Ctrl: agachar.
- Tab: trocar entre Felps e Deryk. E: interagir e atender.
- Q: apoiar caixa na marca verde; a marca vermelha indica bloqueio. Q durante a pegada agenda a soltura.
- Roda do mouse: aproximar até primeira pessoa ou afastar.
- Espaço: avançar diálogo. Esc: fechar caixa/pausar. F: lanterna após o aviso narrativo.

Converse com Felps para iniciar. Reponha as duas caixas na geladeira e organize a caixa solta. A caixa fechada de um pedido tem identificação própria. Bryan e Zirico têm conversas opcionais.

O limite padrão é 30 FPS. Em Configurações, escolha 30 FPS, 60 FPS ou Sem limite. A estabilidade no PC alvo precisa de teste; veja `docs/optimization_v011`.

PS1 em 320×240 e PS1/2 em 640×480 ficam em **Configurações → Resolução interna / qualidade**. Ambos mantêm a janela grande e os menus em resolução normal. Mantenha a resolução global do projeto em 1280×720.

Materiais e iluminação foram preservados. Créditos CC0 em `resources/material_sources/LICENSE.md`. O histórico do bug de largar caixas, corrigido na 0.16.0, e as próximas mecânicas ficam em `docs/PENDENCIAS.md`.

O elenco inclui Dery, Felps, Killer, Bryan, Zirico, Garota 1, Garota 2 e Velha 1. Os FBX originais ficam no [pacote fornecido pelo autor](https://drive.google.com/file/d/1qogHQIpLHR2YuTVj_vi3I2FP-i-Qapxe/view); as derivações necessárias para jogar já estão incluídas. Galerias históricas permanecem no [GitHub](https://github.com/Deriby/TheLastSale).

## Validação

183/183 verificações passaram em Linux no projeto e no ZIP extraído. `./tools/test.sh` roda a suíte; em outra máquina, abra pelo editor ou defina `GODOT_BIN` com o caminho do motor.

A Godot 4.4 tem Windows 10 como requisito oficial mínimo. Windows 7/Radeon R7 não foram validados nativamente. O modo Econômica reduz resolução, sombras e acabamento dos materiais.

`PROJETO_MANIFESTO.json` registra o SHA-256 dos arquivos. Caches `.godot`, saves, Git e exportações para Windows não fazem parte deste pacote.
