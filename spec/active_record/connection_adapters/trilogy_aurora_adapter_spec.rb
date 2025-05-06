# frozen_string_literal: true

RSpec.describe ActiveRecord::ConnectionAdapters::TrilogyAuroraAdapter do
  let :options do
    {
      host: '127.0.0.1',
      port: `docker compose port mysql 3306`.chomp[/[0-9]+$/],
      username: 'root',
      password: nil
    }
  end

  describe '::new_client' do
    it 'create an instance of TrilogyAurora::Client' do
      expect(described_class.new_client(options)).to be_instance_of(TrilogyAurora::Client)
    end

    it 'raises an error' do
      # expect(described_class).to receive(:translate_connect_error)
      expect { described_class.new_client({}) }.to raise_error(ActiveRecord::ConnectionNotEstablished)
    end
  end
end
