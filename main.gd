@icon("res://addons/gamejolt_api/gj_icon.png")
class_name GameJoltAPI extends HTTPRequest

# | Credits |
	# Original Godot GameJolt API created by Ackens
	# : https://github.com/ackens/-godot-gj-api
	#
	# Godot 4 GameJolt API created by IrønBrandon
	# : https://github.com/IronBrandon/Godot-GameJolt-API

# Please view the cleaner documentation by pressing F1 and typing 'GameJolt'.

## A simple GameJolt API node.
## 
## Any methods without a description are untested, if you find any issues please
## report them in the second GitHub repository below.
## [br][br]
## [url=https://github.com/ackens/-godot-gj-api]Godot 3 GameJolt plugin[/url] by Ackens.
## [br]
## [url=https://github.com/IronBrandon/Godot-GameJolt-API]Godot 4 GameJolt plugin[/url] by IrønBrandon.
##
## @tutorial: https://github.com/ackens/-godot-gj-api#Methods-description

signal gamejolt_request_completed(type,message)

const BASE_GAMEJOLT_API_URL = 'https://api.gamejolt.com/api/game/v1_2'

@export_category("Right-Click above to see documentation")
@export var private_key: String ## Your game's private key. 
@export var game_id: String
@export var auto_batch: bool = true #Merge queued requests in one batch
@export var verbose: bool = false

var username_cache: String
var token_cache: String
var busy: bool = false
var queue: Array = []
var current_request: Request

class Request:
	var type: String
	var parameters: Dictionary
	var sub_types: Array
	
	func _init(new_type: String, new_parameters: Dictionary, new_sub_types: Array = []):
		type = new_type; parameters = new_parameters; sub_types = new_sub_types

func _ready():
	request_completed.connect(_on_HTTPRequest_request_completed)

func _call_gj_api(type: String, parameters: Dictionary, sub_types: Array = []):
	var request_error: Error = OK
	if busy:
		request_error = ERR_BUSY
		if auto_batch and type != '/batch/':
			var url:String = _compose_url(type, parameters, true)
			if queue.is_empty() or queue.back().type != '/batch/' or queue.back().sub_types.size()>=50:
				queue.push_back(Request.new('/batch/',{requests = [url]},[type]))
			else:
				queue.back().parameters.requests.push_back(url)
				queue.back().sub_types.push_back(type)
		else:
			queue.push_back(Request.new(type,parameters,sub_types))
		return
	busy = true
	var url:String = _compose_url(type, parameters)
	current_request = Request.new(type,parameters,sub_types)
	request_error = request(url)
	if request_error != OK:
		busy = false
	pass

func _compose_param(parameter,key:String):
	parameter = str(parameter)
	if parameter.empty():
		return ""
	return '&' + key + '=' + parameter.percent_encode()
	
func _compose_url(url_path:String, parameters:Dictionary={}, sub_request := false)->String:
	var final_url:String = ("" if sub_request else BASE_GAMEJOLT_API_URL) + url_path
	final_url += '?game_id=' + str(game_id)

	for key in parameters.keys():
		var parameter = parameters[key]
		if parameter == null:
			continue
		if parameter is Array:
			for p in parameter:
				final_url += _compose_param(p,key+"[]")
		else:
			final_url += _compose_param(parameter,key)
			
	var signature:String = final_url + private_key
	signature = signature.md5_text()
	final_url += '&signature=' + signature
	if verbose:
		_verbose(final_url)
	return final_url
	pass
	
func _on_HTTPRequest_request_completed(result, response_code, headers, response_body):
	if result != OK:
		emit_signal('gamejolt_request_completed',current_request.type,{"success":false})
	else:
		var body:String = response_body.get_string_from_utf8()
		# Prepare for json parsing
		body = body.replace('"true"',"true")
		body = body.replace('"false"',"false")
		if verbose:
			_verbose(body)
		var json_result = JSON.parse_string(body)
		var response:Dictionary = {'success': false}
		if json_result:
			response = json_result.result.get('response',{})
		emit_signal('gamejolt_request_completed',current_request.type,response)
		if response.has("responses"):
			for k in response["responses"].size():
				if current_request.sub_types.size()>k:
					emit_signal('gamejolt_request_completed',current_request.sub_types[k],response["responses"][k])
	busy = false
	if !queue.is_empty():
		var request_queued: Request = queue.pop_front()
		_call_gj_api(request_queued.type, request_queued.parameters, request_queued.sub_types)

func _verbose(message):
	if verbose:
		print('[GAMEJOLT] ' , message)

# public

func init(pk:String,gi:String):
	private_key=pk
	game_id=gi

#region USERS

## Attempts to automatically authenticate the user with the URL in Web exports.
## [br]When debugging, you can add this to the URL:  [code]?gjapi_username=<yourusername>&gjapi_token=<yourtoken>[/code][br][br]
func auto_auth():
	JavaScriptBridge.eval('var urlParams = new URLSearchParams(window.location.search);',true)
	var tmp = JavaScriptBridge.eval('urlParams.get("gjapi_username")', true)
	if tmp is String:
		username_cache = tmp
		tmp = JavaScriptBridge.eval('urlParams.get("gjapi_token")', true)
		if tmp is String:
			token_cache = tmp
			_call_gj_api('/users/auth/', {user_token = token_cache, username = username_cache})

