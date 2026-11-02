class_name CheckoutPanel
extends PanelContainer
signal closed
var world: ShiftWorld
var rows: VBoxContainer
var work: VBoxContainer
var receipt: VBoxContainer
var amount: Label
var status: Label
var subtotal: Label
var selected: Label
var due: Label
var order_number: Label
var shift_total: Label
var workflow: Array[Label]=[]
var quantities: Dictionary={}
var refresh_pending:=false
var phase_shown:=-1
var error_count:=-1
var status_tween: Tween
func _ready() -> void:
 name="CheckoutPanel";custom_minimum_size=Vector2(1060,650);theme=GamePanels.theme()
 var frame:=GamePanels.box(Color("14221d"),Color("7c8769"),20,7);frame.shadow_color=Color(0,0,0,.45);frame.shadow_size=18;frame.shadow_offset=Vector2(0,8);add_theme_stylebox_override("panel",frame)
 rows=VBoxContainer.new();add_child(rows);rows.add_theme_constant_override("separation",14)
 var header:=HBoxContainer.new();rows.add_child(header)
 var identity:=VBoxContainer.new();header.add_child(identity);identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.add_theme_constant_override("separation",0)
 GamePanels.title(identity,"JA / SISTEMA DE VENDAS • ESTAÇÃO 01","FRENTE DE CAIXA")
 var operator:=GamePanels.label(header,"FELPS\nOPERADOR DO TURNO",13,GamePanels.MUTED,GamePanels.MONO);operator.size_flags_horizontal=Control.SIZE_SHRINK_END;operator.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;operator.autowrap_mode=TextServer.AUTOWRAP_OFF;operator.custom_minimum_size.x=170;operator.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 GamePanels.button(header,"CloseRegister","VOLTAR [ESC]",func():closed.emit()).size_flags_vertical=Control.SIZE_SHRINK_CENTER
 var steps:=HBoxContainer.new();rows.add_child(steps)
 for i in 4:
  var chip:=GamePanels.label(steps,"0%d  %s"%[i+1,["PRODUTOS","PAGAMENTO","TROCO","ENTREGA"][i]],14,GamePanels.MUTED,GamePanels.MONO);workflow.append(chip)
 GamePanels.rule(rows)
 var columns:=HBoxContainer.new();rows.add_child(columns);columns.size_flags_vertical=Control.SIZE_EXPAND_FILL;columns.add_theme_constant_override("separation",18)
 receipt=GamePanels.card(columns,GamePanels.PAPER,true);receipt.get_parent().custom_minimum_size.x=290;receipt.get_parent().size_flags_horizontal=Control.SIZE_FILL;receipt.get_parent().size_flags_vertical=Control.SIZE_EXPAND_FILL
 var top:=HBoxContainer.new();receipt.add_child(top);GamePanels.label(top,"DEPÓSITO JA",22,GamePanels.INK,TitlePresentation.TYPEWRITER)
 order_number=GamePanels.label(receipt,"",13,Color("6b624b"),GamePanels.MONO)
 GamePanels.rule(receipt,Color("b2a68c"));GamePanels.label(receipt,"PEDIDO DO CLIENTE",12,Color("6b624b"),GamePanels.MONO)
 for sku in world.sale.order:
  var row:=HBoxContainer.new();receipt.add_child(row)
  GamePanels.label(row,"%d × %s"%[world.sale.order[sku],ShopSale.CATALOG[sku].name],15)
 GamePanels.rule(receipt,Color("b2a68c"));GamePanels.label(receipt,"TOTAL DA COMPRA",12,Color("6b624b"),GamePanels.MONO)
 amount=GamePanels.label(receipt,"",42,GamePanels.INK,TitlePresentation.VCR)
 if world.sale.needs_bulk():
  var supplied:=world.sale.bulk_supplied
  GamePanels.label(receipt,"CAIXA RECEBIDA" if supplied else "AGUARDANDO ESTOQUE",13,Color("436341") if supplied else Color("926332"),GamePanels.MONO)
  GamePanels.label(receipt,"Caixa entregue por Deryk no balcão." if supplied else "VENDA #%03d • etiqueta LARANJA. Deryk entrega na marca do balcão. R1/R2 são de reposição."%world.sale.id,14)
  if not supplied:GamePanels.button(receipt,"CallDeryk","CHAMAR DERYK [TAB]",world.request_stock)
 var space:=Control.new();receipt.add_child(space);space.size_flags_vertical=Control.SIZE_EXPAND_FILL
 GamePanels.rule(receipt,Color("b2a68c"));shift_total=GamePanels.label(receipt,"",12,Color("6b624b"),GamePanels.MONO)
 work=GamePanels.card(columns);work.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL;work.get_parent().size_flags_vertical=Control.SIZE_EXPAND_FILL
 status=GamePanels.label(rows,"",15);status.name="RegisterStatus";status.custom_minimum_size.y=24
 GamePanels.label(rows,"ESC  voltar ao jogo     TAB  trocar para Deryk     •     atendimento salvo",12,GamePanels.MUTED,GamePanels.MONO)
 world.checkout_changed.connect(queue_refresh);refresh();GamePanels.enter(self)
