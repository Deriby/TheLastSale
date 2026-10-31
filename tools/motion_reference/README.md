# Referência de animação

Animações de Quaternius (CC0 1.0), Universal Animation Library Standard. A licença permite uso e adaptação comercial. Os dados incluem apenas poses e contato das solas; os modelos do jogo continuam próprios.

Para reproduzir a extração, baixe o pacote Standard no site do autor ou no OpenGameArt e execute `python tools/extract_motion_reference.py caminho/AnimationLibrary_Godot_Standard.glb` (numpy/scipy, etapa offline). Depois, execute `tools/bake_natural_motion.tscn` no Godot 4.4.1. Para jogar, essas dependências não são necessárias.

A origem e o SHA-256 do GLB estão em `quaternius.json`. A transferência usa rotações relativas à pose de referência, conserva os comprimentos originais e adapta cada sapato por skinning de CPU.
