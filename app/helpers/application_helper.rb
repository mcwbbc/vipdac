# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def all_error_messages_for(*models) 
    errors = []
    for object_name in models
      object = instance_variable_get("@#{object_name.to_s}")
      if object && !object.errors.empty?
        object.errors.full_messages.each { |error| errors << error if !(error =~ /is invalid/)}
      end
    end
  
    unless errors.empty?
      content_tag("div",
        content_tag("h1", "There are problems with your submission") +
        content_tag("ul", errors.collect { |error| content_tag("li", error) }),
        "id" =>  "errorExplanation", "class" => "errorExplanation"
      )
    end
  end

  def page_title(title)
    "<div class='page-title'>#{title}</div>"
  end

  FLASH_NOTICE_KEYS = [:success, :notice, :warning, :error]

  def flash_messages
    return unless messages = flash.keys.select{|k| FLASH_NOTICE_KEYS.include?(k)}
    formatted_messages = messages.map do |type|      
      content_tag :div, :class => type.to_s do
        message_for_item(flash[type], flash["#{type}_item".to_sym])
      end
    end
    formatted_messages.join
  end

  def message_for_item(message, item = nil)
    if item.is_a?(Array)
      message % link_to(*item)
    else
      message % item
    end
  end

  # Only need this helper once, it will provide an interface to convert a block into a partial.
    # 1. Capture is a Rails helper which will 'capture' the output of a block into a variable
    # 2. Merge the 'body' variable into our options hash
    # 3. Render the partial with the given options hash. Just like calling the partial directly.
  def block_to_partial(partial_name, options = {}, &block)
    options.merge!(:body => capture(&block))
    concat(render(:partial => partial_name, :locals => options))
  end

  # Create as many of these as you like, each should call a different partial 
    # 1. Render 'shared/rounded_box' partial with the given options and block content
  def rounded_box(css_class, options = {}, &block)
    block_to_partial('shared/rounded_box', options.merge(:css_class => css_class), &block)
  end
  
  def nice_date(date)
    if date.instance_of?(Float)
      date = Time.at(date)
    end
    h date.strftime("%m-%d-%Y %I:%M%P")
  end

  def pretty_time(t)
    t ? '%.3f' % t : 0
  end

  def age_in_seconds(starting, ending)
    if ((starting > 0) && (ending > 0))
      seconds = ending - starting
      pretty_time(seconds)
    else
      "Not completed"
    end
  end

  def time_in_seconds(seconds)
    "#{pluralize(( '%.2f' % seconds), 'Seconds')}"
  end

  def time_in_minutes(seconds)
    minutes = (seconds/60).to_i
    m_seconds = (seconds % 60).to_i
    pluralize(minutes, 'Minute')+" "+pluralize(m_seconds, 'Second')
  end

  def time_in_hours(seconds)
    minutes = (seconds/60).to_i
    hours = (seconds/3600).to_i
    h_minutes = minutes % 60
    pluralize(hours, 'Hour')+" "+pluralize(h_minutes, 'Minute')
  end

  def time_in_days(seconds)
    hours = (seconds/3600).to_i
    days = (seconds/(3600*24)).to_i
    h_hours = hours % 24
    pluralize(days, 'Day')+" "+pluralize(h_hours, 'Hour')
  end

  def age(starting, ending)
    return "Not launched" unless (starting > 0)
    ending = Time.now.to_f unless (ending > 0)
    seconds = ending - starting
    case seconds
    when 0..59
      time_in_seconds(seconds)
    when 60..3599
      time_in_minutes(seconds)
    when 3600..((3600*24)-1)
      time_in_hours(seconds)
    else
      time_in_days(seconds)
    end
  end

end
