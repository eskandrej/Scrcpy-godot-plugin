@tool
extends PopupPanel

@onready var file_dialog = $FileDialog
@onready var link_rtl = %LinkRTL
@onready var scrcpy_path_ted = %SPathTEd
@onready var custom_args_ted = %CustomArgsTEd
@onready var enabled_chk_btn = %EnabledChkBtn

var scrcpy_main = null

func _ready():
	if scrcpy_main != null:
		scrcpy_path_ted.text = scrcpy_main.scrcpy_path
		custom_args_ted.text = scrcpy_main.scrcpy_args
		enabled_chk_btn.button_pressed = scrcpy_main.enabled
	hide()

func _on_file_dialog_confirmed():
	scrcpy_path_ted.text = file_dialog.current_path

func _on_close_btn_pressed():
	hide()

func _on_browse_btn_pressed():
	file_dialog.popup_centered()

func _on_link_rtl_meta_clicked(meta):
	OS.shell_open(meta);

func _on_popup_hide():
	scrcpy_main.scrcpy_path = scrcpy_path_ted.text
	scrcpy_main.scrcpy_args = custom_args_ted.text
	scrcpy_main.enabled = enabled_chk_btn.button_pressed
	scrcpy_main.save_settings(scrcpy_path_ted.text, custom_args_ted.text, enabled_chk_btn.button_pressed)
