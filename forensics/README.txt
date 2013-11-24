#1)
$ wget http://www.cs.tufts.edu/comp/116/downloads/a.jpg
$ wget http://www.cs.tufts.edu/comp/116/downloads/b.jpg
$ wget http://www.cs.tufts.edu/comp/116/downloads/c.jpg
$ diff b.jpg c.jpg # No difference (b.jpg and c.jpg are identical)
$ diff a.jpg b.jpg # Differ
$ stat a.jpg | grep Size # ==> 912,588 bytes
$ stat b.jpg | grep Size # ==> 914,429 bytes
$ steghide extract -sf a.jpg
Enter passphrase: 
wrote extracted data to "prado.jpg" # a close-up image of Norman Ramsey's face


#2)
$ wget http://www.cs.tufts.edu/comp/116/downloads/sdcard.dd.zip
$ echo "e651ac1429516c5fa63b7c526548b9bb        sdcard.dd.zip" > checksum.md5
$ md5sum --check checksum.md5
sdcard.dd.zip: OK
$ unzip sdcard.dd.zip
$ echo "c4d851d2e6e7d65739b92eb8723a3f3c        sdcard.dd" > checksum.md5
$ md5sum --check checksum.md5
sdcard.dd: OK




1. What is/are the disk format(s) of the SD card?
        A fat16 filesystem partition is 125,000 sectors large
        An ext4 filesystem partition is 15,398,839 sectors large
        (The entire disk is 15,523,840 sectors)


2. Is there a phone carrier involved?
No, this is a raspberry pi:
On the FAT partition, there is a file: LISCENCE.broadcom which talks about software being used only on a Raspberry Pi. The executables are also ARM (which is the chip on a Pi). Furthermore, ./root/.bash_history reveals raspi-config being installed (a raspberry pi configuration editor).


3. What operating system, including version number, is being used? Please elaborate how you determined this information.


Mounting the ext4 partition inside a non-persistent ubuntu VM, we can easily explore the filesystem from the safety of a VM:
$ cat /proc/version
Linux version 3.8.0-32-generic (buildd@batsu) (gcc version 4.6.3 (Ubuntu/Linaro 4.6.3-1ubuntu5) ) #47~precise1-Ubuntu SMP Wed Oct 2 16:19:35 UTC 2013


4. What other applications are installed? Please elaborate how you determined this information.


A list of packages installed can be extracted using:
$ ( zcat $( ls -tr ./var/log/apt/history.log*.gz ) ; cat ./var/log/apt/history.log ) | egrep '^(Start-Date:|Commandline:)' | grep -v aptdaemon | egrep '^Commandline:'


Manually sorting this list we get the following list of applications installed manually
by the owner of the sdcard:


locales-all, git-core, binutils, ca-certificates, initramfs-tools, uboot-mkimage
locales, console-common, less, nano, git, wpasupplicant, initramfs-tools,
uboot-mkimage, nmap, openssh-server, kali-linux-fll,
passing-the-hash, unicornscan, winexe, enum4linux, polenum, nfspy, wmis, nipper-ng,
jsql, ghost-phisher, uniscan, lbd, automater, arachni, bully, inguma, sslsplit,
dumpzilla, recon-ng, ridenum, jd-gui, sysv-rc, metasploit, iceweasel, xfce4,
xfce4-places-plugin, armitage, parted, tor


5. Is there a root password? If so, what is it?


Yes, the password of "toor" can be found as follows:


