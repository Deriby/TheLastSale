# 0.33.0 — o clímax de domingo

[Prévia real com áudio](domingo_preview.mp4) · [Projeto Godot 4.4.1 sem EXE](../../downloads/project/TheLastSale_Godot_0.33.0.zip).

A prévia mostra quatro cenas separadas, em tempo normal: uma última cabeça entre as caixas; a aproximação do perseguidor; os passos de busca atrás de uma porta; e o ambiente depois da saída antes do epílogo. As posições, a investigação já transcorrida e as condições do final foram preparadas para revisão; os intervalos foram cortados. As legendas explicativas pertencem à captura. A investigação e a fuga completas continuam cobertas pela suíte física de domingo. Use fones para perceber os sons posicionais.

Durante a investigação, os equipamentos mantêm seus circuitos reais e o ar da rua continua audível. Os efeitos ambientais periódicos de cachorro/metal/estalos ficam suspensos nesse trecho. Depois de recuperar o módulo e de pelo menos 75 segundos de investigação, pode haver uma única aparição da cabeça do Enemy original entre as caixas. O corpo fica coberto, o ponto precisa passar pelos testes de visão, chão, espaço e testemunhas; interfaces e pessoas próximas impedem a oportunidade. O jogador pode não vê-la. Ela não acrescenta pista, aviso, música ou fala de confirmação e não atrasa o objetivo se for perdida.

Ao começar a fuga, a cabeça se recolhe antes de o modelo da perseguição ficar visível. A física, o modelo, a animação de ataque, a velocidade e a breve proteção inicial do perseguidor permanecem. A mudança não coloca um NPC circulando no salão. O disparo do disjuntor continua no quadro do estoque, com coordenação curta entre Deryk e Felps; o gerador e a cooperação mantêm as funções originais.

Os passos saem da posição real do assassino apenas quando ele se desloca. Portas e paredes abafam o som, e o volume respeita Efeitos. Depois de perder a visão, a ameaça vai ao último ponto conhecido antes de gastar o tempo da busca local. Ela olha e verifica até três posições alcançáveis a no máximo 2,2 metros daquele ponto, sem consultar a posição atual de quem está escondido. Destinos bloqueados têm limite de tempo. Visão, luz, lanterna, ruído, golpes e cobertura continuam decidindo o perigo real.

O HUD discreto não confirma automaticamente que alguém foi visto ou que um golpe começou. O HUD completo mantém essas instruções de ajuda. Não há indicador de que o jogador está seguro. Terceira pessoa continua disponível pela rodinha.

Ao confirmar a saída, a ameaça e os mecanismos param. Há 5,5 segundos de ambiente da rua antes de o epílogo aparecer suavemente. Enter ou LER O RELATO antecipa a leitura. O estado e o final escolhido permanecem salvos; continuar depois desse trecho já concluído não exige revê-lo. As três condições originais de final, as provas, os sobreviventes e a preparação do sábado são preservados.

`tests/sunday_climax_integration.tscn` acrescenta 38 verificações de aparição, retomada, pausa, ausência de confirmação, busca, sons, HUD, rodinha e epílogo. A extração final do ZIP roda as dezesseis suítes, incluindo a sequência física completa de domingo. [Relatório da distribuição](../../downloads/project/release_verification.json) · [Log](integration.log).

Todos os 463 arquivos de assets e os 32 recursos da 0.32.0, incluindo onze bibliotecas de animação, permanecem idênticos. Não há nova gravação de outro jogo. A importação headless conserva os 14 avisos conhecidos de miniatura GLB; a suíte de domingo conserva o diagnóstico conhecido de compressor.ogg no encerramento. Os logs registram esses avisos. Não foi feita medição em uma Radeon R7 física.
