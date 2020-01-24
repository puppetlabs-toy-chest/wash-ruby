require 'json'
require 'wash'

class TestPlugin < Wash::Entry
  label 'test'
  is_singleton

  def init(_config); end
  def list; end
  def metadata; end
  def schema; end
  def read; end
  def stream; end
  def write; end
  def exec; end
  def signal; end
  def delete; end
end

class JsonLike
  def initialize(hash)
    @hash = hash
  end

  def ===(obj)
    symbolize_keys = @hash.keys.any? {|k, _| k.class == Symbol }
    other = JSON.parse(obj, symbolize_names: symbolize_keys)
    @hash == other
  end
end

describe Wash do
  describe 'pretty_print?' do
    it { eq(false) }

    context 'set to true' do
      before { Wash.pretty_print }
      it { eq(true) }
    end
  end

  describe 'entry_schemas_enabled?' do
    it { eq(false) }

    context 'set to true' do
      before { Wash.enable_entry_schemas }
      it { eq(true) }
    end
  end

  describe 'run' do
    context 'a root_klass' do
      let(:klass) { TestPlugin }
      let(:path) { '/test' }
      let(:state) { '{"klass":"TestPlugin"}' }
      def run(method); Wash.run(klass, [method, path, state]) end

      it 'invokes init' do
        expect_any_instance_of(klass).to receive(:init).with(foo: 1)
        expect { Wash.run(klass, %w[init {"foo":1}]) }.to output(/type_id.*TestPlugin/).to_stdout
      end

      it 'invokes list' do
        expect_any_instance_of(klass).to receive(:list).and_return([{name: 'basic entry', methods: []}])
        expect { run('list') }.to output(/basic entry/).to_stdout
      end

      it 'invokes metadata' do
        expect_any_instance_of(klass).to receive(:metadata).and_return(some: 'metadata')
        expect { run('metadata') }.to output(JsonLike.new(some: 'metadata')).to_stdout
      end

      it 'invokes schema' do
        expect_any_instance_of(klass).to receive(:schema).and_return(some: 'schema')
        expect { run('schema') }.to output(JsonLike.new(some: 'schema')).to_stdout
      end

      it 'invokes read' do
        expect_any_instance_of(klass).to receive(:read).and_return('some text')
        expect { run('read') }.to output('some text').to_stdout
      end

      it 'invokes stream' do
        expect_any_instance_of(klass).to receive(:stream) { puts 'some text' }
        expect { run('stream') }.to output("some text\n").to_stdout.
          and raise_error('stream should never return')
      end

      it 'invokes write' do
        expect_any_instance_of(klass).to receive(:write).with($stdin)
        run('write')
      end

      it 'invokes exec' do
        expect_any_instance_of(klass).to receive(:exec).with('whoami', [], {stdin: nil}).and_return(1)
        expect {
          Wash.run(klass, ['exec', path, state, '{"stdin":false}', 'whoami'])
        }.to raise_error SystemExit
      end

      it 'invokes signal' do
        expect_any_instance_of(klass).to receive(:signal).with('hello_in_there')
        Wash.run(klass, ['signal', path, state, 'hello_in_there'])
      end

      it 'invokes delete' do
        expect_any_instance_of(klass).to receive(:delete)
        Wash.run(klass, ['delete', path, state])
      end
    end
  end
end