func action(parent: Node,id: String,value: String,callback: Callable,primary: bool=false) -> Button:
 return GamePanels.button(parent,id,value,callback,primary)
func queue_refresh() -> void:
 if refresh_pending:return
 refresh_pending=true;call_deferred("refresh")
func refresh() -> void:
 refresh_pending=false
 if is_queued_for_deletion() or not is_instance_valid(world) or world.sale==null:return
 var sale:=world.sale
 order_number.text="PEDIDO %03d / %s"%[sale.id,Session.clock_text()];amount.text=ShopSale.money(sale.total());shift_total.text="VENDAS DO TURNO\n"+ShopSale.money(Session.sales_cents)
 for i in workflow.size():workflow[i].add_theme_color_override("font_color",GamePanels.GOLD if i==mini(sale.phase,3) else Color("7f9d81") if i<sale.phase else GamePanels.MUTED)
 if phase_shown!=int(sale.phase):
  phase_shown=int(sale.phase)
  for child in work.get_children():work.remove_child(child);child.queue_free()
  quantities.clear();subtotal=null;selected=null;due=null;build_phase();GamePanels.enter(work)
 for sku in quantities:quantities[sku].text="× %d"%int(sale.registered.get(sku,0))
 if subtotal!=null:subtotal.text=ShopSale.money(ShopSale.sum_items(sale.registered))
 if selected!=null:selected.text=ShopSale.money(sale.selected_change())
 if due!=null:due.text=ShopSale.money(sale.change_due())
 if status.text!=sale.message:
  status.text=sale.message
  status.add_theme_color_override("font_color",Color("f1b29b") if sale.errors>maxi(error_count,0) else Color("d2dbc9"))
  if status_tween!=null:status_tween.kill()
  status.modulate.a=.45;status_tween=create_tween();status_tween.tween_property(status,"modulate:a",1.0,.15)
 error_count=sale.errors
