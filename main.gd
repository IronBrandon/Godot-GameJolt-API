@icon("gj_icon.png")
extends HTTPRequest

# | Credits |
	# Original Godot GameJolt API created by Ackens
	# : https://github.com/ackens/-godot-gj-api
	#
	# Previous Godot GameJolt API created by rojekabc
	# : https://github.com/rojekabc/-godot-gj-api
	#
	# Ported to Godot 4.x by IrønBrandon
	# : https://github.com/IronBrandon/Godot-GameJolt-API

# NOTE: Please view the cleaner documentation by pressing F1 and typing 'GameJolt'.
# or right-click "GameJoltAPI" in the node's inspector and select "Open Documentation".

## A simple GameJolt API node.
## 
## Also look at the [b]" ... main.gd".Request[/b] class.[br][br]
## 
## Any methods without a description are untested, if you find any issues please
## report them in the second GitHub repository below.
## [br][br]
## [url=https://github.com/ackens/-godot-gj-api]Godot 3 GameJolt plugin[/url] by Ackens.
## [br]
## [url=https://github.com/IronBrandon/Godot-GameJolt-API]Godot 4 GameJolt plugin[/url] by IrønBrandon.
## 
## @tutorial(Online Docs): https://github.com/IronBrandon/Godot-GameJolt-API#Latest-Documentation
## @tutorial(Official GameJolt API Docs): https://gamejolt.com/game-api/doc
## 
## @tutorial(Original API Documentation by Ackens): https://github.com/ackens/-godot-gj-api#Methods-description

## Emits after a request to GameJolt has completed.
## [br][br][param message] should follow the format [code]{"success": true, . . .}[/code]
## [br][param type] is will be one of the request types, such as "/users/auth/", "/users/", "/trophies/", "/sessions/check/", "/sessions/open/", etc.
signal gamejolt_request_completed(type: String, message: Dictionary)

const BASE_GAMEJOLT_API_URL = 'https://api.gamejolt.com/api/game/v1_2'

@export_category("Right-Click 'GameJoltAPI' to see documentation")
@export var private_key: String ## Your game's private key.
@export var game_id: String ## Your game's ID. This is public, just look at your game's URL and copy the numbers.
@export var auto_batch: bool = true ## Merge queued requests in one batch.
@export var verbose: bool = false ## Prints more text.

var username_cache: String ## The currently cached username.
var token_cache: String ## The currently cached token.
var busy: bool ## If true the GameJoltAPI is currently busy with a GJ call.
var queue: Array[Request] = [] ## The current queue of [param Request]s.
var current_request: Request ## The currently active GameJolt request.

## The class that handles all data for API calls.
class Request:
	var type: String ## The call type, such as "/users/", "/users/auth/", "/scores/", etc.
	var parameters: Dictionary ## The parameters used for the call.
	var sub_types: Array ## Sub types used for batch requests.
	
	func _init(new_type: String, new_parameters: Dictionary, new_sub_types: Array = []):
		type = new_type; parameters = new_parameters; sub_types = new_sub_types

func _ready():
	request_completed.connect(_on_HTTPRequest_request_completed)

func _call_gj_api(type: String, parameters: Dictionary, sub_types: Array = []):
	var request_error: Error = OK
	if busy:
		request_error = ERR_BUSY
		if auto_batch and type != '/batch/':
			var url: String = _compose_url(type, parameters, true)
			if queue.is_empty() or queue.back().type != '/batch/' or queue.back().sub_types.size()>=50:
				queue.push_back(Request.new('/batch/',{requests = [url]},[type]))
			else:
				queue.back().parameters.requests.push_back(url)
				queue.back().sub_types.push_back(type)
		else:
			queue.push_back(Request.new(type,parameters,sub_types))
		return
	busy = true
	var url: String = _compose_url(type, parameters)
	current_request = Request.new(type,parameters,sub_types)
	request_error = request(url)
	if request_error != OK:
		busy = false
	pass

func _compose_param(parameter, key: String) -> String:
	parameter = str(parameter)
	if parameter.empty():
		return ""
	return '&' + key + '=' + parameter.percent_encode()

