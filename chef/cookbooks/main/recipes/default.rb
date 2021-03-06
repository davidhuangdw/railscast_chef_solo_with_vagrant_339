package 'git-core'
package 'zsh'

user node[:user][:name] do
  password node[:user][:password]
  gid "adm"
  home "/home/#{node[:user][:name]}"
  supports manage_home: true
  shell "/usr/bin/zsh"
end

template "/home/#{node[:user][:name]}/.zshrc" do
  source "zshrc.erb"
  owner node[:user][:name]
end