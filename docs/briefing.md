# PROMPT MESTRE PARA CODEX
## PROJETO: DEPOIS DO FECHAMENTO
### Jogo de terror 3D — Godot 4.4

Você atuará como programador principal, technical artist, level designer, animador 3D e responsável pela implementação de um jogo independente de terror psicológico e sobrevivência.

Quero um **jogo realmente funcional, visualmente consistente, imersivo e organizado**, desenvolvido na Godot 4.4 utilizando GDScript.

Não quero apenas um protótipo genérico. Quero estabelecer uma base profissional que possa receber novos capítulos, personagens, cenários e mecânicas sem precisar reconstruir tudo futuramente.

Leia atentamente todas as instruções e analise os arquivos fornecidos antes de começar.

---

# 1. INFORMAÇÕES DO PROJETO

**Título:** A Ultima Venda

**Engine:** Godot 4.4

**Linguagem:** GDScript

**Plataforma inicial:** Windows PC

**Compatibilidade desejada:** Windows 7, 8, 10, 11, 64 bits

**Gênero:** Terror psicológico, sobrevivência, suspense narrativo e exploração em terceira pessoa com a possibilidade de mudar para primeira pessoa.

**Localização:** Franca, interior de São Paulo, Brasil.

**Época:** Não é dito, mas a vibe é retro.

**Idioma:** Português brasileiro, futuramente traduções.

**Duração planejada:** Aproximadamente 1h30 a 2h30.

**Referências artísticas e narrativas:**

- Puppet Combo: estética PS1, atmosfera perturbadora, ambientes desconfortáveis e terror de perseguição.
- Fears to Fathom: narrativa cotidiana, interações realistas e construção gradual do suspense.

As referências servem como direção artística e técnica. Não copie personagens, mapas, materiais, trilhas sonoras ou códigos proprietários desses jogos.

O objetivo é criar um jogo com identidade própria, fortemente brasileiro.

---

# 2. ARQUIVOS E REFERÊNCIAS FORNECIDOS

Vou disponibilizar modelos 3D, fotografias reais e um endereço do Google Street View.

## 2.1. Modelos principais

**Personagem 1:** Dery

**Personagem 2:** Felps

**Personagem 3:** Enemy

Os três modelos 3D estão prontos visualmente, porém ainda não possuem rig, skinning ou animações.

Você deverá utilizar os arquivos originais como referência visual definitiva.

Não substitua os modelos por cápsulas, personagens genéricos ou modelos criados do zero.

É permitido realizar ajustes técnicos necessários à animação, desde que a identidade visual, roupas, proporções, rosto e texturas sejam preservados.

## 2.2. Google Street View

**LINK DO STREET VIEW:**

