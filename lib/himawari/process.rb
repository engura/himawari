module Himawari
  module Process
    def process_bad_tiles(bad_tiles, tile)
      begin
        i = File.basename(tile[0..-9])
        ending = tile[-7,3]
        stamp = Time.parse(i.dup.insert(-3, ':') + ':00+00:00')
        bad_tiles[i] = [] unless bad_tiles.dig(i)
        bad_tiles[i] << [himawari_format(stamp, ending), himawari_format(stamp - 600, ending), himawari_format(stamp - 1200, ending)]
      rescue
        puts "Error: could not derive timestamp from filename of `#{tile}`"
      end
      # `cp #{tile} #{tile.gsub('/t_', '/x_')}`
      # no need to delete individual "bad tiles" because we will try to recover them.
      # But upon failure, will delete the whole himawari image
      # File.delete(tile)
      bad_tiles
    end

    def himawari_format(stamp, tile_end)
      "#{stamp.year}/#{stamp.month}/#{stamp.day}/#{stamp.hour}#{stamp.min}00_#{tile_end}"
    end

    # bad_tiles structure: { "t_2019-11-11T0240": [ [ [tile_url_1, tile_url_2, tile_url_3] ], [array_of_tiles], [array_of_tiles] ] }
    def recover_bad_sectors(bad_tiles)
      bad_tiles.each do |bad_pic_name, sectors|
        pic_not_good = true

        if sectors.count >= resolution # don't try to fix/recover pics that have too many pieces missing
          puts "#{bad_pic_name} has #{sectors.count} pieces missing. Too many. Can't recover & will delete the whole thing!"
        else
          puts "#{bad_pic_name} has #{sectors.count} pieces missing. Will try to recover/fill in with older data."
          tile = "#{data_path}/#{bad_pic_name}-#{sectors[0][-3,3]}.png"
          sectors.each do |bad_tile|
            `curl -sC - "#{HIMAWARI_URL}/#{resolution}d/550/#{bad_tile}.png" > #{tile}`
            if File.size(tile) == control_size && system("cmp #{tile} #{APP_ROOT}/no_image.png") # yep, it's bad...
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
