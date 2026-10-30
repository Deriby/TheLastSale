class_name CheckoutPanel
extends PanelContainer
signal closed
var world: ShiftWorld
var rows: VBoxContainer
var refresh_pending:=false
func _ready() -> void:
	name="CheckoutPanel";custom_minimum_size=Vector2(960,660)
	var margin:=MarginContainer.new();add_child(margin)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,20)
	var scroll:=ScrollContainer.new();scroll.name="CheckoutScroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;margin.add_child(scroll)
	rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",12);scroll.add_child(rows)
	world.checkout_changed.connect(queue_refresh);refresh()
func text(parent: Node,value: String,size := 18) -> Label:
	var label:=Label.new();parent.add_child(label);label.text=value;label.add_theme_font_size_override("font_size",size)
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return label
func action(parent: Node,id: String,title: String,callback: Callable) -> Button:
	var button:=Button.new();button.name=id;button.text=title;button.custom_minimum_size.y=42;parent.add_child(button);button.pressed.connect(callback);return button
func queue_refresh() -> void:
	if refresh_pending:return
	refresh_pending=true;call_deferred("refresh")
func refresh() -> void:
	refresh_pending=false
	if is_queued_for_deletion() or not is_instance_valid(world) or world.sale==null:return
	var focused:=get_viewport().gui_get_focus_owner()
	var focus_name: String=focused.name if focused!=null and is_ancestor_of(focused) else ""
	for child in rows.get_children():rows.remove_child(child);child.queue_free()
	var sale:=world.sale
	var header:=HBoxContainer.new();rows.add_child(header)
	text(header,"JA • FRENTE DE CAIXA",24)
	action(header,"CloseRegister","VOLTAR AO JOGO [ESC]",func():closed.emit())
	text(rows,"Pedido #%03d  •  Vendas do turno: %s"%[sale.id,ShopSale.money(Session.sales_cents)],16)
	var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",24);rows.add_child(columns)
	var order:=VBoxContainer.new();order.custom_minimum_size.x=260;columns.add_child(order);order.add_theme_constant_override("separation",12)
	text(order,"PEDIDO DO CLIENTE",20);text(order,sale.describe(),20)
	text(order,"TOTAL  "+ShopSale.money(sale.total()),23)
	if sale.needs_bulk():
		text(order,"Caixa no balcão • recebida de Deryk" if sale.bulk_supplied else "VENDA #%03d • etiqueta LARANJA no estoque. Deryk entrega na área ENTREGA DE PEDIDOS do balcão. R1/R2 são de reposição."%sale.id,17)
		if not sale.bulk_supplied:action(order,"CallDeryk","CHAMAR DERYK [TAB]",world.request_stock)
	var work:=VBoxContainer.new();work.custom_minimum_size.x=500;work.size_flags_horizontal=Control.SIZE_EXPAND_FILL;work.add_theme_constant_override("separation",8);columns.add_child(work)
	match sale.phase:
		ShopSale.Phase.REGISTER:
			text(work,"1. REGISTRAR PRODUTOS",20)
			for sku in ShopSale.CATALOG:
				var row:=HBoxContainer.new();work.add_child(row)
				var item: Dictionary=ShopSale.CATALOG[sku]
				var add:=action(row,"Register_"+sku,"+  %s  •  %s"%[str(item.name),ShopSale.money(int(item.price))],world.register_product.bind(sku,1));add.size_flags_horizontal=Control.SIZE_EXPAND_FILL
				action(row,"Remove_"+sku,"−",world.register_product.bind(sku,-1))
				text(row,"× "+str(sale.registered.get(sku,0)),18).custom_minimum_size.x=40
			text(work,"Registrado: "+ShopSale.money(ShopSale.sum_items(sale.registered)),21)
			action(work,"ConfirmItems","CONFERIR E COBRAR",world.checkout_step.bind("confirm",0))
		ShopSale.Phase.PAYMENT:
			text(work,"2. RECEBER DINHEIRO",20)
			text(work,"O cliente entrega "+ShopSale.money(sale.tendered)+".",22)
			action(work,"ReceiveCash","RECEBER "+ShopSale.money(sale.tendered),world.checkout_step.bind("receive",0))
		ShopSale.Phase.CHANGE:
			text(work,"3. SEPARAR O TROCO",20)
			text(work,"Recebido: %s\nTroco devido: %s\nSeparado: %s"%[ShopSale.money(sale.tendered),ShopSale.money(sale.change_due()),ShopSale.money(sale.selected_change())],22)
			var grid:=GridContainer.new();grid.columns=3;work.add_child(grid)
			for cents in ShopSale.COINS:action(grid,"Coin_"+str(cents),ShopSale.money(cents),world.checkout_step.bind("coin",cents)).size_flags_horizontal=Control.SIZE_EXPAND_FILL
			var correction:=HBoxContainer.new();work.add_child(correction)
			action(correction,"UndoCoin","RETIRAR ÚLTIMA",world.checkout_step.bind("undo",0))
			action(correction,"ClearChange","LIMPAR TROCO",world.checkout_step.bind("clear",0))
			action(work,"ConfirmChange","ENTREGAR TROCO",world.checkout_step.bind("change",0))
		ShopSale.Phase.READY:
			text(work,"4. ENTREGAR A COMPRA",20)
			text(work,"Produtos conferidos\nPagamento: %s\nTroco: %s"%[ShopSale.money(sale.tendered),ShopSale.money(sale.selected_change())],22)
			action(work,"DeliverPurchase","ENTREGAR COMPRA E CONCLUIR",world.checkout_step.bind("deliver",0))
	text(rows,sale.message,18).custom_minimum_size.y=65
	text(rows,"ESC volta ao jogo • TAB troca para Deryk • o atendimento fica salvo",15)
	if not focus_name.is_empty():
		var next:=find_child(focus_name,true,false) as Button
		if next!=null:next.grab_focus()
