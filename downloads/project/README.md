# Projeto Godot — 0.14.0

**[Baixar TheLastSale_Godot_0.14.0.zip](https://github.com/Deriby/TheLastSale/raw/refs/heads/main/downloads/project/TheLastSale_Godot_0.14.0.zip)**

Extraia em uma pasta nova, importe `project.godot` no **Godot 4.4.1**, aguarde a importação dos recursos e pressione **F5**.

[Veja a iluminação e as comparações](../../docs/lighting_v014/README.md). As correções de teto, sombras e circulação da 0.12.0 continuam presentes. A falha para largar caixas está [registrada para a etapa de jogabilidade](../../docs/PENDENCIAS.md).

132/132 verificações passaram no projeto e em uma extração limpa do ZIP. [Registro de integridade e importação](release_verification.json).

O ZIP contém modelos animados, cenário, sons, texturas, scripts, testes e ferramentas. O limite padrão continua em 30 FPS, com efeitos simplificados em Econômica. O [relatório de otimização](../../docs/optimization_v011/README.md) descreve as reduções de dados e a meta de 30 FPS. As galerias anteriores permanecem no GitHub, incluindo o elenco e a prévia animada em [docs/cast_v010](../../docs/cast_v010/README.md). Os originais FBX ficam no pacote de origem fornecido pelo autor; as derivações necessárias ao Godot já estão incluídas.

[Ver SHA-256](TheLastSale_Godot_0.14.0.sha256). O próprio ZIP inclui `PROJETO_MANIFESTO.json`, com os hashes dos arquivos. Para gerar novamente: `python3 tools/package_project.py`.
