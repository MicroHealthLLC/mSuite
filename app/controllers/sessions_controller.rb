class SessionsController < ApplicationController

  def create
    sessions[:mindmap_id] = @mindmap.id
  end

end
