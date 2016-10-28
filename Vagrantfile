Vagrant.configure(2) do |config|

  config.vm.box = "fedora/24-cloud-base"

  config.vm.provider "libvirt" do |libvirt, override|
    libvirt.cpus = 2
    libvirt.memory = 4096
    libvirt.driver = 'kvm'
    libvirt.nested = true
    libvirt.storage :file, :size => '20G'
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provision "file", source: "byo-atomic.sh", destination: "byo-atomic.sh"
  config.vm.provision "shell",
    inline: "sed -i 's#^working_dir=.*#working_dir=\"/home/vagrant/working\"#g' byo-atomic.sh"

end