func _compose_url(url_path:String, parameters:Dictionary={}, sub_request := false) -> String:
	var final_url:String = ("" if sub_request else BASE_GAMEJOLT_API_URL) + url_path
	final_url += '?game_id=' + str(game_id)

	for key in parameters.keys():
		var parameter = parameters[key]
		if parameter == null:
			continue
		if parameter is Array:
			for p in parameter:
				final_url += _compose_param(p, key+"[]")
		else:
			final_url += _compose_param(parameter, key)
			
	var signature:String = final_url + private_key
	signature = signature.md5_text()
	final_url += '&signature=' + signature
	if verbose:
		_verbose(final_url)
	return final_url

func _on_HTTPRequest_request_completed(result, response_code, headers, response_body) -> void:
	if result != OK:
		emit_signal('gamejolt_request_completed', current_request.type, {"success":false})
	else:
		var body:String = response_body.get_string_from_utf8()
		# Prepare for json parsing
		body = body.replace("\"true\"","true")
		body = body.replace("\"false\"","false")
		if verbose: _verbose(body)
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

func _verbose(message) -> void:
	if verbose: print('[GAMEJOLT] ' , message)

## This is useful for if you want to create a file that contains the game's private key and load that.
func game_init(new_private_key: String, new_game_id: String = game_id) -> void:
	private_key = new_private_key; game_id = new_game_id

#region USERS

## Attempts to automatically authenticate the user with the URL in Web exports.
## [br]When debugging, you can add this to the URL: 
## [codeblock lang=text]?gjapi_username=<yourusername>&gjapi_token=<yourtoken>[/codeblock]
## Request type is "/users/auth/".
func user_auto_auth() -> void:
	JavaScriptBridge.eval('var urlParams = new URLSearchParams(window.location.search);',true)
	var tmp = JavaScriptBridge.eval('urlParams.get("gjapi_username")', true)
	if tmp is String:
		username_cache = tmp
		tmp = JavaScriptBridge.eval('urlParams.get("gjapi_token")', true)
		if tmp is String:
			token_cache = tmp
			_call_gj_api('/users/auth/', {user_token = token_cache, username = username_cache})

## Attempts to authenticate a user with the given [param username] and [param token].
## [br][br]Request type is "/users/auth/".
func user_auth(username: String, token: String) -> void:
	_call_gj_api('/users/auth/', {user_token = token, username = username})
	username_cache = username; token_cache = token

func user_fetch(username: String, id: int=0) -> void: ## Fetches user data.[br][br]Request type is "/users/"
	_call_gj_api('/users/', {username = username, user_id = id})

func user_friends_fetch() -> void: ## Fetches the currently cached user's friends list.[br][br]Request type is "/friends/"
	_call_gj_api('/friends/', {username = username_cache, user_token = token_cache})
#endregion

#region SESSIONS

func session_open(): ## Opens a session.[br][br]Request type is "/sessions/open/"
	_call_gj_api('/sessions/open/',
		{username = username_cache, user_token = token_cache})

func session_ping(): ## Pings an active session.[br][br]Request type is "/sessions/ping/"
	_call_gj_api('/sessions/ping/',
		{username = username_cache, user_token = token_cache})

func session_close(): ## Closes the active sessions.[br][br]Request type is "/sessions/close/"
	_call_gj_api('/sessions/close/',
		{username = username_cache, user_token = token_cache})

func session_check(): ## Checks for an active session.[br][br]Request type is "/sessions/check/"
	_call_gj_api('/sessions/check/',
		{username = username_cache, user_token = token_cache})
#endregion

#region SCORES

func scores_fetch(table_id=null, limit=null, better_than=null, worse_than=null):
	_call_gj_api('/scores/',
		{username = username_cache, user_token = token_cache, limit = limit, table_id = table_id, better_than = better_than, worse_than = worse_than})

func scores_fetch_guest(guest, limit=null, table_id=null, better_than=null, worse_than=null):
	_call_gj_api('/scores/',
		{guest = guest, limit = limit, table_id = table_id, better_than = better_than, worse_than = worse_than})

