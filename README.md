# himawari
access images from the [himawari8 weather satellite](https://himawari8.nict.go.jp)] and compose real-time Earth backgrounds/high-res images

## Building the gem from source
navigate to the gem's directory and...
```
gem build himawari.gemspec
gem install himawari-0.1.0.gem
```


RUN EXAMPLE: ./himawari.rb -live -focus=top -resolution=8 -desktop='every desktop' -destination=/Users/vladimir/Pictures/live
All args are optional & default to day cycle (every minute pic change); northern-hemisphere close up; 2-level res; set all desktops

To set cron (with all custom args):
./himawari.rb -day -focus=top -resolution=8 -destination=/Users/vladimir/Pictures/live -set_cron
./himawari.rb -clear_cron

objective: grab a tiled image from Himawari, reassemble it, and stick as desktop background.
can change the resolution
and also since we are here, can customize which part of the planet we want to see top/middle section/bottom, etc
then, save the last 24hrs in a folder... We can have 2 options: either show what is "now" outside, or! cycle the last 24... maybe change photo every min? so, 10mins interval every 1min update?

 - 1. do NOT attempt to fetch data from black listed WiFis
 - 2. if no internet, just show last available data
 - 3. keep only 1 day's worth of images (~144 photos)
 - 4. check for `No Image` images and skip those (until? if?) they become available

 install CLI dependencies:
 brew install imagemagick # https://github.com/minimagick/minimagick
 brew install parallel # https://linux.die.net/man/1/parallel