func build_phase() -> void:
 var sale:=world.sale
 match sale.phase:
  ShopSale.Phase.REGISTER:
   GamePanels.label(work,"REGISTRAR PRODUTOS",26,Color("e9e8dc"),TitlePresentation.DISPLAY)
   GamePanels.label(work,"Confira o pedido ao lado. Adicione cada unidade.",14,GamePanels.MUTED)
   var grid:=GridContainer.new();grid.name="ProductCatalog";grid.columns=2;work.add_child(grid);grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   for sku in ShopSale.CATALOG:
    var row:=HBoxContainer.new();grid.add_child(row);row.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_theme_constant_override("separation",4)
    var item: Dictionary=ShopSale.CATALOG[sku]
    var add:=action(row,"Register_"+sku,str(item.name)+"\n+ "+ShopSale.money(int(item.price)),world.register_product.bind(sku,1));add.add_theme_font_size_override("font_size",14);add.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add.custom_minimum_size=Vector2(162,64);add.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    var qty:=GamePanels.label(row,"",15,GamePanels.GOLD,GamePanels.MONO);qty.custom_minimum_size.x=35;qty.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;qty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;quantities[sku]=qty
    action(row,"Remove_"+sku,"−",world.register_product.bind(sku,-1)).custom_minimum_size.x=28
   var gap:=Control.new();work.add_child(gap);gap.size_flags_vertical=Control.SIZE_EXPAND_FILL
   GamePanels.rule(work);GamePanels.label(work,"VALOR REGISTRADO",12,GamePanels.MUTED,GamePanels.MONO);subtotal=GamePanels.label(work,"",36,GamePanels.GOLD,TitlePresentation.VCR)
   action(work,"ConfirmItems","CONFERIR E COBRAR  →",world.checkout_step.bind("confirm",0),true)
  ShopSale.Phase.PAYMENT:
   GamePanels.label(work,"RECEBER DINHEIRO",30,Color("e9e8dc"),TitlePresentation.DISPLAY)
   GamePanels.label(work,"O cliente entrega",16,GamePanels.MUTED);GamePanels.label(work,ShopSale.money(sale.tendered),64,GamePanels.GOLD,TitlePresentation.VCR)
   GamePanels.label(work,"Receba o valor para abrir a gaveta de troco.",16)
   action(work,"ReceiveCash","RECEBER "+ShopSale.money(sale.tendered),world.checkout_step.bind("receive",0),true).grab_focus()
  ShopSale.Phase.CHANGE:
   GamePanels.label(work,"SEPARAR O TROCO",30,Color("e9e8dc"),TitlePresentation.DISPLAY)
   var totals:=HBoxContainer.new();work.add_child(totals)
   for i in 2:
    var col:=VBoxContainer.new();totals.add_child(col);col.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    GamePanels.label(col,"TROCO DEVIDO" if i==0 else "SEPARADO NA GAVETA",12,GamePanels.MUTED,GamePanels.MONO)
    var value:=GamePanels.label(col,"",38,GamePanels.GOLD if i==1 else Color("e9e8dc"),TitlePresentation.VCR)
    if i==0:due=value
    else:selected=value
   GamePanels.label(work,"Recebido: "+ShopSale.money(sale.tendered),14,GamePanels.MUTED)
   var grid:=GridContainer.new();grid.name="CashDrawer";grid.columns=3;work.add_child(grid)
   for cents in ShopSale.COINS:
    var coin:=action(grid,"Coin_"+str(cents),ShopSale.money(cents),world.checkout_step.bind("coin",cents));coin.size_flags_horizontal=Control.SIZE_EXPAND_FILL;coin.add_theme_font_override("font",GamePanels.MONO);coin.custom_minimum_size.y=43
   var correction:=HBoxContainer.new();work.add_child(correction)
   action(correction,"UndoCoin","RETIRAR ÚLTIMA",world.checkout_step.bind("undo",0)).size_flags_horizontal=Control.SIZE_EXPAND_FILL
   action(correction,"ClearChange","LIMPAR",world.checkout_step.bind("clear",0)).size_flags_horizontal=Control.SIZE_EXPAND_FILL
   action(work,"ConfirmChange","ENTREGAR TROCO  →",world.checkout_step.bind("change",0),true).grab_focus()
  ShopSale.Phase.READY,ShopSale.Phase.COMPLETE:
   GamePanels.label(work,"COMPRA CONFERIDA",34,Color("e9e8dc"),TitlePresentation.DISPLAY)
   GamePanels.label(work,"Produtos registrados e troco correto.",16,GamePanels.MUTED)
   GamePanels.rule(work);GamePanels.label(work,"PAGAMENTO    "+ShopSale.money(sale.tendered)+"\nTROCO               "+ShopSale.money(sale.selected_change()),20,GamePanels.GOLD,TitlePresentation.VCR)
   if sale.phase==ShopSale.Phase.READY:action(work,"DeliverPurchase","ENTREGAR COMPRA E CONCLUIR",world.checkout_step.bind("deliver",0),true).grab_focus()
   else:GamePanels.label(work,"VENDA FINALIZADA",22,Color("a1c49b"),GamePanels.MONO)
