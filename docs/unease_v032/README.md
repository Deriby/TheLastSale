# 0.32.0 — o que ficou nos fundos

[Assistir à prévia real com áudio](vestigios_preview.mp4) · [Baixar o projeto Godot 4.4.1](../../downloads/project/TheLastSale_Godot_0.32.0.zip).

A prévia mostra seis cenas separadas: marcas junto à porta trancada; a caixa antes e depois; passos no pátio; tecido atrás da porta antiga; e um rosto no vidro do sedã já estacionado. Os intervalos foram cortados para revisão e as posições foram preparadas. O ritmo das animações é normal. As legendas explicativas pertencem à captura, não aparecem durante o jogo. Use fones para perceber a posição dos sons. Não é preciso encontrar todos os acontecimentos para terminar a noite.

No jogo, a caixa só muda após ser examinada, com o jogador longe e fora da vista. A marca original no pó permanece; o obstáculo da navegação acompanha o objeto. Passos e tecido ficam separados por silêncio e respeitam o volume dos efeitos. As oportunidades anteriores de cabeças ficam suspensas durante esses momentos, as interfaces e os intervalos seguintes.

O encontro no carro é opcional, uma única vez no sábado, depois dos vestígios, dos sons e de pelo menos 35 segundos sem esse áudio. Exige proximidade da janela, distância do companheiro e dos clientes, e vidro fora da vista para preparar a figura. O assassino usa Enemy.glb e Enemy.res originais, dentro do sedã existente; aparece brevemente ao jogador virar a própria câmera e se abaixa atrás da carroceria. Sem música de susto, puxão de câmera, caminhada exposta ou aviso substituto se o jogador perder o momento.

Não foram adicionados objetivos, pistas obrigatórias ou anotações automáticas. As falas de coordenação da investigação foram reduzidas, e a maçaneta continua mexendo fisicamente no fechamento sem legenda automática explicando quem está ali. Os quatro vestígios originais, CCTV, decisões, portas e campanha seguem disponíveis.

O save v5 conserva a mudança, os sons consumidos e a pose e duração do rosto. Rodinha, controles, física, circuitos, modelos publicados e onze bibliotecas de animação permanecem preservados. O novo Foley é uma síntese original reproduzível com `tools/make_saturday_audio.py`.

`tests/saturday_unease_integration.tscn` verifica os eventos físicos, intervalos, origens 3D, retomada, pausa, bloqueios de interface e proximidade, câmera e ausência de confirmação automática. A distribuição é conferida em uma extração nova do ZIP, com as quinze suítes. [Relatório da distribuição](../../downloads/project/release_verification.json) · [Resultados](integration.log).

A importação headless mantém os 14 avisos conhecidos de miniatura GLB (Parameter "t" is null). A suíte de domingo pode emitir no encerramento o diagnóstico já existente do áudio compressor.ogg; nenhum desses avisos é escondido nos logs. Não foi feita medição de FPS em uma Radeon R7 física.
