# 0.1.2
- Updated Readme with more details
- Updated meta links in gemspec
- Fixed a crash/bug related to missing a png file (I forgot that we actually DO need one of those pngs. It is used as a control to compare downloaded images against.)
- ```/var/lib/gems/2.5.0/gems/himawari-0.1.1/lib/himawari/process.rb:14:in `size': No such file or directory @ rb_file_s_size - /var/lib/gems/2.5.0/gems/himawari-0.1.1/lib/himawari/no_image.png (Errno::ENOENT)```

# 0.1.1
- Updated Readme
- Added changelog
- Set a minimum Ruby version to >=2.5
- Removed *.png files from the gem to reduce its size

# 0.1.0
- Initial release
