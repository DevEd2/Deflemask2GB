# Deflemask2GB
An alternate Game Boy hardware player for Deflemask.

#Building the base ROM
In order to build the base ROM, follow these steps:

Windows:
Just run build.bat.

Mac OS X:

1. Make sure you have Xcode installed. If not, you can get it for free from the App Store.

2. Run the following in Terminal (make sure you have admin!):

   git clone https://github.com/bentley/rgbds

   cd rgbds

   sudo make install

   cd ..

3. Run build.sh in Terminal. If it says "permission denied", then type "chmod 750 build.sh" and try again.

LINUX (UNTESTED):

1. Run "sudo apt-get install gcc bison git" in whatever terminal emulator you use (make sure you have admin!)

2. Once that's done, run the following (make sure you have admin!):

   git clone https://github.com/bentley/rgbds

   cd rgbds

   sudo make install

   cd ..

3. Run build.sh.

#Using the base ROM
In order to use the base ROM, you need a GBS file generated by Deflemask (http://www.deflemask.com) and a hex editor.

To use the base ROM:

1. Copy the song data from the GBS file (starting at offset 0x70) and insert it into the base ROM at 0x400, making sure not to overwrite or relocate the graphics data at offset 0x7C000.

2. Replace "SONG NAME HERE" at offset 0x7C715 with the song name, making sure it fits within 18 bytes.

3. Replace "AUTHOR HERE" at offset 0x7C729 with the author name, again making sure it fits within 18 bytes.

4. Open the ROM in a suitable Game Boy emulator, such as bgb (http://bgb.bircd.org) or Gambatte (https://github.com/sinamas/gambatte). Alternatively, you can run the ROM on real hardware using a flash cart (if you have one).