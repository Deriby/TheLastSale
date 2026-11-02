class_name FieldNotebook
extends PanelContainer
signal closed
var world: ShiftWorld
var current_task:=""
var pages: Array[Control]=[]
var tabs: Array[Button]=[]
var page_label: Label
var selected_page:=0
func _ready() -> void:
 name="FieldNotebook";custom_minimum_size=Vector2(940,620);theme=GamePanels.theme(true)
 var style:=GamePanels.box(GamePanels.PAPER,Color("9b8b6b"),26,3);style.shadow_color=Color(0,0,0,.5);style.shadow_size=18;style.shadow_offset=Vector2(0,9);add_theme_stylebox_override("panel",style)
 var body:=VBoxContainer.new();add_child(body);body.add_theme_constant_override("separation",14)
 var header:=HBoxContainer.new();body.add_child(header)
 var titles:=VBoxContainer.new();header.add_child(titles);titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL;titles.add_theme_constant_override("separation",0)
 GamePanels.title(titles,"DEPÓSITO JA / ANOTAÇÕES DO TURNO","CADERNO DO EXPEDIENTE",true)
 var close:=GamePanels.button(header,"CloseNotebook","VOLTAR [J / ESC]",func():closed.emit());close.grab_focus()
 GamePanels.rule(body,Color("a99c7b"))
 var area:=HBoxContainer.new();body.add_child(area);area.size_flags_vertical=Control.SIZE_EXPAND_FILL;area.add_theme_constant_override("separation",24)
 var navigation:=VBoxContainer.new();area.add_child(navigation);navigation.custom_minimum_size.x=162
 GamePanels.label(navigation,Session.night_title().to_upper(),14,Color("716349"),GamePanels.MONO)
 GamePanels.label(navigation,Session.clock_text(),36,GamePanels.INK,TitlePresentation.VCR)
 for i in 3:
  var tab:=GamePanels.button(navigation,["MissionTab","NotesTab","ControlsTab"][i],["01  MISSÕES","02  REGISTROS","03  CONTROLES"][i],show_page.bind(i));tab.alignment=HORIZONTAL_ALIGNMENT_LEFT;tab.add_theme_font_size_override("font_size",14);tabs.append(tab)
 var spacer:=Control.new();navigation.add_child(spacer);spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
 GamePanels.label(navigation,"DERYK / REPOSIÇÃO\nFELPS / CAIXA",12,Color("716349"),GamePanels.MONO)
 var content:=Control.new();area.add_child(content);content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.size_flags_vertical=Control.SIZE_EXPAND_FILL
 for i in 3:
  var scroll:=ScrollContainer.new();scroll.name=["MissionPage","NotesPage","ControlsPage"][i];content.add_child(scroll);scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true
  var col:=VBoxContainer.new();scroll.add_child(col);col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.add_theme_constant_override("separation",14);pages.append(scroll)
  if i==0:build_missions(col)
  elif i==1:build_notes(col)
  else:build_controls(col)
 GamePanels.rule(body,Color("b0a182"))
 var footer:=HBoxContainer.new();body.add_child(footer);GamePanels.label(footer,"J / ESC  fechar caderno     •     expediente em pausa",12,Color("716349"),GamePanels.MONO);page_label=GamePanels.label(footer,"",13,Color("716349"),GamePanels.MONO);page_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 show_page(0);GamePanels.enter(self)
func show_page(index: int) -> void:
 selected_page=index
 for i in pages.size():
  pages[i].visible=i==index
  tabs[i].add_theme_stylebox_override("normal",GamePanels.box(Color("b8bea6") if i==index else Color("d8d0b9"),Color("7b8766") if i==index else Color("b3a78b"),10))
 page_label.text="FOLHA 0%d / 03"%(index+1)
 GamePanels.enter(pages[index])
func item(parent: Node,title: String,detail: String,done: bool,extra: bool=false) -> void:
 var row:=HBoxContainer.new();parent.add_child(row)
 var check:=GamePanels.label(row,"✓" if done else "○",22,Color("526f4a") if done else Color("95896e"));check.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;check.custom_minimum_size.x=24
 var text:=VBoxContainer.new();row.add_child(text);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.add_theme_constant_override("separation",2)
 GamePanels.label(text,title+("  / EXTRA" if extra else ""),17,Color("526f4a") if done else GamePanels.INK)
 GamePanels.label(text,detail,13,Color("71664f"))
