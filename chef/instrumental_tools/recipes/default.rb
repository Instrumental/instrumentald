packagecloud_repo "expectedbehavior/instrumental" do
  case node["platform_family"]
  when "debian"
    type "deb"
  when "rhel"
    type "rpm"
  end
end

package "instrumental-tools" do
  action :install
end

template "/etc/instrumental.yml" do
  source "instrumental.yml.erb"
  mode   "0440"
  owner  "nobody"
  variables(
    :api_key => node[:instrumental][:api_key]
  )
end
