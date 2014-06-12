# rails-0-to-60

A scripted adventure setting up and getting started with Rails on Debian with Postgres in 60 minutes or less.

# 0: If participating in a class...

* COMPLETE STEPS 1 THROUGH 4 BEFORE THE CLASS STARTS.
* Some of these steps can take a while; don't spend the first 30 minutes trying to catch up.
* If you are using a VM you may want to snapshot/clone after completing Step 4.

# 1: Background

If you are not familar with Ruby, Rails, MVC, PostgreSQL visit: 

* http://tryruby.org/
* http://rubyonrails.org/
* http://edgeguides.rubyonrails.org/getting_started.html
* http://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller
* http://www.postgresqltutorial.com/

# 2: What you need

## A clean Debian Squeeze instance

A suitable VirtualBox Debian .ova or .vdi.  For example:
http://downloads.sourceforge.net/virtualboximage/debian_6.0.6.vdi.7z

## A network connection from your desktop to your Squeeze instance

This may require a VirtualBox NAT AND a Host-Only network.
If you are using a cloned VM, be sure to refresh the MAC address on your VirtualBox interfaces *AND*
Run: "rm /etc/udev/rules.d/70-persistent-net.rules; reboot" as root user in your VM after cloning.

Edit /etc/network/interfaces to include where # is your host only adapter:

    allow-hotplug eth#
    iface eth# inet static
    address 192.168.56.xx # Where xx is not already in use on your system
    netmask 255.255.255.0

The default Host-Only IP for your VirtualBox VM is 192.156.56.101.

## The ability to SSH into your VM.

It's not recommended to use the VM's virtual console.  Ensure that
your VM is responding to ssh:

    ssh YOUR-VM-USERNAME@192.156.56.101

# Within your VM:

## git installed

You will need git installed to clone this repo: as root, run "apt-get install git".

## sudo installed

You will need sudo installed to run the ./setup-rails.sh script: as root, run "apt-get install sudo".

Remember to add your user to /etc/sudoers

## A normal user with sudo rights

* You must run the ./setup-rails.sh script as a normal user with sudo permissions.
* DO NOT RUN THESE SCRIPTS AS ROOT.
* Add your user to the "sudo" group in the /etc/group file.

## This git repo cloned into ~/local/src/rails-0-to-60

# 3: Getting Started
 
    # WITHIN YOUR FRESH VM:
    $ mkdir -p ~/local/src
    $ cd ~/local/src/
    $ sudo apt-get install git
    $ git clone git://git.cashnetusa.com/kurt/rails-0-to-60.git
    $ cd rails-0-to-60

# 4: Setup Ruby, Rails and Postgres

    # If you already have ~/.rvm installed,
    # you might want to move it out of the way, temporarily.
    $ [ -d ~/.rvm ] && mv ~/.rvm{,.save}

    # To see the play-by-play notes:
    $ export NOTES_LOG=<<some-file-or-tty>>
    
    # To see what it's gonna do:
    $ ./setup-rails.sh prompt=

    # Really do it, and prompt along the way:
    $ ./setup-rails.sh dryrun= prompt=1

    # Setup current shell with rvm:
    $ source ~/.rvm/scripts/rvm

    # Check rvm and rails:
    $ cd ~/local/src
    $ rvm list
    $ rails new testapp
    
# 5: The Rails "blog" Tutorial

http://edgeguides.rubyonrails.org/getting_started.html

    $ cd ~/local/src
    
    # Step through blog example:
    $ rails-0-to-60/make-blog.sh
    
    # Really do it, and prompt along the way:
    $ rails-0-to-60/make-blog.sh dryrun= prompt=1

