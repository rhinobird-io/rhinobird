RSpec.describe Event do
  time = '2015-9-9 8:00'
  context "with daily repeated event start from #{time}" do
    context 'with frequency 3' do
      context 'with end type Occurrence, repeated times 3' do
        event = Event.new({repeated: true, repeated_type: 'Daily', from_time: DateTime.parse(time)})
        event.repeated_frequency = 3
        event.repeated_end_type = 'Occurrence'
        event.repeated_times = 3
        it 'get next event correctly' do
          expect(event.get_next_event(Date.parse('2015-9-9')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(event.get_next_event(Date.parse('2015-9-10')).from_time).to eq(DateTime.parse('2015-9-12 8:00'))
          expect(event.get_next_event(Date.parse('2015-9-12')).from_time).to eq(DateTime.parse('2015-9-12 8:00'))
          expect(event.get_next_event(Date.parse('2015-9-13')).from_time).to eq(DateTime.parse('2015-9-15 8:00'))
          expect(event.get_next_event(Date.parse('2015-9-16'))).to be_nil
        end
      end
      context 'with end type Date, end date 2015-9-12' do
        event = Event.new({repeated: true, repeated_type: 'Daily', from_time: DateTime.parse(time)})
        event.repeated_frequency = 3
        event.repeated_end_type = 'Date'
        event.repeated_end_date = Date.parse('2015-9-12')
        it 'get next event correctly' do
          expect(event.get_next_event(Date.parse('2015-9-9')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(event.get_next_event(Date.parse('2015-9-10')).from_time).to eq(DateTime.parse('2015-9-12 8:00'))
          expect(event.get_next_event(Date.parse('2015-9-12')).from_time).to eq(DateTime.parse('2015-9-12 8:00'))
          expect(event.get_next_event(Date.parse('2015-9-13'))).to be_nil
          expect(event.get_next_event(Date.parse('2015-9-16'))).to be_nil
        end
      end
    end
  end
end