require 'rails_helper'

describe ReviseEvents do
  it 'revises event entries from Elixir Radar' do
    consistent_entry = {
      title: 'ElixirConf',
      url: 'http://elixirconf.com/',
      subtitle: 'Conference = (DOLAR)450; Conference + Training = (DOLAR)700. (expiration: August 22)\n            <br>',
      tag: 'event'
    }

    divergent_entry = {
      title: 'EmpEx -- Halloween Lightning Talks 2016',
      url: 'http://empex.co/',
      subtitle: 'Call for Proposals now open\n        <br>',
      tag: 'event'
    }

    entries = [consistent_entry, divergent_entry]

    revision_result = ReviseEvents.new.call(entries)

    expect(revision_result.size).to eq(2)

    consistent_result_entry = revision_result.first
    expect(consistent_result_entry[:entry_title]).to eq('ElixirConf')
    expect(consistent_result_entry[:divergences]).to be_empty

    divergent_result_entry = revision_result.last
    expect(divergent_result_entry[:entry_title]).to eq('EmpEx -- Halloween Lightning Talks 2016')
    expect(divergent_result_entry[:divergences]).to be_present
    expect(divergent_result_entry[:divergences].first[:reason]).to eq('page_title_does_not_match')
    expect(divergent_result_entry[:divergences].first[:details][:fetched_page_title]).to eq('Empire City Elixir Conf')
  end

  context 'when events are from Meetup.com' do
    it 'revises a consistent event entry' do
      entry = {
        title: 'Sarasota, FL',
        url: 'https://www.meetup.com/SarasotaSoftwareEngineers/events/232976666/',
        subtitle: 'Concurrent Programming with the Elixir ecosystem',
        tag: 'event'
      }

      revision_result = ReviseEvents.new.call([entry])

      consistent_result_entry = revision_result.first
      expect(consistent_result_entry[:entry_title]).to eq('Sarasota, FL')
      expect(consistent_result_entry[:divergences]).to be_empty
    end

    it 'revises a divergent event entry' do
      entry = {
        title: 'Indianapolis­, IN',
        url: 'http://www.meetup.com/indyelixir/events/233392329/',
        subtitle: 'Releasing Hex packages and neural networks',
        tag: 'event'
      }

      revision_result = ReviseEvents.new.call([entry])

      divergent_result_entry = revision_result.first
      expect(divergent_result_entry[:entry_title]).to eq('Indianapolis­, IN')
      expect(divergent_result_entry[:divergences]).to be_present
      expect(divergent_result_entry[:divergences].first[:reason]).to eq('event_title_does_not_match')
      expect(divergent_result_entry[:divergences].first[:details][:given_event_title]).to eq('Releasing Hex packages and neural networks')
      expect(divergent_result_entry[:divergences].first[:details][:fetched_event_title]).to eq('Indy Elixir Monthly Meetup')
    end
  end

  context 'when accessing the entry url raises an error' do
    it 'revises a divergent event entry' do
      entry = {
        title: 'São Paulo, SP',
        url: 'https://sp.femug.com/t/femug-sp-34-plataformatec/865',
        subtitle: '',
        tag: 'event'
      }

      revision_result = ReviseEvents.new.call([entry])

      divergent_result_entry = revision_result.first
      expect(divergent_result_entry[:entry_title]).to eq('São Paulo, SP')
      expect(divergent_result_entry[:divergences]).to be_present
      expect(divergent_result_entry[:divergences].first[:reason]).to eq('connection_error')
      expect(divergent_result_entry[:divergences].first[:details][:error_message]).to eq('OpenSSL::SSL::SSLError: SSL_connect returned=1 errno=0 state=error: certificate verify failed')
    end
  end
end
