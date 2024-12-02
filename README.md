# Godot GameJolt API
<p align="center"><img src="gj_icon.png" width="180" alt="GameJolt API icon"></p>

A simple GameJolt API plugin for Godot 4.

- - -

Forked from Deakcor's [GameJolt API plugin](https://github.com/deakcor/-godot-gj-api)

The same GameJolt API used in IrønBrandon's [Home Grown](https://ironbrandon.itch.io/homegrown) (_beta and full release_).

## Introduction

**Plugin Version**: `1.1`

### Features

- Verbose mode with detailed comments
- Full offline code documentation in the form of Godot's custom docs
- Code regions to easily review the plugin's code
- Refactored to fit with Godot 4.1+

### Installation

**Release**

Choose one of the official releases and follow its *Installation* instructions.

**Source**

1. Click "Code" and then "Download ZIP".
2. Drag and drop the "Godot-GameJolt-API" folder into your project's addons folder.
    - You do not need the files '.gitattributes' or 'README.md'. All the other files are required.
3. Rename the plugin's folder from "Godot-GameJolt-API" to "gamejolt_api" to follow Godot's naming conventions.
4. Next, go to **Project > Project Settings... > Plugins** and enable the "GameJolt API" plugin.
5. Lastly, go to 'main\.gd', add a line and save*, then remove it and save again, and click **Project > Reload Current Project**.

And it's installed!

**This properly loads the offline documentation*

## **How To Use**

To add the GameJoltAPI node, select "Add Child Node" and add the GameJoltAPI to your main scene or
under an Autoload scene (_if you have multiple scenes_).

> You should only have one GameJoltAPI node per game.

Next, you have two options depending on whether your game is open-source.

**Option A (_most games_)**: Set the export variables `private_key` and `game_id` to your game's private key and game ID.

**Option B (_open-source_)**: Create a JSON file in your Resources with the contents:
```json
{
	"private_key": "<your_private_key>",
	"game_id": "<your_game_id>"
}
```
and set the export variable `key_path` to that JSON file's path, such as "res://gamejolt.json".\
This is useful for open-source projects that you still want to have GameJolt API functionality, as you can now add that file to your repository's .gitignore and not have to worry about cheaters.

Optionally, you can add a "trophy_ids" Array as a key:
```json
{
	"private_key": "<your_private_key>",
	"game_id": "<your_game_id>",
	"trophy_ids": [123456, 789012]
}
```
Which will be loaded into `trophy_ids` during runtime.

Now you can call GameJoltAPI methods through a parent node or an extended script!

### Authenticating Users

**Plugin Version**: `1.0`, `1.1`

If your game is going to be distributed as a Web build on GameJolt, you can execute the method `user_auto_auth()`
which will retrieve the player's username and token via the URL.\
When debugging, add _`?gjapi_username=<username>&gjapi_token=<token>`_ to the URL (_replace
\<username\> and \<token\> with your username and token_).

However, if you're distributing it as a program (_or want a manual option_), you can instead use
`user_auth(username, token)` to authenticate the user. Just create a simple "log-in" menu and
have the player enter their username and token.

Next, you can connect the `gamejolt_request_completed` signal to a node. Do this either through the
editor or the code. Here is some example code:

```gdscript
# In the below example, the GameJoltAPI node is a child of this node.

var user_authenticated: bool = false

@onready var gamejolt_api: GameJoltAPI = get_node("GameJoltAPI")
@onready var username_box: LineEdit = get_node("username_box")
@onready var token_box: LineEdit = get_node("token_box")
@onready var login_button: Button = get_node("login_button")

func _ready() -> void: # Connect the signals to the methods in ready.
	login_button.pressed.connect(_on_login_pressed)
	gamejolt_api.gamejolt_request_completed.connect(_on_gamejolt_request_completed)

func _on_login_pressed() -> void:
	gamejolt_api.user_auth(username_box.text, token_box.text)
	login_button.disabled = true

func _on_gamejolt_request_completed(request_type, response) -> void:
	match request_type:
		'/users/auth/':
			user_authenticated = response['success']
			if user_authenticated:
				pass # Add code for when the user is authenticated.
			else:
				pass # Add code for when the user fails to authenticate.
			login_button.disabled = false
		# Use a match statement so you can add more request_types later
```

### Unlocking Trophies

**Plugin Version**: `1.0`, `1.1`

_Be sure to read the [Authenticating Users](#authenticating-users) tutorial before this one._

In the method `GameJoltAPI.gamejolt_request_completed` is connected to, add '/trophies/add-achieved/'
to your `match request_type` statement:

```gdscript
func _on_gamejolt_request_completed(request_type, response) -> void:
	match request_type:
		'/users/auth/':
			user_authenticated = response['success']
		'/trophies/add-achieved/':
			if response['success']:
				print("Trophy Achieved!")
			else:
				print("Achieve Failed: ", response['message'])
```

> _Note the `response` Dictionary has the same contents laid out in the official [GameJolt API docs](https://gamejolt.com/game-api/doc/trophies/add-achieved)'
> `trophies/add-achieved` section._

Next, add the following method call to a method you can easily call in-game, such
as one that runs when a button is clicked, an enemy is killed, etc.:

```gdscript
gamejolt_api.trophy_add_achieved('<yourtrophyid>')
```

Finally, run your project, make sure you're authenticated in-game, and do the action that should run
the method with the `trophy_add_achieved()` call.

If it was a success, it should print out "Trophy Achieved!". If you receive "Achieve Failed: ..." you
can debug it by reading the given error.

### Fetching Any Data

**Plugin Version**: `1.0`, `1.1`

_Be sure to read the [Authenticating Users](#authenticating-users) tutorial before this one._

Fetching any data from GameJolt is pretty easy. For example, if you want to fetch the
time, add the `request_type` '/time/' to your match statement, receive any data from [Time Fetch's
returns](https://gamejolt.com/game-api/doc/time/fetch) via `response`, and then call
`gamejolt_api.time_fetch()` from the `_ready()` method. Example:

```gdscript
func _on_gamejolt_request_completed(request_type, response) -> void:
	match request_type:
		"/users/auth/":
			user_authenticated = response['success']
		"/time/":
			print("Date: ",response['year'],".",response['month'],".",response['day'])
```

> Note the difference between "Fetch" and "Get" as all the API call methods do
> not directly return data, but some of the GameJoltAPI's methods, such as
> `get_username()` and `get_token()` do.

What if you want to check for the current user's best score?

Once again, add a new `request_type` as "/scores/". In the official GameJolt Docs, you will see everything the `response` can contain for the "/scores/" type.\
For testing purposes, we will add the `scores_fetch()` method after authentication.

```gdscript
func _on_gamejolt_request_completed(request_type, response) -> void:
	match request_type:
		"/users/auth/":
			user_authenticated = response['success']
			if response['success']:
				gamejolt_api.scores_fetch()
		"/scores/":
			if response['success']:
				if response['scores'] is Array:
					print("User ",response['scores'][0]['user'],"'s Best Score: ", 
						response['scores'][0]['score'])
			else:
				print("Score Fetch Failed! Error: ", response['message'])
```

Here's an example output:

`User nilllzz's Best Score: 234 Coins`

If you replace [0]['score'] with [0]['sort'] it will print out the integer value of the score instead (_you get `234` as an int instead of `"234 Coins"` as a String_)

- - -

For details on all methods, read the custom docs in-engine by pressing F1 and typing GameJolt!\
You can also read the online documentation here: https://github.com/IronBrandon/Godot-GameJolt-API/wiki