## Attempts to authenticate a user with the given [param username] and [param token].
func auth_user(username:String, token:String) -> void:
	_call_gj_api('/users/auth/', {user_token = token, username = username})
	username_cache = username
	token_cache = token

func fetch_user(username=null, id:int=0) -> void:
	_call_gj_api('/users/', {username = username, user_id = id})

func fetch_friends():
	_call_gj_api('/friends/', {username = username_cache, user_token = token_cache})

#endregion

#region SESSIONS

func open_session():
	_call_gj_api('/sessions/open/',
		{username = username_cache, user_token = token_cache})
	pass

func ping_session():
	_call_gj_api('/sessions/ping/',
		{username = username_cache, user_token = token_cache})
	pass
	
func close_session():
	_call_gj_api('/sessions/close/',
		{username = username_cache, user_token = token_cache})
	pass
	
func check_session():
	_call_gj_api('/sessions/check/',
		{username = username_cache, user_token = token_cache})
	pass

#endregion

#region SCORES

func fetch_scores(table_id=null, limit=null, better_than=null, worse_than=null):
	_call_gj_api('/scores/',
		{username = username_cache, user_token = token_cache, limit = limit, table_id = table_id, better_than = better_than, worse_than = worse_than})
	pass

func fetch_guest_scores(guest, limit=null, table_id=null, better_than=null, worse_than=null):
	_call_gj_api('/scores/',
		{guest = guest, limit = limit, table_id = table_id, better_than = better_than, worse_than = worse_than})
	pass
	
func fetch_global_scores(limit=null, table_id=null, better_than=null, worse_than=null):
	_call_gj_api('/scores/',
		{limit = limit, table_id = table_id, better_than = better_than, worse_than = worse_than})
	pass

func add_score(score, sort, table_id=null):
	if username_cache!=null:
		_call_gj_api('/scores/add/',
			{score = score, sort = sort, username = username_cache, user_token = token_cache, table_id = table_id})
		pass
	
func add_guest_score(score, sort, guest, table_id=null):
	_call_gj_api('/scores/add/',
		{score = score, sort = sort, guest = guest, table_id = table_id})
	pass
	
func fetch_score_rank(sort, table_id=null):
	_call_gj_api('/scores/get_rank/', {sort = sort, table_id = table_id})
	pass
	
func fetch_tables():
	_call_gj_api('/scores/tables/',{})
	pass

#endregion

#region TROPHIES

func fetch_trophy(achieved=null, trophy_ids=null):
	_call_gj_api('/trophies/',
		{username = username_cache, user_token = token_cache, achieved = achieved, trophy_id = trophy_ids})
	pass
	
func set_trophy_achieved(trophy_id):
	if username_cache!=null:
		_call_gj_api('/trophies/add-achieved/',
			{username = username_cache, user_token = token_cache, trophy_id = trophy_id})
		pass
	
func remove_trophy_achieved(trophy_id):
	_call_gj_api('/trophies/remove-achieved/',
		{username = username_cache, user_token = token_cache, trophy_id = trophy_id})
	pass

#endregion

#region DATA STORE

func fetch_data(key, global=true):
	if global:
		_call_gj_api('/data-store/', {key = key})
	else:
		_call_gj_api('/data-store/', {key = key, username = username_cache, user_token = token_cache})
	pass
	
func set_data(key, data, global=true):
	if global:
		_call_gj_api('/data-store/set/', {key = key, data = data})
	else:
		_call_gj_api('/data-store/set/', {key = key, data = data, username = username_cache, user_token = token_cache})
	pass
	
func update_data(key, operation, value, global=true):
	if global:
		_call_gj_api('/data-store/update/',
			{key = key, operation = operation, value = value})
	else:
		_call_gj_api('/data-store/update/',
			{key = key, operation = operation, value = value, username = username_cache, user_token = token_cache})
	pass
	
func remove_data(key, global=true):
	if global:
		_call_gj_api('/data-store/remove/', {key = key})
	else:
		_call_gj_api('/data-store/remove/', {key = key, username = username_cache, user_token = token_cache})
	pass
	
func get_data_keys(pattern=null, global=true):
	if global:
		_call_gj_api('/data-store/get-keys/', {pattern = pattern})
	else:
		_call_gj_api('/data-store/get-keys/',
			{username = username_cache, user_token = token_cache, pattern = pattern})
	pass

#endregion

#region TIME

func fetch_time():
	_call_gj_api('/time/',{})
	pass

#endregion

#region BATCH

#Put array of Request class
func batch_request(requests:Array,parallel:bool=true,break_on_error:bool=false):
	var requests_url:Array = []
	var sub_types:Array = []
	for request in requests:
		sub_types.push_back(request.type)
		requests_url.push_back(_compose_url(request.type, request.parameters,true))
	_call_gj_api('/batch/',{requests = requests, parallel = parallel, break_on_error = break_on_error}, sub_types)
	pass

#endregion
