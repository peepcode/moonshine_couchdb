# **Moonshine::Couchdb** is a Moonshine plugin for installing and configuring [Couchbase Single Server Community Edition](couchbase)
#
#### Prerequisites

# We need to include any class level methods we need.
# We'll also need to configure some sane defaults for versions of the libraries.
#
# [couchbase]: http://www.couchbase.com/products-and-services/couchbase-single-server
# [download]: http://www.couchbase.com/downloads/couchbase-single-server/community
module Moonshine
  module Couchdb

    def self.included(manifest)
      manifest.class_eval do
        configure :couchdb => { :version => 1.1 }
      end
    end

    #### Recipe
    # We define the `:couchdb` recipe which can take inline options.
    #
    # Currently, this respects the following options:
    #
    # * `:version`: version to download, see [download page](download) for what's available
    def couchdb(options = {})
      # couchbase is available online to download, but not from a debian repository.
      # we'll need us some wget and a place to download it to (/usr/local/src)
      package 'wget', :ensure => :installed
      file '/usr/local/src',
        :ensure => :directory
      

      # The couchbase downloads have an architecture in them, but we can rely on Facter for this.
      arch = Facter.architecture
      deb_filename = "couchbase-server-community_#{arch}_#{options[:version]}.deb"
      # Download couchbase, like a bau5.
      exec 'download couchbase',
        :alias => "/usr/local/src/#{deb_filename}",
        :creates => "/usr/local/src/#{deb_filename}",
        :cwd => '/usr/local/src',
        :require => [package('wget'), file('/usr/local/src')],
        :command => "wget --quiet http://c3145442.r42.cf0.rackcdn.com/#{deb_filename} --output-document=#{deb_filename}"

      # With couchbase downloaded, we can use the dpkg provider to ensure the couchbase-server is installed
      package 'couchbase-server',
        :ensure => :installed,
        :provider => :dpkg,
        :source => "/usr/local/src/#{deb_filename}",
        :require => exec('download couchbase')

      # With it installed, make sure it's running.
      service 'couchbase-server',
        :ensure => :running,
        :require => package('couchbase-server')

      # couchbase-server works out of the box, but if any other configuration was needed, this would be a good place for it.
    end
    
  end
end
