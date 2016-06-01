# Laravel-Apache-Auto-Config
Automatically configure apache2 to run your laravel application.

I would not recommend using this in production.  This will delete symbolic links from ``/etc/apache2/sites-enabled/`` but it will leave ``/etc/apache2/sites-available`` alone.

### Usage:
If you do not have a Laravel app yet, make one
```
laravel new app
```
Then run this config script and specify you app name
```
sudo ./auto-config-laravel.sh app
```
You can use an absolute path for the app name as well

### What it does:
This script changes the group of the folder you specify i.e. ``app`` to ``www-data`` so it can be accessed by the web server.
Then a virtual host file is created for the app using port 80.  All currently enabled sites are disabled (deleted from ``sites-enabled/``).  The virtual host file is moved to ``/etc/apache2/sites-available/`` and apache2 is restarted.

This script will most likely need to be run with sudo




This will not configure laravel 100%.  You may still need to manually enable mod_rewrite, and ensure that apache2.conf allows the use of the .htaccess file. 
