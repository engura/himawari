# himawari
Access images from the [himawari8 weather satellite](https://himawari8.nict.go.jp)] (courtesy of NICT) and compose near real-time desktop backgrounds of Earth or use the high-res images for other personal uses.

# Installation
Add this line to your application's Gemfile:
```
gem 'himawari'
```
And then execute:
```
bundle
```
Or install it yourself as:
```
gem install himawari
```
## Install CLI Dependencies
Mac:
```
brew install imagemagick # https://github.com/minimagick/minimagick
brew install parallel # https://linux.die.net/man/1/parallel
```
or Linux: run `bin/setup`

# Usage

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

# Development
After checking out the repo, doing the steps in `installation` above and messing around with the code, run `rake test` and `rubocop` to use the tests and make sure everything is ok. To run a specific test, use `rake test TEST=spec/test_base.rb TESTOPTS="--name=test_bad_params --seed=1234"` and as for rubocop: `rubocop lib/himawari/base.rb`

## Building the gem on local machine/from source
navigate to the gem's directory and...
Manually:
```
gem build himawari.gemspec
gem install himawari-#.#.#.gem # replace the # with the most recent version
```
Semi-manually (the end result is same as above):
```
bundle exec rake install
```

## Releasing a new version of the Gem
 - Update the version number in `himawari.gemspec`
 - run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the .gem file to rubygems.org.

# Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/engura/himawari.

# License
The gem is available as open source under the terms of the MIT License.
