A simple GameJolt API plugin for Godot 4.\
The same GameJolt API used in IrønBrandon's [Home Grown](https://ironbrandon.itch.io/homegrown) (_beta and full release_).

Forked from Deakcor's [GameJolt API plugin](https://github.com/deakcor/-godot-gj-api)

## Introduction

### Features

- Verbose mode with detailed comments
- Full offline code documentation in the form of Godot's custom docs
- Code regions to easily review the plugin's code
- Refactored to fit with Godot 4(_.3_)+

### Installation

1. Click "Code" and then "Download ZIP".
2. Drag and drop the "Godot-GameJolt-API" folder into your project's addons folder.
    - You do not need the files '.gitattributes' or 'README.md'. All the other files are required.
3. Rename the plugin's folder from "Godot-GameJolt-API" to "gamejolt_api" to follow Godot's naming conventions.
4. Next, go to **Project > Project Settings... > Plugins** and enable the "GameJolt API" plugin.
5. Lastly save your project and click **Project > Reload Current Project**.

And it's installed!

## **How To Use**
_this section is incomplete_

To add the GameJoltAPI node, select "Add Child Node" and add the GameJoltAPI to your main scene or
under an Autoload scene (_if you have multiple scenes_).
- You should only have one GameJoltAPI node per game.

Next, set the export variables `Private Key` and `Game ID` to your game's private key and game ID.

Now you can call GameJoltAPI methods through a parent node or an extended script!

### Authenticate User

If your game is going to be distributed as a Web build, you can execute the method `user_auto_auth()`
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

func _ready(): # Connect the signals to the methods in ready.
    login_button.pressed.connect(_on_login_pressed)
    gamejolt_api.gamejolt_request_completed.connect(_on_gamejolt_request_completed)

func _on_login_pressed():
    gamejolt_api.auth_user(username_box.text, token_box.text)
    login_button.disabled = true

func _on_gamejolt_request_completed(request_type, response):
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

### Unlock Trophies

. . .

### Fetch Any Data

. . .

- - -

For details on all methods, read the custom docs by pressing F1 and typing GameJolt!

(_you can also read the online documentation below_)

## **Latest Documentation**
_this section is incomplete_

Any methods without a description are untested, if you find any issues please report them.
  
### Properties (_variables_)

**Export variables**

- **private_key**: String

Your game's private key.

- **game_id**: String

Your game's ID. This is public, just look at your game's URL and copy the numbers.

- **auto_batch**: bool = true

Merge queued requests in one batch.

- **auto_auth_in_ready**: bool = false

Automatically calls the `user_auto_auth` method during ready.

- **verbose**: bool = false

Causes funtions to print detailed text.


**Public variables**

- **busy**: bool

If true the GameJoltAPI is currently busy with a GJ call.

- **queue**: Array[Request]

The current queue of **Request**s.

- **current_request**: Request

The currently active GameJolt request.
  
### Methods (_functions_)

*Untested in Godot 4.

- `get_username() -> String`

Returns the username cache.

- `get_token() -> String`

Returns the user token cache.

- `time_fetch() -> void`

Fetches the current time.

- *`batch_request(requests: Array[Request], parallel: bool = true, break_on_error: bool = false) -> void`

Calls a batch of **Request**s.

**USERS**

- *`user_auto_auth() -> void`

Attempts to automatically authenticate the user with the URL in Web exports.\
When debugging, you can add this to the URL:  `?gjapi_username=<yourusername>&gjapi_token=<yourtoken>`

Request type is "/users/auth/"


- *`user_auth(username: String, token: String) -> void`

Attempts to authenticate a user with the given `username` and `token`.

Request type is "/users/auth/"


- *`user_fetch(username: String, id: int = 0) -> void`

Fetch's the data of either the `username` or user `id`.

Request type is "/users/"


- *`user_friends_fetch() -> void`

Fetch's the currently cached user's friends list.

Request type is "/friends/"


**SESSIONS**

- *`session_open() -> void`

Opens a session.

Request type is "/sessions/open/"


- *`session_ping() -> void`

Pings an active session.

Request type is "/sessions/ping/"


- *`session_close() -> void`

Closes the active session.

Request type is "/sessions/close/"


- *`session_check() -> void`

Checks for an active session.

Request type is "/sessions/check/"


**SCORES**

- *`scores_fetch(global=false, guest: String = "", limit = null, table_id = null, better_than = null, worse_than = null) -> void`

Fetches a list of scores for cached user, a `guest` or on `global`.\
Leave `guest` empty if you want global or cached user.

Request type is "/scores/"


- *`scores_add(score_string, sort_number, guest: String = "", table_id = null) -> void`

Attempts to add a score to the cached user or guest.
Leave `guest` empty to use the cached user (_User must be authenticated_).


- *`scores_fetch_rank(sort, table_id = null) -> void`

Fetches the rank of a score on a table.

Request type is "/scores/get-rank/"


- *`scores_fetch_tables() -> void`

Fetches a list of high-score tables.

Request type is "/scores/tables/"


**TROPHIES**

- *`trophy_fetch(trophy_ids: String, achieved: String = '') -> void`

Fetches trophies.
If you want a specific trophy or set of trophies, pass them through `trophy_ids` as '123456,135792' each separated by commas.\
If you want only achieved or unachieved trophies, pass `achieved` as 'true' or 'false'.

Request type is "/trophies/"


- *`trophy_add_achieved(trophy_id) -> void`

Unlocks the trophy with id `trophy_id` for the authenticated user. _User must be authenticated_

Request type is "/trophies/add-achieved/"


- *`trophy_remove_achieved(trophy_id) -> void`

Removes the trophy with id `trophy_id` from the authenticated user. _User must be authenticated_\
**NOTE**: Only for debugging.

Request type is "/trophies/remove-achieved/"


**DATA STORE**

. . .
