# 0.28.0 — rotina e suspense no depósito

[Ver a prévia com som](https://github.com/Deriby/TheLastSale/raw/refs/heads/main/docs/everyday_v028/everyday_preview.mp4) · [Baixar o projeto Godot 4.4.1](https://github.com/Deriby/TheLastSale/raw/refs/heads/main/downloads/project/TheLastSale_Godot_0.28.0.zip)

A câmera começa em primeira pessoa, com o corpo original visível e estabilização suave da altura. A **rodinha do mouse mantém a terceira pessoa**: para baixo afasta, para cima aproxima. Tab continua alternando Deryk/Felps com câmeras independentes. Os checkpoints anteriores adotam a nova câmera uma vez; as gravações seguintes conservam a distância escolhida.

![Primeira pessoa](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/everyday_v028/shop.png)
![Terceira pessoa pela rodinha](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/everyday_v028/third_person.png)

**J** abre o caderno do expediente: objetivo completo, destinos de caixas, controles, observações percebidas e anotações da investigação. A leitura pausa movimento, relógio e acontecimentos; J/Esc devolvem o controle. O HUD recolhe objetivos e identificação depois de alguns segundos, conserva interação e avisos contextuais e mantém o acesso ao caderno. Configurações permite retornar ao HUD persistente. C continua sendo o posto das câmeras e decisões de sábado/domingo.

![Caderno](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/everyday_v028/notebook.png)

O salão recebeu luz fria de comércio e duas luminárias fluorescentes emissivas; o estoque tem luz mais contida e a rua mantém a iluminação amarelada. Não foram acrescentadas luzes com sombras nem viewports ao jogo. As luminárias participam do circuito comercial, da pane, do gerador e do fechamento.

A escuta 3D do viewport foi habilitada. Compressores localizados, rádio abafado nos fundos, sino da entrada, passos e ruídos distantes agora chegam ao ponto de vista do jogador. O motor de um carro pode permanecer ligado em frente à loja. Todos respeitam seus volumes e os equipamentos obedecem à energia; o DVR preserva a escuta no lugar de Felps. Os quatro novos sons foram sintetizados para o projeto, sem gravações de outros jogos. Fonte e créditos em `assets/audio/everyday/README.txt`.

As vendas comuns continuam antes do aviso: ele fica disponível depois de cinco minutos e dos requisitos originais de reposição, organização e atendimentos. O tempo sozinho não conclui tarefas. Conversas de abertura e respostas do caixa são mais curtas, com pausas entre falas; Espaço mantém o avanço manual. O cliente de boné demora a sair com a compra, e os clientes alternam olhares e gestos.

Entre os acontecimentos opcionais há um sino na entrada enquanto Deryk está no estoque e Felps pergunta se ele voltou, passos nos fundos e uma pessoa do outro lado da rua. A pessoa entra fora de uma visão desobstruída e só ganha anotação ao ser percebida diretamente ou pela imagem ao vivo da fachada. Sua saída usa corpo físico e navegação; ela não desaparece diante do jogador. Os eventos, notas, posição e saída são conservados no save, sem repetir cenas ao continuar. Essas observações não substituem as provas obrigatórias nem alteram os finais da investigação.

![Rua](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/everyday_v028/street.png)
![Câmera ao vivo](https://raw.githubusercontent.com/Deriby/TheLastSale/main/docs/everyday_v028/cctv.png)

A prévia mostra o jogo real em Godot 4.4.1, com áudio e captura a 30 FPS em Linux/Mesa llvmpipe. É uma montagem condensada: o tempo narrativo e os locais são adiantados entre trechos para apresentar primeira/terceira pessoa, caderno, estoque, rua e câmera de segurança. Na partida, os eventos dependem do tempo, progresso e posição. O desempenho nativo em Radeon R7 não foi medido.

[Validação desta revisão](validation.json) · [Validação do ZIP e resultados completos](../../downloads/project/release_verification.json)

Os modelos, texturas, materiais, pesos e onze bibliotecas de animação continuam idênticos aos publicados na 0.27.0. Física de movimento, caixas, dinheiro/troco, investigação, perseguição, circuitos de energia, intro Two Brothers Lab, menu e modos PS1/PS1/2 permanecem presentes. O save continua na versão 5, aceitando versões 1–5 com os novos campos opcionais. Extraia o ZIP em pasta nova, importe `project.godot` no Godot **4.4.1** e pressione F5. Sem EXE.
