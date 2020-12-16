# frozen-string-literal: true

module Himawari
  # these methods provide checking and (trying to) fix the Tiles that we downloaded from the web.
  # sometimes, the connection might be bad, and instead of an actual PNG for a Tile, we get a blank empty file.
  # in other times, we get a special "no_image" png. This one is annoying. It IS a real picture,
  # but it most CERTAINLY is NOT a picture of the Earth. (These normally come back during 0240 and 1440 timestamps)
  # -- Himawari does not take photos when the Sun is in the view of the Satellite. Well, we wouldn't be able to see
  # the Earth at those times anyway due to the Sun's brightness.
  module Process
    private

    def check_tiles
      @control_size ||= File.size("#{app_root}/no_image.png")
      bad_tiles = {}
      Dir["#{data_path}/t_*.png"].each do |tile|
        bad_tiles = process_bad_tiles(bad_tiles, tile) if bad_tile?(tile)
      end
      recover_bad_sectors(bad_tiles)
    end

    def process_bad_tiles(bad_tiles, tile)
      i = File.basename(tile[0..-9])
      ending = tile[-7, 3]
      stamp = Time.parse("#{i.dup.insert(-3, ':')}:00+00:00")
      bad_tiles[i] = [] unless bad_tiles[i]
      bad_tiles[i] << [
        himawari_format(stamp, ending),
        himawari_format(stamp - 600, ending),
        himawari_format(stamp - 1_200, ending)
      ]
      # `cp #{tile} #{tile.gsub('/t_', '/x_')}`
      # no need to delete individual "bad tiles" because we will try to recover them.
      # But upon failure, will delete the whole himawari image
      # File.delete(tile)
      bad_tiles
    end

    def himawari_format(stamp, tile_end)
      "#{stamp.year}/#{stamp.month}/#{stamp.day}/#{stamp.hour}#{stamp.min}00_#{tile_end}"
    end

    def png?(file)
      File.size(file).positive? && IO.read(file, 4).force_encoding('utf-8') == "\x89PNG"
    end

    def bad_tile?(tile)
      !png?(tile) || File.size(tile) == @control_size && system("cmp #{tile} #{app_root}/no_image.png")
    end

    # bad_tiles structure:
    # { "t_2019-11-11T0240": [ [ [tile_url_1, tile_url_2, tile_url_3] ], [array_of_tiles], [array_of_tiles] ] }
    def recover_bad_sectors(bad_tiles)
      bad_tiles.each do |bad_pic_name, sectors|
        pic_not_good = true

        if sectors.count >= resolution # don't try to fix/recover pics that have too many pieces missing
          puts "#{bad_pic_name} has #{sectors.count} pieces missing. Too many. Can't recover & will delete the whole thing!"
        else
          puts "#{bad_pic_name} has #{sectors.count} pieces missing. Will try to recover/fill in with older data."
          p sectors
          tile = "#{data_path}/#{bad_pic_name}-#{sectors[0][-3, 3]}.png"
          sectors.each do |bad_tile|
            `curl -sC - "#{HIMAWARI_URL}/#{resolution}d/550/#{bad_tile}.png" > #{tile}`
            if bad_tile?(tile) # yep, it's bad...
              # File.delete(tile)
              pic_not_good = true
            else
              puts "#{tile} was recovered using #{bad_tile}!"
              pic_not_good = false
              break
            end
          end
        end
        # either too many pieces missing, or couldn't recover the wholes. It will look UGLY after reassembly,
        # so just bite the bullet and get rid of the whole thing
        `rm #{data_path}/#{bad_pic_name}*` if pic_not_good
      end
    end
  end
end
