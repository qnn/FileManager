class ManagerController < ApplicationController

  def index
  end

  def ls
    path = params[:path] || '/'
    begin
      Dir.chdir(File.join(Dir.home, path))
      files = []
      Dir.foreach('.') do |file|
        stat = File.stat(file)
        files << {
          name: file,
          directory?: stat.directory?,
          size: stat.size
        }
      end
      render json: files
    rescue Errno::ENOENT
      render nothing: true, status: 404
    end
  end

end
