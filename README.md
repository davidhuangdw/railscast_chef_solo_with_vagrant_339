* berkshelf: scaffold cookbook downloading from http://supermarket.getchef.com

        # install chef-dk: http://downloads.getchef.com/chef-dk/mac/
        gem uninstall berkshelf         # don't use bershelf gem's bin, use chef-dk

        # init
        cd cookbooks/main
        berks init                  # init with exist cookbooks/xxx path
        cd cookbooks
        berks cookbook myapp        # or, create new cookbook
        rm myapp/Vagrantfile        # use my own Vagrantfile

        # install vagrant plugin
        vagrant plugin install vagrant-berkshelf            

        # Vagrantfile
          config.berkshelf.enabled = true
          config.berkshelf.berksfile_path = "./cookbooks/myapp/Berksfile"   #set path
          config.vm.provision "chef_solo" do |chef|
            chef.run_list = [
                "recipe[myapp]"
            ]
          end

        # cookbooks/myapp/Berksfile
        cookbook 'nginx'
        # cookbook 'nginx', '~>2.0'             # or require version
        # cookbook 'myown', path: '../myown'    # or local cookbook

        # cookbooks/myapp/recipes/default.rb
        include_recipe 'nginx'

        # override json attr: cookbooks/myapp/attributes/default.rb
        node.override['nginx']['default_site_enabled'] = false

        cd cookbooks/myapp
        berks install               # download cookbooks
        vagrant reload
        vagrant provision


* knife: scaffold a new cookbook

        knife cookbook create nginx -o cookbooks/
        # cookbooks/nginx/recipes/default.rb
        package 'nginx'

        # use vagrant provision to apply: Vagrantfile
          config.vm.provision "chef_solo" do |chef|
            chef.run_list = [
                "recipe[nginx]"
            ]
          end
        # run
        vagrant reload          # for the first time
        vagrant provision


* download shared cookbooks: https://supermarket.getchef.com

* templates resource

        # default.rb
        package 'zsh'
        template "/home/#{node[:user][:name]}/.zshrc" do
          source "zshrc.erb"
          owner node[:user][:name]
        end
        # cookbooks/main/templates/default/zshrc.erb
        export PS1='%m:%3~%# '
        export RAILS_ENV=production
        <% if node[:user][:ls_color] %>
        alias ls='ls --color=auto'
        <% end %>

* chef-solo

        rsync -r root@192.168.10.33:/var/chef/ .
        rsync -r . root@192.168.10.33:/var/chef 
        # generate password hash
        openssl passwd -1 "vagrant"
        # node.json
        {
          "user":{
             "name": "deployer",
             "password": "$1$d3cuHCAg$YTjiMNOcFGrg7mllHV5Hq1"
          },
          "run_list": ["recipe[main]"]
        }
        # default.rb
        package 'git-core'
        user node[:user][:name] do
          password node[:user][:password]
          gid "adm"
          home "/home/#{node[:user][:name]}"
          supports manage_home: true
        end


        # chef-solo
        su --login
        mkdir -p /var/chef/cookbooks/main/recipes
        chef-solo -c solo.rb

        # recipes: /var/chef/cookbooks/main/recipes/default.rb
        package 'git-core'
        ...

        # /var/chef/solo.rb: provide cookbook_path & node.json
        cookbook_path File.expand_path("../cookbooks", __FILE__)
        json_attribs File.expand_path("../node.json", __FILE__)

        # node.json
        { "run_list":["recipe[main]"] }


        # recipe manual: http://docs.getchef.com/chef/resources.html

* chefdk, chef-client, chef-server

        # bootstrap node
        knife bootstrap {{address}} --ssh-user {{user}} --ssh-password '{{password}}' \
          --sudo --use-sudo-password --node-name node1 \
          --run-list 'recipe[learn_chef_apache2]'

        # run cookbook locally
        sudo chef-client --local-mode --runlist 'recipe[learn_chef_apache2]'

        # cookbook
        # install chefdk
        chef generate cookbook learn_chef_apache2
        chef generate template learn_chef_apache index.html
        # learn_chef_apache2/recipes/default.rb
        package 'apache2'
        service 'apache2' do
          action [:start, :enable]
        end
        template '/var/www/html/index.html' do
          source 'index.html.erb'
        end

        # learn_chef_apache2/template/default/index.html.erb
        <html>
          <body>
            <h1>hello from <%= node['fqdn'] %></h1>

            <pre>
              <%= node['hostname'] %>
              <%= node['platform'] %> - <%= node['platform_version'] %>
              <%= node['memory']['total'] %> RAM
              <%= node['cpu']['total'] %> CPUs
            </pre>
          </body>
        </html>


        # chefdk development kit: chef, berkshelf, test kitchen, chefspec, foodcritic, chef-tools: client, knife, chef-zero
        # download: https://downloads.getchef.com/chef-dk/ubuntu/
        sudo dpkg -i chefdk_0.3.5-1_amd64.deb

        # recipe: 
        # method --> define what resource
        # block  --> define action -- how to manage resource
        # default actions: package == install, file == create, service == start ...

*  why chef
    * DRY auto-deploy
    * define abstract task -- easier to read/write; adapt to different system/OS/HW
    * idempotent -- no worry about whether to run
