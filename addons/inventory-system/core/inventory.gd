@icon("res://addons/inventory-system/icons/inventory.svg")
extends Node
class_name Inventory

## This script stores an array of slots via [Dictionary].
##
## This slot contains information about an [Item] and its quantity.

## Emitted when a amount or item has changed in any slot
signal inventory_changed

## Emitted when a slot was added.
## This signal is emitted after calling  [code]add[/code]  function and happens only when there is no space available and  [code]create_slot_if_needed[/code]  is set to true.
signal slot_added(slot_index : int)

## Emitted when a slot was removed.
## This signal is emitted after calling the  [code]remove[/code]  function and happens only when the slot is empty and the  [code]remove_slot_if_empty[/code]  is set to true.
signal slot_removed(slot_index : int)

## Emitted when inventory is filled.
## This signal is emitted after the  [code]add[/code]  ,  [code]add_at[/code]  or  [code]set_slot[/code]  function and it only happens when all slots are filled.
signal filled

## Emitted when inventory is empty.
## This signal is emitted after the  [code]remove[/code]  ,  [code]remove_at[/code]  or  [code]set_slot[/code]  function and it only happens when all slots are empty or there are no slots.
signal emptied

## Emitted when a slot has been changed.
## This signal is issued after functions that change the inventory content:  [code]add[/code] ,  [code]add_at[/code] ,  [code]remove[/code] ,  [code]remove-at[/code]  and  [code]set_slot[/code] .
signal updated_slot(slot_index : int)

## Emitted when inventory is opened.
## Called inside the [b]open()[/b] function when the inventory is closed.
signal opened

## Emitted when inventory is closed.
## Called inside the [b]close()[/b] function when the inventory is closed.
signal closed


## Array of [Dictionary] that stores items and their quantities
## The dictionary uses [b]"item_id"[/b] to store item id information
## and [b]"amount"[/b] for your quantity
@export var slots : Array

## It stores information if this inventory is open or not.
@export var is_open := false

## Creates a slot when use  [code]add[/code]  for adding item to inventory when it is full
@export var create_slot_if_needed := false

## Removes a slot when the slot becomes empty using  [code]remove[/code]  function
@export var remove_slot_if_empty := false

## Sets the initial amount of slots in the inventory in the [code]_ready[/code] function
@export var slot_amount := 16

## The name of the inventory, to be displayed in UI
@export var inventory_name := "Inventory"

## Database used to identify [InventoryItem] and [DroppedItem] ids.
@export var database : InventoryDatabase


func _ready():
	_load_slots()


## Define slot specific index information
func set_slot(slot_index : int, item : InventoryItem, amount : int):
	if slot_index >= slots.size():
		return
	var item_id = database.get_id_from_item(item)
	var old_amount = get_amount()
	var slot = slots[slot_index]
	slot.item_id = item_id
	slot.amount = amount
	slots[slot_index] = slot
	emit_signal("updated_slot", slot_index)
	_call_events(old_amount)


## Define slot specific index information
func set_slot_with_other_slot(slot_index : int, other_slot : Dictionary):
	if slot_index >= slots.size():
		return
	var old_amount = get_amount()
	var slot = slots[slot_index]
	slot.item_id = other_slot.item_id
	slot.amount = other_slot.amount
	slots[slot_index] = slot
	emit_signal("updated_slot", slot_index)
	_call_events(old_amount)


## Returns true if the slot is empty
func is_empty_slot(slot_index : int) -> bool:
	if slots.size() <= slot_index:
		return true
	var slot = slots[slot_index]
	if slot.has("amount") and slot.amount > 0:
		return false;
	return true;


## Returns true if inventory is empty
func is_empty() -> bool:
	return get_amount() == 0


## Returns true if inventory is full
func is_full() -> bool:
	for slot in slots:
		var item_id = slot.item_id
		if item_id <= InventoryItem.NONE:
			return false
		var item = database.get_item(item_id)
		if slot.amount < item.max_stack:
			return false
	return true


## Returns true if the inventory contains the quantity of the specified item
func contains(item : InventoryItem, amount := 1) -> bool:
	var item_id = database.get_id_from_item(item)
	if item_id <= InventoryItem.NONE:
		return 0
	var amount_in_inventory = 0
	for slot in slots:
		if slot.item_id == item_id:
			amount_in_inventory += slot.amount
			if amount_in_inventory > amount:
				return true
	return false


## Returns amount of the specified item in inventory
func get_amount_of(item : InventoryItem) -> int:
	var item_id = database.get_id_from_item(item)
	if item_id <= InventoryItem.NONE:
		return 0
	var amount_in_inventory = 0;
	for slot in slots:
		if slot.item_id == item_id:
			amount_in_inventory += slot.amount
	return amount_in_inventory


