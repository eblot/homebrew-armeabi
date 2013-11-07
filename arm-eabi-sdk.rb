require 'formula'

class ArmEabiSdk <Formula

  url 'file://sdk.sh'
  version '1.0'
  sha1 '81ed0600d9ad3e01339d4871314766ef99f5f1d1'

  def install
    mkdir "#{prefix}/bin"
    cp "sdk.sh", "#{prefix}/bin/sdk.sh"
  end
end
