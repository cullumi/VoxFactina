# To Note
A default set of bindings for 2 players are available under "binds.godot" which can be copied into your project file under the input map section. Make sure to create at least 1 custom input first so the section appears.
To create bindings for a second player, make the binding's number "jump_*0*" equal the player's ID, e.g. "jump_1" for Player 1.
For analog sticks, make sure to turn down deadzone to ensure small movements are possible.
# Gameplay
```
forward_0
left_0
right_0
back_0
```
Movement. Set to left analog/wasd
```
jump_0
```
Self explanatory. Set to A button, Spacebar
```
look_up_0
look_left_0
look_right_0
look_down_0
```
Look controls for gamepads. Set to right analog. Mouse is already handled
# Other
```
mouse_escape
```
Escapes and returns the mouse. Set to escape
