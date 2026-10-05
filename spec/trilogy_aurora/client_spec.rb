# frozen_string_literal: true

RSpec.describe TrilogyAurora::Client do
  let(:trilogy_aurora) { described_class.new(options) }
  let(:aurora_max_retry) { 10 }
  let(:aurora_disconnect_on_readonly) { false }
  let :options do
    {
      host: '127.0.0.1',
      port: `docker compose port mysql 3306`.chomp[/[0-9]+$/],
      username: 'root',
      password: nil,
      aurora_max_retry: aurora_max_retry,
      aurora_disconnect_on_readonly: aurora_disconnect_on_readonly
    }
  end

  describe 'Trilogy' do
    it 'returns TrilogyAurora::Trilogy' do
      expect(Trilogy).to eq described_class
    end
  end

  describe '#trilogy' do
    it 'return an original Trilogy instance' do
      expect(trilogy_aurora.trilogy).to be_instance_of(TrilogyAurora::Trilogy)
    end
  end

  describe '#query' do
    let(:query) { trilogy_aurora.query('SELECT CURRENT_USER() AS user') }

    context 'when aurora_disconnect_on_readonly is true' do
      let(:query) { trilogy_aurora.query('SELECT CURRENT_USER() AS user') }
      let(:aurora_disconnect_on_readonly) { true }

      before do
        allow(trilogy_aurora).to receive(:warn)
        allow(trilogy_aurora).to receive(:disconnect!)
        allow(trilogy_aurora.trilogy).to receive(:query).and_raise(
          Trilogy::BaseError,
          'ERROR 1290 (HY000): The MySQL server is running with the' \
          '--read-only option so it cannot execute this statement'
        )
      end

      it 'disconnects immediately', :aggregate_failures do
        expect { query }.to raise_error(Trilogy::Error)
        expect(trilogy_aurora).to have_received(:disconnect!)
      end
    end

    it 'return a Trilogy::Result' do
      expect(query).to be_instance_of(Trilogy::Result)
    end

    it 'returns a result of size 1' do
      expect(query.to_a.size).to eq(1)
    end

    it 'returns the correct result' do
      expect(query.to_a.first.first).to match(/^root@.+$/)
    end

    it "calls the original Trilogy's #query" do
      allow(trilogy_aurora.trilogy).to receive(:query)
      query
      expect(trilogy_aurora.trilogy).to have_received(:query).once
    end

    context 'when Trilogy::Error is raised' do
      before do
        allow(trilogy_aurora).to receive(:warn)
        allow(trilogy_aurora).to receive(:sleep)
        allow(trilogy_aurora).to receive(:reconnect!)
        allow(trilogy_aurora.trilogy).to receive(:query).and_raise(
          Trilogy::BaseError,
          'ERROR 1290 (HY000): The MySQL server is running with the' \
          '--read-only option so it cannot execute this statement'
        )
      end

      it 'reconnects 10 times', :aggregate_failures do
        expect { query }.to raise_error(Trilogy::Error)
        expect(trilogy_aurora).to have_received(:reconnect!).exactly(10).times
      end

      it 'retries 10 times', :aggregate_failures do
        expect { query }.to raise_error(Trilogy::Error)
        expect(trilogy_aurora.trilogy).to have_received(:query).exactly(11).times
      end

      it 'retries at the correct interval', :aggregate_failures do
        intervals = []
        allow(trilogy_aurora).to receive(:sleep) { |seconds| intervals << seconds }
        expect { query }.to raise_error(Trilogy::Error)
        expect(intervals).to eq([0, 1.5, 3, 4.5, 6, 7.5, 9, 10, 10, 10])
      end
    end

    context 'when Trilogy::Error is raised and is not a failover error' do
      before do
        allow(trilogy_aurora).to receive(:warn)
        allow(trilogy_aurora).to receive(:sleep)
        allow(trilogy_aurora).to receive(:reconnect!)
        allow(trilogy_aurora.trilogy).to receive(:query).and_raise(
          Trilogy::BaseError,
          "Unknown column 'hogehoge' in 'field list'"
        )
      end

      it 'does not reconnect', :aggregate_failures do
        expect { query }.to raise_error(Trilogy::Error)
        expect(trilogy_aurora).not_to have_received(:reconnect!)
      end

      it 'does not retry query', :aggregate_failures do
        expect { query }.to raise_error(Trilogy::Error)
        expect(trilogy_aurora.trilogy).to have_received(:query).once
      end
    end

    context 'when StandardError is raised' do
      before do
        allow(trilogy_aurora).to receive(:reconnect!)
        allow(trilogy_aurora.trilogy).to receive(:query).and_raise(StandardError)
      end

      it 'does not reconnect', :aggregate_failures do
        expect { query }.to raise_error(StandardError)
        expect(trilogy_aurora).not_to have_received(:reconnect!)
      end

      it 'does not retry query', :aggregate_failures do
        expect { query }.to raise_error(StandardError)
        expect(trilogy_aurora.trilogy).to have_received(:query).once
      end
    end
  end

  describe '#reconnect!' do
    let(:reconnect!) { trilogy_aurora.reconnect! }

    it 'changes the existing trilogy client' do
      expect { reconnect! }.to change(trilogy_aurora, :trilogy)
    end

    it 'sets the trilogy client to a new instance of Trilogy' do
      reconnect!
      expect(trilogy_aurora.trilogy).to be_instance_of(TrilogyAurora::Trilogy)
    end

    it 'closes the old #trilogy' do
      old_trilogy = trilogy_aurora.trilogy
      allow(old_trilogy).to receive(:close)
      reconnect!
      expect(old_trilogy).to have_received(:close).once
    end

    context 'when #close raises an error' do
      before { allow(trilogy_aurora.trilogy).to receive(:close).and_raise(Trilogy::BaseError) }

      it 'does not raise error' do
        expect { reconnect! }.not_to raise_error
      end

      it 'changes the existing trilogy client' do
        expect { reconnect! }.to change(trilogy_aurora, :trilogy)
      end

      it 'sets the trilogy client to a new instance of Trilogy' do
        reconnect!
        expect(trilogy_aurora.trilogy).to be_instance_of(TrilogyAurora::Trilogy)
      end
    end
  end

  describe '#method_missing' do
    it 'delegates to #trilogy' do
      allow(trilogy_aurora.trilogy).to receive(:ping)
      trilogy_aurora.ping
      expect(trilogy_aurora.trilogy).to have_received(:ping)
    end
  end

  describe '#respond_to_missing?' do
    it 'delegates to #trilogy' do
      allow(trilogy_aurora.trilogy).to receive(:respond_to?).and_call_original
      trilogy_aurora.respond_to?(:foobar)
      expect(trilogy_aurora.trilogy).to have_received(:respond_to?).with(:foobar, false)
    end
  end

  describe '::method_missing' do
    it 'delegates to Trilogy' do
      allow(TrilogyAurora::Trilogy).to receive(:foobar)
      described_class.foobar
      expect(TrilogyAurora::Trilogy).to have_received(:foobar)
    end
  end

  describe '::respond_to_missing?' do
    it 'delegates to Trilogy' do
      allow(TrilogyAurora::Trilogy).to receive(:respond_to?).and_call_original
      described_class.respond_to?(:foobar)
      expect(TrilogyAurora::Trilogy).to have_received(:respond_to?).with(:foobar, false)
    end
  end

  describe '::const_missing' do
    it 'delegates to Trilogy' do
      expect(Trilogy::SERVER_STATUS_IN_TRANS).to eq described_class::SERVER_STATUS_IN_TRANS
    end
  end

  describe '::const_defined?' do
    it 'delegates to Trilogy' do
      allow(TrilogyAurora::Trilogy).to receive(:const_defined?).and_call_original
      described_class.const_defined?('FOOBAR')
      expect(TrilogyAurora::Trilogy).to have_received(:const_defined?).with('FOOBAR')
    end
  end
end
