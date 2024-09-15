A simple GameJolt API plugin for Godot 4.

### Installation

1. Click "Code" and then "Download ZIP".
2. Drag and drop the "Godot-GameJolt-API" folder into your project's addons folder.
3. (_optional_) Rename the folder "Godot-GameJolt-API" to "gamejolt_api".
4. Next, go to **Project > Project Settings... > Plugins** and enable the "GameJolt API" plugin.

Now, you can add the custom node GameJoltAPI to your main scene or as a singleton.

## Getting Started

For extra detail on all methods, read the custom docs by pressing F1 and typing GameJolt!

(_you can also read the online documentation below_)

## Latest Documentation

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
