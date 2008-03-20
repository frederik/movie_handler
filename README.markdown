MovieHandler
============

About
------------

MovieHandler is a ruby / apple script that automatically imports tv shows into iTunes, assigns a cover and other information like episode number and title.

Requirements
------------

- QuickTime Pro
- Ruby
- rubyosa gem (rubyosa.rubyforge.org)

Installation
------------

Since ruby and ruby gems come with Leopard with Mac OS 10.5 you'll just have to install rubyosa to get the script running. To do that open a Terminal and type:

*sudo gem install rubyosa*

If you're running Tiger or older you can get rubygems at www.rubygems.org

Not that you're all set:

1. Place the movie_handler.scpt file in "~/Library/Scripts/Folder Action Scripts" and edit the location of the .rb file. For that just open the scpt file with the Apple Script Editor and edit the path

2. Add the Folder Action to a Folder of your choice. Right click within the folder, choose more -> Configure Folder Actions and add the scpt file.

3. you can add covers as a .pict file by creating a Cover subfolder in /Users/yourname/Pictures and placing them there

enjoy

Known Issues
------------

Since MovieHandler deletes the original files after conversion please make sure that you checked the "Copy files to iTunes Music folder when adding to library" option in iTunes -> Preferences -> Advanced ( on by default )