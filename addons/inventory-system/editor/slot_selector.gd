@tool
class_name SlotSelector
extends HBoxContainer

signal changed(item_stack : ItemStack)

@onready var item_id_editor : ItemIDEditor = $ItemIDEditor
@onready var option_button = $OptionButton
@onready var product_amount_spin_box = $ProductAmountSpinBox


var item_stack : ItemStack:
	set(new_item_stack):
		item_stack = new_item_stack
	get:
		return item_stack

var database : InventoryDatabase
var ids_list : Array[ItemDefinition]

# Called when the node enters the scene tree for the first time.
func _ready():		
	item_id_editor.changed.connect(_on_product_id_spin_box_value_changed)
	option_button.item_selected.connect(_on_option_button_item_selected)
	product_amount_spin_box.value_changed.connect(_on_product_amount_spin_box_value_changed)
	

func setup(item_stack : ItemStack, database : InventoryDatabase):
	self.item_stack = item_stack
	self.database = database
	if not item_stack.item_id.is_empty():
		var id = item_stack.item_id
		item_id_editor.setup(database, id)
		product_amount_spin_box.value = item_stack.amount
		ids_list.clear()
		option_button.clear()

	for i in database.items.size():
		var item = database.items[i]
		option_button.add_icon_item(item.icon ,item.name)
		ids_list.append(item)
		if item.id == item_stack.item_id:
			option_button.select(i)
	var popup : PopupMenu = option_button.get_popup()
	for i in database.items.size():
		popup.set_item_icon_max_width(i, 24)


func _on_product_id_spin_box_value_changed(value : String):
	var item = database.get_item(value)
	if item == null:
		if option_button.selected == -1:
			push_warning("An item no longer exists in the list, a first item has been replaced.")
			option_button.selected = 0
		item = ids_list[option_button.selected]
		product_amount_spin_box.value = item.amount
	item_stack.item_id = item.id
	var index = ids_list.find(database.get_item(item_stack.item_id))
	if index != -1:
		if option_button.selected != index:
			_on_option_button_item_selected(index)
			option_button.selected = index


func _on_product_amount_spin_box_value_changed(value):
	item_stack.amount = int(value)
	changed.emit(item_stack)


func _on_option_button_item_selected(index):
	var item : ItemDefinition = ids_list[index]
	item_stack.item_id = item.id
	if item_id_editor.id != item.id:
		item_id_editor.setup(database, item.id)
	changed.emit(item_stack)	
