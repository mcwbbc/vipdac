module JobsHelper

  def complete_bar(job)
    html = ""
    return "N/A" if job.chunks.empty?
    total = job.chunks.first.chunk_count.to_f
    complete = job.chunks.complete.size.to_f
    percent = ((complete/total)*100).to_i
    html << image_tag("layout/bar_left.gif", :border => 0)+image_tag("layout/bar_mid.gif", :width => percent*2, :height => 10, :border => 0)+image_tag("layout/bar_right.gif", :border => 0)
    html << " #{percent}%"
    html
  end

  def job_header(stats)
    header = stats.keys.sort.inject([]) { |array, key| array << key if !["parameters", "chunks"].include?(key); array }
    header.join(",")
  end

  def job_values(stats)
    values = stats.keys.sort.inject([]) { |array, key| array << stats[key] if !["parameters", "chunks"].include?(key); array }
    values.join(",")
  end

  def chunk_header(stats)
    header = stats['chunks'].first.keys.sort.inject([]) { |array, key| array << key; array }
    header.join(",")
  end

  def chunk_values(stats, csv=false)
    string = ""
    stats['chunks'].each do |chunk|
      values = chunk.keys.sort.inject([]) { |array, key| array << chunk[key] || " "; array }
      string << values.join(",")
      if csv
        string <<"\n"
      else
        string << "<br />"
      end
    end
    string
  end

  def parameter_header(stats)
    header = stats['parameters'].keys.sort.inject([]) { |array, key| array << key; array }
    header.join(",")
  end

  def parameter_values(stats)
    values = stats['parameters'].keys.sort.inject([]) do |array, key|
      value = ""
      if key == 'modifications' && stats['parameters'][key].is_a?(Array)
        stats['parameters'][key].each do |modification|
          value << "#{modification['amino_acid']}:#{modification['mass']};"
        end
        value.chomp!(";")
      else
        value = stats['parameters'][key].to_s.gsub(",", ";")
      end
      array << value
      array
    end
    values.join(",")
  end

end
