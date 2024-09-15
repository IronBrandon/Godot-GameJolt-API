A simple GameJolt API plugin for Godot 4.

### New Features

- Full offline code documentation in the form of Godot's custom docs
- Code regions to easily review the plugin's code.

### Installation

1. Click "Code" and then "Download ZIP".
2. Drag and drop the "Godot-GameJolt-API" folder into your project's addons folder.
3. I highly suggest renaming the plugin's folder from "Godot-GameJolt-API" to "gamejolt_api".
4. Next, go to **Project > Project Settings... > Plugins** and enable the "GameJolt API" plugin.

And it's installed!

## **How To Use**

**_this section is incomplete_**

To add the GameJoltAPI node, select "Add Child Node" and add the GameJoltAPI to your main scene or
under an Autoload scene (_if you have multiple scenes_).
- You should only have one GameJoltAPI node per game.

Next, set the export variables `Private Key` and `Game ID` to your game's private key and game ID.

Now you can call GameJoltAPI methods through a parent node or an extended script!

### Authenticate User

If your game is going to be distributed as a Web build, you can execute the method `user_auto_auth()`
which will retrieve the player's username and token via the URL.\
When debugging, add _`?gjapi_username=<username>&gjapi_token=<token>`_ to the URL (_replace
<username> and <token> with your username and token_).

However, if you're distributing it as a program (_or want a manual option_), you can instead use
`user_auth(username, token)` to authenticate the user. Just create a simple "log-in" menu and
have the player enter their username and token.

### Unlock Trophies

. . .

- - -

For details on all methods, read the custom docs by pressing F1 and typing GameJolt!

(_you can also read the online documentation below_)

## **Latest Documentation**

**_this section is incomplete_**

Any missing methods are untested, if you find any issues please report them.

*Untested in Godot 4.
  
### Properties (_variables_)

**Export variables**

- **private_key**: String\
  Your game's private key. If your project is open-source on GitHub, you can enter a path to a file and add that file to your .gitignore
- **game_id**: String\
  Your game's ID. This is public, just look at your game's URL and copy the numbers.
- **auto_batch**: bool\
  Merge queued requests in one batch.
- **verbose**: bool\
  Prints more text.

**Public variables**

- **username_cache**: String\
  The currently cached username
- **token_cache**: String\
  The currently cached token
- **busy**: String\
  If true the GameJoltAPI is currently busy with a GJ call.
- **queue**: Array[Request]\
  The current queue of **Request**s.
- **current_request**: Request\
  The currently active GameJolt request.
  
### Methods (_functions_)

**USERS**

- **\*user_auto_auth() _-> void_**\
  Attempts to automatically authenticate the user with the URL in Web exports.\
  When debugging, you can add this to the URL:  ?gjapi_username=<yourusername>&gjapi_token=<yourtoken>\
  Request type is "/users/auth/"
- **\*user_auth(`username`: String, `token`: String) _-> void_**\
  Attempts to authenticate a user with the given `username` and `token`.\
  Request type is "/users/auth/"
- **\*user_fetch(`username`: String, `id`: int = 0) _-> void_**\
  Fetch's the data of either the `username` or user `id`.\
  Request type is "/users/"
- **\*user_friends_fetch() _-> void_**\
  Fetch's the currently cached user's friends list.\
  Request type is "/friends/"

**SESSIONS**

- **\*session_open() _-> void_**\
  Opens a session.\
  Request type is "/sessions/open/"
- **\*session_ping() _-> void_**\
  Pings an active session.\
  Request type is "/sessions/ping/"
- **\*session_close() _-> void_**
  Closes the active session.\
   Request type is "/sessions/close/"
- **\*session_check() _-> void_**\
  Checks for an active session.\
   Request type is "/sessions/check/"

**SCORES**

- **\*scores_fetch(table_id = null, limit = null, better_than = null, worse_than = null)**
- **\*scores_fetch_guest(guest, limit = null, table_id = null, better_than = null, worse_than = null)**
- **\*scores_fetch_global(limit = null, table_id = null, better_than = null, worse_than = null)**
- **\*scores_add(score, sort, guest: String = "", table_id = null)**
- **\*scores_add_guest(score, sort, guest, table_id = null)**
  - **Deprecated**: Add a guest name in **`scores_add()`** instead.
- **\*scores_fetch_rank(sort, table_id = null)**
- **\*scores_fetch_tables()**
