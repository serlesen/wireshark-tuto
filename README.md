# !!! PLEASE REFER TO THE MOST RECENT UPDATED INSTALLATION INSTRUCTIONS [HERE](https://github.com/w4sp-book/w4sp-lab/wiki/Lab-Installation)  !!!!

This is the lab environment for the Wireshark for Security Professionals book. The lab is built on
top of Docker and Kali Linux and provides a realistic network with numerous services useful for learning security fundamentals with Wireshark.

Both Kali and the w4sp-lab are moving targets and are subject to change. Always refer to the [wiki](https://github.com/w4sp-book/w4sp-lab/wiki) for the most recent information regarding working with the lab.



## Fixes By Sergio

Build and run the image with
```
docker build -t wireshark-tuto .
docker run -it wireshark-tuto /bin/bash
```

Based on https://github.com/yoke88/w4sp-lab and https://medium.com/@vaibjav2raj/setting-up-the-w4sp-lab-in-2020-d4df6a3d2a5e

after install kali ,First change to root.
```
sudo useradd -m w4sp-lab -s /bin/bash -G sudo -U
```

Set the password
```
passwd w4sp-lab
```

Log out and change to user w4sp-lab then download or clone the lab from this repo
```
sudo apt install -y python3-docker

sudo apt install wireshark net-tools ethtool xterm

sudo python3 w4sp_webapp.py
```

Keep the user's name after sudo command:
```
sudo visudo
```

And append this at the end:
```
Defaults runas_default=w4sp
```

After all the images are loaded a browser may or may not open automatically. Don’t panic. Open a firefox tab and enter this address.

http://127.0.0.1:5000
