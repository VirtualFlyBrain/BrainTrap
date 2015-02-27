class UploadController < ApplicationController
  def index

  end

  def uptarget
    @filetotal = params[:updata].length
    @upload_names = Array.new(@filetotal)
    fileid = 1;

    #params[:updata].save('public/data/test.tmp')
    #params[:updata].each do |id, upfile|
      #Clean up the filename
      #name = File.basename(upfile.original_filename)

    upfile = params[:updata]

      name = upfile.original_filename
      name = name.sub(/[^\w\.\-]/, '_')

      #prepend an id number
      name = ('000' + fileid.to_s)[0..3] + '_' + name

      #Save the file
      directory = 'C:/dev/BrainTrap/public/data'
      path = File.join(directory, name)
      File.open(path, 'wb') { |f| f.write(upfile.read)}

      @upload_names[fileid] = name

    #end
  end

end
