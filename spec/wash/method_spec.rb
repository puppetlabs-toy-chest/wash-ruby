require 'wash/entry'
require 'wash/method'

describe Wash::Method do
  describe 'invoke' do
    context 'an entry' do
      let(:entry) { TestEntry.new }

      it 'invokes a known method' do
        expect {
          subject.send(:invoke, 'list', entry)
        }.to output("[]\n").to_stdout
      end

      it 'passes arguments to the method' do
        subject.send(:invoke, 'signal', entry, 'hello')
        expect(entry.sig).to eq('hello')
      end

      it 'errors on an undefined method' do
        expect {
          subject.send(:invoke, 'foo', entry)
        }.to raise_error("Entry test (TestEntry) does not implement foo")
      end

      it 'errors on an unexpected method' do
        expect {
          subject.send(:invoke, 'other', entry)
        }.to raise_error("other is not a supported Wash method")
      end
    end
  end
end

class TestEntry < Wash::Entry
  attr_reader :sig

  def initialize
    @name = 'test'
  end

  def list
    []
  end

  def signal(sig)
    @sig = sig
    nil
  end

  def other; end
end
