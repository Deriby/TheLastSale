# Veículos originais — 0.7

`sedan.blend` e `hatchback.blend` contêm os modelos editáveis gerados pelo script. Não dependem de modelos externos. O jogo importa os arquivos GLB em `assets/models/environment`; o preset exclui esta pasta de ferramentas.

Para regenerar, na raiz do projeto com Blender 4.3+:

```sh
blender -b -t 4 --python-exit-code 1 --python tools/model_neighborhood_cars.py -- "$PWD"
```

O comando grava os dois arquivos Blender, os GLBs e `docs/vehicle_report.json`. A unidade é o metro, e a frente do veículo aponta para +X. A Godot converte o eixo vertical do glTF e gera LODs na importação. `scripts/world/neighborhood_car.gd` instancia cada modelo, adapta a inclinação ao terreno, configura o vidro e acrescenta colisão.
