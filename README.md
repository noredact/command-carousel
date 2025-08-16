# command-carousel
A quick app/script launcher

This script lets you launch programs/scripts from a tool tip. 
There are 3 hotkeys used that the user chooses
- The Leader Key
- - The key the script 'listens' for and that launches the selected program when released.
- The Cycle Key
- - The key that cycles through different menus (set up in the initial configuration gui in the menu tab)
- The Selector Key
- - The key that moves a pointer within a menu, when the leader key is released, whatever program is selected will launch.

 - Make sure you have the contents of the src folder for this to work properly.

I've been using this in my main script and thought I'd like to modify it so that I could share it with the world. 
My hotkeys are set to Ctrl (for the leader key), Right Click (for the cycle key) and Left click (for the selector key).
I like this approach because as you use it, you build up muscle memory for where programs are.
I went with multiple menus so that it wasn't just one long tool tip, and wouldn't have to press my selector key a million times to get to something.
This is based on the Tooltip mouse menu from the showcase in the docs, but because its button based, you don't have to 'aim' the mouse for a program. 

***I haven't done very robust testing and assume the user understands the keyword AHK uses for keys/buttons, feedback is welcome***


UPDATE (08-15-2025)
- ToolTipEx requires an alpha version of AHK
- - Added a check to switch to the default tooltip if version is less than 2.1
 
UPDATE (08-16-2025)
- Added Icons
- Added a "settings" menu so user can show the configuration gui again if they uncheck the box
- - this also demonstrates using ahk scripts in the scripts directory.
- There was an issue with the suspend key not updating, now, the script will close the launcher if its running and delete the file before recreating it
- Modified the generic "script.ahk" to a more descriptive file name.
