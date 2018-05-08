require 'rbvmomi'


#size Methods
def bytetoGB(sizein)
  sizeout = sizein/1024/1024/1024
end

def MBtoGB(sizein)
  sizeout = sizein/1024
end

#datadog method
def datadogmetric(label1, label2, host, metric, env)
  currenttime = Time.now.to_i
  datadogoutput = `curl -sS -H "Content-type: application/json" -X POST -d \
        '{"series":\
            [{"metric":"vmware.#{label1}.#{label2}}",
             "points":[[#{currenttime}, #{metric}]],
             "type":"gauge",
             "host":"#{host}",
             "tags":["vmware_env:#{env}"]}]}' \
             https://app.datadoghq.com/api/v1/series?api_key=#{ENV['DATADOG_API_KEY']}`
end

##Connect to vCenter Variables
v = RbVmomi::VIM
vim = v.connect host: "#{ENV['ESX_HOST']}", insecure: true, user: "#{ENV['ESX_USER']}", password: "#{ENV['ESX_PASSWORD']}"
dc = vim.serviceInstance.find_datacenter path="Digital Services"

#pull ESX Host stats
dc.hostFolder.children.first.host.each do |host|
  puts "-----------------------------"
  puts host.summary.config.name.downcase
  puts "Logical Processors: #{host.hardware.cpuInfo.numCpuCores.to_i * 2}"
  cpucapacity = 45.88
  cpuused = (host.summary.quickStats.overallCpuUsage.to_f/1000).round(1)
  cpufree = (45.88-(host.summary.quickStats.overallCpuUsage.to_f/1000)).round(1)
  cpuusedperc = ((((host.summary.quickStats.overallCpuUsage.to_f/1000))/45.88)*100).round(2)
  cpufreeperc = (100-((((host.summary.quickStats.overallCpuUsage.to_f/1000))/45.88)*100)).round(2)
  memcap = bytetoGB(host.hardware.memorySize.to_i)
  memuse = MBtoGB(host.summary.quickStats.overallMemoryUsage.to_i)
  memfree = memcap - memuse
  memfreeperc = ((memuse.to_f/memcap.to_f)*100).round(2)
  memusedperc = (100-((memuse.to_f/memcap.to_f)*100)).round(2)
  puts "CPU Capacity: #{cpucapacity} GHz"
  puts "CPU Used: #{cpuused} GHz"
  puts "CPU Free: #{cpufree} GHz"
  puts "CPU Used: #{cpuusedperc} %"
  puts "CPU Free: #{cpufreeperc} %"
  puts "Memory Capacity: #{memcap} GB"
  puts "Memory Used: #{memuse} GB"
  puts "Memory Free: #{memfree} GB"
  puts "Memory Used: #{memusedperc} %"
  puts "Memory Free: #{memfreeperc} %"
  puts "posting metrics to datadog started"
  datadogmetric("cpu", "capacity", host.summary.config.name.downcase, cpucapacity, "tent")
  datadogmetric("cpu", "used", host.summary.config.name.downcase, cpuused, "tent")
  datadogmetric("cpu", "free", host.summary.config.name.downcase, cpufree, "tent")
  datadogmetric("cpu", "percent_used", host.summary.config.name.downcase, cpuusedperc, "tent")
  datadogmetric("cpu", "percent_free", host.summary.config.name.downcase, cpufreeperc, "tent")
  datadogmetric("memory", "capacity", host.summary.config.name.downcase, memcap, "tent")
  datadogmetric("memory", "used", host.summary.config.name.downcase, memuse, "tent")
  datadogmetric("memory", "free", host.summary.config.name.downcase, memfree, "tent")
  datadogmetric("memory", "percent_used", host.summary.config.name.downcase, memusedperc, "tent")
  datadogmetric("memory", "percent_free", host.summary.config.name.downcase, memfreeperc, "tent")
  puts "posting metrics to datadog completed"
end

#free space of Datastore (single datastore)
puts "===================================="
ds_array = ['GDC-CloudFoundry-VMAX1-01', 'GDC-CloudFoundry-VMAX1-02']
ds_array.each do |datastore|
  puts "------------------------------------"
  ds = dc.find_datastore name = "#{datastore}"
 puts "#{datastore}"
 dscapacity = bytetoGB(ds.summary.capacity.to_i)
 dsused = bytetoGB(ds.summary.capacity.to_i) - bytetoGB(ds.summary.freeSpace.to_i)
 dsfree = bytetoGB(ds.summary.freeSpace.to_i)
 puts "Datastore Capacity: #{dscapacity} GB"
 puts "Datastore Used: #{dsused} GB"
 puts "Datastore Free: #{dsfree} GB"
 puts "posting metics to datadog started"
 datadogmetric("storage", "capacity", datastore, dscapacity, "tent")
 datadogmetric("storage", "used", datastore, dsused, "tent")
 datadogmetric("storage", "free", datastore, dsfree, "tent")
 puts "posting metrics to datadog completed"
end