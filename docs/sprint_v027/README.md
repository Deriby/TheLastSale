# 0.27.0 — caminhada e corrida de Deryk e Felps

[Vídeo: antes, depois e corrida dentro da loja](https://github.com/Deriby/TheLastSale/raw/refs/heads/main/docs/sprint_v027/sprint_comparison.mp4) · [Projeto Godot 4.4.1](https://github.com/Deriby/TheLastSale/raw/refs/heads/main/downloads/project/TheLastSale_Godot_0.27.0.zip)

A corrida dos protagonistas foi refeita com curvas próprias de apoio, impulso, recuperação do pé e movimento de braços. O tronco usa uma inclinação menor e o quadril percorre um arco contínuo. As pernas alternam a mesma passada com meio ciclo de diferença; a altura e o comprimento dos membros mantêm a cadência própria de cada modelo.

![Corrida revisada](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/sprint_v027/run.png)

Na 0.26.0, o quadril variava cerca de **12 cm em Deryk e 13 cm em Felps** por ciclo. O pé podia girar aproximadamente **48° e 43° entre quadros**, calculados a 30 FPS e 3,9 m/s. Na revisão, o arco vertical é de **2,4 cm e 2,7 cm**, e o maior giro do pé por quadro fica próximo de **21° e 20°**. Os dados de cada personagem estão em [antes/depois](before_after.json) e [métricas da revisão](gait_metrics.json).

O cálculo anterior podia abaixar o corpo inteiro para satisfazer a posição de um pé que estava no ar. Agora a altura do corpo é ajustada uma vez para o apoio; o pé em recuperação ganha espaço sem puxar o osso raiz para baixo. As curvas de deslocamento mantêm posição, velocidade e aceleração contínuas nas junções. O pé apoiado recua na mesma velocidade em que o corpo avança.

A corrida também deixa de usar as âncoras horizontais da caminhada. O ajuste de terreno atua no apoio, preservando a perna no ar. Velocidades diferentes para entrar e sair da corrida evitam alternar clipes repetidamente quando a velocidade oscila perto de 2,55 m/s. A caminhada normal e o recuo dos protagonistas receberam o mesmo tratamento da trajetória dos pés.

O vídeo começa com a corrida publicada na **0.26.0**, mostra a revisão em deslocamento contínuo, incluindo transições e parada, e termina com **entrada real de W/Shift, colisões, câmera e HUD no depósito**, usando os dois protagonistas. A gravação exige mais de 1,3 segundo de corrida acima de 3,4 m/s para cada personagem. Captura a 30 FPS em Godot 4.4.1/Linux/Mesa llvmpipe; a interpolação de física fica ligada. O desempenho em Radeon R7 não foi medido.

Os testes novos medem a variação vertical, o giro de pés/joelhos entre quadros, o osso raiz, a velocidade de apoio, a troca de clipes e a interferência das âncoras. Essas medidas verificam defeitos concretos; o vídeo permite avaliar o resultado visual. [Validação](validation.json) · [Verificação do ZIP e resultados completos](../../downloads/project/release_verification.json).

Modelos, malhas, materiais, texturas, pesos, física, câmera, controles, inventário, ações de caixas, energia, saves, shaders PS1, intro e menu foram preservados. As nove bibliotecas dos outros personagens continuam idênticas às da 0.26.0. Para jogar, extraia em uma pasta nova, importe `project.godot` no Godot 4.4.1 e pressione F5. O ZIP contém apenas o projeto do editor, sem EXE.

As curvas ficam prontas em `resources/motion/`. `tools/protagonist_stride.gd` é uma ferramenta offline; para regenerar apenas esses dois rigs, execute `tools/bake_natural_motion.tscn` com `MOTION_ACTORS=Dery,Felps`. O jogador não precisa instalar Python ou Blender. As referências do tronco continuam usando Quaternius/CC0; licença e origem permanecem em `tools/motion_reference/`.
