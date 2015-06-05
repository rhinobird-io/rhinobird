require_relative '../app'

RSpec.describe Event do
  context 'with daily repeated event' do
    event = Event.new({repeated: true, repeated_type: 'Daily'})
    it 'get next event correctly' do
      p event
    end
  end
end