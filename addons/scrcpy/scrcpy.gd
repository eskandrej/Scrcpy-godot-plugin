@tool
extends EditorPlugin

var menuButton: MenuButton
var popupMenu: PopupMenu

var scrcpyMenu = preload("ScrcpyMenu/ScrcpyMenu.tscn").instantiate()

var scrcpy_path: String
var scrcpy_args: String
var enabled: bool

var spawnThreads = []

const SCRCPY_POPUPMENU_ITEM_ID = 420

func load_settings():
	scrcpy_path = ProjectSettings.get_setting("scrcpy_plugin/scrcpy_path", "")
	scrcpy_args = ProjectSettings.get_setting("scrcpy_plugin/scrcpy_args", "")
	enabled = ProjectSettings.get_setting("scrcpy_plugin/enabled", true)
	
func save_settings(p_scrcpy_path, p_scrcpy_args, p_enabled):
	ProjectSettings.set_setting("scrcpy_plugin/scrcpy_path", p_scrcpy_path)
	ProjectSettings.set_setting("scrcpy_plugin/scrcpy_args", p_scrcpy_args)
	ProjectSettings.set_setting("scrcpy_plugin/enabled", p_enabled)
	ProjectSettings.save()
	
func _enter_tree() -> void:
	var editor_run_native = get_editor_run_native()
	if editor_run_native == null: 
		push_error("EditorRunNative is null")
	
	load_settings()
	
	menuButton = editor_run_native.get_child(0) 
	popupMenu = menuButton.get_popup()
	
	scrcpyMenu.scrcpy_main = self
	
	get_editor_interface().get_base_control().add_child(scrcpyMenu)
	
	popupMenu.connect("index_pressed", pressedItemPopupMenu)
	popupMenu.connect("menu_changed", popupMenu_changed)

	popupMenu_changed()

func popupMenu_changed():
	if popupMenu.get_item_index(SCRCPY_POPUPMENU_ITEM_ID) < 0:
		popupMenu.add_item("SCRCPY MENU", SCRCPY_POPUPMENU_ITEM_ID)
	
func extractDeviceID(input_str):
	var regex = RegEx.new()
	regex.compile("Device ID: ([0-9a-f]+)")
	
	var result = regex.search(input_str)
	if result:
		return result.get_string(1)
	else:
		return "Device ID not found"
	
func pressedItemPopupMenu(idx):
	if SCRCPY_POPUPMENU_ITEM_ID == popupMenu.get_item_id(idx):
		scrcpyMenu.popup_centered()
		return
		
	if not enabled: return
	
	if scrcpy_path.is_empty():
		push_error("Scrcpy path is empty! Please set path in SCRCPY MENU.")
		return
	
	if enabled:
		var args = scrcpy_args.split(" ", false)
		var deviceId = extractDeviceID(popupMenu.get_item_tooltip(idx))

		if not deviceId.is_empty(): args.append_array(["-s", deviceId])

		var newThread = Thread.new()
		spawnThreads.append(newThread)
		newThread.start(scrcpy_run_thread.bind(args))
		
func scrcpy_run_thread(args):
	var output = []
	print("Executing scrcpy")
	OS.execute(scrcpy_path, args, output, true)
	print(output)
	
func get_editor_run_native():
	var editor_run_native: Control
	var dummy = Control.new()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, dummy)
	
	for node in dummy.get_parent().get_children():
		if node.is_class("EditorRunBar"):
			for child in node.get_child(0).get_child(0).get_children():
				if child.is_class("EditorRunNative"):
					editor_run_native = child
					break
			break
		
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, dummy)
	dummy.queue_free()
	return editor_run_native

func _exit_tree():
	scrcpyMenu.queue_free()
	for thread in spawnThreads:
		if !thread.is_alive():
			thread.wait_to_finish()
