Get-ChildItem cert:\LocalMachine\My | Where-Object { $_.Subject -match "CN=::if APP_COMPANYID::APP_COMPANYID::else::NME_Example::end::" } | Remove-Item
New-SelfSignedCertificate -Type Custom -Subject "CN=::if APP_COMPANYID::APP_COMPANYID::else::NME_Example::end::" -KeyUsage DigitalSignature -FriendlyName NMEDisplayingCert -CertStoreLocation "Cert:\LocalMachine\My"
#Get-ChildItem cert:\LocalMachine\My | Where-Object { $_.Subject -match "CN=::if APP_COMPANYID::APP_COMPANYID::else::NME_Example::end::" }
$pwd = ConvertTo-SecureString -String ::if APP_CERTIFICATE_PWD::APP_CERTIFICATE_PWD::else::"nmeexample"::end:: -Force -AsPlainText 
$thumbprint=(dir cert:\localmachine\My -recurse | where {$_.Subject -match "CN=::if APP_COMPANYID::APP_COMPANYID::else::NME_Example::end::"} ).Thumbprint;
Export-PfxCertificate -cert "Cert:\LocalMachine\My\$thumbprint" -FilePath ::APP_FILE::.pfx -Password $pwd
