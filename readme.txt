EDIT GitHub Pages
-=-=-=-=-=-=-=-=-=

http://librecat.github.com/Catmandu/

Initialize your working environment
-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

# Open a terminal
# Go to your favorite development directory and follow these steps

$ git@github.com:LibreCat/Catmandu.git
$ cd Catmandu
$ git fetch origin
$ git checkout gh-pages

Now you can edit the website as you wish.

Sending the updated website back to github
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

***For every file or directory you add to the project you need to issue the 'git add' command****

E.g.

$ git add my_file.html
$ git add images/*.jpg
$ mkdir tools
$ git add tools

This way you let git know you have new contente you want to put in version control.

***When you are done with editing the website, send all the changes to github***

 First commit (and explain what you did)
 $ git commit -a

 Fetch the latest updates
 $ git pull

 Push all the changes to git
 $ git push

After a few minutes the updated website should be online.

Style Guides
-=-=-=-=-=-=

See: http://foundation.zurb.com/
