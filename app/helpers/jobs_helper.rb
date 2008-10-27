module JobsHelper

  def complete_bar(job)
    html = ""
    return "N/A" if job.chunks.empty?
    total = job.chunks.first.chunk_count.to_f
    complete = job.chunks.complete.size.to_f
    percent = ((complete/total)*100).to_i
    html << image_tag("layout/bar_left.gif", :border => 0)+image_tag("layout/bar_mid.gif", :width=> percent, :height => 10, :border => 0)+image_tag("layout/bar_right.gif", :border => 0)
    html << " #{percent}%"
    html
  end

end
