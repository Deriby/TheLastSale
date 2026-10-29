# Projeto Godot — 0.16.0

**[Baixar TheLastSale_Godot_0.16.0.zip](https://github.com/Deriby/TheLastSale/raw/refs/heads/main/downloads/project/TheLastSale_Godot_0.16.0.zip)**

Extraia em uma pasta nova, importe `project.godot` no **Godot 4.4.1**, aguarde a importação dos recursos e pressione **F5**.

**Tab** troca entre Deryk e Felps. **Q** apoia a caixa, com indicação de espaço livre e comando agendado durante a pegada. **E** atende clientes com Felps no balcão. O salvamento conserva os dois personagens e as caixas. [Controles, capturas e validação](../../docs/gameplay_v016/README.md).

PS1 em 320×240 e PS1/2 em 640×480 continuam em **Configurações → Resolução interna / qualidade**, mantendo a janela grande e os menus em resolução normal. As correções de teto, sombras e circulação foram preservadas. O problema de largar caixas foi corrigido; [histórico e próximas mecânicas](../../docs/PENDENCIAS.md).

168/168 verificações passaram no projeto e em uma extração limpa do ZIP. [Registro de integridade e importação](release_verification.json).

O ZIP contém modelos animados, cenário, sons, texturas, scripts, testes e ferramentas. O limite padrão continua em 30 FPS, com efeitos simplificados em Econômica. O [relatório de otimização](../../docs/optimization_v011/README.md) descreve as reduções de dados e a meta de 30 FPS. As galerias anteriores permanecem no GitHub, incluindo o elenco e a prévia animada em [docs/cast_v010](../../docs/cast_v010/README.md). Os originais FBX ficam no pacote de origem fornecido pelo autor; as derivações necessárias ao Godot já estão incluídas.

[Ver SHA-256](TheLastSale_Godot_0.16.0.sha256). O próprio ZIP inclui `PROJETO_MANIFESTO.json`, com os hashes dos arquivos. Para gerar novamente: `python3 tools/package_project.py`.
