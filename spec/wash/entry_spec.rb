require 'wash/entry'

describe Wash::Entry do
  context 'an entry using transport' do
    let(:entry) { TestTransport.new }

    it 'specifies an exec tuple when listed' do
      json = JSON.generate(entry)
      opts = {host: 'test', user: 'me', password: 'password', port: 86}
      expected = ['exec', {transport: 'ssh', options: opts}]
      expect(json).to include(JSON.generate(expected))
    end

    it 'includes exec in its schema' do
      schema = entry.schema
      expect(schema['TestTransport'][:methods]).to include(:exec)
    end
  end

  context 'an entry with a core entry child' do
    let(:entry) { TestCoreEntry.new }

    it 'specifies a core entry in list results' do
      items = entry.list
      expect(items[0]).to eq({
        'type_id': Wash::Entry::VOLUMEFS,
        'name': 'stuff',
        'state': '{"maxdepth":1}'
      })
    end
  end
end

class TestTransport < Wash::Entry
  def initialize
    @name = 'test'
    transport :ssh, host: @name, user: 'me', password: 'password', port: 86
  end

  def exec
  end
end

class TestCoreEntry < Wash::Entry
  parent_of VOLUMEFS

  def initialize
    @name = 'test'
  end

  def list
    [volumefs('stuff', maxdepth: 1)]
  end
end
