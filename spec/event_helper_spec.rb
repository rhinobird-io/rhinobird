RSpec.describe EventHelper do
  context 'With set 1 of events' do
    events = []
    events << Event.new({title: 'Normal',
                         from_time: DateTime.parse('2015-9-11 9:00')})
    events << Daily.new({title: 'Daily',
                         from_time: DateTime.parse('2015-9-9 10:00'),
                         repeated_frequency: 4, repeated_end_type: 'Never'})
    events << Weekly.new({title: 'Weekly',
                         from_time: DateTime.parse('2015-9-10 8:00'),
                          repeated_on: '["Tue", "Fri"]',
                         repeated_frequency: 2, repeated_end_type: 'Occurrence', repeated_times: 2 * 2})
    events << Monthly.new({title: 'Monthly',
                         from_time: DateTime.parse('2015-9-8 7:00'),
                         repeated_frequency: 1, repeated_end_type: 'Never', repeated_by: 'Month'})
    it 'get next 10 events correctly' do
      result = EventHelper.next_n_events(events, Date.parse('2015-9-6'), 10)
      expect(result.size).to eq(10)
      expect(result[0].from_time.to_date).to eq(DateTime.parse('2015-9-8'))
      expect(result[0].title).to eq('Monthly')
      expect(result[1].from_time.to_date).to eq(DateTime.parse('2015-9-9'))
      expect(result[1].title).to eq('Daily')
      expect(result[2].from_time.to_date).to eq(DateTime.parse('2015-9-11'))
      expect(result[2].title).to eq('Weekly')
      expect(result[3].from_time.to_date).to eq(DateTime.parse('2015-9-11'))
      expect(result[3].title).to eq('Normal')
      expect(result[4].from_time.to_date).to eq(DateTime.parse('2015-9-13'))
      expect(result[4].title).to eq('Daily')
      expect(result[5].from_time.to_date).to eq(DateTime.parse('2015-9-17'))
      expect(result[5].title).to eq('Daily')
      expect(result[6].from_time.to_date).to eq(DateTime.parse('2015-9-21'))
      expect(result[6].title).to eq('Daily')
      expect(result[7].from_time.to_date).to eq(DateTime.parse('2015-9-22'))
      expect(result[7].title).to eq('Weekly')
      expect(result[8].from_time.to_date).to eq(DateTime.parse('2015-9-25'))
      expect(result[8].title).to eq('Weekly')
      expect(result[9].from_time.to_date).to eq(DateTime.parse('2015-9-25'))
      expect(result[9].title).to eq('Daily')
    end
  end

  context 'With set 2 of events' do
    events = []
    events << Event.new({title: 'Normal',
                         from_time: DateTime.parse('2015-9-11 9:00')})
    events << Daily.new({title: 'Daily Repeated Event',
                         from_time: DateTime.parse('2015-9-11 10:00'),
                         repeated_frequency: 1, repeated_end_type: 'Never'})
    events << Weekly.new({title: 'Weekly Repeated Event on Monday Friday',
                          from_time: DateTime.parse('2015-9-10 11:00'),
                          repeated_on: '["Mon", "Fri"]',
                          repeated_frequency: 1, repeated_end_type: 'Occurrence', repeated_times: 2 * 2})

    it 'get events of 2015-9-11 correctly' do
      result = EventHelper.get_events_by_date(events, Date.parse('2015-9-11'))
      expect(result.size).to eq(3)
    end

    it 'get events of the week of 2015-9-17 correctly' do
      result = EventHelper.get_events_by_week(events, Date.parse('2015-9-17'))
      expect(result.size).to eq(9)
    end
  end
end