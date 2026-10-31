# 0.26.0 — nova base das animações

[Ver a prévia](https://github.com/Deriby/TheLastSale/raw/refs/heads/main/docs/motion_v026/motion_preview.mp4) · [Baixar o projeto Godot 4.4.1](https://github.com/Deriby/TheLastSale/raw/refs/heads/main/downloads/project/TheLastSale_Godot_0.26.0.zip)

As poses centrais de caminhada, corrida, repouso, agachamento e conversa foram refeitas com animações de referência da **Universal Animation Library Standard, de Quaternius (CC0)**. São transferidas para os 11 rigs existentes; modelos, roupas, texturas e pesos permanecem byte a byte iguais. Não há troca dos personagens por manequins.

![Deryk e Felps](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/motion_v026/profile_0.png)

A transferência conserva os comprimentos dos membros e adapta o apoio à sola de cada sapato por skinning de CPU. A corrida tem fase aérea própria. O controlador usa contatos amostrados da referência, em vez de supor a mesma janela fixa para qualquer passada, e limita a estabilização horizontal a 2,5 cm proporcionais à altura. O recuo percorre o ciclo ao contrário, com os pés acompanhando o deslocamento para trás.

Nos três clientes modulares, o pivô do rig estava em x=0,258 m, enquanto a manga começa em x=0,13 m. Girar nesse ponto erguia parte da manga junto à cabeça. A biblioteca agora compensa o pivô para manter a manga presa ao ombro, sem alterar a malha ou os pesos.

Deryk e Felps usam referências de caminhada e posturas diferentes. Garotas e homens têm variações de cadência e postura; a senhora usa passos menores. Zirico acrescenta deslocamento lateral, desequilíbrio de tronco/cabeça e braços abertos. Bryan usa passos proporcionais ao corpo, braços mais ativos e gestos frequentes. As ações de pegar, colocar, largar caixas e atacar conservam seus clipes e tempos originais.

![Garotas e cliente](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/motion_v026/profile_1.png)
![Zirico](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/motion_v026/profile_2.png)
![Bryan](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/motion_v026/profile_3.png)

A prévia mostra deslocamento com colisões e câmera por vários ângulos, seguido de caminhada dentro do depósito com o controlador, câmera e HUD do jogo. Gravação a 30 FPS em Linux/Mesa llvmpipe. A interpolação de física permanece ativa. O desempenho em hardware Radeon R7 não foi medido.

[Validação](validation.json) · [Contato das solas](sole_contact.json) · [Métricas de movimento](kinematic_metrics.json) · [Verificação do ZIP](../../downloads/project/release_verification.json)

As verificações cobrem a campanha, física, caixas, energia, saves, piso PS1 e menu. Regressões novas verificam a manga dos três clientes e o sentido da passada para trás. Testes numéricos delimitam defeitos; a prévia permite avaliar o resultado visual.

Para jogar, importe `project.godot` no Godot 4.4.1 e pressione F5. Não é necessário Blender, Python ou baixar animações. O jogo carrega bibliotecas prontas; a retargetagem é offline. A ferramenta, dados de referência e licença ficam em `tools/reference_pose.gd` e `tools/motion_reference/`. Origem: https://quaternius.com/packs/universalanimationlibrary.html — CC0 1.0, https://creativecommons.org/publicdomain/zero/1.0/.

Intro Two Brothers Lab, menu, HUD, texturas PS1, controles, velocidade, colisões, inventário, circuitos de energia e saves foram preservados. O pacote é o projeto do editor, sem EXE; vídeos ficam no repositório para conservar o ZIP abaixo de 100 MiB.
