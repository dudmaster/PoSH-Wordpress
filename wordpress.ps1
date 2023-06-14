# Execution Policy #

Set-ExecutionPolicy RemoteSigned
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

# Variables #

$SqlDownloadURL = 'https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.33-winx64.zip'
$PhpDownloadURL = 'https://windows.php.net/downloads/releases/php-8.2.7-nts-Win32-vs16-x64.zip'
$WpDownloadURL = 'https://wordpress.org/latest.zip'
$DownloadPath = 'C:\Users\Administrator\Documents\'
$SqlZipPath = 'C:\Users\Administrator\Documents\mysql-8.0.33-winx64.zip'
$PhpZipPath = 'C:\Users\Administrator\Documents\php-8.2.7-nts-Win32-vs16-x64.zip'
$WpZipPath = 'C:\Users\Administrator\Documents\wordpress-6.2.2.zip'
$MysqlPath = 'C:\Program Files (x86)\MySQL'
$PhpPath = 'C:\PHP'
$WpPath = 'C:\inetpub\wwwroot\wordpress'


# Web-Server #

Install-WindowsFeature -name Web-Server -IncludeAllSubFeature

# MySQL #

# Chocolatey download & installation #

Set-ExecutionPolicy Bypass -Scope Process -Force; 
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# MySQL installation (for another flags refer to manual) #

choco install mysql -y



# PHP #

# Download #

Invoke-WebRequest -Uri $PHPDownloadURL -OutFile $PhpZipPath

# Extracting archive and moving to C:\ root directory #

New-Item $PhpPath -ItemType Directory 
Expand-Archive -LiteralPath $PhpZipPath -DestinationPath $PhpPath

# php.ini config file #

Rename-Item -Path "C:\PHP\php.ini-production" -NewName "php.ini"

# Enviromental Variable #

$env:Path += ';C:\PHP'

# Editing configuration file php.ini #

(get-content c:\PHP\php.ini).Replace(';cgi.force_redirect = 1','cgi.force_redirect = 0') | Set-Content c:\PHP\php.ini
(get-content c:\PHP\php.ini).Replace(';cgi.fix_pathinfo=1','cgi.fix_pathinfo = 1') | Set-Content c:\PHP\php.ini
(get-content c:\PHP\php.ini).Replace(';fastcgi.logging = 0','fastcgi.logging = 0') | Set-Content c:\PHP\php.ini
(get-content c:\PHP\php.ini).Replace(';extension=mysqli','extension = mysqli') | Set-Content c:\PHP\php.ini
(get-content c:\PHP\php.ini).Replace(';;extension=pdo_mysql','extension = pdo_mysql') | Set-Content c:\PHP\php.ini


# Wordpress #


# AD Administrator account for wordpress #

$pw = Read-Host -Prompt 'passwrd for wordpress_svc' -AsSecureString 
New-ADUser -Name wordpress_svc -AccountPassword $pw -Passwordneverexpires $true -Enabled $true 
Add-ADGroupMember -Identity "Administrators" -Members wordpress_svc

# IIS website configuration #

# FastCGI #

New-WebHandler -Name "PHP_via_FastCGI" -Path "*.php" -Verb "*" -Modules "FastCgiModule" -ScriptProcessor "C:\PHP\php-cgi.exe" -ResourceType Either

# Default Document #

Add-WebConfigurationProperty -Filter "//defaultDocument/files" -PSPath "IIS:\sites\DefaultWebSite" -AtIndex 0 -Name "Collection" -Value "index.php"

# Wordpress Application Pool #

New-WebAppPool -Name "Wordpress"
Import-Module WebAdministration

# Application Pool Credentials #

Set-ItemProperty IIS:\AppPools\Wordpress -name processModel -value @{userName="LOPATA\wordpress_svc";password="Admin1!";identitytype=3}



# Wordpress download #

Invoke-WebRequest -Uri $WpDownloadURL -OutFile $WpZipPath

# Archive extraction to wwwroot directory #

Expand-Archive -LiteralPath $WpZipPath -DestinationPath $WpPath

# Configuration file renaming #

Rename-Item -Path "C:\inetpub\wwwroot\wordpress\wordpress\wp-config-sample.php" -NewName "wp-config.php"

# Editing configuration file wp-config.php #

(get-content C:\inetpub\wwwroot\wordpress\wordpress\wp-config.php).Replace("define( 'DB_NAME', 'database_name_here');","define( 'DB_NAME', 'wordpress');") | Set-Content C:\inetpub\wwwroot\wordpress\wordpress\wp-config.php
(get-content C:\inetpub\wwwroot\wordpress\wordpress\wp-config.php).Replace("define( 'DB_USER', 'username_here');","define( 'DB_USER', 'root');") | Set-Content C:\inetpub\wwwroot\wordpress\wordpress\wp-config.php
(get-content C:\inetpub\wwwroot\wordpress\wordpress\wp-config.php).Replace("define( 'DB_PASSWORD', 'password_here');","define( 'DB_PASSWORD', '');") | Set-Content C:\inetpub\wwwroot\wordpress\wordpress\wp-config.php