# 0.25.0 — locomoção corrigida e personalidades do elenco

**[Ver as animações e a caminhada dentro do jogo](https://github.com/Deriby/TheLastSale/raw/refs/heads/main/docs/motion_v025/motion_preview.mp4)**

Os modelos, materiais, texturas e pesos das malhas foram preservados. As novas bibliotecas alteram poses e cadência; não mudam os corpos de colisão nem as velocidades dos personagens.

![Deryk e Felps](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/motion_v025/profile_0.png)

## Estilos

- **Deryk e Felps:** passos próprios, braços e tronco com respostas distintas; caminhada, corrida, repouso e transporte.
- **Garota 1 e Garota 2:** caminhadas de cadência e balanço diferentes, respeitando as proporções de cada modelo.
- **Homens:** três perfis de clientes, agora no mesmo controlador medido das personagens importadas, incluindo as seis identidades provisórias e o cliente do aviso.
- **Zirico:** base mais larga, oscilação irregular de quadril/tronco, cabeça atrasada e braços de equilíbrio.
- **Bryan:** passos curtos, cadência infantil, gestos inquietos, movimento de cabeça e gesto de mão junto ao rosto.
- **Senhora:** passos curtos e baixos, postura mais inclinada e balanço contido. O inimigo continua usando seu próprio rig e seus clipes originais de ataque.

![Zirico](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/motion_v025/profile_2.png)
![Bryan](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/motion_v025/profile_3.png)

## Erros corrigidos

Vários clientes homens ignoravam as bibliotecas de movimento novas. Além disso, a passada usava a velocidade pretendida mesmo quando uma parede bloqueava o corpo. Clientes e conhecidos agora usam a distância horizontal realmente percorrida: param a passada ao ficar bloqueados e voltam ao abrir o caminho.

O código de clientes também convertia gestos finitos de repouso em loops. Essa conversão foi removida: a variação termina e o personagem retorna ao repouso. Nas trocas de clipe, os apoios antigos dos pés são limpos e a correção horizontal entra/sai suavemente, com limite proporcional ao tamanho do personagem.

As poses são geradas offline para cada rig; o jogo carrega bibliotecas prontas, sem executar o autor de poses a cada quadro. Pegar, colocar, largar caixas e atacar conservam os clipes e tempos originais. Física do jogador, controles, navegação, limites de velocidade, inventário, energia, saves e a correção de texturas PS1 permanecem preservados.

## Validação

São **587 verificações em nove suítes**. A checagem de contato testa os 11 modelos por skinning de CPU independente, usando os pesos reais das malhas, com tolerância de 2,5 cm. Os testes de locomoção verificam ciclos sem salto de posição, diferenças de movimento, todos os clientes homens, o cliente do aviso, Bryan e Zirico bloqueados por uma parede, retomada do caminho e término dos gestos de repouso.

[Dados](validation.json) · [Métricas de movimento](kinematic_metrics.json) · [Contato das solas](sole_contact.json) · [Verificação do ZIP](../../downloads/project/release_verification.json)

A prévia usa os controladores publicados: primeiro em um palco com colisões, depois com Deryk e Felps no depósito, usando entrada real de movimento, câmera e HUD do jogo. Gravação em Godot 4.4.1, Linux/Mesa llvmpipe e 15 FPS; o trecho dentro do jogo usa a qualidade Retrô. O limite padrão continua em 30 FPS. FPS nativo na Radeon R7 não foi medido.

Para jogar, basta importar o projeto no Godot 4.4.1 e pressionar F5. Os clipes prontos ficam em `resources/motion/` e os perfis em `resources/locomotion_profiles.json`. Blender não é necessário. Para regenerar as bibliotecas, execute `tools/bake_natural_motion.tscn`. O ZIP continua sendo o projeto do editor, sem EXE. Os vídeos ficam no GitHub para manter o pacote abaixo de 100 MiB.