[https://maps.app.goo.gl/PGtYSqukn4xXtTvB9]

Esse link mostra a localização real do depósito de bebidas onde o jogo será ambientado.

Analise o máximo possível da fachada e seus arredores, incluindo:

- Dimensões aproximadas e formato do estabelecimento.
- Entrada principal.
- Portões, janelas e fachada.
- Construções vizinhas.
- Calçadas e meio-fio.
- Inclinação e largura aparente da rua.
- Postes e fiação elétrica.
- Árvores e vegetação.
- Muros, fachadas e garagens.
- Sinalização e características urbanas brasileiras.
- Perspectiva e relação espacial entre os edifícios.

O objetivo é reconstruir uma versão 3D low-poly reconhecível do local real.

Não é necessário reproduzir tudo com precisão milimétrica, mas a disposição e as proporções devem ser visualmente fiéis.

Caso não consiga acessar diretamente o Street View, utilize as capturas de tela anexadas no arquivo "fotosdeposito.zip". Não invente detalhes afirmando que foram observados. Identifique claramente o que é referência real e o que é aproximação.

## 2.3. Fotografias do interior

**FOTOGRAFIAS ANEXADAS:**

[está em anexo chamado fotosdeposito.zip]

Essas imagens devem ser utilizadas para reconstruir o interior do estabelecimento.

Observe:

- Posição do balcão e do caixa.
- Prateleiras de bebidas.
- Geladeiras e freezers.
- Marcas e cores dos equipamentos.
- Piso, paredes e teto.
- Portas e corredores.
- Estoque e áreas de serviço.
- Iluminação noturna.
- Objetos decorativos.
- Caixas de bebidas.
- Propagandas e cartazes.
- Relação espacial entre os ambientes.

Use as fotografias como referência principal.

Se houver várias fotografias mostrando o mesmo ambiente, identifique os elementos comuns para estabelecer a continuidade espacial.

Não crie uma disposição aleatória de prateleiras.

Quando alguma região não aparecer nas fotos, faça uma aproximação coerente com o restante do estabelecimento.

Entradas de manutenção, passagens de perseguição e outros elementos fictícios devem ser integrados de maneira natural, sem comprometer a aparência geral do depósito.

Não reproduza detalhes reais de sistemas de segurança que não sejam necessários à ficção.

---

# 3. DIREÇÃO ARTÍSTICA

O jogo deverá seguir uma estética **low-poly PS1 / horror retrô**.

Entretanto, a câmera, movimentação e interfaces devem transmitir a sensação de um jogo moderno.

## 3.1. Modelagem

Características obrigatórias:

- Poucos polígonos.
- Silhuetas reconhecíveis.
- Geometria angular visível.
- Texturas pixeladas.
- Materiais simples.
- Detalhes geométricos compatíveis com jogos do final dos anos 1990.
- Objetos proporcionais à escala humana.
- Boa leitura visual mesmo em ambientes escuros.

Evite objetos excessivamente detalhados, materiais brilhantes e aparência de jogos modernos realistas.

Não use uma mistura inconsistente de assets modernos e personagens PS1.

## 3.2. Texturas

Priorize texturas com resoluções reduzidas, como 64×64, 128×128 e 256×256, dependendo do tamanho e da importância do objeto.

Utilize filtros de textura compatíveis com o estilo pixelado.

É permitido criar texturas maiores para fachadas ou superfícies específicas, desde que mantenham aparência retrô.

Não aplique filtros que deixem tudo borrado.

## 3.3. Efeitos visuais

Implemente um sistema configurável de estética retrô, incluindo:

- Resolução interna reduzida.
- Upscaling com aparência pixelada.
- Color grading noturno.
- Leve dithering.
- Granulação analógica discreta.
- Efeito VHS opcional.
- Distorção ou instabilidade de vértices opcional.
- Vinheta suave, quando apropriada.

**Importante:** os efeitos não podem comprometer a leitura de textos, interfaces ou objetos interativos.

A movimentação da câmera deve continuar suave mesmo com a estética visual retrô.

---

# 4. RECONSTRUÇÃO DO MAPA

O cenário inicial será composto pelo depósito e uma pequena região ao redor.

Quero uma rua brasileira reconhecível, não uma cidade americana genérica.

## 4.1. Exterior

Reconstrua a rua a partir do Street View.

Inclua os elementos realmente observados nas referências e complemente as áreas não fotografadas com arquitetura coerente com Franca-SP.

Elementos ambientais possíveis:

- Postes de iluminação.
- Fiação elétrica aérea.
- Calçadas irregulares.
- Casas e pequenos comércios.
- Muros e portões.
- Carros estacionados.
- Motos.
- Lixeiras.
- Árvores.
- Placas e letreiros.
- Iluminação residencial.
- Fachadas fechadas.
- Objetos urbanos típicos brasileiros.

Evite ruas exageradamente largas, fachadas americanizadas e distribuição artificial de construções.

O mapa não deve ser totalmente vazio, mas também não precisa ser uma cidade aberta.

Construa apenas a região necessária ao primeiro episódio.

Use geometria otimizada para dar a impressão de que o bairro continua além da região explorável.

## 4.2. Interior do depósito

Crie as seguintes áreas, respeitando as referências fotográficas:

**Área de vendas:** espaço principal com produtos, geladeiras, prateleiras, entrada de clientes e balcão.

**Caixa:** local de trabalho de Felps, com monitor, gaveta de dinheiro, balcão e objetos comerciais.

**Área de reposição:** corredores e prateleiras onde Dery organiza mercadorias.

**Estoque:** área de armazenamento, caixas empilhadas e acesso às tarefas de reposição.

**Área de serviço:** região usada para carregamento e manutenção, quando compatível com o espaço disponível.

**Espaço oculto fictício:** uma área antiga de armazenamento que será descoberta posteriormente durante a história.

O último ambiente deve permanecer inacessível durante a fase inicial.

## 4.3. Escala

Utilize medidas humanas coerentes.

Considere aproximadamente 1 unidade da Godot como 1 metro.

As portas, balcões, corredores e prateleiras devem ser proporcionais aos modelos dos personagens.

Ajuste a escala dos modelos apenas quando tecnicamente necessário, preservando suas proporções relativas.

## 4.4. Objetos

Crie assets reutilizáveis e organizados:

- Caixas de cerveja.
- Engradados.
- Garrafas.
- Latas.
- Fardos.
- Paletes.
- Prateleiras.
- Freezers.
- Geladeiras.
- Balcões.
- Produtos.
- Carrinhos de transporte.
- Equipamentos do estoque.
- Lixeiras.
- Pequenos objetos decorativos.

Evite construir todo o depósito como uma única malha inseparável.

Utilize cenas modulares para facilitar futuras alterações.

---

# 5. ILUMINAÇÃO E ATMOSFERA

O jogo se passa durante a noite.

As fotografias reais devem orientar a iluminação do depósito.

O interior inicialmente precisa parecer um estabelecimento comercial normal e em funcionamento.

Utilize:

- Lâmpadas fluorescentes.
- Luzes frias nas geladeiras.
- Iluminação de rua mais amarelada.
- Sombras em corredores.
- Áreas parcialmente escuras no estoque.
- Contraste entre espaços iluminados e espaços sem iluminação.

O ambiente deve ser visualmente compreensível.

Não quero um jogo onde o jogador precise aumentar o brilho do monitor para enxergar qualquer coisa.

Conforme a história avança, a iluminação pode mudar de forma gradual e justificada.

Exemplo: uma lâmpada começa a falhar depois de um evento narrativo, mas não desde o primeiro segundo do jogo.

Priorize técnicas compatíveis com o renderizador Compatibility, usando iluminação simples, materiais emissivos e soluções econômicas quando necessário.

---

# 6. SISTEMA DE PERSONAGENS E RIGGING

Esta etapa é extremamente importante.

Os modelos Dery, Felps e Enemy foram criados sem armature.

Quero que você prepare os três para animações reais.

## 6.1. Pipeline de rigging

Primeiro, identifique o formato original de cada modelo e verifique:

- Quantidade de malhas.
- Materiais.
- Texturas.
- Orientação.
- Escala.
- Origem e pivôs.
- Integridade da geometria.
- Presença ou ausência de esqueleto.
- Pose original do personagem.

Utilize Blender por script, se estiver disponível e for adequado, para criar armature, ajustar ossos, aplicar pesos e exportar os modelos.

Prefira GLB/glTF 2.0 como formato de entrega para os personagens com esqueleto.

Se os modelos estiverem em OBJ, converta-os para um formato que suporte skeleton e animações.

## 6.2. Esqueleto

Prepare um rig humanoide básico contendo, conforme a anatomia dos modelos:

- Pelve.
- Coluna.
- Tórax.
- Pescoço.
- Cabeça.
- Ombros.
- Braços.
- Antebraços.
- Mãos.
- Coxas.
- Pernas.
- Pés.

Dedos individuais são opcionais se a geometria low-poly não permitir deformação adequada.

## 6.3. Skinning

Garanta que cada parte do modelo acompanhe corretamente os ossos.

Teste deformações durante:

- Flexão de joelhos.
- Movimento dos braços.
- Rotação da cabeça.
- Agachamento.
- Corrida.
- Elevação dos braços.

Não aceite braços atravessando o corpo, pernas deformadas ou texturas deslocadas.

Preserve o aspecto low-poly original.

Caso o rigging automático não produza resultados aceitáveis, identifique os problemas e prepare uma alternativa que preserve a geometria.

Não declare o rig concluído sem validar o movimento.

## 6.4. Animações de Dery

Crie inicialmente:

1. Idle.
2. Walking.
3. Running.
4. Crouching idle.
5. Crouch walking.
6. Picking up objects.
7. Carrying a box.
8. Putting an object on a shelf.
9. Interacting with a door.
10. Looking around.
11. Startled reaction.
12. Taking damage.
13. Death.

## 6.5. Animações de Felps

Crie:

1. Idle.
2. Walking.
3. Running.
4. Cashier idle.
5. Using the register.
6. Handing products to customers.
7. Talking.
8. Looking toward a suspicious sound.
9. Frightened reaction.
10. Hiding.
11. Taking damage.

## 6.6. Animações de Enemy

Quero um comportamento corporal particularmente perturbador.

Animações:

1. Idle assustador.
2. Caminhada lenta.
3. Caminhada investigativa.
4. Corrida de perseguição.
5. Olhar para os lados.
6. Virar a cabeça lentamente.
7. Observar parado.
8. Abrir portas.
9. Atacar.
10. Procurar o jogador.
11. Reagir à perda de contato visual.

O Enemy deve parecer humano, porém ameaçador.

Evite movimentação robótica e velocidade excessivamente artificial.

Implemente transições entre animações com AnimationTree ou sistema equivalente apropriado.

---

# 7. CÂMERA MODERNA EM TERCEIRA PESSOA

Este é um dos sistemas mais importantes.

Quero uma câmera semelhante, em enquadramento e comportamento geral, à de jogos modernos como The Last of Us e God of War (2018).

## 7.1. Câmera padrão

A câmera deve ficar próxima ao personagem, levemente atrás e deslocada para o lado direito.

O personagem não deve ficar exatamente no centro da tela.

Características:

- Câmera sobre o ombro.
- Acompanhamento suave.
- Rotação com o mouse.
- Controle vertical e horizontal.
- Limites adequados de inclinação.
- Correção de colisão com paredes.
- Ausência de atravessamento de geometria.
- Transições suaves de posição.
- Possibilidade de ajuste da distância.
- Campo de visão configurável.

Utilize CharacterBody3D para o controlador do jogador e considere SpringArm3D ou solução equivalente para lidar com obstáculos.

Não aplique suavização exagerada que deixe o controle atrasado.

## 7.2. Primeira pessoa com a roda do mouse

Quero um sistema contínuo de aproximação.

Quando o jogador rolar a roda do mouse para frente, a câmera deverá se aproximar gradualmente do personagem.

Ao atingir uma distância mínima, ela deve entrar em modo de primeira pessoa.

Nesse modo:

- A câmera assume a perspectiva dos olhos.
- O personagem continua se movimentando normalmente.
- O mouse controla a visão.
- Não deve aparecer a parte interna da cabeça.
- O corpo pode continuar visível quando apropriado.
- As interações devem funcionar normalmente.
- A sensibilidade não deve mudar drasticamente.

Quando o jogador rolar a roda do mouse para trás, a câmera deve retornar suavemente à terceira pessoa.

**Não quero uma troca abrupta de câmeras.**

O efeito precisa parecer uma transição natural de distância.

## 7.3. Movimento

Controles padrão:

WASD — movimentação.

Mouse — controlar câmera.

Shift — correr.

Ctrl — agachar.

E — interagir.

Botão esquerdo — ação contextual, quando necessária.

Esc — pausar.

Scroll do mouse — aproximar ou afastar a câmera.

F — lanterna, quando desbloqueada.

O personagem deve movimentar-se em relação à orientação da câmera.

Na terceira pessoa, ele precisa girar suavemente na direção do movimento.

Na primeira pessoa, o comportamento deve ser apropriado à perspectiva.

Adicione aceleração e desaceleração moderadas.

O jogador não deve deslizar pelo chão.

---

# 8. NPCs CLIENTES — CRIAÇÃO AUTOMÁTICA

Os únicos modelos fornecidos por mim serão Dery, Felps e Enemy.

Você deverá criar os NPCs secundários.

**A aparência deles deve seguir rigorosamente a mesma linguagem visual dos personagens fornecidos.**

Analise os três modelos para identificar:

- Densidade de polígonos.
- Proporções.
- Estilo de rosto.
- Resolução de texturas.
- Detalhamento das roupas.
- Estilo de iluminação.
- Tratamento das mãos e pés.

Crie NPCs compatíveis, sem importar personagens modernos que destoem visualmente.

## 8.1. Variedade

Quero alguns perfis diferentes:

- Homem adulto voltando do trabalho.
- Motoboy.
- Jovem comprando refrigerante.
- Cliente de meia-idade.
- Mulher adulta comprando bebidas.
- Homem mais velho.
- Cliente que entra apenas para perguntar o preço.
- Cliente suspeito que observa o estabelecimento.

Não é necessário criar todos imediatamente, mas estabeleça uma base reutilizável com diversidade visual.

Evite clones idênticos.

Utilize combinações de roupas, rostos, cabelos, cores e proporções.

Os personagens precisam parecer moradores comuns de Franca-SP em 2026.

## 8.2. Animações

Todos os NPCs precisam, no mínimo, conseguir:

- Ficar parados.
- Andar.
- Virar.
- Observar produtos.
- Segurar um objeto.
- Interagir com o caixa.
- Sair do estabelecimento.

Utilize rigs e animações compartilhadas quando as proporções permitirem.

## 8.3. Inteligência artificial dos clientes

Implemente uma máquina de estados.

Exemplo:

ENTERING → BROWSING → SELECTING_PRODUCT → GOING_TO_CHECKOUT → WAITING → PAYING → EXITING

O NPC deve:

1. Aparecer a partir de uma região coerente da rua.
2. Caminhar até a entrada.
3. Entrar pela porta.
4. Percorrer o estabelecimento.
5. Observar ou selecionar produtos.
6. Ir até Felps.
7. Aguardar atendimento.
8. Realizar uma compra simplificada.
9. Sair naturalmente.

Use navegação apropriada para evitar atravessar balcões e prateleiras.

Não faça clientes surgirem instantaneamente no meio da loja.

Não mantenha todos os clientes ativos ao mesmo tempo.

Adicione intervalos entre visitas para representar o movimento noturno.

---

# 9. ROTINA DE TRABALHO DO DERY

O jogador começará controlando Dery.

Sua profissão é repositor do depósito.

O início do jogo deve funcionar como um pequeno simulador de trabalho.

## 9.1. Tarefas

Crie um sistema reutilizável de objetivos.

Exemplos:

**Objetivo: Repor a geladeira**

- Caminhar até o estoque.
- Localizar uma caixa de bebidas.
- Pegar a caixa.
- Transportá-la até a área de vendas.
- Abrir a geladeira.
- Colocar os produtos nos espaços indicados.
- Concluir a tarefa.

**Objetivo: Organizar o estoque**

- Identificar caixas fora de posição.
- Pegar os objetos.
- Levá-los aos locais corretos.
- Atualizar o progresso.

**Objetivo: Limpar uma área**

- Encontrar um objeto fora do lugar.
- Interagir com ele.
- Guardá-lo corretamente.

## 9.2. Interações físicas

Não quero simplesmente apertar E e ver o objeto desaparecer.

Quando possível, implemente:

- Animação de pegar.
- Objeto preso às mãos.
- Transporte visível.
- Colocação no destino.
- Atualização visual do ambiente.

Prefira interações controladas, usando pontos de encaixe, em vez de simulações físicas complexas e instáveis.

## 9.3. Interface de objetivos

Quero uma HUD discreta.

Exemplo:

"Repor as bebidas da geladeira."

Progresso: 2/6

Não coloque setas enormes, painéis coloridos ou indicadores excessivos na tela.

Use instruções contextuais e textos discretos.

---

# 10. ROTINA DO FELPS

Felps começa como NPC controlado pela inteligência artificial.

Ele trabalha no caixa.

Durante o expediente:

- Permanece próximo ao balcão.
- Interage com clientes.
- Utiliza o computador ou caixa.
- Conversa com Dery.
- Observa a rua ocasionalmente.
- Reage a eventos do ambiente.
- Pode chamar Dery para ajudar em tarefas.

Felps não deve ficar imóvel como uma estátua.

Crie pequenas animações e comportamentos de rotina.

Em momentos específicos, Felps pode sair do balcão, observar uma prateleira ou conversar com Dery.

Os diálogos devem ser em português brasileiro informal e natural.

Não quero personagens falando como se estivessem lendo um roteiro artificial.

---

# 11. SISTEMA DE DIÁLOGOS

Implemente um sistema de conversas reutilizável.

Características:

- Nome do personagem.
- Texto na tela.
- Avanço manual ou automático configurável.
- Controle de duração.
- Bloqueio temporário de ações, quando necessário.
- Integração com animações.
- Integração com eventos.
- Suporte futuro a áudio de voz.
- Suporte a falas ambientais durante a movimentação.

O sistema deve permitir diálogos sem interromper completamente a jogabilidade.

Exemplo:

Dery está organizando bebidas.

Felps fala do balcão:

**Felps:** "Ô Dery, acabou a Coca de dois litros aqui!"

**Dery:** "Já vou pegar, pera aí."

O jogador continua se movimentando enquanto conversa.

Para cenas cinematográficas importantes, o controle poderá ser restringido temporariamente.

---

# 12. HISTÓRIA PRINCIPAL

A narrativa começa em uma noite de sexta-feira, em Franca-SP.

Dery e Felps trabalham no período noturno de um depósito de bebidas.

Dery é repositor.

Felps trabalha no caixa.

Inicialmente, tudo parece normal.

O jogador deve ter tempo para conhecer o estabelecimento, realizar tarefas e observar os clientes.

Quero um terror gradual.

Não revele o vilão imediatamente.

## CAPÍTULO 1 — EXPEDIENTE NORMAL

Horário inicial: 21h40.

O jogador controla Dery.

Objetivos iniciais:

- Conhecer o depósito.
- Conversar com Felps.
- Organizar caixas.
- Repor bebidas.
- Atender pequenas solicitações.
- Observar clientes chegando.

O ambiente deve parecer relativamente seguro.

O rádio toca baixo.

Veículos passam na rua.

Alguns clientes conversam.

Felps faz comentários ocasionais.

O jogador começa a reconhecer as instalações.

## EVENTO PRINCIPAL — O AVISO

Horário aproximado: 22h35.

Um homem de meia-idade entra no depósito.

Ele parece preocupado.

Dirige-se ao caixa e conversa com Felps.

Diálogo:

**Cliente:** "Boa noite, rapaziada. Cês vão ficar abertos até que horas?"

**Felps:** "Até meia-noite, patrão. Por quê?"

**Cliente:** "Se eu fosse vocês, fechava mais cedo hoje."

**Felps:** "Uai, por quê?"

**Cliente:** "Tem um cara estranho rondando aqui desde ontem. Ontem vi ele perto daquele terreno ali. Hoje tava parado atrás do depósito de vocês."

**Dery:** "Mas o cara tava fazendo o quê?"

**Cliente:** "Nada. Esse que é o problema. Ele só fica olhando."

O cliente compra suas bebidas.

Antes de sair, comenta:

**Cliente:** "Fica esperto, viu? Boa noite."

Após o cliente sair, Felps e Dery comentam sobre a situação.

Felps tenta fazer alguma brincadeira.

Dery demonstra preocupação.

O jogo continua normalmente.

## CAPÍTULO 2 — COMPORTAMENTOS ESTRANHOS

Horário: após 23h.

O movimento de clientes começa a diminuir.

Alguns acontecimentos:

- Sons estranhos vindos do estoque.
- Uma caixa que estava organizada aparece deslocada.
- Um vulto distante surge brevemente na rua.
- Felps acredita ter visto um homem observando o depósito.
- A câmera de segurança registra movimento nos fundos.
- Um portão parece ter sido mexido.

Os acontecimentos devem ocorrer com lógica e progressão.

Evite sustos aleatórios.

O jogador precisa começar a desconfiar do ambiente.

## CAPÍTULO 3 — O FECHAMENTO

Próximo de meia-noite, os protagonistas decidem fechar.

Dery precisa verificar o estoque.

Felps fecha o caixa.

Dery encontra sinais de que alguém esteve utilizando uma área antiga do depósito.

Objetos encontrados:

- Colchão improvisado.
- Embalagens de alimentos.
- Roupas velhas.
- Garrafas de água.
- Anotações sobre o funcionamento do estabelecimento.

Uma anotação revela os horários aproximados dos funcionários.

A descoberta sugere que alguém está observando a rotina deles.

Posteriormente, as portas começam a ser bloqueadas e o invasor se revela.

## CAPÍTULO 4 — INVASÃO

O Enemy consegue separar os dois protagonistas.

O jogador precisa explorar, se esconder, resolver pequenos obstáculos e encontrar maneiras de alcançar o companheiro.

A inteligência artificial do vilão se torna ativa.

## CAPÍTULO 5 — SOBREVIVÊNCIA

Dery e Felps precisam encontrar uma rota de fuga.

O jogador poderá alternar entre os protagonistas em momentos narrativos específicos.

Implemente essa possibilidade arquiteturalmente, mas priorize Dery na primeira versão jogável.

A narrativa deverá permitir futuramente diferentes finais.

**Importante:** esta descrição define a direção narrativa completa. Não significa que todos os capítulos devam ser implementados de uma só vez.

---

# 13. INTELIGÊNCIA ARTIFICIAL DO ENEMY

O vilão deve ser ameaçador sem parecer sobrenatural.

Ele é humano, perigoso, paciente e conhece o ambiente.

Não quero que ele simplesmente persiga o jogador em linha reta.

Crie uma máquina de estados preparada para:

IDLE

OBSERVING

PATROLLING

INVESTIGATING

SEARCHING

STALKING

CHASING

ATTACKING

RETURNING

## 13.1. Percepção

O Enemy deve possuir:

- Campo de visão.
- Distância de detecção.
- Verificação de linha de visão.
- Percepção de ruídos.
- Memória da última posição conhecida do jogador.
- Capacidade de investigar locais suspeitos.

Evite que ele enxergue através de paredes.

## 13.2. Investigação

Quando o Enemy escutar um ruído:

1. Interrompe a atividade atual.
2. Reage ao som.
3. Caminha até o local.
4. Procura sinais do jogador.
5. Retorna ao comportamento anterior se não encontrar nada.

## 13.3. Perseguição

Quando encontrar o jogador:

- Reage de maneira perceptível.
- Começa a perseguição.
- Utiliza a navegação disponível.
- Evita obstáculos.
- Tenta alcançar o jogador.
- Pode perder contato visual.
- Investiga a última posição conhecida.

Não utilize teletransporte arbitrário para colocá-lo perto do jogador.

## 13.4. Terror psicológico

O Enemy pode aparecer em momentos roteirizados:

- Parado na calçada.
- Observando pelas proximidades do depósito.
- Parcialmente escondido na sombra.
- Aparecendo em uma câmera de segurança.
- Passando ao fundo de uma cena.

Esses acontecimentos devem respeitar a continuidade espacial.

Não revele seu rosto constantemente.

Não use jumpscares repetitivos.

O medo deve vir principalmente da antecipação e da sensação de estar sendo observado.

---

# 14. SISTEMA DE SEGURANÇA E CÂMERAS

O depósito possuirá um sistema fictício de monitoramento.

O jogador poderá acessar uma interface de câmeras a partir de um computador.

Quero uma apresentação retrô com:

- Imagens de câmeras.
- Nome ou número das câmeras.
- Horário.
- Pequena interferência visual.
- Granulação.
- Alternância entre pontos de observação.

As câmeras deverão mostrar o cenário real do jogo, usando câmeras internas da Godot e soluções de renderização compatíveis com o orçamento de desempenho.

Não quero vídeos pré-gravados desconectados do mundo 3D.

O sistema deve ser preparado para eventos narrativos.

Exemplo: o Enemy aparece por alguns segundos em determinada câmera e depois sai do enquadramento.

---

# 15. SISTEMA DE ÁUDIO

A ambientação sonora é fundamental.

Crie uma estrutura para áudio espacial e eventos sonoros.

## 15.1. Sons ambientais

Inclua suporte para:

- Motos passando.
- Carros distantes.
- Cachorros latindo.
- Grilos.
- Vento.
- Ruídos de refrigeradores.
- Zumbido de lâmpadas.
- Passos.
- Portas.
- Caixas sendo movimentadas.
- Garrafas e latas.
- Caixa registradora.
- Rádio ambiente.
- Ruídos do estoque.

Utilize arquivos originais, licenciados ou fornecidos.

Não incorpore trilhas ou efeitos protegidos de outros jogos.

## 15.2. Música

A trilha inicial deverá ser discreta.

Durante a rotina, o estabelecimento pode ter um rádio tocando música ambiente.

Quando os eventos estranhos começarem, a música deve diminuir ou desaparecer de maneira natural.

Durante a exploração de terror, utilize principalmente silêncio e sons ambientais.

A trilha de perseguição deve ser curta, repetível, tensa e coerente com o terror retrô.

Deixe pontos preparados para substituir os áudios posteriormente por músicas próprias.

---

# 16. INTERAÇÕES E FÍSICA

Crie um sistema modular de interação baseado em raycast ou solução equivalente.

O jogador deverá conseguir:

- Abrir portas.
- Fechar portas.
- Pegar objetos.
- Soltar objetos.
- Transportar caixas.
- Interagir com geladeiras.
- Acionar interruptores.
- Examinar objetos.
- Ler bilhetes.
- Conversar com personagens.
- Interagir com computadores.
- Utilizar equipamentos.

Cada objeto interativo deve possuir identificação e comportamento próprio.

Evite um único script gigante contendo todas as interações do jogo.

Utilize classes e componentes reutilizáveis.

Implemente estados adequados para evitar executar interações incompatíveis simultaneamente.

---

# 17. INTERFACE

A interface deve ser minimalista, funcional e coerente com o terror PS1.

Inclua:

- Menu principal.
- Iniciar jogo.
- Continuar, quando houver salvamento.
- Configurações.
- Sair.
- Menu de pausa.
- Legendas.
- Objetivos discretos.
- Indicador contextual de interação.
- Tela de carregamento.
- Sistema básico de salvamento.

Não quero menus modernos exageradamente coloridos.

A tipografia deve ser legível, mesmo com efeitos de baixa resolução.

## 17.1. Configurações

Permita ajustar:

- Volume geral.
- Volume da música.
- Volume dos efeitos.
- Sensibilidade do mouse.
- Distância da câmera.
- Campo de visão, quando viável.
- Intensidade dos efeitos VHS.
- Pixelização.
- Granulação.
- Resolução.
- Modo de tela.
- Qualidade gráfica.

---

# 18. ORGANIZAÇÃO TÉCNICA

Utilize uma arquitetura modular.

Estrutura sugerida:

```text
res://
├── scenes/
│   ├── main/
│   ├── world/
│   │   ├── street/
│   │   ├── depot/
│   │   └── props/
│   ├── characters/
│   │   ├── dery/
│   │   ├── felps/
│   │   ├── enemy/
│   │   └── npcs/
│   ├── ui/
│   └── cinematics/
├── scripts/
│   ├── player/
│   ├── camera/
│   ├── ai/
│   ├── interactions/
│   ├── objectives/
│   ├── dialogue/
│   ├── narrative/
│   └── systems/
├── assets/
│   ├── models/
│   ├── textures/
│   ├── animations/
│   └── audio/
├── resources/
├── shaders/
└── project.godot
```

Essa estrutura é uma sugestão, podendo ser melhorada se houver justificativa técnica.

Requisitos:

- Evitar scripts monolíticos.
- Utilizar sinais para comunicação entre sistemas.
- Separar lógica de apresentação.
- Evitar referências rígidas a caminhos de nós quando possível.
- Utilizar recursos configuráveis.
- Criar cenas reutilizáveis.
- Organizar corretamente camadas de colisão.
- Documentar sistemas importantes.
- Evitar dependências externas desnecessárias.
- Compatibilidade com Godot 4.4.

---

# 19. DESEMPENHO E OTIMIZAÇÃO

O projeto deverá funcionar em computadores modestos.

Priorize:

- Modelos low-poly.
- Materiais simples.
- Texturas compactas.
- Iluminação econômica.
- Poucas luzes dinâmicas simultâneas.
- Colisões simplificadas.
- Ocultação de objetos distantes.
- Gerenciamento de NPCs ativos.
- Navegação localizada.
- Quantidade moderada de partículas.
- Redução de renderizações secundárias desnecessárias.

Objetivo inicial: buscar 60 FPS em hardware compatível, com possibilidade de reduzir as configurações.

Evite depender de recursos exclusivos de Vulkan.

Use o renderizador Compatibility como configuração inicial do projeto.

---

# 20. CENAS CINEMATOGRÁFICAS

Crie uma arquitetura de eventos cinematográficos dentro da Godot.

O sistema deve permitir:

- Mover personagens.
- Executar animações.
- Alternar enquadramentos.
- Exibir legendas.
- Acionar sons.
- Controlar portas e objetos.
- Iniciar e encerrar eventos.
- Restaurar o controle do jogador.

Utilize AnimationPlayer, sinais e controladores de sequência quando apropriado.

As cinemáticas devem usar os modelos reais de Dery, Felps e NPCs.

Não substitua personagens por imagens estáticas.

Evite cortes excessivos durante a rotina normal.

---

# 21. SISTEMA DE PROGRESSÃO E EVENTOS

Quero um sistema central de controle narrativo.

O jogo deverá acompanhar:

- Capítulo atual.
- Objetivos concluídos.
- Diálogos já executados.
- Clientes atendidos.
- Eventos desencadeados.
- Estado das portas.
- Alterações ambientais.
- Posição narrativa dos personagens.
- Condições para ativar acontecimentos.

Não baseie toda a história exclusivamente em temporizadores.

Utilize uma combinação de objetivos, localização do jogador, condições e eventos.

Exemplo:

O cliente que alerta sobre o homem suspeito aparece após o jogador concluir um conjunto mínimo de tarefas e ocorrer a progressão adequada do expediente.

O jogador não deve conseguir quebrar a sequência por concluir uma tarefa antes do previsto.

---

# 22. PLANO DE IMPLEMENTAÇÃO

Não tente implementar toda a campanha em uma única etapa.

Quero entregas incrementais, mas cada entrega deverá ser realmente executável.

## ETAPA 1 — BASE JOGÁVEL

Prioridade máxima.

Criar:

1. Projeto Godot 4.4 funcional.
2. Configuração Compatibility.
3. Cena principal.
4. Reconstrução inicial do depósito.
5. Rua explorável baseada nas referências.
6. Importação dos modelos principais.
7. Rigging e animações básicas.
8. Controle de Dery.
9. Câmera sobre o ombro.
10. Transição para primeira pessoa.
11. Colisões.
12. Portas e objetos interativos.
13. Iluminação noturna.
14. Menu simples e interface inicial.

O resultado deve permitir abrir o projeto, executar o jogo e caminhar pelo depósito e pela rua.

A base não deve depender de cenas ou scripts inexistentes.

## ETAPA 2 — ROTINA DO DEPÓSITO

Adicionar:

1. Felps trabalhando no caixa.
2. NPCs clientes.
3. Caminhos de navegação.
4. Sistema de interação com produtos.
5. Reposição de mercadorias.
6. Organização de estoque.
7. Diálogos.
8. Sistema de objetivos.
9. Sons ambientais.

O jogo deve passar a ter um expediente convincente.

## ETAPA 3 — PRIMEIRO EVENTO NARRATIVO

Adicionar:

1. Entrada do cliente preocupado.
2. Conversa sobre o homem estranho.
3. Reação de Felps e Dery.
4. Saída do cliente.
5. Retorno às tarefas.
6. Primeiros sinais discretos de atividade suspeita.

Essa etapa deve finalizar uma primeira demonstração narrativa jogável.

## ETAPA 4 — TERROR E SOBREVIVÊNCIA

Posteriormente:

1. Sistema de câmeras de segurança.
2. Eventos suspeitos.
3. Descoberta do esconderijo.
4. Sistema de inteligência artificial do Enemy.
5. Perseguição.
6. Esconderijos.
7. Progressão dos capítulos.
8. Alternância de protagonistas.
9. Finais.

Não sacrifique a qualidade das primeiras etapas tentando concluir todas simultaneamente.

---

# 23. REQUISITOS DE QUALIDADE

Quero evitar problemas comuns em projetos gerados automaticamente.

Portanto:

**Não entregue:**

- Cenário formado somente por cubos genéricos.
- Personagens substituídos por cápsulas.
- NPCs sem comportamento.
- Personagens deslizando pelo chão.
- Câmera atravessando paredes.
- Modelos sem texturas.
- Rig com deformações graves.
- Ambientes sem iluminação adequada.
- Scripts vazios.
- Funcionalidades apenas descritas, mas não implementadas.
- Cenas referenciando arquivos inexistentes.
- Objetos interativos sem resposta.
- Mensagens constantes de erro.
- Elementos completamente diferentes da direção artística solicitada.

**Priorize:**

- Consistência visual.
- Funcionamento real.
- Boa sensação de movimentação.
- Organização de código.
- Preservação dos modelos.
- Reconstrução fiel das referências.
- Atmosfera convincente.
- Possibilidade de expansão.

Se um recurso estiver incompleto, informe claramente.

Não marque uma funcionalidade como pronta apenas porque criou um script ou uma cena.

---

# 24. VALIDAÇÃO E TESTES

Sempre que o ambiente permitir, execute verificações técnicas.

## Testes essenciais

- O projeto abre na Godot 4.4.
- A cena principal carrega.
- Os modelos aparecem corretamente.
- As texturas estão presentes.
- Os personagens têm escala adequada.
- O jogador consegue andar.
- O jogador consegue correr.
- A câmera funciona.
- A transição entre primeira e terceira pessoa funciona.
- A câmera não atravessa paredes.
- As colisões funcionam.
- As interações podem ser concluídas.
- Os NPCs conseguem entrar e sair.
- O sistema de diálogo funciona.
- Os eventos narrativos respeitam a sequência correta.
- Não existem erros críticos de GDScript.

Execute testes por linha de comando, quando houver Godot disponível.

Quando não puder executar o editor ou verificar visualmente algum resultado, explique essa limitação.

Não invente resultados de testes.

---

# 25. COMO VOCÊ DEVE TRABALHAR

Antes de modificar qualquer arquivo:

1. Inspecione todos os modelos enviados.
2. Identifique os arquivos que podem ser usados diretamente.
3. Examine as fotografias.
4. Examine o Street View ou as capturas disponíveis.
5. Reconstrua mentalmente a disposição espacial do depósito.
6. Identifique as limitações dos modelos para rigging.
7. Planeje a arquitetura das cenas.
8. Defina as dependências da primeira etapa.

Se alguma referência ainda não estiver disponível, não afirme que a analisou. Continue com os sistemas independentes dela, mas mantenha a reconstrução final daquele espaço pendente.

Durante a implementação, trabalhe diretamente nos arquivos reais do projeto.

Não responda apenas com instruções sobre como eu poderia programar.

**Quero que você efetivamente crie e modifique os arquivos necessários.**

Se o projeto estiver conectado a um repositório, utilize a estrutura existente e preserve os assets originais.

Evite recriar arquivos desnecessariamente.

Não apague modelos, texturas ou cenas fornecidas.

Ao concluir uma etapa, forneça:

- Resumo do que foi implementado.
- Arquivos criados ou modificados.
- Funcionalidades verificadas.
- Testes executados.
- Limitações encontradas.
- Pendências.
- Instruções objetivas para executar o projeto.
- Próxima etapa recomendada.

Quando possível, entregue o projeto Godot completo e organizado, pronto para ser aberto no editor.

---

# 26. OBJETIVO IMEDIATO

Sua primeira missão é construir uma **vertical slice jogável do início de Depois do Fechamento**.

Essa demonstração deve incluir:

Dery chegando ou iniciando seu expediente no depósito.

Felps trabalhando no caixa.

O jogador podendo circular entre a área de vendas, o estoque e a entrada do estabelecimento.

Câmera moderna em terceira pessoa com alternância suave para primeira pessoa pela roda do mouse.

Ambiente reconstruído com base nas fotografias e no Street View.

Algumas tarefas reais de reposição.

Clientes NPCs entrando, comprando e saindo.

Conversas naturais entre Dery e Felps.

Atmosfera noturna brasileira.

O primeiro cliente suspeito alertando sobre o homem que está rondando o estabelecimento.

Um pequeno acontecimento perturbador indicando que algo está errado.

A demonstração deve terminar deixando o jogador curioso para continuar.

**Não quero que o terror comece imediatamente. Quero que o jogador se acostume a trabalhar no depósito e passe a acreditar que está em um lugar seguro.**

O contraste entre a rotina normal e a ameaça posterior será a essência da experiência.

# INSTRUÇÃO FINAL

Analise primeiro os arquivos e referências que forneci, organize o plano de execução e inicie a implementação da primeira etapa no projeto Godot.

Tome decisões técnicas razoáveis sem interromper constantemente o trabalho com perguntas sobre detalhes pequenos.

Preserve rigorosamente os três personagens originais.

Construa os NPCs adicionais mantendo a mesma identidade artística.

Trate o depósito real como a principal referência espacial.

Não confunda baixa quantidade de polígonos com baixa qualidade de produção.

**Quero um jogo de terror com gráficos de PS1, mas com movimentação, câmera, interações, direção de cenas e qualidade de experiência de um jogo moderno.**

O resultado precisa transmitir a sensação de estar trabalhando em um depósito de bebidas verdadeiro, em Franca-SP, durante uma noite que começa completamente normal e termina em um pesadelo.