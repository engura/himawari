# himawari
Access images from the [himawari8 weather satellite](https://himawari8.nict.go.jp)] (courtesy of NICT) and compose near real-time desktop backgrounds of Earth or use the high-res images for other personal uses. For example....
![full globe](doc/img/h_2020-06-01T0100.png)
![high res section](doc/img/h_2020-11-29T0110.png)

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

You can use it as a CLI executable, or as a library.

*RUN EXAMPLE*: `himawari -w /home/User/himawari -d /home/User/Pictures/live -r 4 -f top -m day -v`

To set cron (with all the supplied arguments):
`himawari -w /home/User/himawari -d /home/User/Pictures/live -r 4 -f top -m day -v -c set`
and then to remove it from cron:
`himawari -w /home/User/himawari -d /home/User/Pictures/live -r 4 -f top -m day -v -c clear`

### Details
 - Grabs a tiled image from Himawari, (each photo of Earth is split into square tiles of 550x550px) reassembles it into one image, and optionally copies one of the downloaded images into a `destination` folder to use as a desktop background.
![a tile](doc/img/t_2020-12-01T0410-1_0.png)
 - Can change the resolution. Default is "2", smallest. Maximum is "20". It will produce an jpg of ~200MB in size for the full planet. The allowed steps are [2, 4, 8, 16, 20]. Resolution of 2 means that the image is composed of *2* tiles across, so the full image becomes 1100px wide/high. An image of resolution *factor 4* is then 550 * 4 = 2200px across. And the maximum one is 20 * 550 = 11000px X 11000px!!!!!
 - Since the images can be kinda big, we can customize which part of the planet we want to see: `top`, `full` planet, or bottom (`low`).
 - When using the `autorun` option (it's the method that command line utility uses), we save the last 48hrs in a folder (`working_dir`). We can then have 2 options: either show what is `now` outside, or! cycle the last complete 24 hours with a new background photo every 2 minutes? Because the images are all downloaded at once, and then an incremental download of one photo as needed, the internet traffic is relatively reasonable. Cycling the background photos doesn't need to access internet or download anything.

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
 - run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the .gem file to [rubygems.org](https://rubygems.org).

# Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/engura/himawari.

# License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
