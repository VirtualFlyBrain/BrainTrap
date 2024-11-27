# require '../app/models/stack.rb'

class ExtractorThread
  def initialize
    begin
      exe_path = 'C:/dev/BioImageConvert/imgcnv/imgcnv.exe'
      #Extract stacks
      $EXTRACTOR_POINT = '0';
      for s in $EXTRACTOR_STACKS
        $EXTRACTOR_POINT = '1';
        if s[:status] == 'waiting'
          #Process this stack
          $EXTRACTOR_CURRENT = s[:id]
          $EXTRACTOR_POINT = '2';

          #Get info
          command = "#{exe_path} -i #{s[:file_src]} -info"
          exec_result = %x[#{command}]
          $EXTRACTOR_POINT = '3';

          match = exec_result.match(/.*zsize: (\d+).*/m)
          zn = match[1].to_i unless match == nil

          match = exec_result.match(/.*channels: (\d+).*/m)
          channels = match[1].to_i unless match == nil

          match = exec_result.match(/.*width: (\d+).*/m)
          width = match[1].to_i unless match == nil

          match = exec_result.match(/.*height: (\d+).*/m)
          height = match[1].to_i unless match == nil

          $EXTRACTOR_POINT = '4';
          ActiveRecord::Base.verify_active_connections!
          Stack.update(s[:id], :num_images => zn, :max_res_x => width, :max_res_y => height)

          $EXTRACTOR_POINT = '5';
          default_options = ' -t jpeg'
          thumb_runs = [['thumb1', " -resize 256,,BL -page #{(zn/2).ceil}"], ['thumb2', " -resize 128,,BL -page #{(zn/2).ceil}"]]
          size_runs = [['full', ''], ['768',' -resize 768,,BL'], ['512', ' -resize 512,,BL']]
          chan_runs = [['merge', ' -remap 1,2,1'], ['c1', ' -remap 1,0,1'], ['c2', ' -remap 0,2,0']]

          $EXTRACTOR_POINT = '6';
          if channels == 1
            #Extract one channel
            FileUtils.mkdir_p "#{s[:file_dest]}"
            $EXTRACTOR_PROGRESS = 'Step 1 of 3'
            for thumb_options in thumb_runs
              command = "#{exe_path} -i #{s[:file_src]} -o #{s[:file_dest]}#{thumb_options[0]}.jpg#{default_options}#{thumb_options[1]} -remap 0,1,0"
              exec_result += %x[#{command}]
            end
            step = 0
            for size_options in size_runs
              step = step + 1
              $EXTRACTOR_PROGRESS = "Step #{step} of 3"
              FileUtils.mkdir_p(s[:file_dest] + size_options[0])
              command = "#{exe_path} -i #{s[:file_src]} -o #{s[:file_dest]}#{size_options[0]}/c1.jpg#{default_options}#{size_options[1]} -remap 0,1,0"
              exec_result += %x[#{command}]
            end
          elsif channels == 2
            #Extract channel 1, channel 2 and merge
            FileUtils.mkdir_p(s[:file_dest])
            $EXTRACTOR_PROGRESS = 'Step 1 of 9'
            for thumb_options in thumb_runs
              command = "#{exe_path} -i #{s[:file_src]} -o #{s[:file_dest]}#{thumb_options[0]}.jpg#{default_options}#{thumb_options[1]} -remap 1,2,1"
              exec_result += %x[#{command}]
            end
            step = 0
            for size_options in size_runs
              for chan_options in chan_runs
                step = step + 1
                $EXTRACTOR_PROGRESS = "Step #{step} of 9"
                FileUtils.mkdir_p(s[:file_dest] + size_options[0])
                command = "#{exe_path} -i #{s[:file_src]} -o #{s[:file_dest]}#{size_options[0]}/#{chan_options[0]}.jpg#{default_options}#{size_options[1]}#{chan_options[1]}"
                exec_result += %x[#{command}]
              end
            end
          end
          $EXTRACTOR_POINT = '7';


        end
        $EXTRACTOR_POINT = '8';
      end
    rescue
      $EXTRACTOR_ERROR = "Error: #{$!}"
    ensure

      $EXTRACTOR_POINT = '9';
      $EXTRACTOR_CURRENT = 0
      $EXTRACTOR_PROGRESS = 'Not running'
      $EXTRACTOR_RUNNING = false
      $EXTRACTOR_POINT = '10';
    end
end
end
