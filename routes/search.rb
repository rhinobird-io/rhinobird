# encoding: utf-8

class App < Sinatra::Base
  namespace '/api' do

    get '/search/:q' do
      events = Event.search(query: {
                                filtered: {
                                    query: {
                                        match: {
                                            title: params[:q]
                                        }
                                    },
                                    filter: {
                                        term: {
                                            creator_id: @userid
                                        }
                                    }
                                }
                            })
      events.to_json
    end

  end
end