func scores_fetch_global(limit=null, table_id=null, better_than=null, worse_than=null):
	_call_gj_api('/scores/',
		{limit = limit, table_id = table_id, better_than = better_than, worse_than = worse_than})

## Attempts to add a score to the cached user or guest.
func scores_add(score, sort, guest: String = "", table_id=null):
	if username_cache != null:
		var paremeters = {score = score, sort = sort, table_id = table_id}
		if username_cache && token_cache:
			paremeters["username"] = username_cache; paremeters["user_token"] = token_cache
		else:
			paremeters["guest"] = guest
		# Attempt call
		if ((paremeters["username"] && paremeters["user_token"])\
			|| paremeters["guest"]):
				_call_gj_api('/scores/add/', paremeters)

## Attempts to add a score to a guest.
## @deprecated: Add a guest name in [method scores_add] instead.
func scores_add_guest(score, sort, guest, table_id=null):
	_call_gj_api('/scores/add/',
		{score = score, sort = sort, guest = guest, table_id = table_id})

func scores_fetch_rank(sort, table_id=null):
	_call_gj_api('/scores/get_rank/', {sort = sort, table_id = table_id})

func scores_fetch_tables():
	_call_gj_api('/scores/tables/',{})
#endregion

#region TROPHIES

## Fetches trophies.[br][br]
## If you want a specific trophy or set of trophies, pass them through [param trophy_ids] as '123456,135792' each separated by commas.
## [br][br]If you want only achieved or unachieved trophies, pass [param achieved] as 'true' or 'false'.
func trophy_fetch(trophy_ids: String, achieved: String = ''):
	if username_cache != null: _call_gj_api('/trophies/',
		{username = username_cache, user_token = token_cache, achieved = achieved, trophy_id = trophy_ids})

func trophy_add_achieved(trophy_id):
	if username_cache != null: _call_gj_api('/trophies/add-achieved/',
		{username = username_cache, user_token = token_cache, trophy_id = trophy_id})

func trophy_remove_achieved(trophy_id):
	if username_cache != null: _call_gj_api('/trophies/remove-achieved/',
		{username = username_cache, user_token = token_cache, trophy_id = trophy_id})
#endregion

#region DATA STORE

func data_fetch(key, global=true):
	if global:
		_call_gj_api('/data-store/', {key = key})
	else:
		_call_gj_api('/data-store/', {key = key, username = username_cache, user_token = token_cache})

func data_set(key, data, global=true):
	if global:
		_call_gj_api('/data-store/set/', {key = key, data = data})
	else:
		_call_gj_api('/data-store/set/', {key = key, data = data, username = username_cache, user_token = token_cache})

func data_update(key, operation, value, global=true):
	if global:
		_call_gj_api('/data-store/update/',
			{key = key, operation = operation, value = value})
	else:
		_call_gj_api('/data-store/update/',
			{key = key, operation = operation, value = value, username = username_cache, user_token = token_cache})

func data_remove(key, global=true):
	if global:
		_call_gj_api('/data-store/remove/', {key = key})
	else:
		_call_gj_api('/data-store/remove/', {key = key, username = username_cache, user_token = token_cache})

func data_fetch_keys(pattern=null, global=true):
	if global:
		_call_gj_api('/data-store/get-keys/', {pattern = pattern})
	else:
		_call_gj_api('/data-store/get-keys/',
			{username = username_cache, user_token = token_cache, pattern = pattern})
#endregion

#region TIME

func time_fetch(): _call_gj_api('/time/',{}) ## Fetches the current time.
#endregion

#region BATCH

func batch_request(requests: Array, parallel: bool = true, break_on_error: bool = false):
	var requests_url:Array = []
	var sub_types:Array = []
	for request in requests:
		sub_types.push_back(request.type)
		requests_url.push_back(_compose_url(request.type, request.parameters,true))
	_call_gj_api('/batch/',{requests = requests, parallel = parallel, break_on_error = break_on_error}, sub_types)
#endregion