$ strings sdcard.dd | egrep "^([a-z_][a-z0-9_]{0,30}):[^:]*:[0-9]*:[0-9]*:[0-9]*:[0-9]*:[^:]*:[^:]*:$" > shadow
$ cat shadow | sort | uniq > shadow2
$ cat shadow2 | egrep "(root|admin)"
admin:$1$Bwt9zCNI$7rGLYt.wk.axE.6FUNFZe.:11876:0:99999:7:::
miadmin:CENSORED:15544:0:99999:7:::
root:!!$1$3FrxHucD$JL4zVWemZeZJY9LY3PruJ1:15544:0:99999:7:::
root:$1$IJZx7biF$BgyHlA/AgR27VSEBALpqn1:11876:0:99999:7:::
root:$6$9Wim61h8$1BiweJjKZItqv62W5rmS/UCXQR/FGP97btwnJBk0XbeSb43PQseth8SGaxR7bhnDL/iwb2cxpHs80MRRBbulQ/:15855:0:99999:7:::
root:$6$YxDB.SNvtnqhtt.T$slIOJSl7Lz07PtDF23m1G0evZH4MXvpo1VNebUUasM/je2sP6FXi2Y/QE1Ntg.93jOtTQOfZ8k2e/HhT8XzXN/:15818:0:99999:7:::


These are cracked as (??? = not cracked yet):
admin:???
root:???
root:???
root:toor
root:password


6. Are there any additional user accounts on the system?


The only other shadow entry with a password found on the disk was:
kfc:$1$SlSyHd1a$PFZomnVnzaaj3Ei2v1ByC0:15488:0:99999:7:::


There were various other user accounts found, but with no password / are standard
accounts for various applications on various linux distros. In particular, no other
user accounts with passwords were found on the OS currently installed on the sdcard.


Using the following command:
strings sdcard.dd | egrep "(login|username|password|user|pass)[ ]*=[ ]*[\'\"][^\'\"]*[\'\"]"


The following user accounts were found (many of which are clearly facetious / not
persistent / not used in production systems):
admin:1234
pr00f_0f:_c0nc3pt
test:1234
abysssec:absssec
admin:ownedbydusec
SUNTZU:???
suntzu:???
???:akira
waraxe:???
hackname:???
???:eaea
pwned:pwned
user:1234
t26924_siak:siakang
bookoo:???
test:test
World:???
admin:1234
hacker@offsec.local:123456
???:qwe123
nonroot:nonrootuser
scott:tiger
???:rasmuslerdorf
???:OHAI
hacker@znuny.local:123456
xsserbot01:8vnVw8wvs
postgres:secret
fase1c_1:diciembre
ftp:guest
anonymous:axl
e:asd#321
anonymous:Hugh Mann


7. List some of the incriminating evidence that you found. Please elaborate where and how you uncovered the evidence.
A number of jpg files named “old?.jpg” were found in /root/Pictures containing images of Celine Dion. As well a number of jpg files named “new.jpg” were deleted from /root/, but which were found using photorec which were also images of Celine Dion. The other piece of evidence found was the file /root/receipt.pdf which was also deleted. See problem 10 for more detail about receipt.pdf.


8. Did the suspect move or try to delete any files before his arrest? Please list the name(s) of the file(s) and any indications of their contents that you can find.
The files receipt.pdf, new1.jpg, new2.jpg, and new3.jpg were deleted using rm from within the home directory
of the root user. receipt.pdf was recovered using photorec, and contains a receipt for $113.70 to a Celine Dion
show in Las Vegas (see problem 10).


9. Are there any encrypted files? If so, list the contents and a brief description of how you obtained the contents.
Yes, there is a file: /root/.Dropbox.zip is a truecrypt file. After guessing likely passwords: celinedion, dion, celine, imyourbiggestfan. I found the right one after about 20 minutes: iloveyou. Inside the truecrypt archive is a video of a Celine Dion performance and a picture of a ticket from July 2012.


10. Did the suspect at one point went to see this celebrity? If so, note the date and location where the suspect met the celebrity? Please elaborate how you determined this information.
The suspect went to see Celine Dion on Jul. 28th, 2012 at 7:30pm at The Colosseum at Caesars Palace in
Las Vegas, NV. This information was obtained by discovering a file named receipt.pdf which had been deleted
from the home directory of the root user.


11. Is there anything peculiar with the files on the system?
Yes, some files are not as they look. For example:
$ cat ./root/shortcut.lnk
spotify:album:41IwxoZoITRNmQheABRtwc
This is “My Love Essential Collection” by Celine Dion (2008)


There was also a directory /opt/Teeth with some weird things in it


12. Who is the celebrity that the suspect has been stalking?
Celine Dion.