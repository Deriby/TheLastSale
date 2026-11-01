# Aviso no encerramento da rota

A primeira execução da rota completa no ZIP 0.36.0 terminou com as 29 verificações aprovadas e, depois do resultado, informou que um recurso ainda estava em uso ao encerrar o Godot. O processo do jogo retornou zero; o verificador estrito interrompeu a distribuição para investigar o diagnóstico.

A rota foi repetida por inteiro, com `--verbose`, da mesma extração e do mesmo ZIP. As 29 verificações passaram e o Godot encerrou com código zero, sem a mensagem. O recurso da primeira ocorrência não foi identificado; não é atribuído ao áudio sem evidência. Não houve mudança no projeto entre as duas execuções.

- [Primeira execução](route_initial_attempt.log)
- [Repetição detalhada](route_verbose.log)
- [Resultado da distribuição](../../downloads/project/release_verification.json)

As outras dezenove suítes já tinham passado nessa mesma extração. O verificador retomou esses resultados, conferiu os hashes dos 1.045 arquivos do manifesto e concluiu as 48 verificações renderizadas e as auditorias de estrutura. O aviso inicial continua registrado e não é apresentado como corrigido ou como falha de jogabilidade reproduzida.
