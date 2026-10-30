# 0.24.0 — abertura em fita e menu de suspense

**[Assistir à abertura e ao menu](https://github.com/Deriby/TheLastSale/raw/refs/heads/main/docs/title_v024/intro_menu.mp4)**

A apresentação tem clima de fita doméstica e cartaz de terror dos anos 80: preto, creme, vermelho escuro, tipografia serifada, granulação e linhas discretas de vídeo. A câmera revela o próprio depósito vazio à noite, com movimento lento e uma atmosfera sonora original de sintetizador e mecanismos de fita.

![Menu principal](https://github.com/Deriby/TheLastSale/raw/refs/heads/main/docs/title_v024/menu.png)

## Abertura e controles

A sequência dura aproximadamente **9,4 segundos**, depois dos primeiros quadros de carregamento: fita iniciando, **Deriby apresenta**, **Franca, São Paulo — sexta-feira, 21:40**, e a revelação do cenário antes do menu. Não avança o turno nem os objetivos.

**Espaço, Enter, Esc ou clique** pulam a intro. O evento é consumido para não acionar Iniciar expediente por baixo. A abertura aparece uma vez ao executar a cena principal/F5; pausar, continuar, trocar de noite ou reconstruir o mundo não a repete.

O menu oferece **Iniciar expediente**, **Continuar turno salvo**, **Configurações** e **Sair**. Continuar fica desabilitado quando não existe checkpoint. Mouse e teclado têm destaque de seleção. O layout foi verificado em 800×600; PS1 e PS1/2 mantêm a interface em resolução plena. Esc fecha Configurações antes de começar uma partida.

A pausa usa a mesma identidade visual, conserva a câmera do jogador e mantém salvar/retomar. Ao entrar no jogo, a câmera, a visibilidade original dos personagens e o HUD são restaurados; o som do menu termina com a transição.

![Cartão de localização](https://github.com/Deriby/TheLastSale/raw/refs/heads/main/docs/title_v024/intro_franca.png)

## Som, recursos e preservação

A textura sonora de 20 segundos e os efeitos de fita/seleção foram sintetizados para o jogo. Música controla o ambiente; Efeitos controla fita e seleção; Volume geral continua no barramento principal. As fontes DejaVu estão incluídas com sua licença em `assets/fonts/title/LICENSE.txt`.

A apresentação reutiliza o mundo e o viewport existentes e acrescenta apenas uma câmera temporária. Não adiciona luzes, não move personagens nem modifica modelos ou animações. Os personagens ficam ocultos somente na apresentação e recuperam exatamente os estados de visibilidade anteriores. Os 440 arquivos de assets/recursos da 0.23.1 foram preservados byte a byte. Física, energia, saves e a correção do piso permanecem intactos.

Fontes e sons já estão prontos no projeto. Jogar não exige ferramentas extras além do Godot 4.4.1. Para regenerar os recursos, `python3 tools/make_title_assets.py` usa Python/fontTools, FFmpeg e as fontes DejaVu instaladas em Linux.

## Verificação

- `./tools/test.sh`: oito suítes; acrescenta 41 verificações de abertura/menu às 459 existentes.
- `./tools/godot.sh --audio-driver Dummy res://tests/title_integration.tscn`: verifica a sequência, entrada, configurações, volumes, foco, save/continuar e câmera.
- `TITLE_REVIEW_PATH=/tmp/title ./tools/godot.sh --audio-driver Dummy res://tests/title_review.tscn`: capturas com renderização real.
- `./tools/godot.sh --audio-driver Dummy --fixed-fps 15 --write-movie /tmp/title.avi res://tests/title_review.tscn -- movie`: grava a prévia no preset Retrô.

[Dados da implementação](validation.json), [testes da abertura](title_source.log) e [verificação do pacote extraído](https://github.com/Deriby/TheLastSale/blob/main/downloads/project/release_verification.json). A prévia usa Linux/Mesa llvmpipe em 15 FPS de gravação; o limite padrão do jogo permanece em 30 FPS. Desempenho na Radeon R7 não foi medido.

O ZIP contém código, fontes, sons e estes dados. As capturas e o vídeo ficam no repositório para respeitar o limite de 100 MiB por arquivo do GitHub. A entrega continua sendo o projeto Godot 4.4.1, sem EXE.
