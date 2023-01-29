extends Resource
class_name InventoryDatabase

## TODO DOC Scene containing the dropable item version, this information is used by [InventoryHandler] to drop items
@export var items : Array


# TODO Create loading pickables items and items with folder
# @export var path_test := "res://addons/inventory-system/demos/fps/items/"
#func load_items():
#	for item_list in item_list_test:
#		var obj = load(str(path_test, item_list.name, ".tres"))
#		var item = obj as Item
#		items.append(items)
		
#var item_data_example = {
#	"item" : resource,
#	"id" : 0,
#	"pickable_item", packedScene,
#	"hand_item", packedScene,
#}


func get_id_from_item(item : InventoryItem) -> int:
	for item_data in items:
		if item_data.item == item:
			return item_data.id
	printerr("item ",item," is not in the database!")
	return -1


func get_id_from_pickable_item(pickable_item : PickableItem) -> int:
	for item_data in items:
		if item_data.pickable_item == pickable_item:
			return item_data.id
	printerr("pickable_item ",pickable_item," is not in the database!")
	return -1


func get_item(id : int) -> InventoryItem:
	for item_data in items:
		if item_data.id == id:
			return item_data.item
	printerr("id ",id," is not in the database!")
	return null


func get_pickable_item(id : int) -> PackedScene:
	for item_data in items:
		if item_data.id == id:
			return item_data.pickable_item
	printerr("id ",id," is not in the database!")
	return null