## Returns amount of items in inventory
func get_amount() -> int:
	var amount_in_inventory = 0
	for slot in slots:
		amount_in_inventory += slot.amount
	return amount_in_inventory


## Adds a amount of the item to the inventory and 
## returns the amount that was left and not added
func add(item : InventoryItem, amount : int) -> int:
	var amount_in_interact = amount;
	var old_amount = get_amount()
	for i in range(slots.size()):
		amount_in_interact = _add_to_slot(i, item, amount_in_interact)
	if create_slot_if_needed and amount_in_interact > 0:
		_add_slot(slots.size())
		amount_in_interact = _add_to_slot(slots.size() - 1, item, amount_in_interact)
		_call_events(old_amount)
	return amount_in_interact


## Adds a amount of the item to the specified inventory slot index
## and returns the amount left over that was not added
func add_at(slot_index : int, item : InventoryItem, amount := 1) -> int:
	var amount_in_interact = amount
	var old_amount = get_amount()
	if slot_index < slots.size():
		amount_in_interact = _add_to_slot(slot_index, item, amount_in_interact)
		_call_events(old_amount)
	return amount_in_interact


## Removes a amount of the item from inventory and 
## returns the amount that was not removed
func remove(item : InventoryItem, amount := 1) -> int:
	var amount_in_interact = amount
	var old_amount = get_amount()
	for i in range(slots.size()-1, -1, -1):
		var slot = slots[i]
		amount_in_interact = _remove_from_slot(i, item, amount_in_interact)
		if remove_slot_if_empty and slot.amount == 0:
			_remove_slot(i)
			_call_events(old_amount)
	return amount_in_interact


## Removes an item quantity to the specified inventory slot index
## and returns the remaining value that was not removed
func remove_at(slot_index : int, item : InventoryItem, amount := 1) -> int:
	var amount_in_interact = amount
	var old_amount = get_amount()
	if slot_index < slots.size():
		var slot = slots[slot_index]
		amount_in_interact = _remove_from_slot(slot_index, item, amount_in_interact)
		if remove_slot_if_empty and slot.amount == 0:
			_remove_slot(slot_index)
			_call_events(old_amount)
	return amount_in_interact


## Opens the inventory and returns true if done successfully.
## Emits the [b]opened[/b] signal if the was previously closed.
func open() -> bool:
	if !is_open:
		is_open = true
		emit_signal("opened")
		return true
	return false


## Closes the inventory and returns true if done successfully.
## Emits the [b]closed[/b] signal if was previously open.
func close() -> bool:
	if is_open:
		is_open = false
		emit_signal("closed")
		return true
	return false


func _load_slots():
	if not create_slot_if_needed:
		for i in slot_amount:
			_add_slot(i, false)


func _remove_slot(slot_index):
	slots.remove_at(slot_index)
	emit_signal("slot_removed", slot_index)


func _add_slot(slot_index : int, emit_signal := true):
	var slot = { "item_id": InventoryItem.NONE, "amount": 0 }
	slots.insert(slot_index, slot)
	if emit_signal:
		emit_signal("slot_added", slot_index)


func _call_events(old_amount : int):
	var actual_amount = get_amount()
	if old_amount != actual_amount:
		emit_signal("inventory_changed")
		if is_empty():
			emit_signal("emptied")
		if is_full():
			emit_signal("filled")


func _add_to_slot(slot_index : int, item : InventoryItem, amount := 1) -> int:
	var item_id = database.get_id_from_item(item)
	if item_id <= InventoryItem.NONE:
		print(item_id)
		return amount
	var slot = slots[slot_index]
	if amount <= 0 or (slot.item_id != item_id and slot.item_id != InventoryItem.NONE):
		return amount
	var amount_to_add = min(amount, item.max_stack - slot.amount)
	slot.amount = slot.amount + amount_to_add;
	if amount_to_add > 0 and slot.item_id == InventoryItem.NONE:
		slot.item_id = item_id
	emit_signal("updated_slot", slot_index)
	return amount - amount_to_add;


func _remove_from_slot(slot_index : int, item : InventoryItem, amount := 1) -> int:
	var item_id = database.get_id_from_item(item)
	if item_id < 0:
		return amount
	var slot = slots[slot_index]
	var item_slot = slot.item_id
	if amount <= 0 or (item_slot != item_id && item_slot != InventoryItem.NONE):
		return amount;
	var amount_to_remove = min(amount, slot.amount);
	slot.amount = slot.amount - amount_to_remove;
	if slot.amount <= 0:
		slot.item_id = InventoryItem.NONE;
	emit_signal("updated_slot", slot_index);
	return amount - amount_to_remove;
