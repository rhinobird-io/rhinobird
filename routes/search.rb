# encoding: utf-8

class App < Sinatra::Base
  namespace '/api' do

    get '/search/:q' do
      events = Event.search(query: {
                                filtered: {
                                    query: {
                                        multi_match: {
                                            query: params[:q],
                                            fields: %w(title description)
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