func build_missions(column: VBoxContainer) -> void:
 var current:=GamePanels.card(column,GamePanels.PAPER,true);current.get_parent().add_theme_stylebox_override("panel",GamePanels.box(Color("f2ead7"),Color("b3a17a"),16,2))
 GamePanels.label(current,"AGORA / "+world.player.display_name().to_upper(),12,Color("8b5e36"),GamePanels.MONO)
 var task:=GamePanels.label(current,current_task,20,GamePanels.INK);task.name="CurrentTask"
 GamePanels.label(column,"O QUE FALTA NO TURNO",25,GamePanels.INK,TitlePresentation.DISPLAY)
 var count:=0;var total:=0
 if int(Session.campaign.night)==0:
  if Session.campaign.phase in ["outage","restored"]:
   for data in [["counter_secured","Suspender o atendimento","Felps / caixa"],["generator_key","Pegar a chave do gerador","Deryk / suporte junto à porta do estoque"],["generator_running","Restabelecer a energia","Deryk / gerador no pátio"]]:
    var done:=Session.flag(data[0]);item(column,data[1],data[2],done);total+=1;count+=int(done)
  elif Session.campaign.phase=="closing":
   for data in [["till_closed","Conferir o caixa","Felps / balcão"],["stock_checked","Conferir a porta antiga","Deryk / fundos do estoque"],["lights_off","Apagar a iluminação do salão","Quadro junto à porta do estoque"],["reunite","Reunir os dois na saída","Calçada / comando das portas"]]:
    var done:=Session.flag(data[0]);item(column,data[1],data[2],done);total+=1;count+=int(done)
  else:
   for data in [["stock_1","Repor R1","G1 / primeira geladeira da parede esquerda"],["stock_2","Repor R2","G1 / mesma geladeira"],["loose","Organizar cascos vazios","Palete DEVOLUÇÕES / fundo esquerdo do estoque"]]:
    var done: bool=Session.organized if data[0]=="loose" else data[0] in Session.stocked;item(column,data[1],data[2],done);total+=1;count+=int(done)
   item(column,"Repor R3","P1 / prateleira de salgadinhos perto da entrada","stock_shelf" in Session.stocked,true)
   GamePanels.label(column,"Caixas laranja VENDA pertencem aos pedidos do caixa. Entregue a da numeração atual na marca do balcão. Na geladeira: E abre, E novamente repõe.",14,Color("71664f"))
 elif int(Session.campaign.night)==1:
  if Session.campaign.phase in ["saturday_intro","saturday_routine"]:
   item(column,"Atender os dois clientes","Felps / frente de caixa — %d de 2 atendidos"%Session.customers_served,Session.customers_served>=2);total=1;count=int(Session.customers_served>=2)
  else:
   for data in [["dvr_service","Conferir o registro do pátio","Felps / câmeras no computador [C]"],["door_marks","Examinar a fechadura antiga","Deryk / porta SEM ACESSO"],["moved_boxes","Verificar as caixas deslocadas","Deryk / fundos do estoque"],["visitor_receipt","Separar o recibo do visitante","Felps / caderno do computador"]]:
    var done:=bool(Session.campaign.clues.get(data[0],false));item(column,data[1],data[2],done);total+=1;count+=int(done)
   GamePanels.label(column,"As decisões sobre os registros, o contato e a saída ficam no caderno do computador [C].",14,Color("71664f"))
 else:
  var jobs: Array=[["module_found","Recuperar o módulo do DVR","Deryk / área de manutenção"],["module_delivered","Levar o módulo ao balcão","Deryk / entregar para Felps"],["clip_reviewed","Recuperar e analisar a gravação","Felps / terminal do caixa [C]"]]
  if Session.campaign.phase=="sunday_escape":jobs=[["generator_running","Ligar o gerador","Deryk / pátio"],["stock_released","Liberar a porta do estoque","Felps / terminal ou comando da porta"],["front_open","Abrir a saída","Comando manual na frente do salão"]]
  for data in jobs:
   var done:=Session.flag(data[0]);item(column,data[1],data[2],done);total+=1;count+=int(done)
 if int(Session.campaign.night)==0:
  GamePanels.label(column,"PELO DEPÓSITO",23,GamePanels.INK,TitlePresentation.DISPLAY)
  GamePanels.label(column,"A porta ESTOQUE fica no fundo do corredor. R1 e R2 vão na primeira geladeira da parede esquerda, G1. R3 vai na P1, perto da entrada. O palete DEVOLUÇÕES fica no fundo esquerdo do estoque. A lista presa ao balcão pode ser consultada com E.",14,Color("71664f"))
 var progress:=ProgressBar.new();column.add_child(progress);progress.custom_minimum_size.y=5;progress.show_percentage=false;progress.max_value=maxi(total,1);progress.value=count
 GamePanels.label(column,"%d DE %d ETAPAS CONCLUÍDAS"%[count,total],12,Color("71664f"),GamePanels.MONO)
func build_notes(column: VBoxContainer) -> void:
 GamePanels.title(column,"REGISTROS DO EXPEDIENTE","O QUE FOI ANOTADO",true)
 if not str(Session.campaign.friday_story.recap).is_empty():GamePanels.label(column,Session.campaign.friday_story.recap,17,GamePanels.INK,TitlePresentation.TYPEWRITER)
 if int(Session.campaign.night)==1:GamePanels.label(column,world.saturday.journal(),16)
 var notes: Array=Session.campaign.experience.notes
 if notes.is_empty():GamePanels.label(column,"Por enquanto, só mais um expediente.",18,Color("71664f"),TitlePresentation.TYPEWRITER)
 for entry in notes:
  if not entry is Dictionary:continue
  GamePanels.rule(column,Color("c1b598"));GamePanels.label(column,["SEX","SÁB","DOM"][clampi(int(entry.get("night",0)),0,2)]+" / "+str(entry.get("time","")),12,Color("8b5e36"),GamePanels.MONO);GamePanels.label(column,str(entry.get("text","")),17,GamePanels.INK,TitlePresentation.TYPEWRITER)
func build_controls(column: VBoxContainer) -> void:
 GamePanels.title(column,"LEMBRETES DA DUPLA","CONTROLES",true)
 for data in [["WASD / MOUSE","Mover e olhar"],["RODA DO MOUSE","Aproximar e afastar entre primeira e terceira pessoa"],["E / Q","Interagir / apoiar a caixa"],["TAB","Trocar Deryk e Felps"],["SHIFT / CTRL","Correr / agachar"],["F / H","Lanterna / acompanhar ou aguardar"],["C","Câmeras e terminal no caixa"],["ESPAÇO","Continuar a conversa"],["J / ESC","Caderno / pausa"]]:
  GamePanels.label(column,data[0],14,Color("8b5e36"),GamePanels.MONO);GamePanels.label(column,data[1],16)
