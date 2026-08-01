# frozen_string_literal: true

require "stubs/user"

class TestSocket
  attr_reader :identifiers, :logger, :current_user, :server, :subscriptions, :transmissions

  delegate :pubsub, :config, :executor, to: :server

  def initialize(user = User.new("lifo"), coder: ActiveSupport::JSON, subscription_adapter: SuccessAdapter)
    @coder = coder
    @identifiers = [ :current_user ]

    @current_user = user
    @logger = ActiveSupport::TaggedLogging.new ActiveSupport::Logger.new(StringIO.new)
    @server = TestServer.new(subscription_adapter: subscription_adapter)
    @subscriptions = ActionCable::Connection::Subscriptions.new(self)
    @transmissions = []
  end

  def perform_work(receiver, method, *args)
    receiver.send method, *args
  end

  def transmit(cable_message = nil, coder: nil, **cable_options)
    cable_message = cable_options if cable_message.nil? && cable_options.any?
    @transmissions << encode(cable_message, coder: coder)
  end

  def last_transmission
    decode @transmissions.last if @transmissions.any?
  end

  def decode(websocket_message)
    @coder.decode websocket_message
  end

  def encode(cable_message, coder: nil)
    if coder
      cable_message = cable_message.dup
      cable_message[:message] = if defined?(::JSON::Fragment) && coder == ActiveSupport::JSON && @coder == ActiveSupport::JSON
        ::JSON::Fragment.new(cable_message[:message])
      else
        coder.decode(cable_message[:message])
      end
    end

    @coder.encode cable_message
  end
end
