module NodesHelper

  def aws_params(node)
    "State: " << node[:aws_state] << "<br />" <<
    "Reason: " << node[:aws_reason] << "<br />" <<
    "AMI: " << node[:aws_image_id] << "<br />" <<
    "DNS Name: " << node[:dns_name] << "<br />" <<
    "Launch Time: " << node[:aws_launch_time] << "<br />"
  end

  def row_color(status)
    case status
      when "running"
        "complete"
      when "terminated"
        "created"
      else
        "working"
    end
  end

end
