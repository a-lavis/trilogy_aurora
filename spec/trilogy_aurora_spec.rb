# frozen_string_literal: true

RSpec.describe TrilogyAurora do
  let(:aurora_disconnect_on_readonly) { false }

  let :trilogy do
    Trilogy.new(
      host: ENV.fetch("TEST_DB_HOST", nil),
      username: ENV.fetch("TEST_DB_USER", nil),
      password: ENV.fetch("TEST_DB_PASS", nil),
      aurora_max_retry: 10,
      aurora_disconnect_on_readonly: aurora_disconnect_on_readonly
    )
  end

  it "has a version number" do
    expect(TrilogyAurora::VERSION).not_to be_nil
  end

  describe "Trilogy" do
    it "returns TrilogyAurora::Trilogy" do
      expect(Trilogy).to eq(TrilogyAurora::Trilogy)
    end
  end

  describe "#trilogy" do
    let :trilogy_client do
      trilogy.trilogy
    end

    it "return an original Trilogy instance" do
      expect(trilogy_client).to be_instance_of(TrilogyAurora::ORIGINAL_TRILOGY_CLASS)
    end

    describe "#connection_options" do
      let :connection_options do
        trilogy_client.connection_options
      end

      it "has the correct host" do
        expect(connection_options[:host]).to eq(ENV.fetch("TEST_DB_HOST", nil))
      end

      it "has the correct username" do
        expect(connection_options[:username]).to eq(ENV.fetch("TEST_DB_USER", nil))
      end

      it "has the correct password" do
        expect(connection_options[:password]).to eq(ENV.fetch("TEST_DB_PASS", nil))
      end
    end
  end

  describe "#query" do
    let :query do
      trilogy.query("SELECT CURRENT_USER() AS user")
    end

    context "when aurora_disconnect_on_readonly is true" do
      let :query do
        trilogy.query("SELECT CURRENT_USER() AS user")
      end

      let(:aurora_disconnect_on_readonly) { true }

      before do
        allow(trilogy).to receive(:warn)
        allow(trilogy.trilogy).to(
          receive(:query)
          .and_raise(
            Trilogy::BaseError,
            "ERROR 1290 (HY000): The MySQL server is running with the" \
            "--read-only option so it cannot execute this statement"
          )
        )
      end

      describe "#query" do
        it "disconnects immediately" do
          expect(trilogy).to receive(:disconnect!)
          expect { query }.to raise_error(Trilogy::Error)
        end
      end
    end

    it "return a Trilogy::Result" do
      expect(query).to be_instance_of(Trilogy::Result)
    end

    it "returns a result of size 1" do
      expect(query.to_a.size).to eq(1)
    end

    it "returns the correct result" do
      expect(query.to_a.first.first).to match(/^root@.+$/)
    end

    it "calls the original Trilogy's #query" do
      expect(trilogy.trilogy).to receive(:query).once
      query
    end

    context "when Trilogy::Error is raised" do
      before do
        allow(trilogy).to receive(:warn)
        allow(trilogy).to receive(:sleep)
        allow(trilogy).to receive(:reconnect!)
        allow(trilogy.trilogy).to(
          receive(:query)
          .and_raise(
            Trilogy::BaseError,
            "ERROR 1290 (HY000): The MySQL server is running with the" \
            "--read-only option so it cannot execute this statement"
          )
        )
      end

      it "reconnects 10 times" do
        expect(trilogy).to receive(:reconnect!).exactly(10).times
        expect { query }.to raise_error(Trilogy::Error)
      end

      it "retries 10 times" do
        expect(trilogy.trilogy).to receive(:query).exactly(11).times
        expect { query }.to raise_error(Trilogy::Error)
      end

      it "retries at the correct interval" do
        [0, 1.5, 3, 4.5, 6, 7.5, 9, 10, 10, 10].each do |seconds|
          expect(trilogy).to receive(:sleep).with(seconds).ordered
        end
        expect { query }.to raise_error(Trilogy::Error)
      end

      context "when Trilogy::Error is not a failover error" do
        before do
          allow(trilogy.trilogy).to receive(:query).and_raise(Trilogy::BaseError,
                                                              "Unknown column 'hogehoge' in 'field list'")
        end

        it "does not reconnect" do
          expect(trilogy).not_to receive(:reconnect!)
          expect { query }.to raise_error(Trilogy::Error)
        end

        it "does not retry query" do
          expect(trilogy.trilogy).to receive(:query).once
          expect { query }.to raise_error(Trilogy::Error)
        end
      end
    end

    context "when StandardError is raised" do
      before do
        allow(trilogy.trilogy).to receive(:query).and_raise(StandardError)
      end

      it "does not reconnect" do
        expect(trilogy).not_to receive(:reconnect!)
        expect { query }.to raise_error(StandardError)
      end

      it "does not retry query" do
        expect(trilogy.trilogy).to receive(:query).once
        expect { query }.to raise_error(StandardError)
      end
    end
  end

  describe "#reconnect!" do
    let(:reconnect!) { trilogy.reconnect! }

    it "changes the existing trilogy client" do
      expect { reconnect! }.to change(trilogy, :trilogy)
    end

    it "sets the trilogy client to a new instance of Trilogy" do
      reconnect!
      expect(trilogy.trilogy).to be_instance_of(TrilogyAurora::ORIGINAL_TRILOGY_CLASS)
    end

    it "closes the old #trilogy" do
      expect(trilogy.trilogy).to receive(:close).once
      reconnect!
    end

    context "when #close raises an error" do
      before do
        allow(trilogy.trilogy).to receive(:close).and_raise(Trilogy::BaseError)
      end

      it "does not raise error" do
        expect { reconnect! }.not_to raise_error
      end

      it "changes the existing trilogy client" do
        expect { reconnect! }.to change(trilogy, :trilogy)
      end

      it "sets the trilogy client to a new instance of Trilogy" do
        reconnect!
        expect(trilogy.trilogy).to be_instance_of(TrilogyAurora::ORIGINAL_TRILOGY_CLASS)
      end
    end

    context "when `trilogy` is nil" do
      before do
        trilogy.instance_variable_set(:@trilogy, nil)
      end

      it "changes the existing trilogy client from nil" do
        expect { reconnect! }.to change(trilogy, :trilogy).from(nil)
      end

      it "sets the trilogy client to a new instance of Trilogy" do
        reconnect!
        expect(trilogy.trilogy).to be_instance_of(TrilogyAurora::ORIGINAL_TRILOGY_CLASS)
      end
    end
  end

  describe "#method_missing" do
    it "delegates to #trilogy" do
      expect(trilogy.trilogy).to receive(:ping)
      trilogy.ping
    end
  end

  describe "#respond_to_missing?" do
    it "delegates to #trilogy" do
      expect(trilogy.trilogy).to receive(:respond_to?).with(:foobar, false)
      trilogy.respond_to?(:foobar)
    end
  end

  describe ".method_missing" do
    it "delegates to Trilogy" do
      expect(TrilogyAurora::ORIGINAL_TRILOGY_CLASS).to receive(:foobar)
      TrilogyAurora::Trilogy.foobar
    end
  end

  describe ".respond_to_missing?" do
    it "delegates to Trilogy" do
      expect(TrilogyAurora::ORIGINAL_TRILOGY_CLASS).to receive(:respond_to?).with(:foobar, false)
      TrilogyAurora::Trilogy.respond_to?(:foobar)
    end
  end

  describe ".const_missing" do
    it "delegates to Trilogy" do
      expect(TrilogyAurora::Trilogy::SERVER_STATUS_IN_TRANS).to(
        eq(TrilogyAurora::ORIGINAL_TRILOGY_CLASS::SERVER_STATUS_IN_TRANS)
      )
    end
  end
end
