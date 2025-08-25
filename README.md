# command-carousel
A quick app/script launcher written in AHK v2

# Launcher Image

<img width="183" height="108" alt="launcher" src="https://github.com/user-attachments/assets/565da5df-f612-4400-b61c-744587658e0d" />

# Settings Gui Image

<img width="638" height="496" alt="settings1" src="https://github.com/user-attachments/assets/0746d36b-db8f-48ef-8c50-3de1cef1cfb9" />
<img width="631" height="484" alt="settings2" src="https://github.com/user-attachments/assets/09b7f479-c13b-4bfe-8179-e60b92600029" />
<img width="627" height="480" alt="settings3" src="https://github.com/user-attachments/assets/fdb777d1-28a0-4fd0-90b2-04339beb8396" />

# Ini File Image

<img width="1048" height="952" alt="inifile" src="https://github.com/user-attachments/assets/aad4b6f3-7949-49ea-bd30-21683b2289e7" />


# Features
This script lets you launch programs/scripts from a tool tip. 
There are 3 hotkeys used that the user chooses
- The Leader Key
  - The key the script 'listens' for and that launches the selected program when released.
- The Cycle Key
  - The key that cycles through different menus (set up in the initial configuration gui in the menu tab)
- The Selector Key
  - The key that moves a pointer within a menu, when the leader key is released, whatever program is selected will launch.

Very simple config.ini file allows you to make settings changes without going through the settings GUI

 - Make sure you have the contents of the src folder for this to work properly.

# About

I've been using this in my main script and thought I'd like to modify it so that I could share it with the world. 
My hotkeys are set to Ctrl (for the leader key), Right Click (for the cycle key) and Left click (for the selector key).
I like this approach because as you use it, you build up muscle memory for where programs are.
I went with multiple menus so that it wasn't just one long tool tip, and wouldn't have to press my selector key a million times to get to something.
This is based on the Tooltip mouse menu from the showcase in the docs, but because its button based, you don't have to 'aim' the mouse for a program. 

***I haven't done very robust testing and assume the user understands the keyword AHK uses for keys/buttons, feedback is welcome***

# Updates 

UPDATE (08-15-2025)
- ToolTipEx requires an alpha version of AHK
  - Added a check to switch to the default tooltip if version is less than 2.1
 
UPDATE (08-16-2025)
- Added Icons
- Added a "settings" menu so user can show the configuration gui again if they uncheck the box
  - this also demonstrates using ahk scripts in the scripts directory.
- There was an issue with the suspend key not updating, now, the script will close the launcher if its running and delete the file before recreating it
- Modified the generic "script.ahk" to a more descriptive file name.

UPDATE (08-25-2025)
- Added new features
  - Moving/Removing menus/items can now handle multiple selections
  - New button lets users move an item from one menu to another, or create a new menu to move it to
  - Added a file menu to allow users to save their current configuration or load previous versions
    - Makes user defined number of automatic backups
    - User can restore the default config ini.

<noscript><a href="https://liberapay.com/noredact/donate"><img alt="Donate using Liberapay" src="https://liberapay.com/assets/widgets/donate.svg"></a></noscript>
