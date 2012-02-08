require 'engine'

module Lascivious
  
  # API key for Kiss Metrics. Available via https://www.kissmetrics.com/settings
  mattr_accessor :api_key
  @@api_key = ""
  ::ActionView::Base.send(:include, Lascivious)
  ::ActionController::Base.send(:include, Lascivious)
  
  # For use in config so we can do Lascivious.setup
  def self.setup
    yield self
  end
  
  # The main kiss metrics javascript & stuff
  def kiss_metrics_tag
    render :partial => "lascivious/header"
  end
  
  # The email beacon
  def kiss_metrics_email_beacon(email_address, variation, event_type = "Opened Email")
    render :partial => "lascivious/email_beacon", :locals => {
      :event_type => event_type,
      :api_key => kiss_metrics_api_key,
      :email => email_address,
      :variation => variation
    }
  end
  
  # Flash for all kiss metrics
  def kiss_metrics_flash
    messages = flash[:kiss_metrics]

    returnarr = "";

    unless messages.blank? || messages.empty?
      messages.map do |type_hash|
        type_hash.map do |e|
          if not (e.first.to_s == "props" || e.first.to_s == "record")
            returnarr = returnarr + %Q{_kmq.push(['#{e.first.to_s}', '#{e.last.to_s}']);}
          end
        end
      end.flatten.join("\n")
    end
    
    logger.info "LASCIVIOUS INFO: " + messages.to_s  
    unless messages.blank? || messages.empty?
      messages.each do |mhash|
        if mhash.first[0] == :record
          recordstr = ""
          mhash.each do |msg|
            if msg.first == :record
              recordstr = %Q{'#{msg.first.to_s}', '#{msg.last.to_s}'}
            end
            if msg.first == "props"
              opts = msg.last.to_s.gsub("=>", ":").gsub("\"","'")
              logger.info %Q{_kmq.push([#{recordstr}, #{opts}]);} 
              returnarr = returnarr + %Q{_kmq.push([#{recordstr}, #{opts}]);} 
            end
          end
        end     
      end
    end
  
    return returnarr
  end

  # Trigger an event at Kiss (specific: message of event_type 'record', e.g. User Signed Up)
  def kiss_record(value, properties="")
    kiss_metric :record, value, properties
  end
  
  # Set values (e.g. country: uk)
  def kiss_set(value)
    kiss_metric :set, value
  end
  
  # Strong identifier (e.g. user ID)
  def kiss_identify(value)
    kiss_metric :identify, value
  end
  
  # Weak identifier (e.g. cookie)
  def kiss_alias(value)
    kiss_metric :alias, value
  end

  # 
  def kiss_metric(event_type, value, properties = "")
    flash[:kiss_metrics] ||= []
    flash[:kiss_metrics] << { event_type => value, 'props' => properties }
  end
  
  # Get kiss metrics key
  def kiss_metrics_api_key
    return Lascivious.api_key
  end
end