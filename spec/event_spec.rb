RSpec.describe Event do
  time = '2015-9-9 8:00'
  context "with daily repeated event start from #{time}" do
    event = Daily.new({from_time: DateTime.parse(time)})
    context 'with frequency 3' do
      evt = event.dup
      evt.repeated_frequency = 3
      context 'with end type Occurrence, repeated times 3' do
        e = evt.dup
        e.repeated_end_type = 'Occurrence'
        e.repeated_times = 3

        it 'get next event correctly' do
          expect(e.get_next_event(Date.parse('2015-9-1')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-9')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-10')).from_time).to eq(DateTime.parse('2015-9-12 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-12')).from_time).to eq(DateTime.parse('2015-9-12 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-13')).from_time).to eq(DateTime.parse('2015-9-15 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-16'))).to be_nil
        end

        last = e.get_next_event(Date.parse('2015-9-13'))
        it 'get previous event before certain date correctly' do
          expect(last.get_previous_event(Date.parse('2015-9-30')).from_time).to eq(DateTime.parse('2015-9-15 8:00'))
          expect(last.get_previous_event(Date.parse('2015-9-15')).from_time).to eq(DateTime.parse('2015-9-15 8:00'))
          expect(last.get_previous_event(Date.parse('2015-9-14')).from_time).to eq(DateTime.parse('2015-9-12 8:00'))
          expect(last.get_previous_event(Date.parse('2015-9-11')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(last.get_previous_event(Date.parse('2015-9-9')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(last.get_previous_event(Date.parse('2015-9-4'))).to be_nil
        end
      end
      context 'with end type Date, end date 2015-9-12' do
        e = evt.dup
        e.repeated_end_type = 'Date'
        e.repeated_end_date = Date.parse('2015-9-12')
        it 'get next event correctly' do
          expect(e.get_next_event(Date.parse('2015-9-1')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-9')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-10')).from_time).to eq(DateTime.parse('2015-9-12 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-12')).from_time).to eq(DateTime.parse('2015-9-12 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-13'))).to be_nil
          expect(e.get_next_event(Date.parse('2015-9-16'))).to be_nil
        end
      end
      context 'with end type Never' do
        e = evt.dup
        e.repeated_end_type = 'Never'
        it 'get next event correctly' do
          expect(e.get_next_event(Date.parse('2055-9-16')).from_time).to eq(DateTime.parse('2055-9-18 8:00'))
        end
      end
    end
  end

  context "with weekly repeated (Tue, Fri) event start from #{Date.parse(time)}, frequency 2" do
    event = Weekly.new({from_time: DateTime.parse(time)})
    event.repeated_frequency = 2
    event.repeated_on = '["Tue", "Fri"]'
    context 'with end type Occurrence, repeated times 2' do
      evt = event.dup
      evt.repeated_end_type = 'Occurrence'
      evt.repeated_times = 2 * 2
      it 'get next event correctly' do
        expect(evt.get_next_event(Date.parse('2015-8-8')).from_time).to eq(DateTime.parse('2015-9-11 8:00'))
        expect(evt.get_next_event(Date.parse('2015-9-8')).from_time).to eq(DateTime.parse('2015-9-11 8:00'))
        expect(evt.get_next_event(Date.parse('2015-9-9')).from_time).to eq(DateTime.parse('2015-9-11 8:00'))
        expect(evt.get_next_event(Date.parse('2015-9-11')).from_time).to eq(DateTime.parse('2015-9-11 8:00'))
        expect(evt.get_next_event(Date.parse('2015-9-12')).from_time).to eq(DateTime.parse('2015-9-22 8:00'))
        expect(evt.get_next_event(Date.parse('2015-9-23')).from_time).to eq(DateTime.parse('2015-9-25 8:00'))
        expect(evt.get_next_event(Date.parse('2015-9-26'))).to be_nil
      end

      last = evt.get_next_event(Date.parse('2015-9-23'))
      it 'get previous event before certain date correctly' do
        expect(last.get_previous_event(Date.parse('2015-9-26')).from_time).to eq(DateTime.parse('2015-9-25 8:00'))
      end
    end
    context "with end type Date, end date #{Date.parse('2015-9-24')}" do
      evt = event.dup
      evt.repeated_end_type = 'Date'
      evt.repeated_end_date = Date.parse('2015-9-24')
      it 'get next event correctly' do
        expect(evt.get_next_event(Date.parse('2015-8-8')).from_time).to eq(DateTime.parse('2015-9-11 8:00'))
        expect(evt.get_next_event(Date.parse('2015-9-9')).from_time).to eq(DateTime.parse('2015-9-11 8:00'))
        expect(evt.get_next_event(Date.parse('2015-9-11')).from_time).to eq(DateTime.parse('2015-9-11 8:00'))
        expect(evt.get_next_event(Date.parse('2015-9-12')).from_time).to eq(DateTime.parse('2015-9-22 8:00'))
        expect(evt.get_next_event(Date.parse('2015-9-23'))).to be_nil
        expect(evt.get_next_event(Date.parse('2015-9-26'))).to be_nil
      end
    end
  end

  context "with monthly repeated event start from #{Date.parse('2015-10-10 8:00')}, frequency 3" do
    event = Monthly.new({from_time: DateTime.parse('2015-10-10 8:00')})
    event.repeated_frequency = 3
    context 'repeated by day of month' do
      evt = event.dup
      evt.repeated_by = 'Month'
      context 'with end type Occurrence, repeated times 3' do
        ev = evt.dup
        ev.repeated_end_type = 'Occurrence'
        ev.repeated_times = 3
        it 'get next event correctly' do
          expect(ev.get_next_event(Date.parse('2015-6-9')).from_time).to eq(DateTime.parse('2015-10-10 8:00'))
          expect(ev.get_next_event(Date.parse('2015-10-10')).from_time).to eq(DateTime.parse('2015-10-10 8:00'))
          expect(ev.get_next_event(Date.parse('2015-10-11')).from_time).to eq(DateTime.parse('2016-1-10 8:00'))
          expect(ev.get_next_event(Date.parse('2015-10-20')).from_time).to eq(DateTime.parse('2016-1-10 8:00'))
          expect(ev.get_next_event(Date.parse('2016-1-11')).from_time).to eq(DateTime.parse('2016-4-10 8:00'))
          expect(ev.get_next_event(Date.parse('2016-4-11'))).to be_nil
        end

        last = ev.get_next_event(Date.parse('2016-1-11'))
        it 'get previous event before certain date correctly' do
          expect(last.get_previous_event(Date.parse('2016-4-11')).from_time).to eq(DateTime.parse('2016-4-10 8:00'))
          expect(last.get_previous_event(Date.parse('2016-4-10')).from_time).to eq(DateTime.parse('2016-4-10 8:00'))
          expect(last.get_previous_event(Date.parse('2016-4-9')).from_time).to eq(DateTime.parse('2016-1-10 8:00'))
          expect(last.get_previous_event(Date.parse('2016-2-9')).from_time).to eq(DateTime.parse('2016-1-10 8:00'))
          expect(last.get_previous_event(Date.parse('2016-1-9')).from_time).to eq(DateTime.parse('2015-10-10 8:00'))
          expect(last.get_previous_event(Date.parse('2015-12-10')).from_time).to eq(DateTime.parse('2015-10-10 8:00'))
          expect(last.get_previous_event(Date.parse('2015-10-9'))).to be_nil
        end
      end
      context "with end type Date, end date #{Date.parse('2015-12-24')}" do
        ev = evt.dup
        ev.repeated_end_type = 'Date'
        ev.repeated_end_date = Date.parse('2015-12-24')
        it 'get next event correctly' do
          expect(ev.get_next_event(Date.parse('2015-6-10')).from_time).to eq(DateTime.parse('2015-10-10 8:00'))
          expect(ev.get_next_event(Date.parse('2015-10-20'))).to be_nil
        end
      end
    end

    context 'repeated by day of day of Nth week of month' do
      evt = event.dup
      evt.repeated_by = 'Week'
      context 'with end type Occurrence, repeated times 3' do
        ev = evt.dup
        ev.repeated_end_type = 'Occurrence'
        ev.repeated_times = 3
        it 'get next event correctly' do
          expect(ev.get_next_event(Date.parse('2015-2-8')).from_time).to eq(DateTime.parse('2015-10-10 8:00'))
          expect(ev.get_next_event(Date.parse('2015-11-9')).from_time).to eq(DateTime.parse('2016-1-9 8:00'))
          expect(ev.get_next_event(Date.parse('2016-1-10')).from_time).to eq(DateTime.parse('2016-4-9 8:00'))
          expect(ev.get_next_event(Date.parse('2016-4-10'))).to be_nil
        end
      end
      context "with end type Date, end date #{Date.parse('2016-8-24')}" do
        ev = evt.dup
        ev.repeated_end_type = 'Date'
        ev.repeated_end_date = Date.parse('2016-8-24')
        it 'get next event correctly' do
          expect(ev.get_next_event(Date.parse('2015-2-8')).from_time).to eq(DateTime.parse('2015-10-10 8:00'))
          expect(ev.get_next_event(Date.parse('2015-11-9')).from_time).to eq(DateTime.parse('2016-1-9 8:00'))
          expect(ev.get_next_event(Date.parse('2016-1-10')).from_time).to eq(DateTime.parse('2016-4-9 8:00'))
          expect(ev.get_next_event(Date.parse('2016-4-10')).from_time).to eq(DateTime.parse('2016-7-9 8:00'))
          expect(ev.get_next_event(Date.parse('2016-7-10'))).to be_nil
        end
      end
    end
  end

  context "with yearly repeated event start from #{time}" do
    event = Yearly.new({from_time: DateTime.parse(time)})
    context 'with frequency 2' do
      evt = event.dup
      evt.repeated_frequency = 2
      context 'with end type Occurrence, repeated times 3' do
        e = evt.dup
        e.repeated_end_type = 'Occurrence'
        e.repeated_times = 3
        it 'get next event correctly' do
          expect(e.get_next_event(Date.parse('2015-1-1')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-9')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-10')).from_time).to eq(DateTime.parse('2017-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2016-9-2')).from_time).to eq(DateTime.parse('2017-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2017-9-13')).from_time).to eq(DateTime.parse('2019-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2019-9-16'))).to be_nil
        end

        last = e.get_next_event(Date.parse('2017-9-13'))
        it 'get previous event before certain date correctly' do
          expect(last.get_previous_event(Date.parse('2019-9-16')).from_time).to eq(DateTime.parse('2019-9-9 8:00'))
          expect(last.get_previous_event(Date.parse('2019-9-8')).from_time).to eq(DateTime.parse('2017-9-9 8:00'))
          expect(last.get_previous_event(Date.parse('2018-8-8')).from_time).to eq(DateTime.parse('2017-9-9 8:00'))
          expect(last.get_previous_event(Date.parse('2017-9-9')).from_time).to eq(DateTime.parse('2017-9-9 8:00'))
          expect(last.get_previous_event(Date.parse('2015-9-10')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(last.get_previous_event(Date.parse('2015-9-8'))).to be_nil
          expect(last.get_previous_event(Date.parse('2015-5-8'))).to be_nil
        end
      end
      context 'with end type Date, end date 2022-9-12' do
        e = evt.dup
        e.repeated_end_type = 'Date'
        e.repeated_end_date = Date.parse('2022-9-12')
        it 'get next event correctly' do
          expect(e.get_next_event(Date.parse('2015-1-1')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-9')).from_time).to eq(DateTime.parse('2015-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2015-9-10')).from_time).to eq(DateTime.parse('2017-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2016-9-2')).from_time).to eq(DateTime.parse('2017-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2017-9-13')).from_time).to eq(DateTime.parse('2019-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2019-9-16')).from_time).to eq(DateTime.parse('2021-9-9 8:00'))
          expect(e.get_next_event(Date.parse('2022-9-16'))).to be_nil
        end
      end
    end
  end
end