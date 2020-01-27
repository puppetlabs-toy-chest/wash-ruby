require 'wash/streamer'

describe Wash::Streamer do
  it 'writes 200 then output' do
    expect {
      subject.write("hello")
      subject.write(" world")
    }.to output("200\nhello world").to_stdout
  end
end
